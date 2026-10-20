class_name CastleSim
extends RefCounted
# Pure RTS simulation. All modes share these budgets; quality changes presentation only.
const SIZE = 40
const TILE = 3.0
const SAVE = "user://castle-rts-v1.json"
const COSTS = {"stockpile":[30,0],"woodcutter":[25,0],"farm":[35,0],"mill":[45,10],"bakery":[35,10],"quarry":[30,0],"house":[35,5],"wall":[0,8],"gate":[15,20],"barracks":[50,30]}
const FOOTPRINT = {"keep":3,"stockpile":2,"woodcutter":2,"farm":3,"mill":2,"bakery":2,"quarry":2,"house":2,"wall":1,"gate":1,"barracks":2}
var resources = {"wood":220,"stone":150,"grain":0,"flour":0,"bread":30,"gold":250}
var buildings: Array = []
var units: Array = []
var navigation = AStarGrid2D.new()
var time = 0.0
var food_clock = 0.0
var stage = 0
var next_id = 1
var wave = 0
var wave_clock = 0.0
var ended = ""
var rally = Vector2i(20,20)
var revision = 0
var deliveries = 0
var baked = 0
var kills = 0
var loaded = false

func _init() -> void:
	navigation.region = Rect2i(0,0,SIZE,SIZE)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()
	buildings.append({"id":0,"kind":"keep","x":18,"y":16,"hp":600.0,"built":1.0})
	rebuild_navigation()

static func world(cell: Vector2) -> Vector3:
	return Vector3((cell.x-SIZE*.5)*TILE,0,(cell.y-SIZE*.5)*TILE)

static func cell(point: Vector3) -> Vector2i:
	return Vector2i(roundi(point.x/TILE+SIZE*.5),roundi(point.z/TILE+SIZE*.5))

static func water(p: Vector2i) -> bool:
	return p.x<3 or p.y<3 or p.x>=SIZE-3 or p.y>=SIZE-3 or (p.x>=30 and p.x<=32 and not p.y in [16,17,18])

func rebuild_navigation() -> void:
	for y in SIZE:
		for x in SIZE:
			navigation.set_point_solid(Vector2i(x,y),water(Vector2i(x,y)))
	for b in buildings:
		if b.kind=="gate":
			continue
		for y in FOOTPRINT[b.kind]:
			for x in FOOTPRINT[b.kind]:
				navigation.set_point_solid(Vector2i(b.x+x,b.y+y))
	# Repath moving units after every placement/demolition rather than walking through new walls.
	for u in units:
		u.route = []

func entrance(b: Dictionary) -> Vector2i:
	var n: int = FOOTPRINT[b.kind]
	for p in [Vector2i(b.x+n,b.y),Vector2i(b.x-1,b.y),Vector2i(b.x,b.y+n),Vector2i(b.x,b.y-1)]:
		if navigation.is_in_boundsv(p) and not navigation.is_point_solid(p):
			return p
	return Vector2i(-1,-1)

func can_build(kind: String, p: Vector2i) -> bool:
	if not COSTS.has(kind) or not ended.is_empty():
		return false
	if resources.wood<COSTS[kind][0] or resources.stone<COSTS[kind][1]:
		return false
	for y in FOOTPRINT[kind]:
		for x in FOOTPRINT[kind]:
			var q = p+Vector2i(x,y)
			if water(q) or navigation.is_point_solid(q):
				return false
			for b in buildings:
				if Rect2i(b.x,b.y,FOOTPRINT[b.kind],FOOTPRINT[b.kind]).has_point(q):
					return false
			for u in units:
				if u.hp>0 and Vector2(q).distance_to(u.at)<.7:
					return false
	return true

func place(kind: String, p: Vector2i) -> bool:
	if not can_build(kind,p):
		return false
	resources.wood-=COSTS[kind][0]
	resources.stone-=COSTS[kind][1]
	buildings.append({"id":next_id,"kind":kind,"x":p.x,"y":p.y,"hp":180.0 if kind in ["wall","gate"] else 250.0,"built":0.0})
	next_id+=1
	rebuild_navigation()
	revision+=1
	return true

