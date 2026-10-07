extends Node3D

var hero: MarchKnight
var soldiers: Array[MarchKnight] = []
var camera: Camera3D
var hud: Control
var state = "title"
var order = "FOLLOW"
var fighting = false
var paused = false
var map_open = false
var gold = 120
var victories = 0
var stamina = 100.0
var yaw = .12
var pitch = .20
var stick = Vector2.ZERO
var attacking = false
var blocking = false
var dash_time = 0.0
var hold_point = Vector3.ZERO
var clock = 0.0
var toast = ""
var toast_time = 0.0
var result_time = 0.0
var impact_nodes: Array = []
var capture_frame = 0
var capture_mode = false
var smoke_mode = false
var terrain: MarchWorld

func _ready() -> void:
	capture_mode = "--capture" in OS.get_cmdline_user_args()
	smoke_mode = "--smoke" in OS.get_cmdline_user_args()
	load_progress()
	build_lighting()
	terrain = MarchWorld.new()
	add_child(terrain)
	terrain.build()
	hero = spawn_knight(Vector3(0,0,10),0,true)
	for i in range(8):
		spawn_knight(Vector3(-4.5+(i%4)*3.0,0,5-(i/4)*2.3),0,false)
	hold_point = Vector3(0,0,4)
	camera = Camera3D.new()
	camera.fov = 62
	camera.near = .12
	camera.far = 210
	camera.current = true
	add_child(camera)
	camera.position = Vector3(-4.5,3.5,18)
	camera.look_at(Vector3(-3,1.4,0))
	var layer = CanvasLayer.new()
	add_child(layer)
	hud = load("res://scripts/hud.gd").new()
	hud.game = self
	layer.add_child(hud)
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false
	if smoke_mode:
		call_deferred("run_smoke")

func build_lighting() -> void:
	var world_environment = WorldEnvironment.new()
	var env = Environment.new()
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("61939f")
	sky_material.sky_horizon_color = Color("e9dabb")
	sky_material.ground_bottom_color = Color("779078")
	sky_material.ground_horizon_color = Color("e9dabb")
	sky_material.sky_curve = .21
	sky_material.sun_angle_max = 5
	sky.sky_material = sky_material
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c4d6d5")
	env.ambient_light_energy = .65
	env.reflected_light_source = Environment.REFLECTED_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.12
	world_environment.environment = env
	add_child(world_environment)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46,-34,0)
	sun.light_color = Color("ffe4af")
	sun.light_energy = 1.45
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.shadow_bias = .035
	add_child(sun)

func spawn_knight(at: Vector3, team: int, is_player: bool) -> MarchKnight:
	var soldier = MarchKnight.new()
	add_child(soldier)
	soldier.position = at
	soldier.setup(team,is_player)
	soldiers.append(soldier)
	return soldier

func enter_world() -> void:
	state = "play"
	reset_controls()
	announce("Welcome to Hearthglen. Explore, or begin a skirmish.")

func begin_battle() -> void:
	if fighting:
		return
	map_open = false
	state = "play"
	paused = false
	clear_enemies()
	hero.hp = hero.maximum_hp
	hero.dead = false
	hero.fall = 0
	hero.visual.rotation = Vector3.ZERO
	hero.visual.position = Vector3.ZERO
	hero.ring.visible = true
	hero.position = Vector3(0,0,10)
	stamina = 100
	var count = mini(8+victories*2,16)
	for i in range(count):
		var knight = spawn_knight(Vector3(-5+(i%4)*3.1,0,-9-(i/4)*2.4),1,false)
		knight.rotation.y = PI
	fighting = true
	order = "HOLD"
	hold_point = Vector3(0,0,4)
	announce("Raiders on the road! Defend Hearthglen.")
	reset_controls()

func clear_enemies() -> void:
	for i in range(soldiers.size()-1,-1,-1):
		if soldiers[i].team==1 or (soldiers[i].dead and not soldiers[i].player):
			soldiers[i].queue_free()
			soldiers.remove_at(i)
	for soldier in soldiers:
		soldier.target = null

