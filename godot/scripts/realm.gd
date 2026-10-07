class_name CrownRealm
extends Node3D

# Original, road-connected campaign continent. Battle arenas remain separate.
var WIDTH = 2700.0
var DEPTH = 2040.0
var FACTIONS: Array = []
var COLORS: Array = []
var ANCHORS: Array = []
var world_definition: Dictionary = {}
var game
var life: WandererLife
var settlements: Array = []
var graph = AStar3D.new()
var road_edges: Array = []
var party = Vector3(-165,0,130)
var route: Array = []
var destination = -1
var selected = -1
var speed = 0
var day = 1
var hours = 0.0
var food = 35
var grain = 0
var relations = [0,0,0,0]
var holdings: Array = []
var defeated: Array = []
var quest = -1
var quest_done = 0
var travel_distance = 0.0
var map_focus = Vector3(70,0,-10)
var zoom = 760.0
var pending = ""
var encounter_npc = -1
var encounter_fief = -1
var checkpoint_army = 8
var civilians: Array = []
var player_model: Node3D
var route_mesh: MeshInstance3D
var deco: Node3D
var noise = FastNoiseLite.new()
var rng = RandomNumberGenerator.new()
var save_clock = 0.0
var npc_clock = 0.0
var prepared = false
var palette: Dictionary = {}
var return_to_map = false
var camera_offset = Vector3(1700,0,0)

func initialize(owner: Node) -> void:
	game = owner
	life = WandererLife.new(self)
	position = camera_offset
	noise.seed = 1907
	noise.frequency = .014
	noise.fractal_octaves = 4
	rng.seed = 8631
	world_definition = ContentAssets.json("res://assets/content/world.json")
	assert(world_definition.schema==1 and world_definition.id=="ashen-marches","Unsupported world definition")
	WIDTH = float(world_definition.width)
	DEPTH = float(world_definition.depth)
	for faction in world_definition.factions:
		FACTIONS.append(str(faction.name))
		COLORS.append(Color(str(faction.color)))
	relations.resize(FACTIONS.size())
	relations.fill(0)
	for anchor in world_definition.anchors:
		ANCHORS.append(Vector2(anchor[0],anchor[1]))
	for settlement in world_definition.settlements:
		assert(int(settlement.id)==settlements.size(),"Settlement IDs must be stable and contiguous")
		add_settlement(str(settlement.name),Vector2(settlement.at[0],settlement.at[1]),str(settlement.kind),int(settlement.faction))
	party.y = elevation(party.x,party.z)

func add_settlement(title: String, at: Vector2, kind: String, faction: int) -> void:
	settlements.append({"name":title,"at":at,"kind":kind,"faction":faction,"stock":45,"prosperity":35+settlements.size()%37,"garrison":16 if kind=="Town" else 12 if kind=="Castle" else 4})

func elevation(x: float, z: float) -> float:
	var h = 7.0 + noise.get_noise_2d(x,z)*6.0
	# Continuous sculpted ranges, not the old cone-shaped horizon props.
	for definition in world_definition.ridges:
		var ridge = Vector3(definition[0],definition[1],definition[2])
		var dx = (x-ridge.x)/47.0
		var dz = (z-ridge.y)/83.0
		h += ridge.z*exp(-(dx*dx+dz*dz))*clampf(.75+noise.get_noise_2d(x*2.3,z*2.3)*.65,.4,1.25)
	var river_distance = absf(x-river_x(z))
	h = lerpf(5.5,h,smoothstep(5,23,river_distance))
	for settlement in settlements:
		var distance = Vector2(x,z).distance_to(settlement.at)
		if distance<24:
			h = lerpf(8,h,smoothstep(8,24,distance))
	var shore = -WIDTH*.46+sin(z*.006)*70+cos(z*.013)*35
	var east = WIDTH*.46+sin(z*.005)*60
	var north = -DEPTH*.46+sin(x*.006)*50
	var south = DEPTH*.46+cos(x*.007)*60
	var inland = minf(minf(x-shore,east-x),minf(z-north,south-z))
	# Round the outer corners and cut a western gulf without cutting old roads.
	var ellipse = 1-pow(x/(WIDTH*.50),4)-pow(z/(DEPTH*.50),4)
	inland = minf(inland,ellipse*180)
	inland -= 180*exp(-pow((x+WIDTH*.46)/200,2)-pow((z+30)/230,2))
	return lerpf(-7,h,smoothstep(-18,35,inland))

