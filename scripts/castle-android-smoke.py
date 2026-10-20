"""Real APK + public SAF import + touch controls; inspect saves read-only via debug run-as."""
import json, struct, subprocess, time
from pathlib import Path
PKG='com.ironcrowns.castles.maps'
OUT=Path('artifacts/android'); OUT.mkdir(parents=True,exist_ok=True)
def adb(*args):
    return subprocess.check_output(['adb',*args],timeout=40)
def logs():
    return adb('logcat','-d','-s','godot').decode(errors='replace')
def wait(marker, seconds=90):
    deadline=time.monotonic()+seconds
    while time.monotonic()<deadline:
        if marker in logs(): return
        time.sleep(1)
    raise AssertionError('Timed out waiting for '+marker)
def screenshot(name):
    image=adb('exec-out','screencap','-p'); (OUT/name).write_bytes(image)
    return struct.unpack('>II',image[16:24])
try:
    adb('install','-r','artifacts/Iron-Crowns-0.10.0-Castle-Maps.apk')
    adb('shell','wm','size','720x1280'); adb('shell','wm','density','160')
    adb('logcat','-c')
    adb('shell','am','start','-W','-n',PKG+'/com.godot.game.GodotApp')
    adb('push','artifacts/Iron-Crowns-0.10.0-Castle-Data.icdata','/sdcard/Download/Iron-Crowns-0.10.0-Castle-Data.icdata')
    wait('IRON_DATA_REQUIRED')
    w,h=screenshot('00-installer.png')
    def tap_xy(x,y):
        scale=min(w/1280,h/720)
        adb('shell','input','tap',str(round((w-1280*scale)/2+x*scale)),str(round((h-720*scale)/2+y*scale)))
        time.sleep(2)
    tap_xy(640,515)
    subprocess.run(['python3','scripts/godot-picker.py','Iron-Crowns-0.10.0-Castle-Data.icdata'],check=True,timeout=90)
    wait('IRON_RTS_READY'); time.sleep(3)
    w,h=screenshot('01-intro.png')
    points=json.loads(Path('artifacts/rts-touch-points.json').read_text())
    assert points['viewport']==[1280,720],points
    def tap(name): tap_xy(*points[name])
    tap('mission'); time.sleep(4)
    tap('start'); tap('farm'); screenshot('02-farm-selected.png')
    tap('suggest'); screenshot('03-farm-position.png')
    tap('build')
    # Software-emulated graphics can advance simulation much slower than wall time.
    # Observe actual completed construction; never change speed/resources for the test.
    deadline=time.monotonic()+180
    while True:
        tap('save')
        saved=json.loads(adb('exec-out','run-as',PKG,'cat','files/castle-rts-v1.json'))
        (OUT/'farm-save.json').write_text(json.dumps(saved,indent=2))
        farms=[b for b in saved['buildings'] if b['kind']=='farm']
        if len(farms)==1 and farms[0]['built']==1: break
        if time.monotonic()>=deadline: break
        time.sleep(1)
    assert len(farms)==1 and farms[0]['built']==1, saved
    assert saved['mission_id']=='crossing',saved
    assert saved['resources']['wood']==245, saved['resources']
    screenshot('04-built-farm.png')
    adb('shell','am','force-stop',PKG); adb('logcat','-c')
    adb('shell','am','start','-W','-n',PKG+'/com.godot.game.GodotApp')
    wait('IRON_RTS_READY'); time.sleep(3)
    # Resume occupies the original New Game row; New Game now sits below it.
    tap('start'); tap('save')
    restored=json.loads(adb('exec-out','run-as',PKG,'cat','files/castle-rts-v1.json'))
    assert restored['mission_id']=='crossing',restored
    assert [b['id'] for b in restored['buildings'] if b['kind']=='farm']==[farms[0]['id']],restored
    screenshot('05-restored-farm.png')
    assert 'SCRIPT ERROR' not in logs(), logs()[-4000:]
    print('IRON_ANDROID_TOUCH_FARM_PASS',flush=True)
except Exception as exc:
    print('::error::Android farm smoke: '+repr(exc).replace('%','%25').replace('\n','%0A'),flush=True)
    try:
        screenshot('failure.png')
        print('::error::'+logs()[-4000:].replace('%','%25').replace('\n','%0A').replace('\r','%0D'))
    except Exception: pass
    raise
finally:
    (OUT/'logcat.txt').write_bytes(adb('logcat','-d'))
