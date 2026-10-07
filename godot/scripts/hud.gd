extends Control

var game
var help_open = false
var buttons: Array = []
var fingers = {}
var joystick = Vector2.ZERO
var heading: Font = preload("res://assets/fonts/cinzel.ttf")
var body: Font = preload("res://assets/fonts/manrope.ttf")
var ink = Color("142f35")
var gold = Color("e8c184")
var white = Color("f7f0dd")
var muted = Color("b8c9c5")
var red = Color("da8368")
var base = Vector2(1280,720)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func reset_touches() -> void:
	fingers.clear()
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
	if game.state=="title":
		draw_title()
	elif game.map_open:
		draw_map()
	else:
		draw_game()
	if game.state=="victory" or game.state=="defeat":
		draw_result()
	elif game.paused and not help_open:
		draw_pause()
	if help_open:
		draw_help()

func draw_title() -> void:
	for i in range(90):
		draw_rect(Rect2(i*9,0,9,720),Color(.035,.095,.12,.97*(1-pow(float(i)/90,2))))
	crown(Vector2(75,83),1.4,gold)
	label("THE ASHEN MARCHES",Vector2(113,89),14,gold)
	label("IRON",Vector2(53,238),82,white,heading)
	label("CROWNS",Vector2(53,330),82,white,heading)
	draw_line(Vector2(59,363),Vector2(166,363),gold,2)
	label("A captain. A company. A kingdom to forge.",Vector2(58,402),18,white)
	label("Walk the Marches. Fight beside your soldiers.",Vector2(58,434),15,muted)
	button("enter","ENTER THE MARCHES",Rect2(58,480,335,60),true)
	button("help","FIELD GUIDE",Rect2(58,557,160,47))
	label("STYLIZED 3D  /  EARLY FIELD BUILD 0.2",Vector2(58,670),11,muted)
	panel(Rect2(930,42,299,47),Color(.06,.15,.18,.72),8)
	label("HEARTHGLEN  ·  THE WESTERN ROAD",Vector2(948,71),12,white)

func draw_game() -> void:
	panel(Rect2(27,24,323,87),Color(.045,.12,.15,.87),10)
	crown(Vector2(61,66),1,gold)
	label("THE CAPTAIN",Vector2(91,52),15,white,heading)
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
	label(str(game.living(1))+" raiders remaining" if game.fighting else "Explore the village and meadow",Vector2(46,181),14,white)
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
	draw_circle(Vector2(1156,585),63,gold)
	draw_arc(Vector2(1156,585),70,0,TAU,64,Color(.92,.87,.74,.4),1.5,true)
	# Sword pictogram.
	draw_line(Vector2(1139,591),Vector2(1173,556),ink,5,true)
	draw_line(Vector2(1140,575),Vector2(1158,593),ink,4,true)
	centered("STRIKE",Vector2(1156,618),11,ink)
	draw_circle(Vector2(1014,605),43,Color(.06,.15,.18,.80))
	draw_arc(Vector2(1014,605),44,0,TAU,48,Color(.91,.87,.72,.6),1,true)
	centered("BLOCK",Vector2(1014,611),11,white)
	draw_circle(Vector2(1115,465),35,Color(.06,.15,.18,.75))
	centered("DASH",Vector2(1115,470),10,white)
	panel(Rect2(384,625,505,70),Color(.045,.12,.15,.85),10)
	label("COMPANY ORDER",Vector2(403,616),10,white)
	var orders = ["FOLLOW","HOLD","CHARGE","WALL"]
	for i in range(4):
		button(orders[i],orders[i],Rect2(395+i*122,637,115,45),game.order==orders[i])
	if game.toast_time>0:
		panel(Rect2(365,110,550,42),Color(.045,.12,.15,.86),7)
		centered(game.toast,Vector2(640,136),13,white)
	if not game.fighting:
		centered("Drag the right side to look around  ·  Tap REALM for the region overview",Vector2(640,577),12,white)

