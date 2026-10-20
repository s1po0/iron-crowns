extends Node3D
var sim=CastleSim.new()
var world=CastleWorld.new()
var ui=CastleUI.new()
var camera=Camera3D.new()
var ghost: MeshInstance3D
var focus=Vector3(-2,0,-5)
var distance=58.0
var target_distance=58.0
var chosen="stockpile"
var placement=Vector2i(15,20)
var started=false
var paused=false
var quality_index=1
var touches: Dictionary={}
var dragging=false
var pointer_down=Vector2.ZERO
var mouse_drag=false
var last_pinch=0.0
var autosave=0.0
var sound=true
var audio: AudioStreamPlayer
var screenshot_clock=0.0
var demolition_id=-1
var demolition_until=0

func _ready() -> void:
	# Native Control widgets need emulated mouse clicks; map gestures handle raw touches separately.
	Input.emulate_mouse_from_touch=true
	var prefs=ConfigFile.new()
	if prefs.load("user://castle-settings.cfg")==OK:
		quality_index=clampi(int(prefs.get_value("graphics","quality",1)),0,2)
		sound=bool(prefs.get_value("audio","enabled",true))
	add_child(world)
	world.setup()
	add_child(camera)
	camera.current=true
	camera.fov=42
	camera.near=.2
	camera.far=280
	ghost=MarchArt.box(self,Vector3.ZERO,Vector3(6,.12,6),MarchArt.material(Color("7ab779")))
	ghost.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost.visible=false
	add_child(ui)
	ui.setup(self)
	set_quality(quality_index)
	audio=AudioStreamPlayer.new()
	audio.stream=ContentAssets.audio("res://assets/audio/wind.wav")
	audio.volume_db=-24
	add_child(audio)
	audio.finished.connect(func():
		if sound:
			audio.play())
	if sound:
		audio.play()
	if "--rts-capture" in OS.get_cmdline_user_args():
		new_game()
		sim.resources.wood=1000
		sim.resources.stone=1000
		for entry in [["stockpile",14,20],["woodcutter",12,12],["farm",14,26],["mill",19,24],["bakery",23,23],["barracks",23,17],["house",17,29],["wall",22,12],["wall",23,12],["wall",24,12],["gate",25,12]]:
			sim.place(entry[0],Vector2i(entry[1],entry[2]))
		for b in sim.buildings:
			b.built=1.0
		sim.resources.bread=100
		for i in 6:
			sim.train()
		sim.order(Vector2i(24,14))
	world.sync(sim,0)

func _process(dt: float) -> void:
	distance=lerpf(distance,target_distance,minf(1,dt*8))
	camera.position=focus+Vector3(distance*.55,distance*.8,distance*.65)
	camera.look_at(focus)
	if started and not paused:
		sim.step(dt)
		world.sync(sim,dt)
		autosave+=dt
		if autosave>30:
			autosave=0
			sim.save_game()
	ui.update(sim)
	ghost.visible=started and CastleSim.FOOTPRINT.has(chosen) and sim.ended.is_empty()
	if ghost.visible:
		var n: int=CastleSim.FOOTPRINT[chosen]
		ghost.position=CastleSim.world(Vector2(placement))+Vector3((n-1)*1.5,.12,(n-1)*1.5)
		ghost.scale=Vector3(n*.5,1,n*.5)
		ghost.material_override.albedo_color=Color("73b58255") if sim.can_build(chosen,placement) else Color("b65c4f55")
	if "--rts-capture" in OS.get_cmdline_user_args():
		screenshot_clock+=dt
		if screenshot_clock>4:
			get_viewport().get_texture().get_image().save_png("/tmp/iron-castle-rts.png")
			print("IRON_RTS_RENDER_PASS")
			get_tree().quit()

func new_game() -> void:
	if FileAccess.file_exists(CastleSim.SAVE):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(CastleSim.SAVE),ProjectSettings.globalize_path(CastleSim.SAVE+".previous"))
	started=true
	ui.intro.hide()

func restart() -> void:
	for node in world.structures.values()+world.actors.values():
		node.queue_free()
	world.structures.clear()
	world.actors.clear()
	world.rotating.clear()
	sim=CastleSim.new()
	paused=false
	autosave=0
	ui.finish.text=""
	ui.notice.text=""
	new_game()
	locate()

func resume() -> void:
	if not sim.load_game():
		ui.notice.text="پاشەکەوتەکە ناگونجێت؛ گوندێکی نوێ دەست پێ بکە."
		return
	started=true
	ui.intro.hide()

func choose(kind: String) -> void:
	chosen=kind
	demolition_id=-1

func choose_rally() -> void:
	chosen=""
	ui.notice.text="شوێنی کۆبوونەوەی سوپا لە نەخشە دابگرە."

