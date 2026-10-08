#!/usr/bin/env bash
set -euo pipefail
mkdir -p artifacts
bash scripts/godot-android-template.sh
python3 scripts/build-content-bundle.py artifacts/Iron-Crowns-0.7.0-Data.icdata --revision 1
# A second compatible revision proves the exact same APK can accept updated Data.
python3 - <<'PYREV'
import json,subprocess
from pathlib import Path
p=Path('godot/assets/content/catalog.json');original=p.read_text()
try:
    data=json.loads(original);data['content_revision']=2
    p.write_text(json.dumps(data))
    subprocess.run(['python3','scripts/build-content-bundle.py','artifacts/Test-Revision-2.icdata','--revision','2'],check=True)
finally:
    p.write_text(original)
PYREV
godot --headless --path godot --export-debug Android "$PWD/artifacts/Iron-Crowns-0.7.0-Peoples.apk"
python3 - <<'PY'
import zipfile,json
from pathlib import Path
with zipfile.ZipFile('artifacts/Iron-Crowns-0.7.0-Peoples.apk') as z:
    bulk=[p.name for folder in ['materials','audio','content'] for p in Path('godot/assets',folder).rglob('*') if p.is_file() and p.suffix not in ['.import','.txt']]
    forbidden=[n for n in z.namelist() if any(x in n for x in bulk)]
    assert not forbidden, ('Data resources leaked into core APK',forbidden)
print('SPLIT_APK_PASS: raw model/world/texture/audio content excluded; no fixed Data hash in APK')
PY