func river_x(z: float) -> float:
	return 205+sin(z*.010)*32+cos(z*.027)*8

func terrain_point(at: Vector2, lift: float = .0) -> Vector3:
	return Vector3(at.x,elevation(at.x,at.y)+lift,at.y)

func build() -> void:
	if prepared:
		return
	prepared = true
	deco = Node3D.new()
	add_child(deco)
	build_land()
	build_roads()
	build_forests()
	for i in range(settlements.size()):
		build_settlement(i)
	MarchArt.batch_static(deco)
	player_model = token(Color("e4bd74"),true)
	add_child(player_model)
	player_model.position = party
	MarchArt.batch_static(player_model)
	for i in range(16):
		var start = (i*7)%settlements.size()
		var kind = "Caravan" if i<8 else "Patrol" if i<12 else "Raiders"
		var node = token(Color("b6a880") if kind=="Caravan" else COLORS[i%COLORS.size()] if kind=="Patrol" else Color("ad4d36"),false,kind=="Caravan")
		add_child(node)
		var point = graph.get_point_position(start)
		node.position = point
		MarchArt.batch_static(node)
		civilians.append({"node":node,"at":point,"route":[],"kind":kind,"faction":i%COLORS.size(),"men":8+i%5,"active":not defeated.has(i),"goal":start})
		plan_npc(i)
	life.bind_caravan()
	draw_route()

func build_land() -> void:
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step = WIDTH/150.0
	var z_step = DEPTH/114.0
	for zi in range(114):
		for xi in range(150):
			var x = -WIDTH*.5+xi*step
			var z = -DEPTH*.5+zi*z_step
			for corner in [Vector2(0,0),Vector2(step,z_step),Vector2(0,z_step),Vector2(0,0),Vector2(step,0),Vector2(step,z_step)]:
				var p = terrain_point(Vector2(x,z)+corner)
				var n = noise.get_noise_2d(p.x*3,p.z*3)
				var color = Color(str(MarchCatalog.data().regions[0].color)).lerp(Color("a29d7c"),clampf(.5+n,0,1))
				if p.z>100 and p.x>100:
					color = Color("b3a075").lerp(Color("927d5f"),clampf(.4+n,0,1))
				if p.y>22:
					color = color.lerp(Color("72776d"),clampf((p.y-22)/24,0,1))
				if p.y>51 or (p.z< -170 and p.y>27):
					color = color.lerp(Color("d6d8cc"),clampf((p.y-28)/30,0,1))
				if p.x< -395:
					color = color.lerp(Color("bfb393"),.55)
				surface.set_color(color)
				surface.set_uv(Vector2(p.x,p.z)*.1)
				surface.add_vertex(p)
	surface.generate_normals()
	# Broad relief color must remain readable at atlas scale: do not multiply
	# it by a dark full-strength field texture or a high-frequency normal map.
	var shader = Shader.new()
	shader.code = """shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D meadow : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 region_color;
void vertex(){region_color=COLOR.rgb;}
void fragment(){
 float grain=texture(meadow,UV*0.35).g;
 ALBEDO=region_color*mix(0.94,1.10,grain);
 ROUGHNESS=0.96;
 SPECULAR=0.12;
}"""
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("meadow",ContentAssets.texture("res://assets/materials/meadow.jpg"))
	var land_mesh = surface.commit()
	assert(land_mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL][0].y>0,"Terrain winding must face sky")
	MarchArt.mesh(self,land_mesh,Vector3.ZERO,mat)
	var ocean = PlaneMesh.new()
	ocean.size = Vector2(WIDTH*1.8,DEPTH*1.8)
	var water = realm_material(Color("3e616a"))
	water.roughness = .45
	MarchArt.mesh(self,ocean,Vector3(0,-1.3,0),water)
	var river: Array = []
	for i in range(139):
		var z = -DEPTH*.5+i*DEPTH/138
		river.append(terrain_point(Vector2(river_x(z),z),.25))
	var banks: Array = []
	var waterline: Array = []
	for point in river:
		banks.append(point-Vector3(0,.12,0))
		waterline.append(point+Vector3(0,.12,0))
	ribbon(banks,5.2,realm_material(Color("76958c")),deco)
	ribbon(waterline,3.3,realm_material(Color("4e7277")),deco)

