import hashlib
import json
from pathlib import Path
import struct
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT/'art-source/human/generated/human-foundation.glb'

class HumanModelTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw=MODEL.read_bytes()
        magic,version,size=struct.unpack_from('<III',cls.raw)
        assert magic==0x46546c67 and version==2 and size==len(cls.raw)
        length,kind=struct.unpack_from('<II',cls.raw,12)
        assert kind==0x4e4f534a
        cls.doc=json.loads(cls.raw[20:20+length])
        start=20+length
        length,kind=struct.unpack_from('<II',cls.raw,start)
        assert kind==0x004e4942
        cls.binary=cls.raw[start+8:start+8+length]

    def rows(self,index):
        a=self.doc['accessors'][index]
        view=self.doc['bufferViews'][a['bufferView']]
        count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
        fmt={5126:'f',5123:'H',5125:'I'}[a['componentType']]
        start=view.get('byteOffset',0)+a.get('byteOffset',0)
        return list(struct.iter_unpack('<'+fmt*count,self.binary[start:start+view['byteLength']]))

    def test_skeleton_and_anatomy(self):
        self.assertEqual(len(self.doc['skins'][0]['joints']),20)
        attrs=self.doc['meshes'][0]['primitives'][0]['attributes']
        p=self.rows(attrs['POSITION'])
        self.assertGreater(len(p),10000)
        self.assertAlmostEqual(max(v[1] for v in p)-min(v[1] for v in p),1.85,places=5)
        names={n['name'] for n in self.doc['nodes']}
        self.assertTrue({'head','wrist_L','wrist_R','Sclera_L','Iris_R'}.issubset(names))

    def test_weights_indices_normals(self):
        primitive=self.doc['meshes'][0]['primitives'][0]
        attrs=primitive['attributes']
        for row in self.rows(attrs['WEIGHTS_0']):
            self.assertAlmostEqual(sum(row),1,places=5)
            self.assertTrue(all(0<=v<=1 for v in row))
        for row in self.rows(attrs['JOINTS_0']):
            self.assertTrue(all(0<=v<20 for v in row))
        vertices=len(self.rows(attrs['POSITION']))
        self.assertTrue(all(0<=r[0]<vertices for r in self.rows(primitive['indices'])))
        for row in self.rows(attrs['NORMAL']):
            self.assertAlmostEqual(sum(v*v for v in row),1,places=4)

    def test_provenance_and_reproducibility(self):
        p=json.loads(MODEL.with_name('provenance.json').read_text())
        self.assertEqual(p['license'],'CC0-1.0')
        self.assertEqual(p['sha256'],hashlib.sha256(self.raw).hexdigest())
        subprocess.run(['python3',str(ROOT/'scripts/build-human-model.py')],check=True,capture_output=True)
        self.assertEqual(MODEL.read_bytes(),self.raw)

if __name__=='__main__':
    unittest.main()
