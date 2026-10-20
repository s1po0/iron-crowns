#!/usr/bin/env bash
set -euo pipefail
PKG=com.ironcrowns.game.prototype
mkdir -p artifacts/smoke
exec > >(tee /tmp/smoke.log) 2>&1
finish() {
  status=$?
  adb logcat -d > artifacts/smoke/logcat.txt
  if [ "$status" -ne 0 ]; then
    adb shell wm size
    adb shell dumpsys input | grep -E 'SurfaceWidth|SurfaceHeight|SurfaceOrientation' || true
    cat artifacts/smoke/transactions.xml 2>/dev/null || true
    tail -60 /tmp/smoke.log | python3 -c 'import sys; s=sys.stdin.read(); print("::error::"+s.replace("%","%25").replace("\n","%0A").replace("\r","%0D"))'
    grep -A 20 'FATAL EXCEPTION' artifacts/smoke/logcat.txt || true
  fi
}
trap finish EXIT
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell pm clear "$PKG"
adb shell wm size 620x1000
adb shell wm density 160
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 0
adb logcat -c
adb shell am start -W -n "$PKG/com.ironcrowns.game.MainActivity"
sleep 3
adb shell pidof "$PKG"
adb exec-out screencap -p > artifacts/smoke/01-title.png
adb shell input tap 200 438
sleep 1
adb shell input tap 205 320
sleep 2
adb shell input tap 350 286
adb shell input tap 645 286
adb shell input tap 350 355
sleep 1
adb exec-out run-as "$PKG" cat shared_prefs/iron_crowns_v1.xml > artifacts/smoke/transactions.xml
python3 - <<'PY'
import json, xml.etree.ElementTree as ET
root=ET.parse('artifacts/smoke/transactions.xml').getroot()
save=json.loads(next(e.text for e in root if e.attrib.get('name')=='save'))
assert save['soldiers']==18, '::error::Recruitment assertion '+str(save)
assert save['gold']==70, save
assert save['food']==60, save
assert save['veterans']==4, save
print('On-device recruitment, purchase, training, and save assertions passed.')
PY
adb exec-out screencap -p > artifacts/smoke/02-settlement.png
adb shell input tap 740 195
adb shell input tap 610 590
sleep 2
adb shell input tap 350 584
adb shell input swipe 95 542 135 542 1800
adb shell input swipe 900 548 901 548 1500
adb shell input swipe 774 553 775 553 500
adb exec-out screencap -p > artifacts/smoke/03-battle.png
adb shell input keyevent KEYCODE_BACK
sleep 1
adb exec-out screencap -p > artifacts/smoke/04-paused.png
adb shell input tap 500 341
adb shell input keyevent KEYCODE_HOME
sleep 1
adb shell am start -W -n "$PKG/com.ironcrowns.game.MainActivity"
sleep 1
adb shell am force-stop "$PKG"
adb shell am start -W -n "$PKG/com.ironcrowns.game.MainActivity"
sleep 2
adb shell pidof "$PKG"
adb shell input tap 200 438
sleep 1
adb exec-out screencap -p > artifacts/smoke/05-restored.png
adb exec-out run-as "$PKG" cat shared_prefs/iron_crowns_v1.xml > artifacts/smoke/restored.xml
python3 - <<'PY'
import json, xml.etree.ElementTree as ET
root=ET.parse('artifacts/smoke/restored.xml').getroot()
save=json.loads(next(e.text for e in root if e.attrib.get('name')=='save'))
assert save['soldiers']==18 and save['gold']==70 and save['veterans']==4, save
print('Process-kill recovery preserved the pre-battle campaign checkpoint.')
PY
adb logcat -d > artifacts/smoke/logcat.txt
if grep -q 'FATAL EXCEPTION' artifacts/smoke/logcat.txt; then
  echo '::error::Android crashed during smoke test'
  exit 1
fi
printf 'PASS: Android API 29 emulator install, launch, campaign transactions, battle interaction, pause, background, and process-kill save recovery.\nPhysical-device performance remains untested.\n' > artifacts/SMOKE-TEST.txt
