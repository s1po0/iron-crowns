class_name CrownTown
extends Node3D
var camera: Camera3D
var people: Array=[]
var hero: CastleActor
var hero_position=Vector2(0,4)
var path: Array=[]
var navigation=AStarGrid2D.new()
var clock=0.0
var followers: Array=[]
func setup(sim: CrownSim) -> void:
	var env=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("829a9b")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("c8d0c7")
	env.environment.ambient_light_energy=.7
	add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-35,0);sun.light_energy=1.2;add_child(sun)
	camera=Camera3D.new();camera.position=Vector3(22,24,27);camera.fov=48;add_child(camera);camera.look_at(Vector3(9,0,0));camera.current=true
	MarchArt.box(self,Vector3(0,-.12,0),Vector3(64,.2,64),FieldMaterials.surface("earth",Color("858a65"),12))
	MarchArt.box(self,Vector3(0,.005,0),Vector3(10,.04,52),FieldMaterials.surface("masonry",Color("a99a7c"),8))
	var helper=CastleWorld.new();helper.models=ContentAssets.json("res://assets/content/rts/models.json")
	navigation.region=Rect2i(0,0,60,60);navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER;navigation.update()
	var town=sim.world.settlements[sim.state.location]
	var number=clampi(int(sim.state.houses[sim.state.location]),8,24)
	for i in number:
		var p=Vector3([-26,-18,-10,10,18,26][i%6],0,[-22,-10,10,22][int(i/6)])
		var house=helper.model("house_long" if i%5==0 else "house_small")
		house.position=p;house.rotation.y=PI*.5 if p.x<0 else -PI*.5;add_child(house)
		block(p,3)
	if town.kind=="castle":
		var keep=helper.building({"kind":"keep","x":19,"y":14,"id":0,"built":1.0,"hp":600})
		add_child(keep);block(Vector3(0,0,-15),5)
	helper.free()
	for i in 10:
		var actor=CastleActor.new();add_child(actor)
		actor.setup("worker" if i<6 else "soldier",i,"" if i<6 else "#"+sim.world.factions[sim.owner()].color)
		var center=Vector2(-6+(i%5)*3,-4+int(i/5)*8)
		people.append({"actor":actor,"center":center,"index":i})
		var label=Label3D.new();label.text=town.people[i%6].name if i<6 else sim.world.factions[sim.owner()].name+" · پاسەوان"
		label.font=load("res://assets/fonts/vazirmatn.ttf");label.font_size=30;label.pixel_size=.025;label.visible=i<4;label.position.y=2.5;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;actor.add_child(label)
	hero=CastleActor.new();add_child(hero);hero.setup("soldier" if sim.rank()>=2 else "worker",23,"#"+sim.world.factions[sim.state.oath].color if sim.state.oath>=0 else "")
	var badge=Label3D.new();badge.text=sim.state.name+" · "+CrownSim.RANKS[sim.rank()];badge.position.y=2.8;badge.font=load("res://assets/fonts/vazirmatn.ttf");badge.font_size=38;badge.pixel_size=.016;badge.modulate=Color("f0d98e");badge.billboard=BaseMaterial3D.BILLBOARD_ENABLED;hero.add_child(badge)
	for i in mini(6,sim.count()):
		var follower=CastleActor.new();add_child(follower);follower.setup("soldier",i+30,"#"+sim.world.factions[sim.state.oath].color if sim.state.oath>=0 else "#b79a62")
		followers.append({"actor":follower,"at":Vector2((i%3-1)*2,7+int(i/3)*2),"index":i,"route":[],"goal":Vector2i(-1,-1)})
func block(p: Vector3,radius: int) -> void:
	for y in range(roundi(p.z)+30-radius,roundi(p.z)+31+radius):
		for x in range(roundi(p.x)+30-radius,roundi(p.x)+31+radius):
			if navigation.is_in_bounds(x,y):navigation.set_point_solid(Vector2i(x,y))
func walk(screen: Vector2) -> void:
	var hit=Plane(Vector3.UP,0).intersects_ray(camera.project_ray_origin(screen),camera.project_ray_normal(screen))
	if hit==null:return
	var goal=Vector2i(roundi(hit.x)+30,roundi(hit.z)+30)
	if not navigation.is_in_boundsv(goal) or navigation.is_point_solid(goal):return
	path=navigation.get_id_path(Vector2i(hero_position.round())+Vector2i(30,30),goal)
func unit(p: Vector2,facing: float,walking: bool) -> Dictionary:
	return {"at":Vector2(20,20)+p/3,"facing":facing,"walking":walking,"hp":100,"carry":"","attack":0,"wait":0}
func _process(dt: float) -> void:
	clock+=dt
	for person in people:
		var p: Vector2=person.center+Vector2(sin(clock*.35+person.index)*1.2,cos(clock*.35+person.index)*1.2)
		person.actor.update(unit(p,atan2(-cos(clock*.35+person.index),sin(clock*.35+person.index)),true),dt)
	if hero!=null:
		var facing=hero.rotation.y
		if not path.is_empty():
			var goal=Vector2(path[0])-Vector2(30,30)
			var delta=goal-hero_position
			facing=atan2(-delta.x,-delta.y)
			hero_position=hero_position.move_toward(goal,dt*2.3)
			if hero_position.distance_to(goal)<.05:path.pop_front()
		hero.update(unit(hero_position,facing,not path.is_empty()),dt)

	for follower in followers:
		var offset=Vector2((follower.index%3-1)*2,3+int(follower.index/3)*2)
		var goal=Vector2i((hero_position+offset).round())+Vector2i(30,30)
		if not navigation.is_in_boundsv(goal) or navigation.is_point_solid(goal):goal=Vector2i(hero_position.round())+Vector2i(30,30)
		if goal!=follower.goal:
			follower.goal=goal
			follower.route=navigation.get_id_path(Vector2i(follower.at.round())+Vector2i(30,30),goal)
		var facing: float=follower.actor.rotation.y
		if not follower.route.is_empty():
			var target=Vector2(follower.route[0])-Vector2(30,30)
			var delta: Vector2=target-follower.at
			facing=atan2(-delta.x,-delta.y)
			follower.at=follower.at.move_toward(target,dt*2.3)
			if follower.at.distance_to(target)<.05:follower.route.pop_front()
		follower.actor.update(unit(follower.at,facing,not follower.route.is_empty()),dt)
