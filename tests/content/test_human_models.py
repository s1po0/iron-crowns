import hashlib,json,struct,subprocess,sys,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]

def glb(name):
    raw=(ROOT/'godot/assets/models'/name).read_bytes()
    magic,version,length=struct.unpack_from('<III',raw)
    assert magic==0x46546c67 and version==2 and length==len(raw)
    size,kind=struct.unpack_from('<II',raw,12)
    assert kind==0x4e4f534a
    document=json.loads(raw[20:20+size]);start=20+size
    count,kind=struct.unpack_from('<II',raw,start)
    assert kind==0x004e4942
    return document,raw[start+8:start+8+count]

def values(doc,data,index):
    a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
    width={'VEC3':3,'VEC4':4,'SCALAR':1,'MAT4':16}[a['type']]
    fmt={5126:'f',5125:'I',5123:'H'}[a['componentType']]
    return struct.unpack_from('<'+fmt*a['count']*width,data,v.get('byteOffset',0)+a.get('byteOffset',0))

class HumanModels(unittest.TestCase):
    def test_rig_weights(self):
        d,b=glb('human-rig.glb');self.assertEqual(len(d['skins'][0]['joints']),163)
        attr=d['meshes'][0]['primitives'][0]['attributes']
        weights=values(d,b,attr['WEIGHTS_0']);joints=values(d,b,attr['JOINTS_0'])
        self.assertEqual(len(weights),len(joints));self.assertLess(max(joints),163)
        for i in range(0,len(weights),4):self.assertAlmostEqual(sum(weights[i:i+4]),1,places=6)
        parents={}
        for i,node in enumerate(d['nodes']):
            for child in node.get('children',[]):
                self.assertNotIn(child,parents);parents[child]=i
        for i in parents:
            visited=set();j=i
            while j in parents:
                self.assertNotIn(j,visited);visited.add(j);j=parents[j]
    def test_head_and_eyes(self):
        d,b=glb('human-head.glb');primitives=d['meshes'][0]['primitives']
        self.assertEqual(len(primitives),7)
        self.assertGreater(len(values(d,b,primitives[0]['indices']))//3,8000)
        coords=values(d,b,primitives[0]['attributes']['POSITION'])
        self.assertGreater(min(coords[1::3]),1.50);self.assertLess(max(coords[1::3]),1.85)
        for p in primitives:
            self.assertLess(max(values(d,b,p['indices'])),d['accessors'][p['attributes']['POSITION']]['count'])
    def test_reproducible(self):
        paths=list((ROOT/'godot/assets/models').glob('*.glb'))
        before={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
        subprocess.run([sys.executable,str(ROOT/'scripts/build-human-models.py')],check=True)
        self.assertEqual(before,{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in paths})

if __name__=='__main__':unittest.main()