func ribbon(points: Array, width: float, mat: Material, parent: Node3D) -> MeshInstance3D:
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size()-1):
		var a: Vector3 = points[i]
		var b: Vector3 = points[i+1]
		var side = Vector3(-(b.z-a.z),0,b.x-a.x).normalized()*width
		var left_a = a-side
		var right_a = a+side
		var left_b = b-side
		var right_b = b+side
		for p in [left_a,right_b,right_a,left_a,left_b,right_b]:
			surface.add_vertex(p)
	surface.generate_normals()
	# Ribbons have no gameplay collision; both sides render above relief slopes.
	if mat is StandardMaterial3D:
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return MarchArt.mesh(parent,surface.commit(),Vector3.ZERO,mat)

func build_roads() -> void:
	for i in range(settlements.size()):
		graph.add_point(i,terrain_point(settlements[i].at,.7))
	road_edges = world_definition.roads.duplicate(true)
	var next_id = settlements.size()
	var road_mat = realm_material(Color("b5a17a"))
	var bridge_mat = realm_material(Color("746044"))
	for edge in road_edges:
		var a: Vector2 = settlements[edge[0]].at
		var b: Vector2 = settlements[edge[1]].at
		var side = Vector2(-(b.y-a.y),b.x-a.x).normalized()
		var segments = maxi(3,int(a.distance_to(b)/6))
		var previous = edge[0]
		var points: Array = [graph.get_point_position(previous)]
		for j in range(1,segments+1):
			var t = float(j)/segments
			var at = a.lerp(b,t)+side*sin(t*PI)*minf(7,a.distance_to(b)*.04)
			var p = terrain_point(at,.38)
			var id = edge[1] if j==segments else next_id
			if j!=segments:
				graph.add_point(id,p)
				next_id += 1
			graph.connect_points(previous,id)
			points.append(p)
			if absf(at.x-river_x(at.y))<3:
				var bridge = MarchArt.box(deco,p+Vector3(0,.7,0),Vector3(10,.8,5),bridge_mat)
				bridge.rotation.y = -atan2(b.y-a.y,b.x-a.x)
			previous = id
		ribbon(points,1.0,road_mat,deco)

