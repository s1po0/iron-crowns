extends Node3D

var horse: MarchHorse
var mounted = false
var cut_side = 1
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
var ready_frames = 0
var capture_mode = false
var smoke_mode = false
var terrain: MarchWorld
var realm: CrownRealm
var saved_realm: Dictionary = {}
var restored_army = 8
var realm_ready_frames = 0
var encounter_reward_note = ""
var audio: CombatAudio
var sun: DirectionalLight3D
var field_environment: Environment
var high_detail = false
var sound_enabled = true
var footstep_clock = 0.0
var camera_shake = 0.0
var evade_direction = Vector3.ZERO
var combat_notice = ""
var combat_notice_time = 0.0
var field_ready_frames = 0

func _ready() -> void:
	capture_mode = "--capture" in OS.get_cmdline_user_args()
	smoke_mode = "--smoke" in OS.get_cmdline_user_args()
	load_progress()
	load_settings()
	audio = CombatAudio.new()
	add_child(audio)
	audio.enabled = sound_enabled
	build_lighting()
	terrain = MarchWorld.new()
	add_child(terrain)
	terrain.build()
	apply_quality()
	hero = spawn_knight(Vector3(0,0,10),0,true)
	hero.rotation.y = PI+.2
	horse = MarchHorse.new()
	add_child(horse)
	horse.position = Vector3(3,1,11)
	for i in range(restored_army):
		spawn_knight(Vector3(-4.5+(i%4)*3.0,0,5-(i/4)*2.3),0,false)
	hold_point = Vector3(0,0,4)
	realm = CrownRealm.new()
	add_child(realm)
	realm.initialize(self)
	realm.restore(saved_realm)
	realm.visible = false
	camera = Camera3D.new()
	camera.fov = 55
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
	field_environment = env
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("70868d")
	sky_material.sky_horizon_color = Color("afb4ac")
	sky_material.ground_bottom_color = Color("676e63")
	sky_material.ground_horizon_color = Color("afb4ac")
	sky_material.sky_curve = .21
	sky_material.sun_angle_max = 5
	sky.sky_material = sky_material
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c4d6d5")
	env.ambient_light_energy = .48
	env.fog_enabled = true
	env.fog_light_color = Color("8d9b98")
	env.fog_density = .0018
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = .95
	# Soft sky-side fill keeps imported facial relief visible in the sun's shadow.
	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20,150,0)
	fill.light_color = Color("d6e1e5")
	fill.light_energy = .32
	fill.shadow_enabled = false
	add_child(fill)
	world_environment.environment = env
	add_child(world_environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-37,-28,0)
	sun.light_color = Color("eeede1")
	sun.light_energy = .9
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
	if realm.life.origin=="":
		state = "origin"
		return
	hero.rotation.y = 0
	state = "play"
	reset_controls()
	realm.show_map()
	realm.selected = -1
	for id in range(realm.settlements.size()):
		if realm.near_settlement(id):
			realm.selected = id
			realm.life.visit(id)
			break
	paused = false
	realm.hide_map()
	announce("You are on the western road. Walk, practice combat, or open REALM to travel.")

func begin_battle() -> void:
	if fighting:
		return
	reset_mount()
	if realm!=null and map_open:
		realm.hide_map()
	map_open = false
	state = "play"
	paused = false
	clear_enemies()
	realm.checkpoint_army = living(0)
	hero.hp = hero.maximum_hp
	hero.collision_layer = 2
	hero.strike_clock = -1
	hero.swing = 0
	hero.stagger = 0
	hero.dead = false
	hero.fall = 0
	hero.visual.rotation = Vector3.ZERO
	hero.visual.position = Vector3.ZERO
	hero.ring.visible = false
	hero.position = Vector3(0,0,10)
	stamina = 100
	encounter_reward_note = ""
	var count = mini(8+victories*2,16)
	if realm.return_to_map:
		count = realm.settlements[realm.encounter_fief].garrison if realm.encounter_fief>=0 else realm.civilians[realm.encounter_npc].men
	for i in range(count):
		var knight = spawn_knight(Vector3(-5+(i%4)*3.1,0,-9-(i/4)*2.4),1,false)
		knight.rotation.y = PI
	fighting = true
	order = "HOLD"
	hold_point = Vector3(0,0,4)
	update_follow_camera(1.0,true)
	announce("Raiders on the road. Watch their windup; block or step out of reach.")
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
		hold_point = hero.position + Vector3(-sin(yaw),0,-cos(yaw))*7.0
	announce("Company: "+new_order.to_lower()+"!")