func reinforce() -> void:
	if fighting:
		announce("Reinforcements are available between battles.")
		return
	if gold<30:
		announce("Need 30 gold. Victories award 80 gold.")
		return
	if living(0)>=12:
		announce("Your company is at full strength.")
		return
	gold -= 30
	var amount = mini(3,12-living(0))
	for i in range(amount):
		spawn_knight(hero.position+Vector3(-3+i*2,0,-3),0,false)
	save_progress()
	announce("Reinforcements have joined your banner.")

func living(team: int) -> int:
	var amount = 0
	for soldier in soldiers:
		if not soldier.dead and not soldier.player and soldier.team==team:
			amount += 1
	return amount

func reset_controls() -> void:
	stick = Vector2.ZERO
	attacking = false
	blocking = false
	if hud != null:
		hud.reset_touches()

func set_order(new_order: String) -> void:
	order = new_order
	if order=="HOLD" or order=="WALL":
		hold_point = hero.position + Vector3(0,0,-2)
	announce("Company: "+new_order.to_lower()+"!")

func dash() -> void:
	if stamina>=28 and dash_time<=0 and not hero.dead:
		stamina -= 28
		dash_time = .20

func attack() -> void:
	if hero.dead or hero.cooldown>0 or stamina<12 or hero.block:
		return
	stamina -= 12
	hero.swing = .48
	hero.cooldown = .57
	var target = nearest_enemy(hero)
	if target != null and hero.position.distance_to(target.position)<2.65:
		var direction = target.position-hero.position
		hero.rotation.y = atan2(-direction.x,-direction.z)
		target.damage(38)
		impact(target.position+Vector3(0,1.3,0))

func nearest_enemy(unit: MarchKnight) -> MarchKnight:
	var best: MarchKnight = null
	var best_distance = INF
	for other in soldiers:
		if other.team==unit.team or other.dead:
			continue
		var distance = unit.position.distance_squared_to(other.position)
		if distance<best_distance:
			best = other
			best_distance = distance
	return best

func impact(at: Vector3) -> void:
	var mat = MarchArt.material(Color("ffdd8e"))
	mat.emission_enabled = true
	mat.emission = Color("ffc971")
	for i in range(4):
		var particle = MarchArt.sphere(self,at+Vector3(sin(i*2)*.2,i*.06,cos(i*2)*.2),Vector3(.045,.12,.045),mat)
		impact_nodes.append({"node":particle,"life":.16,"direction":Vector3(sin(i*2),.7,cos(i*2))})

func _physics_process(delta: float) -> void:
	clock += delta
	toast_time = maxf(0,toast_time-delta)
	if hud != null:
		hud.queue_redraw()
	if state=="title":
		for knight in soldiers:
			knight.animate(delta)
		return
	if paused or map_open or state!="play":
		return
	stamina = minf(100,stamina+delta*(7 if blocking else 21))
	dash_time = maxf(0,dash_time-delta)
	var input_vector = stick
	input_vector.x += float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
	input_vector.y += float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))
	input_vector = input_vector.limit_length()
	var forward = Vector3(-sin(yaw),0,-cos(yaw))
	var right = Vector3(cos(yaw),0,-sin(yaw))
	var movement = right*input_vector.x-forward*input_vector.y
	hero.block = (blocking or Input.is_physical_key_pressed(KEY_Q)) and stamina>0
	if hero.block:
		stamina = maxf(0,stamina-delta*10)
	if not hero.dead:
		var speed = 13.0 if dash_time>0 else (2.3 if hero.block else 5.0)
		hero.velocity.x = movement.x*speed
		hero.velocity.z = movement.z*speed
		hero.velocity.y -= 24*delta
		if movement.length()>.1:
			hero.rotation.y = lerp_angle(hero.rotation.y,atan2(-movement.x,-movement.z),delta*12)
		hero.move_and_slide()
		hero.position.x = clampf(hero.position.x,-26,24)
		hero.position.z = clampf(hero.position.z,-36,24)
		hero.speed = movement.length()*speed
		if attacking or Input.is_physical_key_pressed(KEY_SPACE):
			attack()
	var slot = 0
	for knight in soldiers:
		knight.animate(delta)
		if knight.player or knight.dead:
			continue
		update_ai(knight,slot,delta)
		if knight.team==0:
			slot += 1
	for i in range(impact_nodes.size()-1,-1,-1):
		impact_nodes[i].life -= delta
		impact_nodes[i].node.position += impact_nodes[i].direction*delta*2
		if impact_nodes[i].life<=0:
			impact_nodes[i].node.queue_free()
			impact_nodes.remove_at(i)
	if fighting:
		if hero.dead:
			finish_battle(false)
		elif living(1)==0:
			finish_battle(true)

