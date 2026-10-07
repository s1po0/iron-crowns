extends Control

var game
var help_open = false
var journal_open = false
var journal_tab = 0
var origin_choice = 0
var caravan_choice = 0
var buttons: Array = []
var fingers = {}
var map_origins = {}
var map_latest = {}
var map_moved = {}
var joystick = Vector2.ZERO
var heading: Font = preload("res://assets/fonts/cinzel.ttf")
var body: Font = preload("res://assets/fonts/lato.ttf")
var ink = Color("142f35")
var gold = Color("c0a67e")
var white = Color("f7f0dd")
var muted = Color("b8c9c5")
var red = Color("da8368")
var base = Vector2(1280,720)
var menu_gradient: GradientTexture2D

func _ready() -> void:
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0,0.45,1.0])
	gradient.colors = PackedColorArray([Color(.035,.095,.12,.98),Color(.035,.095,.12,.90),Color(.035,.095,.12,0)])
	menu_gradient = GradientTexture2D.new()
	menu_gradient.width = 256
	menu_gradient.height = 1
	menu_gradient.gradient = gradient
	menu_gradient.fill_from = Vector2.ZERO
	menu_gradient.fill_to = Vector2(1,0)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func reset_touches() -> void:
	fingers.clear()
	map_origins.clear()
	map_latest.clear()
	map_moved.clear()
	joystick = Vector2.ZERO

func panel(rect: Rect2, color: Color, radius: int = 12, border: Color = Color.TRANSPARENT) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1 if border.a>0 else 0)
	style.border_color = border
	draw_style_box(style,rect)