func dash() -> void:
	if mounted:
		horse.pace = (horse.pace+1)%3
		print("IRON_GAIT:",horse.pace)
		return
	if stamina>=28 and dash_time<=0 and not hero.dead and not map_open and not paused:
		stamina -= 28
		dash_time = .23
		var input = stick+Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		var forward = Vector3(-sin(yaw),0,-cos(yaw))
		var right = Vector3(cos(yaw),0,-sin(yaw))
		evade_direction = (right*input.x-forward*input.y).normalized() if input.length()>.1 else -forward

func attack() -> void:
	if hero.dead or hero.cooldown>0 or stamina<12 or hero.block or hero.stagger>0 or paused or map_open:
		return
	stamina -= 12
	if not mounted:
		hero.rotation.y = yaw
	hero.cut_side = cut_side
	start_strike(hero)
	audio.play_effect("swing",.7)

func start_strike(unit: MarchKnight) -> void:
	unit.swing = .64
	unit.cooldown = .85 if unit.player else 1.1
	unit.strike_clock = .23 if unit.player else .34

func tick_strike(unit: MarchKnight, delta: float) -> void:
	if unit.dead or unit.stagger>0:
		unit.strike_clock = -1
		return
	if unit.strike_clock<0:
		return
	unit.strike_clock -= delta
	if unit.strike_clock>0:
		return
	unit.strike_clock = -1
	if unit==hero and mounted:
		mounted_strike()
		return
	var victim = nearest_enemy(unit)
	if victim==null or unit.position.distance_to(victim.position)>2.05:
		return
	var direction = victim.position-unit.position
	direction.y = 0
	if (-unit.basis.z).dot(direction.normalized())<.35:
		return
	var query = PhysicsRayQueryParameters3D.create(unit.position+Vector3.UP*1.2,victim.position+Vector3.UP*1.2,1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return
	var guarded = victim.guarding_from(unit.position)
	var parried = guarded and victim.player and victim.guard_time>0
	if victim==hero and mounted and unit.get_index()%2==0:
		horse.hp = maxf(0,horse.hp-18)
		if horse.hp<=0:
			mounted = false
			hero.riding = false
			hero.collision_layer = 2
			hero.stagger = .8
			announce("Your horse is wounded. Continue on foot until the company rests.")
	else:
		victim.damage(38 if unit.player else 12 if victim.player else 17,unit.position)
	if guarded:
		unit.stagger = .42 if parried else .16
		if victim.player:
			stamina = maxf(0,stamina-(0 if parried else 16))
			if stamina<=0:
				victim.block = false
				victim.stagger = .55
	if unit.player or victim.player:
		camera_shake = .035 if guarded else .065
		combat_notice = "PARRY" if parried else "GUARD BROKEN" if guarded and victim.player and stamina<=0 else "BLOCKED" if guarded else "HIT" if unit.player else "WOUNDED"
		combat_notice_time = .55
	if unit.position.distance_to(hero.position)<12:
		audio.play_effect("clang" if guarded else "impact",1.0 if unit.player or victim.player else .35)
	if guarded:
		impact(victim.position+Vector3(0,1.3,0))

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
		var particle = MarchArt.sphere(self,at+Vector3(sin(i*2)*.2,i*.06,cos(i*2)*.2),Vector3(.018,.05,.018),mat)
		impact_nodes.append({"node":particle,"life":.10,"direction":Vector3(sin(i*2),.7,cos(i*2))})

func _physics_process(delta: float) -> void:
	clock += delta
	toast_time = maxf(0,toast_time-delta)
	combat_notice_time = maxf(0,combat_notice_time-delta)
	if audio!=null:
		audio.ambience(state=="play" and not paused and not map_open)
	if hud != null:
		hud.queue_redraw()
	if state=="title":
		for knight in soldiers:
			knight.animate(delta)
		return
	if map_open:
		realm.update(delta)
		return
	if paused or state!="play":
		return
	stamina = minf(100,stamina+delta*(0 if hero.swing>0 or dash_time>0 else 7 if blocking else 18))
	dash_time = maxf(0,dash_time-delta)
	var input_vector = stick
	input_vector.x += float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
	input_vector.y += float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))
	input_vector = input_vector.limit_length()
	var forward = Vector3(-sin(yaw),0,-cos(yaw))
	var right = Vector3(cos(yaw),0,-sin(yaw))
	var movement = right*input_vector.x-forward*input_vector.y
	var was_blocking = hero.block
	hero.block = (blocking or Input.is_physical_key_pressed(KEY_Q)) and stamina>0 and hero.swing<=0 and hero.stagger<=0
	if hero.block and not was_blocking:
		hero.guard_time = .18
	if hero.block:
		stamina = maxf(0,stamina-delta*10)
	if not hero.dead and not mounted:
		var speed = (2.0 if hero.block else 4.3)*(0.25 if hero.stagger>0 else .55 if hero.swing>0 else 1.0)
		if dash_time>0:
			movement = evade_direction
			speed = 8.5
		hero.velocity.x = movement.x*speed
		hero.velocity.z = movement.z*speed
		hero.velocity.y -= 24*delta
		if movement.length()>.1 and hero.swing<=0 and not hero.block and dash_time<=0:
			hero.rotation.y = lerp_angle(hero.rotation.y,atan2(-movement.x,-movement.z),delta*12)
		hero.move_and_slide()
		hero.position.x = clampf(hero.position.x,-26,24)
		hero.position.z = clampf(hero.position.z,-36,24)
		if hero.block:
			hero.rotation.y = lerp_angle(hero.rotation.y,yaw,delta*12)
		hero.speed = movement.length()*speed
		footstep_clock += delta*hero.speed
		if footstep_clock>1.9 and hero.is_on_floor():
			footstep_clock = 0
			audio.play_effect("step",.55)
		if attacking or Input.is_physical_key_pressed(KEY_SPACE):
			attack()
	horse.drive(input_vector,delta,mounted and not hero.dead)
	if mounted:
		hero.position = horse.position+Vector3(0,.82,0)
		hero.rotation.y = horse.rotation.y
		hero.speed = absf(horse.speed)
		hero.velocity = horse.velocity
		if attacking or Input.is_physical_key_pressed(KEY_SPACE):
			attack()
	var slot = 0
	for knight in soldiers:
		tick_strike(knight,delta)
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