func by_kind(kind: String) -> Array:
	return buildings.filter(func(b):return b.kind==kind and b.built>=1.0 and b.hp>0)

func add_unit(kind: String, p: Vector2i, home: int=-1) -> void:
	units.append({"id":next_id,"kind":kind,"at":Vector2(p),"hp":45.0 if kind=="raider" else 75.0,"home":home,"route":[],"goal":p,"phase":"out","wait":0.0,"carry":"","amount":0,"attack":0.0,"facing":0.0,"walking":false,"hit":false})
	next_id+=1

func train() -> bool:
	if not ended.is_empty() or by_kind("barracks").is_empty() or resources.gold<20 or resources.bread<2 or units.filter(func(u):return u.kind=="soldier" and u.hp>0).size()>=24:
		return false
	var p = entrance(by_kind("barracks")[0])
	if p.x<0:
		return false
	resources.gold-=20
	resources.bread-=2
	add_unit("soldier",p)
	return true

func order(p: Vector2i) -> bool:
	if not ended.is_empty() or water(p) or navigation.is_point_solid(p):
		return false
	rally=p
	for u in units:
		if u.kind=="soldier":
			u.route=[]
	return true

func route(u: Dictionary, goal: Vector2i, dt: float) -> bool:
	var current = Vector2i(roundi(u.at.x),roundi(u.at.y))
	u.walking=false
	if goal.x<0 or water(goal) or navigation.is_point_solid(goal):
		return false
	if u.at.distance_to(Vector2(goal))<.12:
		return true
	if u.route.is_empty() or u.goal!=goal:
		u.goal=goal
		var path = navigation.get_id_path(current,goal,true)
		u.route=Array(path)
		if not u.route.is_empty():
			u.route.pop_front()
	if u.route.is_empty():
		return false
	var next = Vector2(u.route[0])
	var delta: Vector2 = next-u.at
	u.facing=atan2(-delta.x,-delta.y)
	u.walking=true
	u.at=u.at.move_toward(next,dt*(.55 if u.kind=="worker" else .8))
	if u.at.distance_to(next)<.04:
		u.route.pop_front()
	return false

func worker(u: Dictionary, dt: float) -> void:
	var homes = buildings.filter(func(b):return b.id==u.home)
	if homes.is_empty() or by_kind("stockpile").is_empty():
		u.walking=false
		return
	var home: Dictionary = homes[0]
	var depot: Dictionary = by_kind("stockpile")[0]
	var source = entrance(home)
	var good = "wood"
	if home.kind=="woodcutter":
		source=Vector2i(8,10)
	elif home.kind=="quarry":
		source=Vector2i(8,28)
		good="stone"
	elif home.kind=="farm":
		good="grain"
	elif home.kind=="mill":
		good="flour"
	elif home.kind=="bakery":
		good="bread"
	if u.phase=="input":
		if route(u,entrance(depot),dt):
			var input = "grain" if home.kind=="mill" else "flour"
			if resources[input]>=2:
				resources[input]-=2
				u.carry=input
				u.amount=2
				u.phase="out"
	elif u.phase=="out":
		if route(u,source,dt):
			u.wait+=dt
			if u.wait>=3:
				u.wait=0.0
				u.carry=good
				u.amount=4 if good=="bread" else 3
				u.phase="return"
	elif route(u,entrance(depot),dt):
		resources[u.carry]+=u.amount
		deliveries+=1
		if u.carry=="bread":
			baked+=u.amount
		u.carry=""
		u.amount=0
		u.phase="input" if home.kind in ["mill","bakery"] else "out"