func build_forests() -> void:
	var leaf_mat = realm_material(Color("465e43"))
	var trunks = MultiMesh.new()
	var leaves = MultiMesh.new()
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.height = 3.7
	trunk_mesh.bottom_radius = .4
	trunk_mesh.top_radius = .2
	trunk_mesh.radial_segments = 5
	trunk_mesh.rings = 1
	var leaf_mesh = SphereMesh.new()
	leaf_mesh.height = 6.4
	leaf_mesh.radius = 2.6
	leaf_mesh.radial_segments = 10
	leaf_mesh.rings = 5
	trunks.transform_format = MultiMesh.TRANSFORM_3D
	leaves.transform_format = MultiMesh.TRANSFORM_3D
	trunks.mesh = trunk_mesh
	leaves.mesh = leaf_mesh
	var positions: Array = []
	for i in range(11000):
		var at = Vector2(rng.randf_range(-WIDTH*.46,WIDTH*.46),rng.randf_range(-DEPTH*.46,DEPTH*.46))
		var h = elevation(at.x,at.y)
		if h<1 or h>42 or (at.x>150 and at.y>60) or absf(at.x-river_x(at.y))<9:
			continue
		if noise.get_noise_2d(at.x*.55+500,at.y*.55)<-.12:
			continue
		var point = Vector3(at.x,h,at.y)
		var close = graph.get_point_position(graph.get_closest_point(point))
		if Vector2(close.x,close.z).distance_to(at)<7:
			continue
		var clear = true
		for settlement in settlements:
			if at.distance_to(settlement.at)<15:
				clear = false
		if clear:
			positions.append(point)
	trunks.instance_count = positions.size()
	leaves.instance_count = positions.size()
	for i in range(positions.size()):
		var s = rng.randf_range(.75,1.5)
		var basis = Basis().scaled(Vector3(s,s,s))
		trunks.set_instance_transform(i,Transform3D(basis,positions[i]+Vector3(0,1.5*s,0)))
		leaves.set_instance_transform(i,Transform3D(basis,positions[i]+Vector3(0,5*s,0)))
	for data in [[trunks,realm_material(Color("5a503f"))],[leaves,leaf_mat]]:
		var instance = MultiMeshInstance3D.new()
		instance.multimesh = data[0]
		instance.material_override = data[1]
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)

func build_settlement(id: int) -> void:
	var s = settlements[id]
	var base = Node3D.new()
	deco.add_child(base)
	base.position = terrain_point(s.at,.4)
	var stone = realm_material(Color("b7ac91"))
	var timber = realm_material(Color("5b4b3c"))
	var plaster = realm_material(Color("c8b995"))
	var roof = realm_material(Color("6c594b") if s.faction!=3 else Color("9b7851"))
	var color = Color("e5bd75") if holdings.has(id) else COLORS[s.faction]
	var count = 12 if s.kind=="Town" else 3 if s.kind=="Castle" else 5
	for i in range(count):
		var angle = float(i)/count*TAU
		var radius = 7 if s.kind=="Town" else 4
		var at = Vector3(sin(angle)*radius,0,cos(angle)*radius)
		var h = 2.8+float(i%3)*.65
		MarchArt.box(base,at+Vector3(0,h/2,0),Vector3(2.8,h,3.3),plaster)
		MarchArt.roof(base,at+Vector3(0,h,0),3.3,3.9,1.6,roof)
		MarchArt.box(base,at+Vector3(0,h*.6,1.68),Vector3(.6,.9,.06),timber)
	if s.kind!="Village":
		var width = 21 if s.kind=="Town" else 13
		var tall = 9 if s.kind=="Castle" else 7
		for side in [-1,1]:
			MarchArt.box(base,Vector3(side*width/2,2.0,0),Vector3(1.5,4,width),stone)
			MarchArt.box(base,Vector3(0,2,-width/2),Vector3(width,4,1.5),stone)
			MarchArt.box(base,Vector3(side*(width/4+1.5),2,width/2),Vector3(width/2-3,4,1.5),stone)
			for end in [-1,1]:
				var at = Vector3(side*width/2,0,end*width/2)
				MarchArt.cylinder(base,at+Vector3(0,3.1,0),1.8,6.2,stone,1.7,8)
				for k in range(6):
					MarchArt.box(base,at+Vector3(sin(k*TAU/6)*1.5,6.5,cos(k*TAU/6)*1.5),Vector3(.75,1,.75),stone)
		MarchArt.box(base,Vector3(0,tall/2,-2),Vector3(4.5,tall,4.5),stone)
		MarchArt.roof(base,Vector3(0,tall,-2),5.3,5.3,2.5,roof)
	else:
		# Ploughed fields and hay plots make villages legible from the campaign camera.
		for field in range(3):
			var at = Vector3(9+field*3.5,.0,0)
			MarchArt.box(base,at,Vector3(3,.15,9),realm_material(Color("8d8450") if field%2==0 else Color("7d6947")))
			for row in range(4):
				MarchArt.box(base,at+Vector3(0,.16,-3+row*2),Vector3(3,.13,.16),timber)
	var flag = flag_mesh(color)
	add_child(flag)
	flag.position = base.position+Vector3(0,13 if s.kind=="Town" else 11 if s.kind=="Castle" else 7,0)
	MarchArt.batch_static(flag)
	s["flag"] = flag