func escort_slot(slot: int) -> Vector3:
	# Keep a clear corridor between the shoulder camera and its hero. A trailing
	# central formation previously put allies directly in front of the lens.
	var right = Vector3(cos(yaw),0,-sin(yaw))
	var forward = Vector3(-sin(yaw),0,-cos(yaw))
	var side = -1 if slot%2==0 else 1
	return hero.position+right*side*(3.8+int(slot/4)*.7)+forward*(1.0-int(slot/2)*1.8)

func update_ai(knight: MarchKnight, slot: int, delta: float) -> void:
	knight.think -= delta
	if knight.think<=0 or not is_instance_valid(knight.target) or knight.target.dead:
		knight.target = nearest_enemy(knight) if fighting else null
		knight.think = .25
	var target_point = knight.position
	var target = knight.target
	var distance = 100.0
	knight.block = knight.team==0 and order=="WALL" and knight.swing<=0
	if target != null:
		distance = knight.position.distance_to(target.position)
		if knight.team==1 and knight.swing<=0 and knight.stagger<=0 and distance<2.6:
			knight.block = target.swing>.25 and fmod(clock+float(knight.get_index())*.37,2.0)>.65
		if knight.team==1 or order=="CHARGE" or distance<3:
			target_point = target.position
	if knight.team==0 and (target==null or (order!="CHARGE" and distance>=3)):
		if order=="FOLLOW":
			target_point = escort_slot(slot)
		else:
			target_point = hold_point+Vector3(-3.0+(slot%4)*2.0,0,2.7+(slot/4)*1.9)
	var movement = target_point-knight.position
	movement.y = 0
	if target!=null and distance<1.9:
		movement = Vector3.ZERO
		var direction = target.position-knight.position
		knight.rotation.y = lerp_angle(knight.rotation.y,atan2(-direction.x,-direction.z),delta*10)
		if knight.cooldown<=0 and knight.stagger<=0 and not knight.block:
			start_strike(knight)
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
	var speed = (1.5 if knight.block else 2.8)*(0.15 if knight.stagger>0 else .25 if knight.swing>0 else 1.0)
	knight.velocity.x = movement.x*speed+separation.x
	knight.velocity.z = movement.z*speed+separation.z
	knight.velocity.y -= 24*delta
	knight.move_and_slide()
	knight.speed = Vector2(knight.velocity.x,knight.velocity.z).length()