func update_ai(knight: MarchKnight, slot: int, delta: float) -> void:
	knight.think -= delta
	if knight.think<=0 or not is_instance_valid(knight.target) or knight.target.dead:
		knight.target = nearest_enemy(knight) if fighting else null
		knight.think = .25
	var target_point = knight.position
	var target = knight.target
	var distance = 100.0
	knight.block = knight.team==0 and order=="WALL"
	if target != null:
		distance = knight.position.distance_to(target.position)
		if knight.team==1 or order=="CHARGE" or distance<3:
			target_point = target.position
	if knight.team==0 and (target==null or (order!="CHARGE" and distance>=3)):
		var anchor = hero.position if order=="FOLLOW" else hold_point
		target_point = anchor+Vector3(-3.0+(slot%4)*2.0,0,2.7+(slot/4)*1.9)
	var movement = target_point-knight.position
	movement.y = 0
	if target!=null and distance<1.9:
		movement = Vector3.ZERO
		var direction = target.position-knight.position
		knight.rotation.y = lerp_angle(knight.rotation.y,atan2(-direction.x,-direction.z),delta*10)
		if knight.cooldown<=0:
			knight.cooldown = .95+float(slot%3)*.1
			knight.swing = .48
			target.damage(12 if target.player else 17)
			if target.player:
				impact(target.position+Vector3(0,1.2,0))
	elif movement.length()>.7:
		movement = movement.normalized()
		knight.rotation.y = lerp_angle(knight.rotation.y,atan2(-movement.x,-movement.z),delta*7)
	else:
		movement = Vector3.ZERO
	# Local avoidance keeps readable spacing without expensive per-agent path searches.
	var separation = Vector3.ZERO
	for other in soldiers:
		if other==knight or other.dead:
			continue
		var difference = knight.position-other.position
		difference.y = 0
		var length = difference.length()
		if length<.80 and length>.01:
			separation += difference/length*(.8-length)*3
	var speed = 2.0 if knight.block else 3.0
	knight.velocity.x = movement.x*speed+separation.x
	knight.velocity.z = movement.z*speed+separation.z
	knight.velocity.y -= 24*delta
	knight.move_and_slide()
	knight.speed = Vector2(knight.velocity.x,knight.velocity.z).length()

func _process(delta: float) -> void:
	if camera==null:
		return
	if map_open:
		camera.position = camera.position.lerp(Vector3(34,45,37),minf(1,delta*4))
		camera.look_at(Vector3(0,0,-8))
	elif state!="title":
		var focus = hero.position+Vector3(0,1.3,0)
		var offset = Vector3(sin(yaw)*7.0,3.3+pitch*4,cos(yaw)*7.0)
		camera.position = camera.position.lerp(focus+offset,minf(1,delta*10))
		camera.look_at(focus)
	if capture_mode:
		capture_frame += 1
		if capture_frame==90:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/iron-title.png")
			enter_world()
			begin_battle()
			fighting = false
		if capture_frame==180:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/iron-field.png")
			map_open = true
		if capture_frame==270:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/iron-map.png")
			get_tree().quit()

