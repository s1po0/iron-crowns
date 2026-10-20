#!/usr/bin/env python3
"""Independent bounded verifier for all region payloads, hashes and PNG pixels."""
import hashlib,io,json,struct,sys
from pathlib import Path
from PIL import Image
root=Path(sys.argv[1]); catalog=json.loads((root/'realm-manifest.json').read_text())
assert catalog['world']=='realm-400-v1' and not catalog['test_fixture']
assert len(catalog['regions'])==25
seen=set(); pixels=0; total=0; coordinates=set()
for region in catalog['regions']:
    path=root/region['file']; size=path.stat().st_size
    assert size==region['bytes'] and size<=96*1024*1024
    total+=size; digest=hashlib.sha256()
    with path.open('rb') as f:
        while block:=f.read(65536):digest.update(block)
        assert digest.hexdigest()==region['sha256']
        f.seek(0); assert f.read(8)==b'ICREG002'
        length=struct.unpack('<I',f.read(4))[0]; assert length<=32768
        m=json.loads(f.read(length)); assert m['region']==region['region'] and m['api']==2
        rx,ry=m['region']; assert (rx,ry) not in coordinates; coordinates.add((rx,ry))
        expected={f'{x}_{y}_{kind}.png' for x in range(rx*5,rx*5+5) for y in range(ry*5,ry*5+5) for kind in ('albedo','normal')}
        assert len(m['files'])==50
        for entry in m['files']:
            assert entry['name'] in expected; expected.remove(entry['name'])
            assert 33<=entry['bytes']<=8*1024*1024
            payload=f.read(entry['bytes']); h=hashlib.sha256(payload).hexdigest()
            assert h==entry['sha256'] and h not in seen; seen.add(h)
            image=Image.open(io.BytesIO(payload)); image.load()
            assert image.size==(1024,1024) and image.mode=='RGB'
            pixels+=image.width*image.height
        assert not expected and f.read(1)==b''
    print(f'PASS {path.name}: {size} bytes',flush=True)
assert total==catalog['total_bytes'] and total>1024**3 and len(seen)==1250
print(f'REALM_VERIFIED: {total} bytes; {len(seen)} distinct decoded textures; {pixels} pixels',flush=True)