func _process(delta: float) -> void:
	ready_frames += 1
	if ready_frames==30:
		print("IRON_SCENE_READY")
	if camera==null:
		return
	if map_open:
		realm.update_camera(delta)
		realm_ready_frames += 1
		if realm_ready_frames==30:
			print("IRON_REALM_READY")
	elif state!="title" and state!="origin":
		update_follow_camera(delta)
		if state=="play":
			field_ready_frames += 1
			if field_ready_frames==30:
				print("IRON_FIELD_READY: third-person hero visible")
	if capture_mode:
		capture_frame += 1
		if capture_frame==90:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/iron-title.png")
			state = "origin"
		if capture_frame==120:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/iron-origin.png")
			realm.life.choose_origin(0)
			enter_world()
			begin_battle()
			fighting = false
		if capture_frame==180:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/iron-field.png")
			realm.show_map()
			realm.selected = -1
		if capture_frame==240:
			realm.zoom = realm.WIDTH*.86
		if capture_frame==270:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/iron-map.png")
			hud.journal_open = true
			hud.journal_tab = 0
		if capture_frame==300:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/iron-wanderer.png")
			hud.journal_open = false
			realm.hide_map()
			hero.position = horse.position+Vector3(1,0,0)
			toggle_mount()
			yaw = horse.rotation.y+.45
		if capture_frame==345:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/iron-mounted.png")
			hud.visible = false
			state = "title"
			hero.rotation.y = 0
			camera.position = hero.position+Vector3(.24,1.82,-.85)
			camera.look_at(hero.position+Vector3(0,1.73,0))
		if capture_frame==380:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/iron-human.png")
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
	realm.battle_result(won)
	save_progress()

func return_to_camp() -> void:
	reset_mount()
	clear_enemies()
	state = "play"
	hero.dead = false
	hero.hp = hero.maximum_hp
	hero.collision_layer = 2
	hero.strike_clock = -1
	hero.swing = 0
	hero.stagger = 0
	hero.collision_layer = 2
	hero.visual.rotation = Vector3.ZERO
	hero.visual.position = Vector3.ZERO
	hero.ring.visible = false
	hero.position = Vector3(0,0,10)
	hero.speed = 0
	stamina = 100
	order = "FOLLOW"
	while living(0)<4:
		spawn_knight(hero.position+Vector3(-3+living(0)*1.5,0,-3),0,false)
	for knight in soldiers:
		knight.hp = knight.maximum_hp
	if realm.return_to_map:
		realm.return_to_map = false
		realm.show_map()
	announce("Company rested. Your campaign continues.")
	save_progress()

func announce(message: String) -> void:
	toast = message
	toast_time = 4

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_E:
			toggle_mount()
		if event.keycode==KEY_R:
			cut_side *= -1
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
				toggle_realm()
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and state=="play" and not paused and not map_open:
		look(event.relative)
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and state=="play" and not paused and not map_open:
		attacking = event.pressed

func look(amount: Vector2) -> void:
	yaw -= amount.x*.006
	pitch = clampf(pitch+amount.y*.004,-.2,.8)

func back() -> void:
	if hud.factions_open:
		hud.factions_open = false
		return
	reset_controls()
	if hud.journal_open:
		hud.journal_open = false
	elif state=="origin":
		state = "title"
	elif hud.help_open:
		hud.help_open = false
		paused = false
	elif map_open:
		if realm.selected>=0:
			realm.selected = -1
		else:
			realm.hide_map()
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
	file.store_string(JSON.stringify({"version":3,"gold":gold,"victories":victories,"realm":realm.serialize() if realm!=null else saved_realm}))
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
	if data is Dictionary and data.get("version",0) in [1,2,3]:
		gold = clampi(int(data.get("gold",120)),0,1000000)
		victories = clampi(int(data.get("victories",0)),0,100000)
		if data.get("realm",{}) is Dictionary:
			saved_realm = data.get("realm",{})
			restored_army = clampi(int(saved_realm.get("army",8)),4,12)

func run_smoke() -> void:
	# Allow collision-server registration before testing camera and weapon rays.
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(hero!=null and soldiers.size()==9,"Character scene initialization failed")
	assert(hero.right_arm!=null and hero.left_leg!=null,"Articulated character parts missing")
	realm.life.choose_origin(1)
	enter_world()
	begin_battle()
	assert(living(1)==8,"Encounter spawn count incorrect")
	var enemy = nearest_enemy(hero)
	enemy.position = hero.position+Vector3(0,0,-1.2)
	var before = enemy.hp
	attack()
	assert(enemy.hp==before and hero.strike_clock>0,"Melee must have a real windup")
	tick_strike(hero,.24)
	assert(enemy.hp<before,"Player melee did not damage target after windup")
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
	run_mounted_tests()
	run_combat_tests()
	run_realm_tests()
	run_wanderer_tests()
	print("IRON_SMOKE_PASS: characters, battle, campaign roads, trade, travel, persistence, fiefs")
	get_tree().quit()

