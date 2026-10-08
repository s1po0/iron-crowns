#!/usr/bin/env python3
"""Derive game-scale head/hair meshes from the CC0 MakeHuman hm08 base.
No MakeHuman program code is bundled. Neck seams sit under the character collar.
"""
from pathlib import Path
import math,json,hashlib
SOURCE=Path('art-source/human/base.obj')
OUT=Path('godot/assets/content/humans');OUT.mkdir(parents=True,exist_ok=True)
verts=[];uvs=[];faces=[];group=''
for line in SOURCE.read_text().splitlines():
    p=line.split()
    if not p:continue
    if p[0]=='v':verts.append(tuple(map(float,p[1:4])))
    elif p[0]=='vt':uvs.append(tuple(map(float,p[1:3])))
    elif p[0]=='g':group=p[1]
    elif p[0]=='f' and group=='body':
        faces.append([(int(t.split('/')[0])-1,int(t.split('/')[1])-1) for t in p[1:]])
scale=1.87/(8.4913+8.1676)
def output(name,predicate,expand=0):
    selected=[f for f in faces if predicate([verts[i] for i,u in f])]
    ids=sorted({i for f in selected for i,u in f}); lookup={v:i+1 for i,v in enumerate(ids)}
    texids=sorted({u for f in selected for i,u in f}); tl={u:i+1 for i,u in enumerate(texids)}
    result=['# Derived from MakeHuman hm08, CC0. See NOTICE.txt.','s 1']
    for i in ids:
        x,y,z=verts[i]
        # Reflect front to Godot -Z; reverse each face below to preserve normals.
        result.append(f'v {x*scale*(1+expand):.7f} {(y+8.1676)*scale+expand*.07:.7f} {-(z-.16075)*scale*(1+expand):.7f}')
    for i in texids:result.append('vt %.7f %.7f'%uvs[i])
    # Explicit smooth vertex normals avoid importer-dependent unlit heads.
    normals={i:[0.,0.,0.] for i in ids}
    for face in selected:
        indices=[i for i,u in reversed(face)]
        points=[(verts[i][0]*scale,(verts[i][1]+8.1676)*scale,-(verts[i][2]-.16075)*scale) for i in indices]
        for k in range(1,len(points)-1):
            a,b,c=points[0],points[k],points[k+1]
            e=[b[j]-a[j] for j in range(3)];f=[c[j]-a[j] for j in range(3)]
            n=[e[1]*f[2]-e[2]*f[1],e[2]*f[0]-e[0]*f[2],e[0]*f[1]-e[1]*f[0]]
            for index in [indices[0],indices[k],indices[k+1]]:
                for j in range(3):normals[index][j]+=n[j]
    for i in ids:
        n=normals[i];length=math.sqrt(sum(v*v for v in n)) or 1
        result.append('vn '+' '.join(f'{v/length:.7f}' for v in n))
    for face in selected:result.append('f '+' '.join(f'{lookup[i]}/{tl[u]}/{lookup[i]}' for i,u in reversed(face)))
    (OUT/name).write_text('\n'.join(result)+'\n')
    print(name,len(ids),'vertices',len(selected),'faces')
    return len(selected)
head=output('human-head.obj',lambda ps:min(p[1] for p in ps)>5.87)
hair=output('human-hair.obj',lambda ps:all(p[1]>7.83 or (p[1]>7.05 and p[2]<.3) for p in ps),.04)
assert head>1000 and hair>50
(OUT/'NOTICE.txt').write_text('Human head and scalp derived from MakeHuman hm08 base mesh.\nUpstream: https://github.com/makehumancommunity/makehuman\nSource git blob: d26635e9326e3cca30778fd7b9c00062b03cce09\nLicense: CC0 1.0 Universal, included as LICENSE.txt.\nCopyright holders at CC0 release: Data Collection AB, Joel Palmius, Jonas Hauquier (2020).\nChanges: head/scalp extraction, metric scaling, coordinate conversion.\nThis is not a Bannerlord asset.\n')
(OUT/'LICENSE.txt').write_text(Path('art-source/human/LICENSE.ASSETS.md').read_text())