func flag_mesh(color: Color) -> Node3D:
	var node = Node3D.new()
	MarchArt.cylinder(node,Vector3(0,-1,0),.16,7,realm_material(Color("564b3c")),.16,5)
	MarchArt.box(node,Vector3(1.6,1,0),Vector3(3.2,3.8,.12),realm_material(color))
	MarchArt.box(node,Vector3(1.6,1,-.1),Vector3(.22,2.4,.06),realm_material(Color("d9c398")))
	MarchArt.box(node,Vector3(1.6,1.4,-.12),Vector3(1.8,.22,.06),realm_material(Color("d9c398")))
	return node

func token(color: Color, captain: bool, wagon: bool = false) -> Node3D:
	var node = Node3D.new()
	var dark = realm_material(Color("594a3c"))
	var armor = realm_material(color)
	# Horse/rider silhouettes, with wagon bodies for commercial parties.
	MarchArt.box(node,Vector3(0,2.1,0),Vector3(1.8,1.6,3.4),dark)
	MarchArt.box(node,Vector3(0,3,-1.5),Vector3(.9,1.4,1.0),dark).rotation.x = -.25
	for side in [-1,1]:
		for end in [-1,1]:
			MarchArt.box(node,Vector3(side*.65,.9,end*1.05),Vector3(.35,1.8,.35),dark)
	MarchArt.cylinder(node,Vector3(0,3.6,0),.65,1.4,armor,.8,6)
	MarchArt.sphere(node,Vector3(0,4.6,0),Vector3(.55,.6,.55),realm_material(Color("adb4aa")))
	var flag = flag_mesh(color)
	node.add_child(flag)
	flag.position = Vector3(1,6,1)
	if wagon:
		MarchArt.box(node,Vector3(0,1.8,4),Vector3(3.2,1.8,3.5),realm_material(Color("a89b7a")))
		for side in [-1,1]:
			for end in [-1,1]:
				var wheel = MarchArt.cylinder(node,Vector3(side*1.6,1,end*1.3+4),.9,.3,dark,.9,8)
				wheel.rotation.z = PI/2
	var ring = TorusMesh.new()
	ring.inner_radius = 3.1 if captain else 2.1
	ring.outer_radius = 3.5 if captain else 2.3
	ring.rings = 20
	ring.ring_segments = 5
	MarchArt.mesh(node,ring,Vector3(0,.35,0),armor)
	return node

func show_map() -> void:
	game.field_environment.fog_enabled = false
	build()
	visible = true
	game.terrain.visible = false
	game.horse.visible = false
	for soldier in game.soldiers:
		soldier.visible = false
	game.map_open = true
	game.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	game.camera.far = 2600
	game.reset_controls()
	update_camera(1)

func hide_map() -> void:
	game.field_environment.fog_enabled = true
	visible = false
	game.terrain.visible = true
	game.horse.visible = true
	for soldier in game.soldiers:
		soldier.visible = true
	game.map_open = false
	speed = 0
	game.camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	game.camera.far = 210
	game.reset_controls()
	game.update_follow_camera(1.0,true)
	print("IRON_FIELD_ENTERED")

func update_camera(_delta: float) -> void:
	game.camera.size = zoom
	var focus = position+map_focus
	game.camera.position = focus+Vector3(0,620,490)
	game.camera.look_at(focus)

func pan(amount: Vector2) -> void:
	map_focus.x = clampf(map_focus.x-amount.x*zoom/720,-WIDTH*.45,WIDTH*.45)
	map_focus.z = clampf(map_focus.z-amount.y*zoom/520,-DEPTH*.45,DEPTH*.45)