func toggle_realm() -> void:
	if fighting:
		announce("Finish or retreat from this battle before returning to the campaign.")
		return
	if map_open:
		realm.hide_map()
	else:
		realm.show_map()

func run_realm_tests() -> void:
	assert(realm.settlements.size()==64,"Campaign settlement count")
	for id in range(realm.settlements.size()):
		assert(realm.graph.get_point_path(0,id).size()>0,"Disconnected road node")
	for id in realm.graph.get_point_ids():
		assert(realm.graph.get_point_position(id).y>0,"Road node must stay on land")
	realm.selected = 0
	assert(realm.near_settlement(0),"Initial town proximity")
	var money = gold
	assert(realm.transact("buy"),"Trade purchase")
	assert(realm.transact("sell"),"Trade sale")
	assert(gold<money and realm.grain==0,"Local arbitrage must lose money")
	realm.selected = 20
	money = gold
	assert(not realm.transact("food") and gold==money,"Remote purchase rejected")
	assert(realm.travel_to(20),"Campaign route planning")
	var planned = realm.route.duplicate()
	var start = realm.party
	var halfway = realm.follow_path(start,planned,35)
	assert(start.distance_to(halfway)>0 and planned.size()>0,"Incremental travel")
	var arrived = realm.follow_path(halfway,planned,10000)
	assert(arrived.distance_to(realm.graph.get_point_position(20))<.1 and planned.is_empty(),"Road arrival")
	realm.route.clear()
	realm.speed = 0
	realm.holdings = [1]
	realm.food = 45
	money = gold
	realm.next_day()
	assert(gold>money,"Fief income after wages")
	var serialized = JSON.parse_string(JSON.stringify(realm.serialize()))
	var restored = CrownRealm.new()
	restored.initialize(self)
	restored.restore(serialized)
	assert(restored.holdings.has(1) and restored.food==realm.food and restored.day==realm.day,"Save round trip")
	restored.free()
	# An encounter result can only reward once, including its campaign side effects.
	realm.return_to_map = true
	realm.encounter_fief = 5
	realm.battle_result(true)
	assert(realm.holdings.has(5) and realm.relations[realm.settlements[5].faction]<0,"Fief conquest")
	var count = realm.holdings.size()
	realm.battle_result(true)
	assert(realm.holdings.size()==count,"No duplicated fiefs")
	realm.return_to_map = false