func label(text: String, at: Vector2, font_size: int = 16, color: Color = Color.WHITE, font: Font = null) -> void:
	draw_string(body if font==null else font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func centered(text: String, at: Vector2, font_size: int, color: Color, font: Font = null) -> void:
	var selected = body if font==null else font
	var width = selected.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	label(text,at-Vector2(width/2,0),font_size,color,selected)

func button(id: String, text: String, rect: Rect2, accent: bool = false) -> void:
	panel(rect,gold if accent else Color(.06,.15,.18,.88),8,Color(.80,.76,.61,.3))
	centered(text,rect.get_center()+Vector2(0,6),16,ink if accent else white)
	buttons.append({"id":id,"rect":rect})

func crown(at: Vector2, scale_value: float, color: Color) -> void:
	var points = PackedVector2Array([Vector2(-16,-10),Vector2(-7,-3),Vector2(0,-17),Vector2(7,-3),Vector2(16,-10),Vector2(12,10),Vector2(-12,10)])
	for i in range(points.size()):
		points[i] = at+points[i]*scale_value
	draw_colored_polygon(points,color)
	draw_line(at+Vector2(-10,5)*scale_value,at+Vector2(10,5)*scale_value,ink,2*scale_value)

func _draw() -> void:
	if game==null:
		return
	buttons.clear()
	draw_set_transform(Vector2.ZERO,0,size/base)
	if game.state=="origin":
		WandererOverlay.creation(self)
	elif game.state=="title":
		draw_title()
	elif game.map_open:
		draw_map()
	else:
		draw_game()
	if game.state=="victory" or game.state=="defeat":
		draw_result()
	elif game.paused and not help_open:
		draw_pause()
	if journal_open and not game.paused and game.map_open:
		WandererOverlay.journal(self)
	if help_open:
		draw_help()

func draw_title() -> void:
	draw_texture_rect(menu_gradient,Rect2(0,0,825,720),false)
	crown(Vector2(75,83),1.4,gold)
	label("THE ASHEN MARCHES",Vector2(113,89),14,gold)
	label("IRON",Vector2(53,238),82,white,heading)
	label("CROWNS",Vector2(53,330),82,white,heading)
	draw_line(Vector2(59,363),Vector2(166,363),gold,2)
	label("No king. No oath. Your journey.",Vector2(58,402),18,white)
	label("32 settlements. Four realms. A continent to explore.",Vector2(58,434),15,muted)
	button("enter","CREATE WANDERER" if game.realm.life.origin=="" else "CONTINUE JOURNEY",Rect2(58,480,335,60),true)
	button("help","FIELD GUIDE",Rect2(58,557,160,47))
	label("THE WESTERN ROAD  /  COMBAT REBUILD 0.5",Vector2(58,670),11,muted)
	panel(Rect2(930,42,299,47),Color(.06,.15,.18,.72),8)
	label("HEARTHGLEN  ·  THE WESTERN ROAD",Vector2(948,71),12,white)

func draw_game() -> void:
	panel(Rect2(27,24,323,87),Color(.045,.12,.15,.87),10)
	crown(Vector2(61,66),1,gold)
	label("SAMIR FARROAD",Vector2(91,52),15,white,heading)
	label("HEARTHGLEN COMPANY",Vector2(91,72),10,muted)
	panel(Rect2(91,84,233,7),Color(.08,.12,.15,1),3)
	panel(Rect2(91,84,233*maxf(0,game.hero.hp/game.hero.maximum_hp),7),Color("83bca1"),3)
	panel(Rect2(91,97,233,3),Color(.08,.12,.15,1),1)
	panel(Rect2(91,97,233*game.stamina/100,3),gold,1)
	panel(Rect2(920,24,192,51),Color(.045,.12,.15,.86),8)
	crown(Vector2(945,51),.55,gold)
	label(str(game.gold)+" GOLD",Vector2(967,57),15,gold)
	button("map","REALM",Rect2(1127,24,125,51))
	button("pause","II",Rect2(1200,92,52,45))
	panel(Rect2(28,128,292,94),Color(.045,.12,.15,.74),8)
	label("DEFEND HEARTHGLEN" if game.fighting else "THE WESTERN ROAD",Vector2(46,154),14,gold,heading)
	label(str(game.living(1))+" raiders remaining" if game.fighting else "Explore on foot or open REALM",Vector2(46,181),14,white)
	label(str(game.living(0))+" soldiers under your banner",Vector2(46,204),12,muted)
	if not game.fighting:
		button("battle","BEGIN SKIRMISH",Rect2(470,29,190,48),true)
		button("recruit","RECRUIT 3  ·  30 GOLD",Rect2(674,29,222,48))
	else:
		panel(Rect2(492,24,295,54),Color(.045,.12,.15,.85),8)
		centered("THE RAIDERS APPROACH",Vector2(639,47),11,muted)
		centered("HOLD THE WESTERN ROAD",Vector2(639,67),14,white,heading)
	# Character health bars are projected from actual 3D positions.
	for unit in game.soldiers:
		if unit.player or unit.dead or unit.hp>=unit.maximum_hp or game.camera.is_position_behind(unit.global_position):
			continue
		var at = game.camera.unproject_position(unit.global_position+Vector3(0,2.36,0))*base/size
		if at.x<0 or at.x>1280 or at.y<0 or at.y>500:
			continue
		panel(Rect2(at-Vector2(18,0),Vector2(36,4)),Color(.05,.1,.13,.85),2)
		panel(Rect2(at-Vector2(18,0),Vector2(36*unit.hp/unit.maximum_hp,4)),red if unit.team==1 else Color("8ac6c3"),2)
	# Transparent mobile controls leave the character silhouette unobstructed.
	draw_circle(Vector2(125,584),68,Color(.06,.15,.18,.45))
	draw_arc(Vector2(125,584),68,0,TAU,64,Color(.91,.87,.72,.4),1.5,true)
	draw_circle(Vector2(125,584)+joystick*43,25,Color(.92,.90,.79,.56))
	centered("MOVE",Vector2(125,679),10,white)
	draw_circle(Vector2(1156,585),63,Color(.065,.08,.08,.82))
	draw_arc(Vector2(1156,585),70,0,TAU,64,Color(.92,.87,.74,.4),1.5,true)
	# Sword pictogram.
	draw_line(Vector2(1139,591),Vector2(1173,556),white,3,true)
	draw_line(Vector2(1140,575),Vector2(1158,593),white,3,true)
	centered("STRIKE",Vector2(1156,618),11,white)
	draw_circle(Vector2(1014,605),43,Color(.06,.15,.18,.80))
	draw_arc(Vector2(1014,605),44,0,TAU,48,Color(.91,.87,.72,.6),1,true)
	centered("BLOCK",Vector2(1014,611),11,white)
	draw_circle(Vector2(1115,465),35,Color(.06,.15,.18,.75))
	centered("DODGE",Vector2(1115,470),10,white)
	panel(Rect2(384,625,505,70),Color(.045,.12,.15,.85),10)
	panel(Rect2(384,595,147,25),Color(.045,.12,.15,.78),5)
	label("COMPANY ORDER",Vector2(397,612),10,white)
	var orders = ["FOLLOW","HOLD","CHARGE","WALL"]
	for i in range(4):
		button(orders[i],orders[i],Rect2(395+i*122,637,115,45),game.order==orders[i])
	if game.toast_time>0:
		panel(Rect2(365,110,550,42),Color(.045,.12,.15,.86),7)
		centered(game.toast,Vector2(640,136),13,white)
	if not game.fighting:
		panel(Rect2(365,162,550,36),Color(.045,.12,.15,.70),7)
		centered("Your hero is here. Drag to look; REALM opens long-distance travel.",Vector2(640,186),12,white)

	# A restrained aim point, with brief readable feedback instead of screen-filling effects.
	for side in [-1,1]:
		draw_line(Vector2(640+side*4,360),Vector2(640+side*9,360),Color(.85,.84,.79,.6),1)
	if game.combat_notice_time>0:
		centered(game.combat_notice,Vector2(718,398),14,gold)
	elif game.hero.block:
		centered("GUARD",Vector2(718,398),12,muted)

func draw_map() -> void:
	RealmOverlay.draw(self)

func draw_result() -> void:
	buttons.clear()
	draw_rect(Rect2(0,0,1280,720),Color(.03,.08,.11,.73))
	panel(Rect2(330,150,620,411),Color(.045,.12,.15,.97),15,Color(.91,.76,.51,.5))
	var won = game.state=="victory"
	crown(Vector2(640,219),1.7,gold)
	centered("THE ROAD IS OURS" if won else "A BANNER STILL STANDS",Vector2(640,289),32,white,heading)
	centered("Victory: +80 gold. Your company holds the field." if won else "Your surviving company returns to camp. Ransom: up to 20 gold.",Vector2(640,340),15,muted)
	centered(str(game.living(0))+" surviving soldiers  ·  "+str(game.victories)+" victories",Vector2(640,383),16,gold)
	centered(game.encounter_reward_note,Vector2(640,414),12,gold)
	button("camp","RETURN TO CAMPAIGN" if game.realm.return_to_map else "RETURN TO CAMP",Rect2(445,438,390,60),true)

func draw_pause() -> void:
	buttons.clear()
	draw_rect(Rect2(0,0,1280,720),Color(.025,.04,.045,.9))
	centered("A MOMENT OF RESPITE",Vector2(640,150),32,white,heading)
	centered("Mobile: 600 grass clusters / 2x AA. High: 1,800 / 4x AA / longer shadows.",Vector2(640,190),14,muted)
	button("pause","RESUME",Rect2(445,235,390,54),true)
	button("quality","GRAPHICS: "+("HIGH DETAIL" if game.high_detail else "MOBILE"),Rect2(445,306,390,54))
	button("sound","SOUND: "+("ON" if game.sound_enabled else "OFF"),Rect2(445,377,390,54))
	button("help","CONTROLS / FIELD GUIDE",Rect2(445,448,390,54))
	button("retreat","RETREAT TO CAMP" if game.fighting else "TITLE SCREEN",Rect2(445,519,390,54))
	centered("Higher detail costs performance. These settings are saved independently of your campaign.",Vector2(640,620),13,muted)

func draw_help() -> void:
	buttons.clear()
	draw_rect(Rect2(0,0,1280,720),Color(.035,.09,.12,.98))
	label("A CAPTAIN'S FIELD GUIDE",Vector2(105,113),36,white,heading)
	var lines = [
		"MOVE       Left thumbstick, or WASD on desktop.",
		"LOOK        Drag the right side; on desktop hold the right mouse button.",
		"STRIKE     Hold the sword button, left click, or Space near an enemy.",
		"DEFEND   Hold BLOCK / Q facing the enemy. A fresh guard can parry; DODGE / Shift steps away.",
		"LEAD        FOLLOW escorts you. HOLD anchors. CHARGE engages. WALL protects.",
		"CAMPAIGN  Drag to pan, pinch to zoom. Select a settlement and tap TRAVEL.",
		"FIGHT       Strikes land after a windup. Aim forward, stay in reach, and exploit enemy recovery.",
		"SAVE        Company, campaign position, food, fiefs and gold persist; travel resumes paused."
	]
	for i in range(lines.size()):
		label(lines[i],Vector2(108,178+i*47),17,muted if i%2 else white)
	label("32 original settlements; one shared battle arena. Full sieges and dynasties are not implemented.",Vector2(108,591),14,gold)
	button("help_close","BACK TO THE MARCHES",Rect2(108,627,330,52),true)

func action(id: String) -> void:
	if id.begins_with("origin_") and id.trim_prefix("origin_").is_valid_int():
		origin_choice = clampi(int(id.trim_prefix("origin_")),0,2)
		return
	if id.begins_with("journal_tab_"):
		journal_tab = clampi(int(id.trim_prefix("journal_tab_")),0,3)
		return
	if id.begins_with("companion_"):
		game.realm.life.hire(int(id.trim_prefix("companion_")))
		return
	match id:
		"origin_back": game.state = "title"
		"origin_begin":
			game.realm.life.choose_origin(origin_choice)
			game.enter_world()
		"journal":
			journal_open = true
			game.realm.speed = 0
			game.reset_controls()
		"journal_close": journal_open = false
		"delivery_accept": game.realm.life.accept_delivery()
		"delivery_claim": game.realm.life.claim_delivery()
		"delivery_abandon": game.realm.life.abandon_delivery()
		"delivery_route":
			if not game.realm.life.delivery.is_empty():
				if game.realm.travel_to(int(game.realm.life.delivery.to)):
					journal_open = false
		"caravan_leader": caravan_choice += 1
		"caravan_buy":
			var l = game.realm.life
			l.found_caravan(-1 if l.companions.is_empty() else l.companions[caravan_choice%l.companions.size()])
		"workshop_buy": game.realm.life.buy_workshop()
		"enter": game.enter_world()
		"battle": game.begin_battle()
		"recruit": game.reinforce()
		"camp": game.return_to_camp()
		"map": game.toggle_realm()
		"field": game.realm.hide_map()
		"select_close": game.realm.selected = -1
		"select_previous", "select_next":
			game.realm.selected = posmod(game.realm.selected+(-1 if id=="select_previous" else 1),32)
			var at = game.realm.settlements[game.realm.selected].at
			game.realm.map_focus = Vector3(at.x,0,at.y)
			game.realm.zoom = minf(game.realm.zoom,350)
		"travel": game.realm.travel_to(game.realm.selected)
		"zoom_in": game.realm.change_zoom(.82)
		"zoom_out": game.realm.change_zoom(1.22)
		"locate":
			game.realm.map_focus = Vector3(game.realm.party.x,0,game.realm.party.z)
			game.realm.zoom = 280
		"atlas":
			game.realm.map_focus = Vector3(70,0,-10)
			game.realm.zoom = 800
			game.realm.selected = -1
		"time0": game.realm.speed = 0
		"time1": game.realm.speed = 1
		"time2": game.realm.speed = 2
		"time4": game.realm.speed = 4
		"food": game.realm.transact("food")
		"buy_grain": game.realm.transact("buy")
		"sell_grain": game.realm.transact("sell")
		"realm_recruit": game.realm.transact("recruit")
		"quest": game.realm.transact("quest")
		"truce": game.realm.transact("truce")
		"assault": game.realm.launch_encounter(game.realm.selected)
		"fight_party": game.realm.launch_encounter()
		"avoid_party": game.realm.avoid_encounter()
		"quality":
			game.high_detail = not game.high_detail
			game.apply_quality()
			game.save_settings()
		"sound":
			game.sound_enabled = not game.sound_enabled
			game.apply_quality()
			game.save_settings()
		"pause":
			game.paused = not game.paused
			game.reset_controls()
		"help":
			help_open = true
			game.paused = true
			game.reset_controls()
		"help_close":
			help_open = false
			game.paused = false
		"retreat":
			game.paused = false
			if game.fighting:
				game.finish_battle(false)
			else:
				if game.map_open:
					game.realm.hide_map()
				game.state = "title"
				game.hero.rotation.y = PI+.2
				game.camera.position = Vector3(-4.5,3.5,18)
				game.camera.look_at(Vector3(-3,1.4,0))
		_:
			game.set_order(id)
	queue_redraw()

func pressed(at: Vector2, index: int) -> bool:
	for item in buttons:
		if item.rect.has_point(at):
			action(item.id)
			return true
	if game.state!="play" or game.paused or help_open or journal_open:
		return true
	if game.map_open:
		fingers[index] = "map"
		map_origins[index] = at
		map_latest[index] = at
		map_moved[index] = false
		return true
	if at.distance_to(Vector2(125,584))<100:
		fingers[index] = "move"
		move_joystick(at)
	elif at.distance_to(Vector2(1156,585))<78:
		fingers[index] = "attack"
		game.attacking = true
	elif at.distance_to(Vector2(1014,605))<56:
		fingers[index] = "block"
		game.blocking = true
	elif at.distance_to(Vector2(1115,465))<45:
		fingers[index] = "dash"
		game.dash()
	else:
		fingers[index] = "look"
	return true

func move_joystick(at: Vector2) -> void:
	joystick = ((at-Vector2(125,584))/53).limit_length()
	game.stick = joystick

func release(index: int) -> void:
	var owned = fingers.get(index,"")
	if owned=="move":
		joystick = Vector2.ZERO
		game.stick = Vector2.ZERO
	elif owned=="attack":
		game.attacking = false
	elif owned=="block":
		game.blocking = false
	elif owned=="map":
		if not map_moved.get(index,false) and map_latest.has(index):
			game.realm.select_at(map_latest[index]*size/base)
		map_origins.erase(index)
		map_latest.erase(index)
		map_moved.erase(index)
	fingers.erase(index)

func _input(event: InputEvent) -> void:
	if size.x<=0 or size.y<=0:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			pressed(event.position*base/size,event.index)
		else:
			release(event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var owned = fingers.get(event.index,"")
		if owned=="move":
			move_joystick(event.position*base/size)
		elif owned=="look":
			game.look(event.relative*base/size)
		elif owned=="map":
			map_drag(event.index,event.position*base/size,event.relative*base/size)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and game.map_open and not journal_open and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		game.realm.change_zoom(.9 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.11)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			var at = event.position*base/size
			for item in buttons:
				if item.rect.has_point(at):
					action(item.id)
					get_viewport().set_input_as_handled()
					return
			if at.y>425 or game.map_open:
				pressed(at,-1)
				get_viewport().set_input_as_handled()
		else:
			release(-1)
	elif event is InputEventMouseMotion and fingers.get(-1,"")=="move":
		move_joystick(event.position*base/size)
		get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and fingers.get(-1,"")=="map":
		map_drag(-1,event.position*base/size,event.relative*base/size)
		get_viewport().set_input_as_handled()

func map_drag(index: int, at: Vector2, relative: Vector2) -> void:
	if not map_latest.has(index):
		return
	if map_latest.size()>=2:
		var other = map_latest.keys()[0]
		if other==index:
			other = map_latest.keys()[1]
		var previous = map_latest[index].distance_to(map_latest[other])
		var current = at.distance_to(map_latest[other])
		if previous>5 and current>5:
			game.realm.change_zoom(previous/current)
		map_moved[index] = true
		map_moved[other] = true
	else:
		if at.distance_to(map_origins[index])>12:
			map_moved[index] = true
		if map_moved.get(index,false):
			game.realm.pan(relative)
	map_latest[index] = at