func change_zoom(factor: float) -> void:
	zoom = clampf(zoom*factor,150,WIDTH*1.15)

func select_at(screen: Vector2) -> void:
	var best = -1
	var distance = 38.0
	for i in range(settlements.size()):
		var s = settlements[i]
		if game.camera.is_position_behind(position+terrain_point(s.at)):
			continue
		var p = game.camera.unproject_position(position+terrain_point(s.at,6))
		var d = p.distance_to(screen)
		if d<distance:
			distance = d
			best = i
	if best>=0:
		selected = best
		game.announce(settlements[best].name+" selected. Choose Travel to follow the roads.")

func travel_to(id: int) -> bool:
	if id<0 or id>=settlements.size() or pending!="":
		return false
	var start = graph.get_closest_point(party)
	var path = graph.get_point_path(start,id)
	route.clear()
	for p in path:
		route.append(p)
	destination = id
	speed = 1
	draw_route()
	game.save_progress()
	return true

func draw_route() -> void:
	if is_instance_valid(route_mesh):
		route_mesh.queue_free()
	if route.size()<1:
		return
	var points: Array = [party+Vector3(0,.65,0)]
	for p in route:
		points.append(p+Vector3(0,.65,0))
	route_mesh = ribbon(points,.72,realm_material(Color("e3c47e")),self)

func plan_npc(id: int) -> void:
	var npc = civilians[id]
	var target = (int(npc.goal)+5+id*2)%settlements.size()
	if npc.kind=="Raiders" or (npc.kind=="Patrol" and relations[npc.faction]<0):
		if npc.at.distance_to(party)<85:
			target = graph.get_closest_point(party)
	npc.goal = target
	npc.route = Array(graph.get_point_path(graph.get_closest_point(npc.at),target))

func update(delta: float) -> void:
	if not prepared or speed==0 or pending!="" or game.paused or game.state!="play":
		return
	var elapsed = delta*speed
	hours += elapsed*24.0/24.0
	while hours>=24:
		hours -= 24
		next_day()
	if route.size()>0:
		var old = party
		party = follow_path(party,route,elapsed*(15.0 if food>0 else 9.0)*life.travel_multiplier())
		travel_distance += old.distance_to(party)
		if old.distance_to(party)>.01:
			player_model.rotation.y = atan2(old.x-party.x,old.z-party.z)
		player_model.position = party
		if route.is_empty():
			selected = destination
			life.visit(selected)
			destination = -1
			speed = 0
			game.announce("Arrived at "+settlements[selected].name+". Time paused.")
			print("IRON_ARRIVED:"+settlements[selected].name)
			draw_route()
			game.save_progress()
	for i in range(civilians.size()):
		var npc = civilians[i]
		npc.node.visible = npc.active
		if not npc.active:
			continue
		if npc.route.is_empty():
			life.caravan_arrival(i,int(npc.goal))
			plan_npc(i)
		var old: Vector3 = npc.at
		npc.at = follow_path(npc.at,npc.route,elapsed*(7 if npc.kind in ["Caravan","Your caravan"] else 9))
		npc.node.position = npc.at
		if old.distance_to(npc.at)>.01:
			npc.node.rotation.y = atan2(old.x-npc.at.x,old.z-npc.at.z)
		if npc.at.distance_to(party)<10 and (npc.kind=="Raiders" or (npc.kind=="Patrol" and relations[npc.faction]<0)):
			pending = npc.kind+" intercept your company"
			encounter_npc = i
			speed = 0
			game.save_progress()
			break
	save_clock += delta
	if save_clock>4:
		save_clock = 0
		game.save_progress()

func follow_path(at: Vector3, path: Array, budget: float) -> Vector3:
	while not path.is_empty() and budget>0:
		var target: Vector3 = path[0]
		var distance = at.distance_to(target)
		if distance<=budget:
			at = target
			budget -= distance
			path.pop_front()
		else:
			at = at.move_toward(target,budget)
			budget = 0
	return at