func run_wanderer_tests() -> void:
	var guard_model = CrownRealm.new()
	guard_model.initialize(self)
	gold = 120
	assert(guard_model.life.choose_origin(2) and hero.maximum_hp==220 and hero.hp==220,"Freeblade health benefit")
	guard_model.free()
	var scout_model = CrownRealm.new()
	scout_model.initialize(self)
	assert(scout_model.life.choose_origin(1) and scout_model.food==50 and scout_model.life.travel_multiplier()>1.14,"Pathfinder supplies and movement")
	scout_model.free()
	var model = CrownRealm.new()
	model.initialize(self)
	var life = model.life
	gold = 120
	assert(life.choose_origin(0) and gold==180,"Merchant origin seed capital")
	assert(not life.choose_origin(2) and gold==180,"Origin cannot award twice")
	assert(life.neutral and life.regions_seen()==1,"Independent starting identity")
	model.selected = 0
	assert(life.accept_delivery(),"Local courier contract")
	var job = life.delivery.duplicate()
	assert(not life.accept_delivery(),"One active delivery")
	var money = gold
	assert(not life.claim_delivery() and gold==money,"Remote delivery claim denied")
	var pending_save = JSON.parse_string(JSON.stringify(model.serialize()))
	var pending_restore = CrownRealm.new()
	pending_restore.initialize(self)
	pending_restore.restore(pending_save)
	assert(pending_restore.life.delivery==job,"Active delivery reload")
	pending_restore.free()
	model.party = model.terrain_point(model.settlements[1].at)
	model.selected = 1
	assert(life.claim_delivery() and gold==money+45,"Courier arrival reward")
	money = gold
	assert(not life.claim_delivery() and gold==money,"No double delivery reward")
	assert(life.completed==1,"Delivery milestone")
	model.party = model.terrain_point(model.settlements[0].at)
	model.selected = 0
	assert(not life.accept_delivery(),"Courier origin cooldown")
	model.day += 2
	assert(life.accept_delivery(),"Board refresh")
	model.day = int(life.delivery.due)+1
	assert(not life.claim_delivery() and life.delivery.is_empty(),"Expired job cannot pay")
	assert(not life.hire(1),"Companion cannot be recruited remotely")
	assert(not life.found_caravan(),"Caravan requires a companion")
	assert(life.hire(0) and life.has_role("Scout"),"Local companion and passive ability")
	money = gold
	assert(not life.hire(0) and gold==money,"No duplicate companion charges")
	assert(not life.found_caravan(),"Insufficient business funds")
	gold = 1600
	assert(life.buy_workshop() and gold==1100 and model.holdings.is_empty(),"Workshop without land")
	assert(not life.buy_workshop() and gold==1100,"No duplicate workshop")
	assert(life.found_caravan() and gold==700,"Caravan purchase")
	assert(not life.has_role("Scout"),"Assigned leader no longer scouts player party")
	assert(not life.found_caravan() and gold==700,"One owned caravan")
	life.caravan_arrival(0,4)
	assert(gold>700 and int(life.caravan.paid)>0,"Caravan arrival earnings")
	money = gold
	life.caravan_arrival(0,4)
	assert(gold==money,"No duplicate caravan stop credit")
	life.caravan_arrival(1,8)
	assert(gold==money,"NPC caravan cannot credit player")
	model.day = 8 # Avoid the scheduled weekly toll for this accounting assertion.
	money = gold
	var income = life.workshop_income(0)
	life.daily()
	assert(gold==money+income-6,"Workshop income and caravan operating costs")
	model.day = 14
	money = gold
	life.daily()
	assert(gold==money+income-36,"Weekly bandit toll accounting")
	model.defeated = [12,13,14,15]
	money = gold
	life.daily()
	assert(gold==money+income-6,"Clearing raiders ends tolls")
	model.relations[0] = -20
	assert(life.workshop_income(0)==0,"Hostile business suspension")
	model.relations[0] = 0
	model.settlements[0].stock = 0
	assert(life.workshop_income(0)==0,"Workshop needs actual local supply")
	model.settlements[0].stock = 45
	life.visit(8)
	life.visit(24)
	life.visit(4)
	assert(life.regions_seen()==4,"Four-culture exploration milestone")
	var restored = CrownRealm.new()
	restored.initialize(self)
	restored.restore(JSON.parse_string(JSON.stringify(model.serialize())))
	assert(restored.life.serialize()==life.serialize(),"Full wanderer save round trip")
	restored.free()
	var legacy = CrownRealm.new()
	legacy.initialize(self)
	legacy.restore({"x":-165,"z":130,"holdings":[1]})
	assert(legacy.life.origin=="Veteran" and not legacy.life.neutral and legacy.holdings.has(1),"Legacy saves retain conquest access")
	legacy.free()
	var malformed = CrownRealm.new()
	malformed.initialize(self)
	malformed.restore({"life":{"origin":"bad","visited":[-1,999,"x",0,0],"companions":[-1,99],"workshops":[1,4,4,100],"caravan":{"companion":99,"home":0,"last_stop":0,"paid":0}}})
	assert(malformed.life.origin=="" and malformed.life.visited==[0] and malformed.life.workshops==[4] and malformed.life.caravan.is_empty(),"Invalid saved IDs rejected")
	malformed.free()
	var old_life = realm.life
	realm.life = life
	fighting = false
	var old_party = realm.party
	realm.party = realm.terrain_point(realm.settlements[9].at)
	assert(not realm.holdings.has(9),"Test castle must be unowned")
	realm.launch_encounter(9)
	assert(not fighting,"Neutral oath forbids settlement assault")
	realm.party = old_party
	realm.life = old_life
	model.free()
	# Integrate ownership with the existing visible NPC and its actual connected route.
	realm.life = WandererLife.new(realm)
	realm.life.companions = [0]
	realm.relations = [0,0,0,0]
	realm.selected = 0
	realm.party = realm.terrain_point(realm.settlements[0].at)
	gold = 1000
	assert(realm.life.found_caravan(),"Visible caravan launch")
	var npc = realm.civilians[0]
	assert(npc.kind=="Your caravan" and not npc.route.is_empty(),"Owned caravan model and route")
	npc.at = realm.follow_path(npc.at,npc.route,100000)
	assert(npc.at.distance_to(realm.graph.get_point_position(int(npc.goal)))<.01,"Caravan road arrival")
	for i in range(1,realm.civilians.size()):
		realm.civilians[i].active = false
	realm.pending = ""
	realm.speed = 1
	state = "play"
	paused = false
	money = gold
	realm.update(.01)
	assert(gold>money and not npc.route.is_empty(),"Simulation credits arrival and plans onward travel")
	var paid = int(realm.life.caravan.paid)
	realm.life.bind_caravan()
	assert(npc.at.distance_to(realm.graph.get_point_position(0))<.01 and int(realm.life.caravan.paid)==paid,"Caravan reload starts home without changing earnings")
	realm.life = old_life
	print("IRON_WANDERER_PASS: origins, deliveries, companions, neutrality, businesses, accounting, migration, save validation")

