#!/usr/bin/env python3
"""Deterministic CC0 human OBJ/rig -> glTF 2.0, without Blender or proprietary assets.

Full mesh retains the upstream skeleton and four normalized influences per vertex.
The separate head mesh is the first runtime integration; the full rig is staging
content until combat animations and fitted clothing pass engine visual review.
"""
import hashlib,json,math,struct
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'art-source/human'
OUT=ROOT/'godot/assets/models'
meta=json.loads((SRC/'PROVENANCE.json').read_text())
for name,entry in meta['files'].items():
    assert hashlib.sha256((SRC/name).read_bytes()).hexdigest()==entry['sha256'],name
verts=[];faces=[];group=''
for line in (SRC/'base.obj').read_text().splitlines():
    parts=line.split()
    if not parts:continue
    if parts[0]=='v':verts.append(tuple(map(float,parts[1:4])))
    elif parts[0]=='g':group=parts[1]
    elif parts[0]=='f' and group=='body':
        poly=[int(p.split('/')[0])-1 for p in parts[1:]]
        for i in range(1,len(poly)-1):faces.append((poly[0],poly[i],poly[i+1]))
used={i for f in faces for i in f}
floor=min(verts[i][1] for i in used);top=max(verts[i][1] for i in used)
scale=1.84/(top-floor)
def point(v):return (-v[0]*scale,(v[1]-floor)*scale,-v[2]*scale)
positions=[point(v) for v in verts]
def sub(a,b):return tuple(x-y for x,y in zip(a,b))
def cross(a,b):return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def norm(v):
    length=math.sqrt(sum(x*x for x in v))
    return tuple(x/max(length,1e-12) for x in v)
normals=[[0.,0.,0.] for _ in verts]
for a,b,c in faces:
    n=cross(sub(positions[b],positions[a]),sub(positions[c],positions[a]))
    for i in (a,b,c):
        for j in range(3):normals[i][j]+=n[j]
normals=[norm(n) for n in normals]
skel=json.loads((SRC/'default.mhskel').read_text())
weights=json.loads((SRC/'weights.json').read_text())['weights']
# Topological order makes the hierarchy deterministic and easy to validate.
bones=[]
def add_bone(name):
    if name in bones:return
    parent=skel['bones'][name]['parent']
    if parent:add_bone(parent)
    bones.append(name)
for name in sorted(skel['bones']):add_bone(name)
centers=[]
for name in bones:
    ids=skel['joints'][skel['bones'][name]['head']]
    centers.append(point(tuple(sum(verts[i][j] for i in ids)/len(ids) for j in range(3))))
influences=[[] for _ in verts]
for name,entries in weights.items():
    for vertex,weight in entries:
        if weight>0:influences[vertex].append((bones.index(name),weight))

