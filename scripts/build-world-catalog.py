#!/usr/bin/env python3
"""Original enlarged world. Stable settlement IDs 0..31 preserve old campaigns."""
import json
from pathlib import Path
factions=[
 ('Ashen Crown','8c4149','House Ardent','Maren Ardent','Westland towns and armored retainers'),
 ('Northguard','466b8c','House Rime','Eirik Rime','Northern passes and shield-bearing infantry'),
 ('Verdant League','566e42','House Alder','Talia Alder','Western woodland towns and merchant roads'),
 ('Sunward Dominion','bd9354','House Saren','Nadir Saren','Southern markets and desert caravan routes'),
 ('Khurai Horse Clans','876249','Clan Temur','Saran Temur','Eastern grasslands and horse-herding families'),
 ('Storm Coast Pact','607a77','House Vey','Idra Vey','Coastal trading settlements and island traditions')]
anchors=[[-165,130],[-320,-15],[-220,-210],[20,-250],[25,-35],[300,-105],[285,220],[-40,245],[-850,-450],[-620,-700],[180,-710],[730,-520],[880,-70],[820,470],[290,680],[-660,490]]
names=['Hearthglen','Crownharbor','Stonewatch','Wintermere','Highcourt','Eastmere','Duneshade','Greenhaven','Greyhaven','Ravenfjord','Frostmere','Temur Crossing','Orun Steppe','Saran Oasis','Copperhaven','Stormwatch']
castles=['Dusk Tower','Saltwatch','Ironpass','Frostgate','Crownspire',"Falcon’s Rest",'Sunspire','Thornwall','Tidekeep','Ravenhold','Icegate','Skywatch','Windkeep','Amberkeep','Copper Gate','Gale Tower']
villages=['Ashford','Barleywick','Reedbank','Westmere','Pinecross','Greybrook','Snowfell','Whitefield','Oakridge','Millstead','Longford','Windmere','Redwell','Saffron Vale','Willowford','Meadowend','Pebblewick','Tideford','Ravenfield','Pineshore','Frostford','Coldwell','Horsewell','Tengri Vale','Orunford','Reed Steppe','Amberwell','Palmstead','Copperford','Southwell','Galehaven','Mossbank']
owners=[0,2,1,1,0,3,3,2,5,1,1,4,4,3,3,5]
settlements=[]
for i,(x,z) in enumerate(anchors):
 for name,dx,dz,kind in [(names[i],0,0,'Town'),(castles[i],32,-33,'Castle'),(villages[i*2],-33,27,'Village'),(villages[i*2+1],38,29,'Village')]:
  settlements.append(dict(id=len(settlements),name=name,at=[x+dx,z+dz],kind=kind,faction=owners[i]))
world=dict(schema=1,id='ashen-marches',width=2700,depth=2040,seed=1907,anchors=anchors,
 factions=[dict(id=i,name=n,color=c,clan=cl,leader=l,description=d) for i,(n,c,cl,l,d) in enumerate(factions)],settlements=settlements,
 roads=[[i*4,i*4+sub] for i in range(16) for sub in [1,2,3]]+[[a*4,b*4] for a,b in [[0,1],[1,2],[2,3],[3,4],[4,0],[4,5],[5,6],[6,7],[7,0],[0,2],[8,2],[9,8],[10,3],[11,10],[12,5],[13,12],[14,6],[15,7]]],
 ridges=[[-115,-95,55],[-95,-180,65],[90,-175,64],[155,-255,77],[158,70,46],[-275,205,40],[-500,-570,100],[-250,-670,90],[410,-620,105],[600,-320,75],[650,250,60],[-440,400,65]])
Path('godot/assets/content/world.json').write_text(json.dumps(world,indent=2)+'\n')
assert len(world['settlements'])==64 and len(world['factions'])==6