func next_day() -> void:
	day += 1
	life.daily()
	food = maxi(0,food-maxi(1,maxi(2,int(game.living(0)/3))-(1 if life.has_role("Steward") else 0)))
	var wages = maxi(2,int(game.living(0)/2))
	game.gold = maxi(0,game.gold+holdings.size()*18-wages)
	if food==0 and game.living(0)>4:
		for unit in game.soldiers:
			if not unit.player and not unit.dead and unit.team==0:
				unit.damage(1000)
				break
		game.announce("Food exhausted: a soldier deserted. Buy provisions at a settlement.")
	for settlement in settlements:
		settlement.stock = mini(90,int(settlement.stock)+6)

func near_settlement(id: int) -> bool:
	return id>=0 and id<settlements.size() and Vector2(party.x,party.z).distance_to(settlements[id].at)<13

func buy_price(id: int) -> int:
	return 8+settlements[id].faction*2+maxi(0,50-int(settlements[id].stock))/8+(day+id)%3-(1 if life.origin=="Merchant" else 0)

func sell_price(id: int) -> int:
	return maxi(3,buy_price(id)-3)

func transact(action: String) -> bool:
	if not near_settlement(selected):
		game.announce("Travel to this settlement first.")
		return false
	var s = settlements[selected]
	if action=="quest":
		if quest>=0:
			game.announce("A Roadwarden contract is already active. Defeat a raider party.")
			return false
		var available = false
		for id in range(12,16):
			if not defeated.has(id):
				available = true
		if not available:
			game.announce("All known raiders are defeated. No new bounty is available.")
			return false
	var success = false
	if relations[s.faction]<0 and not holdings.has(selected) and action!="truce":
		game.announce("This faction is hostile. Pay a truce or choose another settlement.")
		return false
	match action:
		"food":
			if game.gold>=20 and food<=180:
				game.gold -= 20
				food += 20
				success = true
		"buy":
			if game.gold>=buy_price(selected) and grain<20 and s.stock>0:
				life.cargo_cost += buy_price(selected)
				game.gold -= buy_price(selected)
				grain += 1
				s.stock -= 1
				success = true
		"sell":
			if grain>0:
				var cost = life.cargo_cost/maxi(1,grain)
				if cost>0:
					life.trade_profit += maxi(0,int(sell_price(selected)-cost))
				life.cargo_cost = maxf(0,life.cargo_cost-cost)
				game.gold += sell_price(selected)
				grain -= 1
				s.stock += 1
				success = true
		"recruit":
			var before = game.gold
			game.reinforce()
			success = game.gold<before
		"quest":
			if quest<0:
				quest = selected
				success = true
		"truce":
			if game.gold>=100 and relations[s.faction]<0:
				game.gold -= 100
				relations[s.faction] = 0
				success = true
	if success:
		game.save_progress()
		game.announce("Roadwarden contract: defeat a raider party for 120 gold." if action=="quest" else "Transaction complete.")
	else:
		game.announce("Insufficient gold, stock, cargo, or company space.")
	return success

func launch_encounter(fief: int = -1) -> void:
	if fief>=0 and life.neutral:
		game.announce("Your neutral oath forbids attacking settlements. Take civilian contracts instead.")
		return
	if fief>=0:
		if not near_settlement(fief) or settlements[fief].kind!="Castle" or holdings.has(fief):
			return
		encounter_fief = fief
		pending = "Garrison challenge"
	elif encounter_npc<0:
		return
	checkpoint_army = game.living(0)
	return_to_map = true
	hide_map()
	game.begin_battle()
	game.announce("Garrison field battle — siege interiors are not implemented." if fief>=0 else "The road is blocked. Defeat the raiders!")

