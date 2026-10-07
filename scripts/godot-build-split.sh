#!/usr/bin/env bash
set -euo pipefail
mkdir -p artifacts
godot --headless --path godot --export-pack Data "$PWD/artifacts/Iron-Crowns-0.6.0-Data.pck"
python3 - <<'PY'
from pathlib import Path
import hashlib,json
p=Path('artifacts/Iron-Crowns-0.6.0-Data.pck')
r={'format':1,'id':'marches-riders-0.6','filename':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
Path('godot/assets/data_requirements.json').write_text(json.dumps(r))
Path('artifacts/DATA-MANIFEST.json').write_text(json.dumps(r,indent=2)+'\n')
print('Pinned data pack:',r)
PY
godot --headless --path godot --export-debug Android "$PWD/artifacts/Iron-Crowns-0.6.0-Riders.apk"
python3 - <<'PY'
import zipfile
with zipfile.ZipFile('artifacts/Iron-Crowns-0.6.0-Riders.apk') as z:
    names=z.namelist()
    forbidden=[n for n in names if any(x in n for x in ['meadow.jpg','steel.jpg','wind.wav','catalog.json'])]
    assert not forbidden, ('Bulk data leaked into core APK',forbidden)
    assert any('data_requirements.json' in n for n in names), 'Core data manifest missing'
print('SPLIT_APK_PASS: bulk world/audio/catalog resources excluded from core APK')
PY
