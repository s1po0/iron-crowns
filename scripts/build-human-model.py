#!/usr/bin/env python3
"""Deterministic CC0 MakeHuman → glTF 2 skin, without Blender dependencies.

Retains UVs, averaged anatomical normals and up to four normalized influences.
Collapses the upstream detailed facial/finger skeleton into a mobile body rig.
"""
from pathlib import Path
import collections
import hashlib
import json
import math
import struct

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art-source/human'
OUT = SOURCE / 'generated'


def build():
    vertices, uvs, faces = [], [], []
    group = ''
    for line in (SOURCE / 'base.obj').read_text().splitlines():
        words = line.split()
        if not words:
            continue
        if words[0] == 'v':
            vertices.append(tuple(map(float, words[1:4])))
        elif words[0] == 'vt':
            uvs.append(tuple(map(float, words[1:3])))
        elif words[0] == 'g':
            group = words[1]
        elif words[0] == 'f' and group == 'body':
            face = [tuple(int(x)-1 for x in w.split('/')[:2]) for w in words[1:]]
            for i in range(1, len(face)-1):
                faces.append([face[0], face[i], face[i+1]])
    used = {v for f in faces for v, _ in f}
    floor = min(vertices[i][1] for i in used)
    height = max(vertices[i][1] for i in used)-floor
    scale = 1.85/height

    def convert(p):
        # Rotate Y by pi: face Godot -Z, keep right-handed triangle winding.
        return [-p[0]*scale, (p[1]-floor)*scale, -p[2]*scale]

    points = [convert(p) for p in vertices]
    skeleton = json.loads((SOURCE / 'default.mhskel').read_text())
    weight_source = json.loads((SOURCE / 'default_weights.mhw').read_text())
    assert skeleton['license'] == weight_source['license'] == 'CC0'
    kept = ['root', 'spine05', 'spine03', 'spine01', 'neck01', 'head']
    for side in ['L', 'R']:
        kept += [f'{name}.{side}' for name in ['clavicle', 'upperarm01', 'lowerarm01', 'wrist', 'upperleg01', 'lowerleg01', 'foot']]
    bones = skeleton['bones']

    def retained(name):
        while name not in kept:
            name = bones[name]['parent']
            if name is None:
                return 'root'
        return name

    parents, heads = [], []
    for name in kept:
        parent = bones[name]['parent']
        parents.append(retained(parent) if parent else None)
        ids = skeleton['joints'][bones[name]['head']]
        heads.append([sum(points[i][axis] for i in ids)/len(ids) for axis in range(3)])
    weights = collections.defaultdict(lambda: collections.defaultdict(float))
    for name, rows in weight_source['weights'].items():
        bone = kept.index(retained(name))
        for vertex, weight in rows:
            weights[vertex][bone] += weight
    normal_sum = [[0., 0., 0.] for _ in vertices]
    for face in faces:
        a, b, c = [points[v] for v, _ in face]
        u, v = ([b[i]-a[i] for i in range(3)], [c[i]-a[i] for i in range(3)])
        n = [u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0]]
        for vertex, _ in face:
            for axis in range(3):
                normal_sum[vertex][axis] += n[axis]
    normals = []
    for n in normal_sum:
        length = math.sqrt(sum(v*v for v in n)) or 1
        normals.append([v/length for v in n])
    keys = sorted({key for face in faces for key in face})
    lookup = {key: index for index, key in enumerate(keys)}
    positions, texcoords, ns, joints, skin_weights = [], [], [], [], []
    for vertex, uv in keys:
        positions.append(points[vertex])
        ns.append(normals[vertex])
        texcoords.append([uvs[uv][0], 1-uvs[uv][1]])
        strongest = sorted(weights[vertex].items(), key=lambda p: (-p[1], p[0]))[:4]
        if not strongest:
            strongest = [(0, 1.)]
        total = sum(w for _, w in strongest)
        strongest += [(0, 0.)] * (4-len(strongest))
        joints.append([i for i, _ in strongest])
        skin_weights.append([w/total for _, w in strongest])
    indices = [lookup[key] for face in faces for key in face]
    blob = bytearray()
    doc = {'asset': {'version': '2.0', 'generator': 'Iron Crowns CC0 human pipeline'}, 'bufferViews': [], 'accessors': []}

    def accessor(rows, component, kind, bounds=False):
        while len(blob) % 4:
            blob.append(0)
        offset = len(blob)
        fmt = {5126: 'f', 5123: 'H', 5125: 'I'}[component]
        flat = [v for row in rows for v in row]
        blob.extend(struct.pack('<'+fmt*len(flat), *flat))
        view = len(doc['bufferViews'])
        info = {'buffer': 0, 'byteOffset': offset, 'byteLength': len(blob)-offset}
        if kind != 'MAT4':
            info['target'] = 34963 if kind == 'SCALAR' else 34962
        doc['bufferViews'].append(info)
        result = {'bufferView': view, 'componentType': component, 'count': len(rows), 'type': kind}
        if bounds:
            result.update(min=[min(r[i] for r in rows) for i in range(len(rows[0]))], max=[max(r[i] for r in rows) for i in range(len(rows[0]))])
        doc['accessors'].append(result)
        return len(doc['accessors'])-1

    attrs = {'POSITION': accessor(positions, 5126, 'VEC3', True), 'NORMAL': accessor(ns, 5126, 'VEC3'), 'TEXCOORD_0': accessor(texcoords, 5126, 'VEC2'), 'JOINTS_0': accessor(joints, 5123, 'VEC4'), 'WEIGHTS_0': accessor(skin_weights, 5126, 'VEC4')}
    idx = accessor([[i] for i in indices], 5125, 'SCALAR')
    matrices = [[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -h[0], -h[1], -h[2], 1] for h in heads]
    inverse = accessor(matrices, 5126, 'MAT4')
    nodes = []
    for i, name in enumerate(kept):
        parent = parents[i]
        h = heads[kept.index(parent)] if parent else [0, 0, 0]
        node = {'name': name.replace('.', '_'), 'translation': [heads[i][axis]-h[axis] for axis in range(3)]}
        children = [j for j, p in enumerate(parents) if p == name]
        if children:
            node['children'] = children
        nodes.append(node)
    nodes.append({'name': 'HumanAnatomy', 'mesh': 0, 'skin': 0})
    doc.update(nodes=nodes, scenes=[{'nodes': [0, len(nodes)-1]}], scene=0,
               meshes=[{'name': 'CC0_Human', 'primitives': [{'attributes': attrs, 'indices': idx, 'material': 0}]}],
               skins=[{'name': 'MobileHuman20', 'inverseBindMatrices': inverse, 'skeleton': 0, 'joints': list(range(len(kept)))}],
               materials=[{'name': 'SkinFoundation', 'pbrMetallicRoughness': {'baseColorFactor': [.54, .35, .25, 1], 'metallicFactor': 0, 'roughnessFactor': .82}}])
    # Separate eyes use the licensed skeleton's anatomical eye centers, not
    # guessed screen-space dots. Parenting to the head preserves head animation.
    for label, radius, tint, forward in [('Sclera', .0125, [.72,.69,.62,1], 0), ('Iris', .0055, [.17,.23,.12,1], -.011), ('Pupil', .0025, [.015,.018,.015,1], -.0125)]:
        ps, normal, ids = [], [], []
        for ring in range(9):
            angle=math.pi*ring/8
            for segment in range(17):
                longitude=2*math.pi*segment/16
                n=[math.sin(angle)*math.cos(longitude),math.cos(angle),math.sin(angle)*math.sin(longitude)]
                normal.append(n)
                ps.append([n[0]*radius,n[1]*radius,n[2]*radius*(1 if label=='Sclera' else .25)])
        for ring in range(8):
            for segment in range(16):
                a=ring*17+segment; b=a+17
                ids += [[a],[a+1],[b],[a+1],[b+1],[b]]
        material=len(doc['materials'])
        doc['materials'].append({'name':label,'pbrMetallicRoughness':{'baseColorFactor':tint,'metallicFactor':0,'roughnessFactor':.4}})
        mesh=len(doc['meshes'])
        doc['meshes'].append({'name':label,'primitives':[{'attributes':{'POSITION':accessor(ps,5126,'VEC3',True),'NORMAL':accessor(normal,5126,'VEC3')},'indices':accessor(ids,5125,'SCALAR'),'material':material}]})
        for side in ['L','R']:
            group=skeleton['joints'][bones['eye.'+side]['head']]
            center=[sum(points[i][axis] for i in group)/len(group) for axis in range(3)]
            h=heads[kept.index('head')]
            at=[center[axis]-h[axis] for axis in range(3)]
            at[2]+=forward
            node=len(nodes)
            nodes.append({'name':label+'_'+side,'mesh':mesh,'translation':at})
            nodes[kept.index('head')].setdefault('children',[]).append(node)
    while len(blob) % 4:
        blob.append(0)
    doc['buffers'] = [{'byteLength': len(blob)}]
    encoded = json.dumps(doc, separators=(',', ':'), sort_keys=True).encode()
    encoded += b' ' * ((-len(encoded)) % 4)
    glb = struct.pack('<III', 0x46546C67, 2, 12+8+len(encoded)+8+len(blob))
    glb += struct.pack('<II', len(encoded), 0x4E4F534A)+encoded
    glb += struct.pack('<II', len(blob), 0x004E4942)+blob
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'human-foundation.glb').write_bytes(glb)
    report = {'status': 'rigging foundation; not a completed character', 'license': 'CC0-1.0', 'source_revision': 'a8bc2d54ff0ac92e78ff71431b1023eda42bf482', 'vertices': len(keys), 'triangles': len(faces), 'bones': len(kept), 'height_metres': 1.85, 'sha256': hashlib.sha256(glb).hexdigest(), 'source_sha256': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(SOURCE.iterdir()) if p.suffix in ['.obj', '.mhskel', '.mhw']}}
    (OUT / 'provenance.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    build()