func finish_battle(won: bool) -> void:
	if not fighting:
		return
	fighting = false
	state = "victory" if won else "defeat"
	reset_controls()
	if won:
		gold += 80
		victories += 1
	else:
		gold = maxi(30,gold-20)
	save_progress()

func return_to_camp() -> void:
	clear_enemies()
	state = "play"
	hero.dead = false
	hero.hp = hero.maximum_hp
	hero.collision_layer = 2
	hero.visual.rotation = Vector3.ZERO
	hero.visual.position = Vector3.ZERO
	hero.ring.visible = true
	hero.position = Vector3(0,0,10)
	hero.speed = 0
	stamina = 100
	order = "FOLLOW"
	while living(0)<4:
		spawn_knight(hero.position+Vector3(-3+living(0)*1.5,0,-3),0,false)
	for knight in soldiers:
		knight.hp = knight.maximum_hp
	announce("Company rested. Explore Hearthglen or prepare another skirmish.")

func announce(message: String) -> void:
	toast = message
	toast_time = 4

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:
			back()
		if state!="play" or paused:
			return
		match event.keycode:
			KEY_1: set_order("FOLLOW")
			KEY_2: set_order("HOLD")
			KEY_3: set_order("CHARGE")
			KEY_4: set_order("WALL")
			KEY_SHIFT: dash()
			KEY_M:
				map_open = not map_open
				reset_controls()
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and state=="play" and not paused and not map_open:
		look(event.relative)
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and state=="play" and not paused and not map_open:
		attacking = event.pressed

func look(amount: Vector2) -> void:
	yaw -= amount.x*.006
	pitch = clampf(pitch+amount.y*.004,-.2,.8)

func back() -> void:
	reset_controls()
	if hud.help_open:
		hud.help_open = false
	elif map_open:
		map_open = false
	elif state=="play":
		paused = not paused

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		if state=="play":
			paused = true
		reset_controls()
		save_progress()
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST:
		back()
	elif what==NOTIFICATION_WM_CLOSE_REQUEST:
		save_progress()
		get_tree().quit()

func save_progress() -> void:
	if capture_mode or smoke_mode:
		return
	var file = FileAccess.open("user://progress.tmp",FileAccess.WRITE)
	if file==null:
		announce("Progress could not be saved. Check free storage.")
		return
	file.store_string(JSON.stringify({"version":1,"gold":gold,"victories":victories}))
	file.flush()
	file.close()
	var error = DirAccess.rename_absolute("user://progress.tmp","user://progress.json")
	if error!=OK:
		announce("Progress save failed. Check free storage.")

func load_progress() -> void:
	if capture_mode or smoke_mode:
		return
	if not FileAccess.file_exists("user://progress.json"):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string("user://progress.json"))
	if data is Dictionary and data.get("version",0)==1:
		gold = clampi(int(data.get("gold",120)),0,1000000)
		victories = clampi(int(data.get("victories",0)),0,100000)

func run_smoke() -> void:
	assert(hero!=null and soldiers.size()==9,"Character scene initialization failed")
	assert(hero.right_arm!=null and hero.left_leg!=null,"Articulated character parts missing")
	enter_world()
	begin_battle()
	assert(living(1)==8,"Encounter spawn count incorrect")
	var enemy = nearest_enemy(hero)
	enemy.position = hero.position+Vector3(0,0,-1.2)
	var before = enemy.hp
	attack()
	assert(enemy.hp<before,"Player melee did not damage target")
	set_order("WALL")
	assert(order=="WALL","Formation order failed")
	for soldier in soldiers:
		if soldier.team==1:
			soldier.damage(1000)
	finish_battle(true)
	assert(victories==1 and gold==200,"Victory transaction failed")
	finish_battle(true)
	assert(gold==200,"Victory must not award twice")
	return_to_camp()
	assert(not hero.dead and state=="play","Return-to-camp failed")
	print("IRON_SMOKE_PASS: characters, spawn, melee, formation, victory idempotency, camp recovery")
	get_tree().quit()