class GLB:
    def __init__(self):
        self.bin=bytearray()
        self.doc={'asset':{'version':'2.0','generator':'Iron Crowns CC0 human pipeline'},'bufferViews':[],'accessors':[],
            'materials':[{'name':name,'pbrMetallicRoughness':{'baseColorFactor':color,'metallicFactor':0,'roughnessFactor':.86},'doubleSided':False} for name,color in [
                ('Skin',[.57,.36,.25,1]),('Undertunic',[.14,.19,.21,1]),('Boots',[.12,.095,.07,1]),
                ('Hair',[.10,.055,.025,1]),('Eye white',[.7,.66,.55,1]),('Iris',[.12,.20,.19,1]),('Pupil',[.012,.015,.014,1])]],
            'meshes':[],'nodes':[],'scenes':[],'scene':0}
    def array(self,rows,kind,fmt='f',component=5126):
        while len(self.bin)%4:self.bin.append(0)
        rows=list(rows);width={'SCALAR':1,'VEC3':3,'VEC4':4,'MAT4':16}[kind]
        flat=[r for r in rows] if width==1 else [v for row in rows for v in row]
        data=struct.pack('<'+fmt*len(flat),*flat);offset=len(self.bin);self.bin.extend(data)
        view=len(self.doc['bufferViews']);self.doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(data)})
        acc={'bufferView':view,'componentType':component,'count':len(rows),'type':kind}
        if kind=='VEC3':acc.update(min=[min(r[i] for r in rows) for i in range(3)],max=[max(r[i] for r in rows) for i in range(3)])
        index=len(self.doc['accessors']);self.doc['accessors'].append(acc);return index
    def mesh(self,selected,rig=False):
        ids=sorted({v for f in selected for v in f});lookup={old:new for new,old in enumerate(ids)}
        attr={'POSITION':self.array([positions[i] for i in ids],'VEC3'),'NORMAL':self.array([normals[i] for i in ids],'VEC3')}
        if rig:
            js=[];ws=[]
            for i in ids:
                inf=sorted(influences[i],key=lambda item:(-item[1],item[0]))[:4]
                if not inf:inf=[(bones.index('root'),1.)]
                total=sum(w for _,w in inf)
                js.append([b for b,_ in inf]+[0]*(4-len(inf)))
                ws.append([w/total for _,w in inf]+[0.]*(4-len(inf)))
            attr['JOINTS_0']=self.array(js,'VEC4','H',5123);attr['WEIGHTS_0']=self.array(ws,'VEC4')
        groups={}
        for f in selected:
            y=sum(positions[i][1] for i in f)/3
            mat=(2 if y<.18 else 1 if y<1.48 else 0) if rig else 0
            groups.setdefault(mat,[]).extend(lookup[i] for i in f)
        prim=[{'attributes':attr,'indices':self.array(indices,'SCALAR','I',5125),'material':mat} for mat,indices in sorted(groups.items())]
        self.doc['meshes'].append({'name':'Human body' if rig else 'Anatomical head','primitives':prim})
    def save(self,path):
        while len(self.bin)%4:self.bin.append(0)
        self.doc['buffers']=[{'byteLength':len(self.bin)}]
        text=json.dumps(self.doc,separators=(',',':')).encode();text+=b' '*((-len(text))%4)
        payload=struct.pack('<II',len(text),0x4e4f534a)+text+struct.pack('<II',len(self.bin),0x004e4942)+self.bin
        path.write_bytes(struct.pack('<III',0x46546c67,2,12+len(payload))+payload)

OUT.mkdir(exist_ok=True,parents=True)
full=GLB();full.mesh(faces,True)
for i,name in enumerate(bones):
    parent=skel['bones'][name]['parent'];pos=centers[i]
    if parent:pos=sub(pos,centers[bones.index(parent)])
    node={'name':name.replace('.','_'),'translation':pos}
    children=[j for j,n in enumerate(bones) if skel['bones'][n]['parent']==name]
    if children:node['children']=children
    full.doc['nodes'].append(node)
inverse=[]
for x,y,z in centers:inverse.append([1,0,0,0,0,1,0,0,0,0,1,0,-x,-y,-z,1])
full.doc['skins']=[{'name':'MakeHuman CC0 rig','joints':list(range(len(bones))),'inverseBindMatrices':full.array(inverse,'MAT4')}]
full.doc['nodes'].append({'name':'HumanMesh','mesh':0,'skin':0})
full.doc['scenes']=[{'nodes':[i for i,n in enumerate(bones) if not skel['bones'][n]['parent']]+[len(bones)]}]
full.save(OUT/'human-rig.glb')
head=GLB();head_faces=[f for f in faces if min(positions[i][1] for i in f)>1.51];head.mesh(head_faces)
# Eye surfaces use the real eye joint centers, not a painted line on a sphere.
for side in ['L','R']:
    c=centers[bones.index('eye.'+side)]
    for radius,material,depth in [(.0118,4,0),(.0058,5,-.0105),(.0027,6,-.0117)]:
        points=[];ns=[];indices=[]
        for row in range(13):
            a=math.pi*row/12
            for col in range(25):
                b=math.tau*col/24;n=(math.sin(a)*math.cos(b),math.cos(a),math.sin(a)*math.sin(b))
                points.append((c[0]+n[0]*radius,c[1]+n[1]*radius,c[2]+depth+n[2]*radius*(1 if material==4 else .12)));ns.append(n)
        for row in range(12):
            for col in range(24):
                a=row*25+col;b=a+25
                indices.extend([a,a+1,b,a+1,b+1,b])
        head.doc['meshes'][0]['primitives'].append({'attributes':{'POSITION':head.array(points,'VEC3'),'NORMAL':head.array(ns,'VEC3')},'indices':head.array(indices,'SCALAR','I',5125),'material':material})
head.doc['nodes']=[{'name':'HumanHead','mesh':0}];head.doc['scenes']=[{'nodes':[0]}];head.save(OUT/'human-head.glb')
print(f'Built: {len(faces)} body triangles, {len(head_faces)} head triangles, {len(bones)} bones. Source hashes verified.')
