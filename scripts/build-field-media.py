"""Build runtime textures/normal maps and original synthesized combat SFX.
Requires Pillow and numpy. The three source images were AI-generated material
surfaces for this project, not photographs/scans or third-party game assets.
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import wave
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'godot/assets/materials'; OUT.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(517)
N=1024

def tile(a,band=40):
    a=a.copy()
    for axis in [0,1]:
        for i in range(band):
            w=.5*(1-i/band)**2
            p=[slice(None)]*3;q=p.copy();p[axis]=i;q[axis]=-i-1
            x=a[tuple(p)].copy();y=a[tuple(q)].copy()
            a[tuple(p)]=x*(1-w)+y*w;a[tuple(q)]=y*(1-w)+x*w
    return a

def output(name,a,strength=.7):
    a=np.clip(tile(a),0,255)
    Image.fromarray(a.astype('uint8')).save(OUT/f'{name}.jpg',quality=91)
    height=np.asarray(Image.fromarray(a.astype('uint8')).convert('L').filter(ImageFilter.GaussianBlur(.65)),dtype=float)/255
    dx=(np.roll(height,1,1)-np.roll(height,-1,1))*strength
    dy=(np.roll(height,1,0)-np.roll(height,-1,0))*strength
    normal=np.stack([dx,dy,np.ones_like(dx)],axis=2)
    normal/=np.linalg.norm(normal,axis=2,keepdims=True)
    Image.fromarray(((normal*.5+.5)*255).astype('uint8')).save(OUT/f'{name}-normal.png')

for name,strength in [('meadow',1.5),('masonry',2.0),('steel',.55)]:
    a=np.asarray(Image.open(ROOT/'art-source'/f'{name}-source.png').convert('RGB').resize((N,N)),dtype=float)
    output(name,a,strength)

def noise(scale):
    a=rng.random((scale,scale))*255
    return np.asarray(Image.fromarray(a.astype('uint8')).resize((N,N),Image.Resampling.BICUBIC),dtype=float)/255-.5
Y,X=np.mgrid[:N,:N]
fine=rng.normal(0,1,(N,N))
field=noise(12)*24+noise(80)*14+fine*5
output('earth',np.array([91,78,60])+field[:,:,None],1.4)
wood=noise(80)*13+fine*2+np.sin(X*.26+noise(9)*7)*8+noise(12)*14
output('timber',np.array([78,65,51])+wood[:,:,None],1.0)
cloth=fine*2+np.sin(X*np.pi)*4+np.cos(Y*np.pi)*4+noise(50)*8
output('cloth',np.array([164,162,147])+cloth[:,:,None],.8)
plaster=noise(10)*22+noise(90)*13+fine*4
output('plaster',np.array([150,143,126])+plaster[:,:,None],.7)
roof=noise(50)*15+fine*4
row=Y//128; seam=(Y%128<10)|((X+(row%2)*64)%128<6)
roof[seam]-=30
output('roof',np.array([82,81,77])+roof[:,:,None],1.8)
# Alpha-cutout foliage. Transparent background avoids opaque geometric crowns.
im=Image.new('RGBA',(256,256));d=ImageDraw.Draw(im)
for i in range(72):
    x,y=rng.integers(30,226,2); sz=int(rng.integers(7,18))
    if ((x-128)/104)**2+((y-128)/110)**2>1:continue
    c=int(rng.integers(-12,14))
    d.ellipse((x-sz,y-sz//2,x+sz,y+sz//2),fill=(70+c,80+c,45+c,255))
    d.line((x-sz,y,x+sz,y),fill=(92,89,57,220),width=1)
im.save(OUT/'leaves.png')
# Crossed grass card, narrow translucent blades rather than toy cones.
im=Image.new('RGBA',(128,256));d=ImageDraw.Draw(im)
for i in range(25):
    x=int(rng.integers(8,120)); top=int(rng.integers(10,190)); lean=int(rng.integers(-25,25)); c=int(rng.integers(-12,20))
    d.polygon([(x-2,255),(x+lean,top),(x+2,255)],fill=(96+c,101+c,62+c,255))
im.save(OUT/'grass.png')
AUDIO=ROOT/'godot/assets/audio'; AUDIO.mkdir(parents=True,exist_ok=True)
SR=22050
for name,duration in [('step',.16),('swing',.30),('clang',.45),('impact',.22),('wind',6.)]:
    t=np.arange(int(duration*SR))/SR;n=rng.normal(0,1,len(t))
    if name=='step': signal=(np.convolve(n,np.ones(5)/5,'same')*.38+np.sin(t*2*np.pi*90)*.18)*np.exp(-t*30)
    elif name=='swing': signal=np.convolve(n,np.ones(8)/8,'same')*.6*np.sin(t/duration*np.pi)**2
    elif name=='clang': signal=sum(np.sin(t*2*np.pi*f)*np.exp(-t*(10+i*4))*.1 for i,f in enumerate([941,1513,2269,3411,4727]))+n*.12*np.exp(-t*80)
    elif name=='impact': signal=(np.sin(2*np.pi*(130*t-90*t*t))*.45+np.convolve(n,np.ones(4)/4,'same')*.3)*np.exp(-t*23)
    else:
        # Circular smoothing produces a continuous seamless noise loop.
        freqs=np.fft.rfftfreq(len(t),1/SR)
        signal=np.fft.irfft(np.fft.rfft(n)*np.exp(-freqs/240),n=len(t))*.16
    with wave.open(str(AUDIO/f'{name}.wav'),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR)
        w.writeframes((np.clip(signal,-.95,.95)*32767).astype('<i2').tobytes())
print('Built original runtime material maps, cutouts and five sound effects.')
