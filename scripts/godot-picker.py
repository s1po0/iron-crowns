"""Exercise the actual Android Storage Access Framework picker, not app-private injection."""
import re, subprocess, sys, time, xml.etree.ElementTree as ET

def adb(*args):
    return subprocess.check_output(['adb',*args],timeout=35)
def nodes():
    adb('shell','uiautomator','dump','/sdcard/window.xml')
    raw=adb('shell','cat','/sdcard/window.xml')
    open('artifacts/android/picker.xml','wb').write(raw)
    return list(ET.fromstring(raw).iter('node'))
def click(labels):
    for node in nodes():
        if node.get('text') in labels or node.get('content-desc') in labels:
            x,y,xx,yy=map(int,re.findall(r'\d+',node.get('bounds')))
            adb('shell','input','tap',str((x+xx)//2),str((y+yy)//2))
            time.sleep(1)
            return True
    return False
filename=sys.argv[1]
if not click([filename]):
    click(['Show roots','Open navigation drawer'])
    if not click(['Downloads','Download']):
        raise SystemExit('Downloads provider not visible; inspect picker.xml')
    if not click([filename]):
        raise SystemExit('Requested data file not visible; inspect picker.xml')
click(['Open','OPEN','Select','SELECT'])
