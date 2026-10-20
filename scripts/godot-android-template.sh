#!/usr/bin/env bash
set -euo pipefail
# Install the official source template, then add only our small SAF bridge.
TEMPLATE="$HOME/.local/share/godot/export_templates/4.4.1.stable/android_source.zip"
mkdir -p godot/android/build
unzip -q -o "$TEMPLATE" -d godot/android/build
printf '4.4.1.stable\n' > godot/android/.build_version
touch godot/android/.gdignore
mkdir -p godot/android/build/src/com/ironcrowns/data
cp native/android/DataPicker.java godot/android/build/src/com/ironcrowns/data/
python3 - <<'PY'
from pathlib import Path
p=Path('godot/android/build/AndroidManifest.xml')
s=p.read_text()
marker='<meta-data android:name="org.godotengine.plugin.v2.DataPicker" android:value="com.ironcrowns.data.DataPicker" />'
assert '</application>' in s
s=s.replace('</application>',marker+'\n</application>')
p.write_text(s)
PY