func avoid_encounter() -> void:
	if pending=="":
		return
	game.gold = maxi(0,game.gold-25)
	if encounter_npc>=0:
		var npc = civilians[encounter_npc]
		npc.at = graph.get_point_position((int(npc.goal)+10)%settlements.size())
		plan_npc(encounter_npc)
	pending = ""
	encounter_npc = -1
	game.save_progress()

func battle_result(won: bool) -> void:
	if not return_to_map:
		return
	if won:
		if encounter_npc>=0:
			if not defeated.has(encounter_npc):
				defeated.append(encounter_npc)
			civilians[encounter_npc].active = false
			if quest>=0 and civilians[encounter_npc].kind=="Raiders":
				game.gold += 120
				quest = -1
				quest_done += 1
				game.encounter_reward_note = "Roadwarden contract completed: +120 bonus gold."
		if encounter_fief>=0 and not holdings.has(encounter_fief):
			holdings.append(encounter_fief)
			game.encounter_reward_note = settlements[encounter_fief].name+" captured: +18 gold/day. Its former faction is hostile."
			relations[settlements[encounter_fief].faction] -= 20
			var flag = settlements[encounter_fief].get("flag")
			if flag!=null:
				flag.queue_free()
			var owned_flag = flag_mesh(Color("e5bd75"))
			add_child(owned_flag)
			owned_flag.position = terrain_point(settlements[encounter_fief].at,11)
			MarchArt.batch_static(owned_flag)
			settlements[encounter_fief].flag = owned_flag
	pending = ""
	encounter_npc = -1
	encounter_fief = -1
	speed = 0

func serialize() -> Dictionary:
	var stocks: Array = []
	for s in settlements:
		stocks.append(s.stock)
	return {"version":2,"life":life.serialize(),"x":party.x,"z":party.z,"day":day,"hours":hours,"food":food,"grain":grain,"holdings":holdings,"relations":relations,"stocks":stocks,"defeated":defeated,"quest":quest,"quest_done":quest_done,"distance":travel_distance,"army":checkpoint_army if game.fighting else game.living(0)}

func restore(data: Dictionary) -> void:
	var x = float(data.get("x",-165))
	var z = float(data.get("z",130))
	if not is_finite(x) or not is_finite(z):
		return
	party = terrain_point(Vector2(clampf(x,-WIDTH*.45,WIDTH*.45),clampf(z,-DEPTH*.45,DEPTH*.45)))
	day = clampi(int(data.get("day",1)),1,100000)
	hours = clampf(float(data.get("hours",0)),0,23.999)
	food = clampi(int(data.get("food",35)),0,200)
	grain = clampi(int(data.get("grain",0)),0,20)
	quest = clampi(int(data.get("quest",-1)),-1,settlements.size()-1)
	quest_done = clampi(int(data.get("quest_done",0)),0,100000)
	travel_distance = maxf(0,float(data.get("distance",0)))
	for id in data.get("holdings",[]):
		if id is float or id is int:
			if int(id)>=0 and int(id)<settlements.size() and settlements[int(id)].kind=="Castle" and not holdings.has(int(id)):
				holdings.append(int(id))
	for id in data.get("defeated",[]):
		if int(id)>=0 and int(id)<16 and not defeated.has(int(id)):
			defeated.append(int(id))
	var saved_relations = data.get("relations",[])
	if saved_relations is Array and not saved_relations.is_empty():
		for i in range(mini(saved_relations.size(),relations.size())):
			relations[i] = clampi(int(saved_relations[i]),-100,100)
	var stocks = data.get("stocks",[])
	if stocks is Array and not stocks.is_empty():
		for i in range(mini(stocks.size(),settlements.size())):
			settlements[i].stock = clampi(int(stocks[i]),0,110)

	if data.get("life",{}) is Dictionary:
		life.restore(data.get("life",{}))
	if not data.is_empty() and not data.has("life"):
		life.origin = "Veteran"
		life.neutral = false

func realm_material(color: Color) -> StandardMaterial3D:
	var key = color.to_html()
	if not palette.has(key):
		palette[key] = MarchArt.material(color)
	return palette[key]
