import json,math,subprocess,unittest
from pathlib import Path

class PlayableHumanTests(unittest.TestCase):
    def test_rebuild_and_clothing(self):
        path=Path('godot/assets/content/humans/human-body.json')
        before=path.read_bytes()
        subprocess.run(['python3','scripts/build-playable-human.py'],check=True)
        self.assertEqual(before,path.read_bytes())
        model=json.loads(before)
        self.assertEqual(len(model['bones']),20)
        self.assertEqual({s['kind'] for s in model['surfaces']},{'skin','coat','trousers','boots'})
        for i,bone in enumerate(model['bones']):
            self.assertTrue(-1<=bone['parent']<i)
        for surface in model['surfaces']:
            count=len(surface['positions'])
            for field in ['normals','uv','joints','weights']:
                self.assertEqual(len(surface[field]),count)
            for weights in surface['weights']:
                self.assertAlmostEqual(sum(weights),1,places=5)
                self.assertTrue(all(math.isfinite(w) and 0<=w<=1 for w in weights))
            self.assertTrue(all(0<=i<count for i in surface['indices']))
        # No bare torso or pelvis: skin contains only the head and hands.
        skin=next(s for s in model['surfaces'] if s['kind']=='skin')
        for start in range(0,len(skin['indices']),3):
            tri=skin['indices'][start:start+3]
            center=sum(skin['positions'][i][1] for i in tri)/3
            if center<1.59:
                self.assertTrue(all('wrist' in model['bones'][skin['joints'][i][max(range(4),key=lambda j:skin['weights'][i][j])]]['name'] for i in tri))

if __name__=='__main__':unittest.main()
