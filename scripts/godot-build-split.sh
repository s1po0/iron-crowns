#!/usr/bin/env bash
set -euo pipefail
mkdir -p artifacts
bash scripts/godot-android-template.sh
godot --headless --path godot --export-pack Data "$PWD/artifacts/Iron-Crowns-0.6.0-Data.pck"
python3 - <<'PY'
from pathlib import Path
import hashlib,json,struct,io
p=Path('artifacts/Iron-Crowns-0.6.0-Data.pck')
f=io.BytesIO(p.read_bytes())
assert f.read(4)==b'GDPC', 'Not a genuine Godot resource pack'
version,major,minor,patch,flags,base=struct.unpack('<IIIIIQ',f.read(28))
assert version==2 and major==4 and not flags&1, 'Unexpected pack directory format'
f.read(64)
count,=struct.unpack('<I',f.read(4))
entries=[]
for _ in range(count):
    length,=struct.unpack('<I',f.read(4))
    name=f.read(length).decode('utf-8').rstrip('\0')
    f.read(36) # uint64 offset/size, 16-byte MD5, uint32 flags
    entries.append(name)
assert any(n.endswith('assets/content/catalog.json') for n in entries), 'Missing Data catalog'
assert any('meadow.jpg' in n and n.endswith('.ctex') for n in entries), 'Missing imported Data texture'
assert any('wind.wav' in n and n.endswith(('.sample','.wav')) for n in entries), 'Missing Data sound'
assert not any(n.endswith(('.gd','.gdc','.tscn')) or (n.endswith('.scn') and 'human-' not in n) for n in entries), 'Unexpected executable/scene content in asset pack'
Path('artifacts/DATA-CONTENTS.txt').write_text('\n'.join(entries)+'\n')
print('DATA_PACK_PASS:',count,'resource entries; real imported textures, sound and catalog')
r={'format':1,'id':'marches-riders-0.6','filename':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
Path('godot/assets/data_requirements.json').write_text(json.dumps(r))
Path('artifacts/DATA-MANIFEST.json').write_text(json.dumps(r,indent=2)+'\n')
print('Pinned data pack:',r)
PY
godot --headless --path godot --export-debug Android "$PWD/artifacts/Iron-Crowns-0.6.0-Riders.apk"
python3 - <<'PY'
import zipfile,json
from pathlib import Path
with zipfile.ZipFile('artifacts/Iron-Crowns-0.6.0-Riders.apk') as z:
    names=z.namelist()
    bulk=[p.name for folder in ['materials','audio','content','models'] for p in Path('godot/assets',folder).iterdir() if p.suffix not in ['.import','.txt']]
    forbidden=[n for n in names if any(x in n for x in bulk)]
    assert not forbidden, ('Bulk data leaked into core APK',forbidden)
    manifest=next(n for n in names if n.endswith('assets/data_requirements.json'))
    assert json.loads(z.read(manifest))==json.loads(Path('artifacts/DATA-MANIFEST.json').read_text()), 'APK manifest does not match exported Data'
print('SPLIT_APK_PASS: bulk world/audio/catalog resources excluded from core APK')
PY
