#!/usr/bin/env bash
set -euo pipefail
PKG=com.ironcrowns.marches
mkdir -p artifacts/android
exec > >(tee /tmp/android-smoke.log) 2>&1
finish() {
  status=$?
  adb logcat -d > artifacts/android/logcat.txt
  if [ "$status" -ne 0 ]; then
    adb exec-out screencap -p > artifacts/android/failure.png
    python3 - <<'PYLOG'
lines=open('artifacts/android/logcat.txt',errors='replace').readlines()
selected=[x for x in lines if any(t in x for t in ['godot','Godot','FATAL','Fatal','DEBUG','AndroidRuntime','ironcrowns'])]
s=''.join(selected[-150:])[-18000:]
print('::error::'+s.replace('%','%25').replace('\n','%0A').replace('\r','%0D'))
PYLOG
    tail -60 /tmp/android-smoke.log | python3 -c 'import sys; s=sys.stdin.read(); print("::error::"+s.replace("%","%25").replace("\n","%0A").replace("\r","%0D"))'
  fi
}
trap finish EXIT
adb install -r artifacts/Iron-Crowns-0.2.0-3D.apk
adb shell pm clear "$PKG"
adb shell wm size 720x1280
adb shell wm density 160
adb logcat -c
adb shell am start -W -n "$PKG/com.godot.game.GodotApp"
for attempt in $(seq 1 45); do
  if adb logcat -d -s godot | grep -q IRON_SCENE_READY; then break; fi
  sleep 1
 done
adb logcat -d -s godot | grep IRON_SCENE_READY
sleep 3
adb shell pidof "$PKG"
adb exec-out screencap -p > artifacts/android/01-title.png
adb shell input tap 220 510
sleep 3
adb shell input tap 780 52
sleep 1
adb exec-out run-as "$PKG" cat files/progress.json > artifacts/android/progress.json
cat artifacts/android/progress.json
python3 - <<'PYTEST'
import json
save=json.load(open('artifacts/android/progress.json'))
assert save['gold']==90 and save['victories']==0, save
print('On-device 3D HUD recruitment and progress-write assertion passed.')
PYTEST
adb shell input tap 570 52
sleep 3
adb shell input swipe 125 584 180 584 1500
adb shell input swipe 1156 585 1157 585 1000
adb shell input tap 691 660
adb exec-out screencap -p > artifacts/android/02-battle.png
adb shell input keyevent KEYCODE_BACK
sleep 1
adb exec-out screencap -p > artifacts/android/03-pause.png
adb shell input keyevent KEYCODE_HOME
sleep 1
adb shell am start -W -n "$PKG/com.godot.game.GodotApp"
sleep 2
adb shell am force-stop "$PKG"
adb shell am start -W -n "$PKG/com.godot.game.GodotApp"
sleep 5
adb shell pidof "$PKG"
adb logcat -d > artifacts/android/logcat.txt
if grep -E 'FATAL EXCEPTION|SCRIPT ERROR|Parse Error|E godot.*ERROR:|GL_MAX_FRAGMENT_UNIFORM' artifacts/android/logcat.txt; then
  echo '::error::Runtime error during Android 3D smoke test'
  exit 1
fi
printf 'PASS: Android API 29 x86_64 emulator install, launch, touch battle interaction, pause/background, and process restart.\nReal-device performance and touch usability remain unverified.\n' > artifacts/ANDROID-SMOKE.txt
