#!/usr/bin/env python3
"""Offline conversion of credited CC0 MegaKit assemblies into restricted OBJ parts.
Input: .tools/megakit/megakit_*.glb. Requires trimesh, numpy, pillow.
No source scripts or arbitrary serialized Godot resources enter game Data.
"""
from pathlib import Path
import hashlib,json,trimesh
root=Path('godot/assets');manifest={'schema':1,'models':{}}
for name in ['house_small','house_long','yard_corner']:
 scene=trimesh.load(Path('.tools/megakit')/f'megakit_{name}.glb')
 parts=[]
 for i,mesh in enumerate(scene.geometry.values()):
  mesh=mesh.copy();mesh.apply_scale(.65)
  dest=root/'content/rts'/f'{name}-{i}.obj'
  dest.write_text(trimesh.exchange.obj.export_obj(mesh,include_normals=True,include_texture=True,write_texture=False,return_texture=False))
  mat=mesh.visual.material;tex=getattr(mat,'baseColorTexture',None)
  color=getattr(mat,'baseColorFactor',None)
  item={'mesh':'res://'+dest.relative_to(Path('godot')).as_posix()}
  if tex:
   # Deduplicate shared atlases across assemblies.
   digest=hashlib.sha256(tex.tobytes()).hexdigest()[:12];p=root/'materials/rts'/f'{digest}.jpg'
   tex.convert('RGB').save(p,quality=90)
   item['texture']='res://'+p.relative_to(Path('godot')).as_posix()
  item['color']=[float(x)/255 for x in color[:3]] if color is not None else [1,1,1]
  parts.append(item)
 manifest['models'][name]=parts
(root/'content/rts/models.json').write_text(json.dumps(manifest,indent=2)+'\n')
