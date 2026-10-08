#!/usr/bin/env bash
set -euo pipefail
PKG=com.ironcrowns.marches
# A dead emulator must fail with diagnostics, not hold the job indefinitely.
ADB_BIN=$(command -v adb)
adb() { timeout 35 "$ADB_BIN" "$@"; }
godot_log() {
  local pid
  pid=$(adb shell pidof "$PKG" | tr -d '\r')
  adb logcat -d --pid="${pid%% *}" -s godot
}
mkdir -p artifacts/android
exec > >(tee /tmp/android-smoke.log) 2>&1
finish() {
  status=$?
  trap - EXIT
  set +e
  adb logcat -d > artifacts/android/logcat.txt
  if [ "$status" -ne 0 ]; then
    adb exec-out screencap -p > artifacts/android/failure.png
    python3 - <<'PYLOG'
lines=open('artifacts/android/logcat.txt',errors='replace').readlines()
selected=[x for x in lines if any(t in x for t in ['godot','Godot','FATAL','Fatal','DEBUG','AndroidRuntime','ironcrowns'])]
s=''.join(selected[-150:])[-18000:]
for i in range(0,len(s),2800):
    print('::error::Android diagnostics '+str(i//2800+1)+': '+s[i:i+2800].replace('%','%25').replace('\n','%0A').replace('\r','%0D'))
PYLOG
    tail -60 /tmp/android-smoke.log | python3 -c 'import sys; s=sys.stdin.read()[-3000:]; print("::error::"+s.replace("%","%25").replace("\n","%0A").replace("\r","%0D"))'
  fi
  exit "$status"
}
trap 'printf "FAILED command at line %s: %s\n" "$LINENO" "$BASH_COMMAND"' ERR
trap finish EXIT
adb install -r artifacts/Iron-Crowns-0.7.0-Peoples.apk
adb shell pm clear "$PKG"
adb shell wm size 720x1280
adb shell wm density 160
adb logcat -c
adb shell am start -W -n "$PKG/com.godot.game.GodotApp"
# Both correct and same-size corrupted packs arrive through public Downloads.
adb push artifacts/Iron-Crowns-0.7.0-Data.icdata /sdcard/Download/Iron-Crowns-0.7.0-Data.icdata
python3 - <<'PYCORRUPT'
from pathlib import Path
p=bytearray(Path('artifacts/Iron-Crowns-0.7.0-Data.icdata').read_bytes())
p[len(p)//2]^=1
Path('artifacts/Wrong-Data.icdata').write_bytes(p)
PYCORRUPT
adb push artifacts/Wrong-Data.icdata /sdcard/Download/Wrong-Data.icdata
rm artifacts/Wrong-Data.icdata
for attempt in $(seq 1 45); do
  if godot_log | grep -q IRON_DATA_REQUIRED; then break; fi
  sleep 1
done
godot_log | grep IRON_DATA_REQUIRED
adb exec-out screencap -p > artifacts/android/00-data.png
read -r SCREEN_W SCREEN_H < <(python3 -c 'import struct; b=open("artifacts/android/00-data.png","rb").read(); print(*struct.unpack(">II",b[16:24]))')
export SCREEN_W SCREEN_H
import_tap() {
  read -r x y < <(python3 -c 'import os;w=int(os.environ["SCREEN_W"]);h=int(os.environ["SCREEN_H"]);s=min(w/1280,h/720);print(round(w/2),round((h-720*s)/2+515*s))')
  adb shell input tap "$x" "$y"
  sleep 2
}
import_tap
python3 scripts/godot-picker.py Wrong-Data.icdata
for attempt in $(seq 1 45); do
  if godot_log | grep -q IRON_DATA_REJECTED; then break; fi
  sleep 1
done
godot_log | grep IRON_DATA_REJECTED
! godot_log | grep -q IRON_SCENE_READY
import_tap
python3 scripts/godot-picker.py Iron-Crowns-0.7.0-Data.icdata
for attempt in $(seq 1 60); do
  if godot_log | grep -q IRON_DATA_READY; then break; fi
  sleep 1
done
godot_log | grep IRON_DATA_READY
# Let initial scene/resource/GL initialization finish before killing the process.
for attempt in $(seq 1 60); do
  if godot_log | grep -q IRON_SCENE_READY; then break; fi
  sleep 1
done
godot_log | grep IRON_SCENE_READY
# Imported pack remains available without public Downloads or networking.
adb shell rm /sdcard/Download/Iron-Crowns-0.7.0-Data.icdata /sdcard/Download/Wrong-Data.icdata
adb shell am force-stop "$PKG"
sleep 3
adb logcat -c
adb shell am start -W -n "$PKG/com.godot.game.GodotApp"
for attempt in $(seq 1 45); do
  if godot_log | grep -q IRON_SCENE_READY; then break; fi
  sleep 1
 done
godot_log | grep IRON_SCENE_READY
sleep 3
adb shell pidof "$PKG"
adb exec-out screencap -p > artifacts/android/01-title.png
# Godot letterboxes its 1280x720 logical canvas on wider Android displays.
# Convert logical control positions to actual screenshot pixels, not assumed wm sizes.
read -r SCREEN_W SCREEN_H < <(python3 -c 'import struct; b=open("artifacts/android/01-title.png","rb").read(); print(*struct.unpack(">II",b[16:24]))')
export SCREEN_W SCREEN_H
coords() {
  python3 -c 'import os,sys; w=int(os.environ["SCREEN_W"]);h=int(os.environ["SCREEN_H"]);s=min(w/1280,h/720);print(round((w-1280*s)/2+float(sys.argv[1])*s),round((h-720*s)/2+float(sys.argv[2])*s))' "$1" "$2"
}
tap() { read -r x y < <(coords "$1" "$2"); adb shell input tap "$x" "$y"; }
swipe() { read -r x y < <(coords "$1" "$2"); read -r tx ty < <(coords "$3" "$4"); adb shell input swipe "$x" "$y" "$tx" "$ty" "$5"; }
# Update actual catalog bytes and revision without replacing/reinstalling the APK.
adb push artifacts/Test-Revision-2.icdata /sdcard/Download/Test-Revision-2.icdata
adb logcat -c
tap 1135 644
# MANAGE DATA deliberately cold-starts the installer instead of tearing down
# the 3D battlefield and reopening the native activity in the same engine.
sleep 2
adb shell am force-stop "$PKG"
sleep 3
adb logcat -d -s godot | grep IRON_DATA_MANAGER_RESTART
adb logcat -c
adb shell am start -W -n "$PKG/com.godot.game.GodotApp"
for attempt in $(seq 1 30); do
  if godot_log | grep -q 'Choose compatible replacement Data'; then break; fi
  sleep 1
done
godot_log | grep 'Choose compatible replacement Data'
import_tap
python3 scripts/godot-picker.py Test-Revision-2.icdata
for attempt in $(seq 1 60); do
  if godot_log | grep -q 'IRON_DATA_INSTALLED: API 1 revision 2'; then break; fi
  sleep 1
done
godot_log | grep 'IRON_DATA_INSTALLED: API 1 revision 2'
adb exec-out run-as "$PKG" cat files/content/active.json > artifacts/android/active-data.json
BUNDLE_DIR=$(python3 -c 'import json;d=json.load(open("artifacts/android/active-data.json"));assert d["manifest"]["revision"]==2;print(d["directory"])')
adb exec-out run-as "$PKG" cat "files/content/$BUNDLE_DIR/assets/content/catalog.json" > artifacts/android/updated-catalog.json
python3 -c 'import json;assert json.load(open("artifacts/android/updated-catalog.json"))["content_revision"]==2'
# Use the actual CLOSE GAME button; do not kill during picker/surface resume.
adb shell rm /sdcard/Download/Test-Revision-2.icdata
import_tap
sleep 3
adb shell am force-stop "$PKG"
sleep 3
adb logcat -c
adb shell am start -W -n "$PKG/com.godot.game.GodotApp"
for attempt in $(seq 1 60); do
  if godot_log | grep -q IRON_SCENE_READY; then break; fi
  sleep 1
done
godot_log | grep 'IRON_DATA_READY: API 1 revision 2'
godot_log | grep IRON_SCENE_READY
sleep 2
tap 220 510
sleep 1
adb exec-out screencap -p > artifacts/android/00-origin.png
tap 640 636
for attempt in $(seq 1 90); do
  if godot_log | grep -q IRON_FIELD_READY; then break; fi
  sleep 1
done
godot_log | grep IRON_FIELD_READY
sleep 2
adb exec-out screencap -p > artifacts/android/06-hero.png
# Actual touch mounting, gait, side selection, riding and safe dismount.
tap 95 260
sleep 1
godot_log | grep '^.*IRON_MOUNTED$'
tap 95 310
tap 1115 465
sleep 1
godot_log | grep IRON_GAIT
swipe 125 584 125 520 1200
sleep 2
adb exec-out screencap -p > artifacts/android/07-mounted.png
tap 1156 585
sleep 1
tap 95 260
sleep 1
godot_log | grep IRON_DISMOUNTED
# New games now start with the visible, playable hero, not a map token.
tap 1190 50
for attempt in $(seq 1 90); do
  if godot_log | grep -q IRON_REALM_READY; then break; fi
  sleep 1
done
godot_log | grep IRON_REALM_READY
sleep 2
tap 1100 370
sleep 1
adb exec-out run-as "$PKG" cat files/progress.json > artifacts/android/progress.json
cat artifacts/android/progress.json
python3 - <<'PYTEST'
import json
save=json.load(open('artifacts/android/progress.json'))
assert save['gold']==150 and save['victories']==0 and save['realm']['army']==11, save
print('On-device 3D HUD recruitment and progress-write assertion passed.')
PYTEST
# Hire the local scout and accept a neutral delivery through the real journal UI.
tap 335 667
sleep 1
tap 760 220
sleep 1
tap 975 295
sleep 1
tap 500 220
sleep 1
tap 350 520
sleep 1
adb exec-out screencap -p > artifacts/android/05-journal.png
adb exec-out run-as "$PKG" cat files/progress.json > artifacts/android/wanderer-active.json
python3 - <<'PYLIFE'
import json
s=json.load(open('artifacts/android/wanderer-active.json'))
l=s['realm']['life']
assert s['version']==3 and s['gold']==90, s
assert l['origin']=='Merchant' and l['neutral'] and l['companions']==[0], l
assert l['delivery']['to']==1 and l['completed']==0, l
print('Android origin, tavern hiring, courier acceptance and active-job save passed.')
PYLIFE
tap 1111 107
sleep 1
# Visit the adjacent castle using actual map selection and route execution.
tap 1172 574
sleep 1
tap 1110 365
for attempt in $(seq 1 60); do
  if godot_log | grep -q IRON_ARRIVED:Dusk; then break; fi
  sleep 1
done
godot_log | grep IRON_ARRIVED:Dusk
adb exec-out run-as "$PKG" cat files/progress.json > artifacts/android/progress.json
python3 - <<'PYTRAVEL'
import json
save=json.load(open('artifacts/android/progress.json'))
r=save['realm']
assert r['distance']>30 and abs(r['x']+133)<2 and abs(r['z']-97)<2, r
assert save['gold']==90 and r['army']==11, save
print('Android campaign travel, castle arrival and saved position passed.')
PYTRAVEL
# Complete the job at its physical destination (duplicate claims are covered by the engine suite).
tap 335 667
sleep 1
tap 640 510
sleep 1
adb exec-out screencap -p > artifacts/android/05-journal.png
adb shell input keyevent KEYCODE_BACK
sleep 1
adb exec-out run-as "$PKG" cat files/progress.json > artifacts/android/progress.json
python3 - <<'PYCLAIM'
import json
s=json.load(open('artifacts/android/progress.json'))
l=s['realm']['life']
assert s['gold']==135 and l['completed']==1 and l['delivery']=={}, s
assert 1 in l['visited'] and l['companions']==[0], l
assert s['realm']['holdings']==[] and all(x==0 for x in s['realm']['relations']), s
print('Android courier payout, visit milestone and full faction neutrality passed.')
PYCLAIM
adb exec-out screencap -p > artifacts/android/04-campaign.png
# Pan/zoom the actual map and return to the shared field scene for combat checks.
tap 48 330
swipe 500 350 590 390 450
tap 1080 46
sleep 2
tap 570 52
sleep 3
swipe 125 584 180 584 1500
swipe 1156 585 1157 585 1000
tap 691 660
adb exec-out screencap -p > artifacts/android/02-battle.png
adb shell input keyevent KEYCODE_BACK
sleep 1
adb exec-out screencap -p > artifacts/android/03-pause.png
# Exercise both new persistent settings through actual Android touch controls.
tap 640 334
sleep 1
tap 640 404
sleep 1
adb exec-out run-as "$PKG" cat files/settings.cfg > artifacts/android/settings.cfg
grep -q 'high_detail=true' artifacts/android/settings.cfg
grep -q 'enabled=false' artifacts/android/settings.cfg
tap 640 334
tap 640 404
sleep 1
adb shell input keyevent KEYCODE_HOME
sleep 1
adb shell am start -W -n "$PKG/com.godot.game.GodotApp"
sleep 2
adb shell am force-stop "$PKG"
sleep 3
adb logcat -d > artifacts/android/before-restart.log
adb logcat -c
adb shell am start -W -n "$PKG/com.godot.game.GodotApp"
for attempt in $(seq 1 45); do
  if godot_log | grep -q IRON_SCENE_READY; then break; fi
  sleep 1
done
godot_log | grep IRON_SCENE_READY
adb shell pidof "$PKG"
adb exec-out run-as "$PKG" cat files/progress.json > artifacts/android/restored.json
python3 - <<'PYRESTORE'
import json
saved=json.load(open('artifacts/android/progress.json'))
restored=json.load(open('artifacts/android/restored.json'))
assert restored==saved, (saved,restored)
print('Android saved progress survives process restart.')
PYRESTORE
adb logcat -d > artifacts/android/logcat.txt
if grep -E 'FATAL EXCEPTION|SCRIPT ERROR|Parse Error|E godot.*ERROR:|GL_MAX_FRAGMENT_UNIFORM' artifacts/android/logcat.txt artifacts/android/before-restart.log; then
  echo '::error::Runtime error during Android 3D smoke test'
  exit 1
fi
printf 'PASS: Android API 29 x86_64 emulator split APK/Data installation, native picker import, same-size corrupt pack rejection, changed-catalog revision 2 Data update on the identical installed APK, verified offline restart, mounted touch controls/gait/side/riding/dismount, visible third-person hero, mobile/high settings and sound controls, origin selection, tavern companion hire, courier acceptance and delivery payout, neutrality, recruiting, connected-road travel, saved arrival, pan/zoom, battle controls, pause/background, and progress restore.\nReal-device performance and touch usability remain unverified.\n' > artifacts/ANDROID-SMOKE.txt
