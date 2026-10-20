#!/usr/bin/env python3
"""One API-3 Data: base assets + all terrain, pixel-identical lossless WebP.
Reads verified official regions. Never holds the complete library in memory.
"""
import argparse,hashlib,io,json,struct,tempfile,shutil
from pathlib import Path
from PIL import Image,ImageChops
from importlib.machinery import SourceFileLoader
base=SourceFileLoader('base','scripts/build-content-bundle.py').load_module()
def digest(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(65536),b''):h.update(b)
 return h.hexdigest()
def build(regions,out):
 out.parent.mkdir(parents=True,exist_ok=True)
 with tempfile.TemporaryDirectory(dir=out.parent,prefix='complete-') as temp:
  folder=Path(temp); entries=[]; paths=[]
  for root in base.ROOTS:
   for p in sorted(Path('godot/assets',root).rglob('*')):
    if p.is_file() and p.suffix in base.ALLOWED:
     entries.append(dict(path=p.relative_to('godot').as_posix(),bytes=p.stat().st_size,sha256=digest(p)));paths.append(p)
  seen=set()
  for region in sorted(regions.glob('*.icregion')):
   with region.open('rb') as f:
    assert f.read(8)==b'ICREG002'
    n=struct.unpack('<I',f.read(4))[0];assert n<=32768
    m=json.loads(f.read(n)); assert m['api']==2 and len(m['files'])==50
    for e in m['files']:
     assert 0<e['bytes']<=8*1024**2
     raw=f.read(e['bytes']);assert hashlib.sha256(raw).hexdigest()==e['sha256']
     name=e['name']; x,y,kind=name.removesuffix('.png').split('_')
     assert kind in ('albedo','normal') and 0<=int(x)<25 and 0<=int(y)<25
     name=f'{int(x)}_{int(y)}_{kind}.webp';assert name not in seen;seen.add(name)
     image=Image.open(io.BytesIO(raw));image.load();assert image.size==(1024,1024) and image.mode=='RGB'
     p=folder/name;image.save(p,format='WEBP',lossless=True,method=4)
     decoded=Image.open(p).convert('RGB');assert ImageChops.difference(image,decoded).getbbox() is None
     entries.append(dict(path='assets/content/realm/'+name,bytes=p.stat().st_size,sha256=digest(p)));paths.append(p)
    assert not f.read(1)
   print('Converted and pixel-verified',region.name,flush=True)
  assert len(seen)==1250
  manifest=dict(api=3,world_id='ashen-marches',revision=4,files=entries)
  header=json.dumps(manifest,separators=(',',':'),sort_keys=True).encode();assert len(header)<=524288
  with out.open('wb') as f:
   f.write(b'ICDATA03'+struct.pack('<I',len(header))+header)
   for p in paths:
    with p.open('rb') as source:shutil.copyfileobj(source,f,65536)
  assert 1024**3<out.stat().st_size<2*1024**3
  out.with_suffix('.manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
  out.with_suffix('.sha256').write_text(digest(out)+'  '+out.name+'\n')
  print('COMPLETE_DATA_PASS',out.stat().st_size,len(entries),digest(out),flush=True)
if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('regions',type=Path);ap.add_argument('output',type=Path);a=ap.parse_args();build(a.regions,a.output)