func update_follow_camera(delta: float, snap: bool = false) -> void:
	if camera==null or hero==null:
		return
	camera_shake = maxf(0,camera_shake-delta*.25)
	var right = Vector3(cos(yaw),0,-sin(yaw))
	var back_direction = Vector3(sin(yaw),0,cos(yaw))
	var focus = hero.position+Vector3(0,1.27,0)
	var desired = focus+back_direction*(6.3 if mounted else 4.1)+right*.65+Vector3(0,.68+pitch*1.8,0)
	var query = PhysicsRayQueryParameters3D.create(focus,desired,1)
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		desired = hit.position+hit.normal*.23
	camera.position = desired if snap or not hit.is_empty() else camera.position.lerp(desired,minf(1,delta*12))
	var shake = Vector3(sin(clock*73),cos(clock*61),0)*camera_shake
	camera.look_at(focus+right*.40+shake)

func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg")==OK:
		high_detail = bool(config.get_value("video","high_detail",false))
		sound_enabled = bool(config.get_value("audio","enabled",true))

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("video","high_detail",high_detail)
	config.set_value("audio","enabled",sound_enabled)
	config.save("user://settings.cfg")

func apply_quality() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_4X if high_detail else Viewport.MSAA_2X
	if sun!=null:
		sun.directional_shadow_max_distance = 70 if high_detail else 42
	if terrain!=null and terrain.grass!=null:
		terrain.grass.multimesh.visible_instance_count = 1800 if high_detail else 600
	if audio!=null:
		audio.enabled = sound_enabled

func run_combat_tests() -> void:
	assert(not map_open and hero.visible and terrain.visible,"Field entry must show the actual hero")
	update_follow_camera(1,true)
	var head = camera.unproject_position(hero.position+Vector3.UP*1.9)
	var feet = camera.unproject_position(hero.position)
	assert(not camera.is_position_behind(hero.position) and feet.y-head.y>160,"Hero must be prominently framed")
	assert(head.x>280 and head.x<950 and head.y>100 and feet.y<625,"Hero must stay clear of primary HUD")
	for slot in range(12):
		var lateral = (escort_slot(slot)-hero.position).dot(Vector3(cos(yaw),0,-sin(yaw)))
		assert(absf(lateral)>=3.79,"Following allies must leave the hero/camera corridor clear")
	var saved_position = hero.position
	var saved_angle = yaw
	hero.position = Vector3(-6,0,-20.8)
	yaw = PI
	update_follow_camera(1,true)
	assert(camera.position.distance_to(hero.position+Vector3.UP*1.27)<3.1,"Camera must stop before the stone tower")
	hero.position = saved_position
	yaw = saved_angle
	update_follow_camera(1,true)
	var victim = MarchKnight.new()
	add_child(victim)
	victim.setup(1,false)
	victim.position = Vector3(0,0,0)
	victim.block = true
	var hp_before = victim.hp
	victim.damage(20,Vector3(0,0,-2))
	assert(victim.hp>hp_before-5,"Front-facing shield reduces damage")
	hp_before = victim.hp
	victim.damage(20,Vector3(0,0,2))
	assert(victim.hp==hp_before-20,"A shield cannot block a rear attack")
	victim.player = true
	victim.guard_time = .1
	victim.stagger = 0
	hp_before = victim.hp
	victim.damage(20,Vector3(0,0,-2))
	assert(victim.hp==hp_before,"Timed player parry prevents chip damage")
	victim.queue_free()
	hero.cooldown = 0
	hero.swing = 0
	hero.stagger = 0
	hero.block = false
	stamina = 100
	var saved_yaw = yaw
	yaw = 0
	dash()
	assert(dash_time>0 and stamina==72 and evade_direction.z>.9,"Stationary dodge is a real backward step")
	dash_time = 0
	yaw = saved_yaw
	var old = high_detail
	high_detail = true
	apply_quality()
	assert(terrain.grass.multimesh.visible_instance_count==1800,"High foliage setting")
	high_detail = false
	apply_quality()
	assert(terrain.grass.multimesh.visible_instance_count==600,"Mobile foliage setting")
	high_detail = old
	apply_quality()
	assert(audio.effects.size()==4 and audio.wind.stream!=null,"Combat and ambience audio available")
	print("IRON_COMBAT_PASS: visible hero, proportional armor, delayed strikes, directional shields, parry, dodge, graphics settings, audio")

