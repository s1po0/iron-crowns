#!/usr/bin/env python3
"""Export a bounded, non-executable skin definition from the licensed mobile rig.
Clothing surfaces cover torso/pelvis/legs; this is not a nude character preset.
"""
import json,struct
from pathlib import Path
raw=Path('art-source/human/generated/human-foundation.glb').read_bytes()
n=struct.unpack_from('<I',raw,12)[0]; doc=json.loads(raw[20:20+n]); binary=raw[28+n:]
def rows(index):
 a=doc['accessors'][index]; v=doc['bufferViews'][a['bufferView']]
 fmt={5126:'f',5123:'H',5125:'I'}[a['componentType']]*{'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
 return [list(r) for r in struct.iter_unpack('<'+fmt,binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']])]
p=doc['meshes'][0]['primitives'][0]; attrs={k:rows(v) for k,v in p['attributes'].items()}; ids=[v[0] for v in rows(p['indices'])]
bones=[]
for i in doc['skins'][0]['joints']:
 node=doc['nodes'][i];parent=next((j for j in doc['skins'][0]['joints'] if i in doc['nodes'][j].get('children',[])),-1)
 bones.append({'name':node['name'],'parent':parent,'rest':node['translation']})
heads=[]
for bone in bones:
 parent=heads[bone['parent']] if bone['parent']>=0 else [0,0,0]
 heads.append([a+b for a,b in zip(parent,bone['rest'])])
groups={k:[] for k in ['skin','coat','trousers','boots']}
for start in range(0,len(ids),3):
 tri=ids[start:start+3]; center=[sum(attrs['POSITION'][i][a] for i in tri)/3 for a in range(3)]
 dominant=[bones[attrs['JOINTS_0'][i][max(range(4),key=lambda j:attrs['WEIGHTS_0'][i][j])]]['name'] for i in tri]
 if center[1]>1.59 or all('wrist' in b for b in dominant):kind='skin'
 elif center[1]<.23:kind='boots'
 elif center[1]<.96 and not any('arm' in b or 'wrist' in b for b in dominant):kind='trousers'
 else:kind='coat'
 groups[kind].append(tri)
surfaces=[]
for kind,tris in groups.items():
 used=sorted({i for t in tris for i in t}); lookup={old:new for new,old in enumerate(used)}
 surface={'kind':kind,'indices':[lookup[i] for t in tris for i in reversed(t)]}
 for key,name in [('POSITION','positions'),('NORMAL','normals'),('TEXCOORD_0','uv'),('JOINTS_0','joints'),('WEIGHTS_0','weights')]:
  surface[name]=[[round(x,7) if isinstance(x,float) else x for x in attrs[key][i]] for i in used]
 surfaces.append(surface)
eyes=[]
for node in doc['nodes']:
 if node['name'].startswith('Sclera_'):
  eyes.append([a+b for a,b in zip(heads[5],node['translation'])])
result={'schema':1,'bones':bones,'surfaces':surfaces,'eyes':eyes,'head_origin':heads[5]}
path=Path('godot/assets/content/humans/human-body.json');path.write_text(json.dumps(result,separators=(',',':'))+'\n')
assert path.stat().st_size<16*1024*1024
print('Playable skin:',len(bones),'bones',len(ids)//3,'triangles',path.stat().st_size,'bytes')