func confirm_build() -> void:
	if not started or paused or not CastleSim.COSTS.has(chosen):
		return
	ui.notice.text="بنیاتنان دەستی پێ کرد." if sim.place(chosen,placement) else "شوێنەکە داخراوە یان سەرچاوەکان بەس نین."

func inspect() -> void:
	choose("inspect")
	ui.notice.text="بینایەک لە نەخشە هەڵبژێرە؛ دەروازە، چاککردنەوە و ڕووخاندن لێرەن."

func manage(action: String) -> void:
	if not started or paused or chosen!="inspect":
		return
	var b=sim.at_building(placement)
	if b.is_empty():
		ui.notice.text="سەرەتا بینایەک هەڵبژێرە."
		return
	if action=="demolish":
		if demolition_id!=b.id or Time.get_ticks_msec()>demolition_until:
			demolition_id=b.id
			demolition_until=Time.get_ticks_msec()+5000
			ui.notice.text="بۆ ڕووخاندن دووبارە دابگرە؛ تا نیوەی تێچوو دەگەڕێتەوە."
			return
		demolition_id=-1
	var ok=false
	if action=="demolish":
		ok=sim.demolish(placement)
	elif action=="repair":
		ok=sim.repair(placement)
	else:
		ok=sim.toggle_gate(placement)
	ui.notice.text="فەرمانەکە جێبەجێ کرا." if ok else "نەکرا: دوژمن، کەمی سەرچاوە، یان دەروازەی داگیرکراو بپشکنە."

func train() -> void:
	if started and not paused:
		ui.notice.text="سەربازێک ئامادە کرا." if sim.train() else "سەربازگە، شوێنی بەتاڵی نیشتەجێبوون، ٢٠ زێڕ و ٢ نان پێویستە."

func save_game() -> void:
	if started:
		ui.notice.text="پاشەکەوت کرا." if sim.save_game() else "پاشەکەوت نەکرا؛ بۆشایی ئامێرەکە بپشکنە."

func toggle_pause() -> void:
	paused=not paused
	ui.notice.text="یاری وەستێنراوە." if paused else "یاری بەردەوامە."

func toggle_sound() -> void:
	sound=not sound
	if sound:
		audio.play()
	else:
		audio.stop()
	set_quality(quality_index)

func set_quality(index: int) -> void:
	quality_index=clampi(index,0,2)
	world.set_quality(quality_index)
	var prefs=ConfigFile.new()
	prefs.set_value("graphics","quality",quality_index)
	prefs.set_value("audio","enabled",sound)
	prefs.save("user://castle-settings.cfg")

func zoom(amount: float) -> void:
	target_distance=clampf(target_distance+amount,28,100)

func locate() -> void:
	focus=Vector3(-2,0,-5)
	target_distance=58

func select_world(point: Vector2) -> void:
	if paused or not sim.ended.is_empty():
		return
	var hit=Plane(Vector3.UP,0).intersects_ray(camera.project_ray_origin(point),camera.project_ray_normal(point))
	if hit==null:
		return
	var cell=CastleSim.cell(hit)
	if chosen.is_empty():
		sim.order(cell)
	else:
		placement=cell
		demolition_id=-1

func pan(delta: Vector2) -> void:
	var right=camera.global_basis.x
	var forward=camera.global_basis.z
	right.y=0
	forward.y=0
	focus-=right.normalized()*delta.x*distance*.0014
	focus-=forward.normalized()*delta.y*distance*.0014
	focus.x=clampf(focus.x,-46,46)
	focus.z=clampf(focus.z,-46,46)

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device==InputEvent.DEVICE_ID_EMULATION:
		return
	if not started:
		return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:
			zoom(-4)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			zoom(4)
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				mouse_drag=true
				dragging=false
				pointer_down=event.position
			else:
				if mouse_drag and not dragging:
					select_world(event.position)
				mouse_drag=false
	elif event is InputEventMouseMotion and mouse_drag:
		if event.position.distance_to(pointer_down)>8:
			dragging=true
		if dragging:
			pan(event.relative)
	elif event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index]=event.position
			pointer_down=event.position
			dragging=touches.size()>1
			if touches.size()==2:
				last_pinch=touches.values()[0].distance_to(touches.values()[1])
		else:
			if not dragging and touches.size()==1:
				select_world(event.position)
			touches.erase(event.index)
	elif event is InputEventScreenDrag:
		touches[event.index]=event.position
		if touches.size()==2:
			dragging=true
			var span=touches.values()[0].distance_to(touches.values()[1])
			zoom((last_pinch-span)*.08)
			last_pinch=span
		else:
			if event.position.distance_to(pointer_down)>8:
				dragging=true
			if dragging:
				pan(event.relative)
	elif event is InputEventKey and event.pressed:
		if event.keycode==KEY_ESCAPE:
			toggle_pause()
		elif event.keycode==KEY_ENTER:
			confirm_build()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_WM_CLOSE_REQUEST] and started:
		sim.save_game()
		paused=true