func combat(u: Dictionary, dt: float) -> void:
	u.attack=maxf(0,u.attack-dt)
	var enemies = units.filter(func(other):return other.hp>0 and ((u.kind=="soldier" and other.kind=="raider") or (u.kind=="raider" and other.kind=="soldier")))
	enemies.sort_custom(func(a,b):return u.at.distance_squared_to(a.at)<u.at.distance_squared_to(b.at))
	if not enemies.is_empty() and u.at.distance_to(enemies[0].at)<7:
		var target: Dictionary=enemies[0]
		if u.at.distance_to(target.at)<.65:
			u.walking=false
			u.facing=atan2(u.at.x-target.at.x,u.at.y-target.at.y)
			if u.attack<=0:
				u.attack=1.1
				u.hit=false
			if u.attack<=.65 and u.attack>.45 and not u.hit:
				u.hit=true
				target.hp-=12 if u.kind=="soldier" else 7
				if target.hp<=0 and target.kind=="raider":
					kills+=1
		else:
			route(u,Vector2i(target.at.round()),dt)
	elif u.kind=="soldier":
		var rank=units.filter(func(other):return other.kind=="soldier" and other.hp>0).find(u)
		var goal=rally+Vector2i(rank%4,int(rank/4))
		if water(goal) or navigation.is_point_solid(goal):
			goal=rally
		route(u,goal,dt)
	else:
		var target: Dictionary=buildings[0]
		var walls=buildings.filter(func(b):return b.kind in ["wall","gate"] and b.hp>0)
		walls.sort_custom(func(a,b):return u.at.distance_squared_to(Vector2(a.x,a.y))<u.at.distance_squared_to(Vector2(b.x,b.y)))
		if not walls.is_empty():
			target=walls[0]
		if u.at.distance_to(Vector2(entrance(target)))<.65:
			u.walking=false
			if u.attack<=0:
				u.attack=1.1
				target.hp-=8
		else:
			route(u,entrance(target),dt)

func step(dt: float) -> void:
	if not ended.is_empty():
		return
	dt=clampf(dt,0,.2)
	time+=dt
	food_clock+=dt
	if food_clock>=30:
		food_clock=0
		resources.bread=maxi(0,resources.bread-2)
		resources.gold+=8
	for b in buildings:
		b.built=minf(1,b.built+dt/8)
		if b.built>=1 and b.kind in ["woodcutter","farm","mill","bakery","quarry"] and not units.any(func(u):return u.home==b.id):
			var p=entrance(b)
			if p.x>=0:
				add_unit("worker",p,b.id)
				if b.kind in ["mill","bakery"]:
					units[-1].phase="input"
	for u in units:
		if u.hp<=0:
			u.walking=false
			continue
		if u.kind=="worker":
			worker(u,dt)
		else:
			combat(u,dt)
	var destroyed=buildings.filter(func(b):return b.hp<=0 and b.kind!="keep")
	if not destroyed.is_empty():
		buildings=buildings.filter(func(b):return b.hp>0 or b.kind=="keep")
		rebuild_navigation()
	if buildings[0].hp<=0:
		ended="defeat"
	var targets=["stockpile","woodcutter","farm","mill","bakery","wall","barracks"]
	if stage<targets.size() and not by_kind(targets[stage]).is_empty():
		if stage!=5 or by_kind("wall").size()>=3:
			stage+=1
	if stage==7 and units.filter(func(u):return u.kind=="soldier" and u.hp>0).size()>=6 and baked>=4:
		stage=8
	if stage>=8 and wave==0:
		wave=1
		for i in 8:
			add_unit("raider",Vector2i(26+i%3,7+i/3))
	if wave>0 and not units.any(func(u):return u.kind=="raider" and u.hp>0):
		stage=9
		ended="victory"
	revision+=1

func save_game(path: String=SAVE) -> bool:
	var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:
		return false
	var saved_units=units.duplicate(true)
	for u in saved_units:
		u.at=[u.at.x,u.at.y]
		u.goal=[u.goal.x,u.goal.y]
		u.route=[]
	file.store_string(JSON.stringify({"schema":1,"resources":resources,"buildings":buildings,"units":saved_units,"time":time,"food_clock":food_clock,"stage":stage,"next_id":next_id,"wave":wave,"ended":ended,"rally":[rally.x,rally.y],"baked":baked,"kills":kills,"deliveries":deliveries}))
	file.flush()
	var ok=file.get_error()==OK
	file.close()
	return ok and DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))==OK