func draw_map() -> void:
	panel(Rect2(28,27,420,113),Color(.045,.12,.15,.9),10)
	label("THE ASHEN MARCHES",Vector2(51,70),26,white,heading)
	label("HEARTHGLEN  /  LOCAL REGION",Vector2(52,103),12,gold)
	button("map","RETURN TO CAPTAIN",Rect2(986,28,266,52),true)
	var points = [Vector3(0,7,-25),Vector3(-21,4,-4),Vector3(1,1,10)]
	var names = ["HEARTHGLEN","ASHWOOD","YOUR COMPANY"]
	for i in range(points.size()):
		var at = game.camera.unproject_position(points[i])*base/size
		panel(Rect2(at-Vector2(94,20),Vector2(188,42)),Color(.045,.12,.15,.87),7)
		centered(names[i],at+Vector2(0,6),13,gold,heading)
	panel(Rect2(344,652,592,42),Color(.045,.12,.15,.88),8)
	centered("A 3D region overview. Kingdom simulation is not yet implemented.",Vector2(640,678),12,muted)

func draw_result() -> void:
	buttons.clear()
	draw_rect(Rect2(0,0,1280,720),Color(.03,.08,.11,.73))
	panel(Rect2(330,150,620,411),Color(.045,.12,.15,.97),15,Color(.91,.76,.51,.5))
	var won = game.state=="victory"
	crown(Vector2(640,219),1.7,gold)
	centered("THE ROAD IS OURS" if won else "A BANNER STILL STANDS",Vector2(640,289),32,white,heading)
	centered("Hearthglen is safe. Your company earns 80 gold." if won else "Your surviving company returns to camp. Ransom: up to 20 gold.",Vector2(640,340),15,muted)
	centered(str(game.living(0))+" surviving soldiers  ·  "+str(game.victories)+" victories",Vector2(640,383),16,gold)
	button("camp","RETURN TO CAMP",Rect2(445,438,390,60),true)

func draw_pause() -> void:
	buttons.clear()
	draw_rect(Rect2(0,0,1280,720),Color(.03,.08,.11,.78))
	centered("A MOMENT OF RESPITE",Vector2(640,213),34,white,heading)
	centered("Battles restart from camp if the application is closed.",Vector2(640,256),15,muted)
	button("pause","RESUME",Rect2(445,307,390,58),true)
	button("help","FIELD GUIDE",Rect2(445,386,390,54))
	button("retreat","RETREAT TO CAMP" if game.fighting else "TITLE SCREEN",Rect2(445,460,390,54))

func draw_help() -> void:
	buttons.clear()
	draw_rect(Rect2(0,0,1280,720),Color(.035,.09,.12,.98))
	label("A CAPTAIN'S FIELD GUIDE",Vector2(105,113),36,white,heading)
	var lines = [
		"MOVE       Left thumbstick, or WASD on desktop.",
		"LOOK        Drag the right side; on desktop hold the right mouse button.",
		"STRIKE     Hold the sword button, left click, or Space near an enemy.",
		"DEFEND   Hold BLOCK / Q. DASH / Shift costs stamina and creates space.",
		"LEAD        FOLLOW escorts you. HOLD anchors. CHARGE engages. WALL protects.",
		"EXPLORE  Walk into Hearthglen; REALM shows the actual 3D region from above.",
		"FIGHT       Begin a skirmish, defeat the raiders, and earn gold for reinforcements.",
		"SAVE        Gold and victories persist. Your field company resets when reopening."
	]
	for i in range(lines.size()):
		label(lines[i],Vector2(108,178+i*47),17,muted if i%2 else white)
	label("This build focuses on 3D characters and a single playable region—not the full RPG.",Vector2(108,591),14,gold)
	button("help_close","BACK TO THE MARCHES",Rect2(108,627,330,52),true)

func action(id: String) -> void:
	match id:
		"enter": game.enter_world()
		"battle": game.begin_battle()
		"recruit": game.reinforce()
		"camp": game.return_to_camp()
		"map":
			game.map_open = not game.map_open
			game.reset_controls()
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
				game.state = "title"
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
	if game.state!="play" or game.paused or game.map_open or help_open:
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
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			var at = event.position*base/size
			for item in buttons:
				if item.rect.has_point(at):
					action(item.id)
					get_viewport().set_input_as_handled()
					return
			if at.y>425:
				pressed(at,-1)
				get_viewport().set_input_as_handled()
		else:
			release(-1)
	elif event is InputEventMouseMotion and fingers.get(-1,"")=="move":
		move_joystick(event.position*base/size)
		get_viewport().set_input_as_handled()