func toggle_mount() -> void:
	if hero.dead or paused or map_open or state!="play":
		return
	if not mounted:
		if horse.hp<=0 or hero.position.distance_to(horse.position)>3.4:
			announce("Approach your horse on the western road to mount.")
			return
		mounted = true
		print("IRON_MOUNTED")
		hero.riding = true
		hero.collision_layer = 0
		dash_time = 0
		hero.position = horse.position+Vector3(0,.82,0)
		announce("Ride: forward/back, steer left/right. DODGE changes gait; CUT selects sword side.")
	else:
		if absf(horse.speed)>1.5:
			announce("Slow to a walk before dismounting.")
			return
		for side in [-1,1]:
			var at = horse.position+horse.basis.x*side*1.45
			var floor_ray = PhysicsRayQueryParameters3D.create(at+Vector3.UP*3,at-Vector3.UP*4,1)
			var floor_hit = get_world_3d().direct_space_state.intersect_ray(floor_ray)
			if floor_hit.is_empty() or floor_hit.normal.y<.7:
				continue
			at = floor_hit.position+Vector3.UP*.06
			var shape = CapsuleShape3D.new()
			shape.radius = .32
			shape.height = 1.84
			var query = PhysicsShapeQueryParameters3D.new()
			query.shape = shape
			query.transform = Transform3D(Basis.IDENTITY,at+Vector3.UP*.94)
			query.collision_mask = 1|2|4
			if not get_world_3d().direct_space_state.intersect_shape(query).is_empty():
				continue
			mounted = false
			hero.riding = false
			hero.collision_layer = 2
			hero.position = at
			hero.velocity = Vector3.ZERO
			print("IRON_DISMOUNTED")
			return
		announce("No clear ground beside the saddle. Move away from obstacles.")

func mounted_strike() -> void:
	var victim: MarchKnight = null
	var distance = 2.8
	for other in soldiers:
		if other.team==hero.team or other.dead:
			continue
		var offset = other.position-horse.position
		if absf(offset.y)>1.7:
			continue
		offset.y = 0
		var local = horse.basis.inverse()*offset
		if local.x*hero.cut_side<.3 or local.z>1.25 or local.z< -2.5 or offset.length()>distance:
			continue
		var ray = PhysicsRayQueryParameters3D.create(hero.position+Vector3.UP*1.2,other.position+Vector3.UP*1.2,1)
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		victim = other
		distance = offset.length()
	if victim==null:
		return
	var guarded = victim.guarding_from(hero.position)
	victim.damage(32+minf(18,absf(horse.speed)*1.8),hero.position)
	audio.play_effect("clang" if guarded else "impact",.8)
	combat_notice = "MOUNTED BLOCK" if guarded else "MOUNTED CUT"
	combat_notice_time = .6
	camera_shake = .05

func reset_mount() -> void:
	mounted = false
	hero.riding = false
	horse.hp = float(MarchCatalog.data().horse.health)
	horse.stamina = 100
	horse.speed = 0
	horse.velocity = Vector3.ZERO
	horse.position = Vector3(3,1,11)
	horse.body.rotation = Vector3.ZERO

func run_mounted_tests() -> void:
	state = "play"
	paused = false
	map_open = false
	var original = hero.position
	hero.position = horse.position+Vector3(1,0,0)
	toggle_mount()
	assert(mounted and hero.riding and hero.collision_layer==0,"Nearby mounting failed")
	horse.speed = 5
	toggle_mount()
	assert(mounted,"Must not dismount at a canter")
	var old_pace = horse.pace
	dash()
	assert(horse.pace==(old_pace+1)%3,"Mounted dodge must change gait")
	var enemy = spawn_knight(horse.position+horse.basis.x*1.8,1,false)
	hero.cut_side = -1
	var before = enemy.hp
	mounted_strike()
	assert(enemy.hp==before,"Wrong-side mounted cut must miss")
	hero.cut_side = 1
	mounted_strike()
	assert(enemy.hp<before and before-enemy.hp<=50,"Right-side mounted cut or bounded speed bonus failed")
	enemy.dead = true
	soldiers.erase(enemy)
	enemy.queue_free()
	reset_mount()
	hero.collision_layer = 2
	hero.position = original
	print("IRON_MOUNTED_PASS: mounting, safe dismount speed, gait and side-specific sword hits")