func load_game(path: String=SAVE) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var raw=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not valid(raw):
		return false
	resources=raw.resources
	for key in resources:
		resources[key]=int(resources[key])
	buildings=raw.buildings
	units=raw.units
	for b in buildings:
		b.id=int(b.id)
		b.x=int(b.x)
		b.y=int(b.y)
	for u in units:
		u.hit=bool(u.get("hit",false))
		u.id=int(u.id)
		u.home=int(u.home)
		u.amount=int(u.amount)
		u.at=Vector2(u.at[0],u.at[1])
		u.goal=Vector2i(u.goal[0],u.goal[1])
		u.route=[]
	for key in ["time","food_clock","stage","next_id","wave","ended","baked","kills","deliveries"]:
		set(key,int(raw[key]) if key in ["stage","next_id","wave","baked","kills","deliveries"] else raw[key])
	rally=Vector2i(raw.rally[0],raw.rally[1])
	rebuild_navigation()
	loaded=true
	return true

static func valid(raw) -> bool:
	if not raw is Dictionary or raw.get("schema")!=1:
		return false
	for key in ["resources","buildings","units","time","food_clock","stage","next_id","wave","ended","rally","baked","kills","deliveries"]:
		if not raw.has(key):
			return false
	if not raw.resources is Dictionary or not raw.buildings is Array or raw.buildings.is_empty() or raw.buildings.size()>400 or not raw.units is Array or raw.units.size()>100:
		return false
	for key in ["wood","stone","grain","flour","bread","gold"]:
		if not raw.resources.get(key) is float and not raw.resources.get(key) is int:
			return false
		if raw.resources[key]<0 or raw.resources[key]>1000000:
			return false
	var occupied={}
	var ids={}
	for b in raw.buildings:
		if not b is Dictionary or not FOOTPRINT.has(b.get("kind","")):
			return false
		for key in ["id","x","y","hp","built"]:
			if not b.get(key) is float and not b.get(key) is int:
				return false
		if b.id<0 or b.id!=int(b.id) or b.x!=int(b.x) or b.y!=int(b.y) or b.id in ids or b.x<3 or b.y<3 or b.x+FOOTPRINT[b.kind]>=SIZE-3 or b.y+FOOTPRINT[b.kind]>=SIZE-3 or b.hp<0 or b.hp>600 or b.built<0 or b.built>1:
			return false
		ids[b.id]=true
		for y in FOOTPRINT[b.kind]:
			for x in FOOTPRINT[b.kind]:
				var p=Vector2i(b.x+x,b.y+y)
				if water(p) or p in occupied:
					return false
				occupied[p]=true
	if raw.buildings[0].kind!="keep":
		return false
	for u in raw.units:
		if not u is Dictionary or not u.get("kind") in ["worker","soldier","raider"]:
			return false
		for key in ["at","goal"]:
			if not valid_vector(u.get(key),2,SIZE):
				return false
		for key in ["hp","home","id","wait","amount","attack","facing"]:
			if not valid_number(u.get(key),-600,1000000):
				return false
		if not u.get("walking") is bool or u.id<0 or u.id!=int(u.id) or u.id in ids:
			return false
		ids[u.id]=true
		if not u.get("carry") in ["","wood","stone","grain","flour","bread"] or not u.get("phase") in ["out","input","return"]:
			return false
	for key in ["time","food_clock","stage","next_id","wave","baked","kills","deliveries"]:
		if not valid_number(raw[key],0,1000000):
			return false
	return raw.next_id>ids.keys().max() and raw.stage<=9 and raw.wave<=1 and raw.ended in ["","victory","defeat"] and valid_vector(raw.rally,2,SIZE)

static func valid_number(value, low: float, high: float) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and value>=low and value<=high

static func valid_vector(value, count: int, limit: float) -> bool:
	if not value is Array or value.size()!=count:
		return false
	for v in value:
		if not valid_number(v,0,limit):
			return false
	return true
