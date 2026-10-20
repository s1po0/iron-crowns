extends Node3D
var sim=CastleSim.new("realm_valley")
var world=CastleWorld.new()
var ui=CastleUI.new()
var camera=Camera3D.new()
var ghost: MeshInstance3D
var focus=Vector3(-2,0,-5)
var distance=58.0
var target_distance=58.0
var chosen="stockpile"
var placement=Vector2i(15,20)
var placement_selected=false
var started=false
var paused=false
var quality_index=0
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
var selected_mission="realm_valley"
var end_save_attempted=false
var speed=1
var region_importing=false
var region_picker: FileDialog

func _ready() -> void:
	# Native Control widgets need emulated mouse clicks; map gestures handle raw touches separately.
	Input.emulate_mouse_from_touch=true
	var prefs=ConfigFile.new()
	if prefs.load("user://castle-settings.cfg")==OK:
		quality_index=clampi(int(prefs.get_value("graphics","quality",0)),0,2)
		sound=bool(prefs.get_value("audio","enabled",true))
	add_child(world)
	world.setup(sim.mission_id)
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
	if Engine.has_singleton("DataPicker"):
		var native=Engine.get_singleton("DataPicker")
		native.connect("region_selected",region_selected)
		native.connect("regions_finished",func():
			region_importing=false
			ui.notice.text="Data دامەزرا؛ بۆ یاری «بەردەوام بە» دابگرە.")
		native.connect("region_error",func(message):
			region_importing=false
			ui.notice.text=message)
	locate()
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
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mission="):
			var id=arg.trim_prefix("--mission=")
			if CastleMissions.exists(id):
				select_mission(CastleMissions.IDS.find(id))
	if "--rts-capture" in OS.get_cmdline_user_args():
		new_game()
		sim.resources.wood=1000
		sim.resources.stone=1000
		for entry in [["stockpile",14,20],["woodcutter",12,12],["farm",14,26],["mill",19,24],["bakery",23,23],["barracks",23,17],["house",17,29],["wall",22,12],["wall",23,12],["wall",24,12],["gate",25,12]]:
			sim.place(entry[0],Vector2i(entry[1],entry[2])+CastleMissions.keep(sim.mission_id)-Vector2i(18,16))
		for b in sim.buildings:
			b.built=1.0
		sim.resources.bread=100
		for i in 6:
			sim.train()
		sim.order(Vector2i(24,14)+CastleMissions.keep(sim.mission_id)-Vector2i(18,16))
	world.sync(sim,0)
	print("IRON_RTS_READY")

func _process(dt: float) -> void:
	distance=lerpf(distance,target_distance,minf(1,dt*8))
	camera.position=focus+Vector3(distance*.55,distance*.8,distance*.65)
	camera.look_at(focus)
	world.stream(focus)
	if started and not paused:
		for tick in speed:
			sim.step(dt)
		if not sim.ended.is_empty() and not end_save_attempted:
			end_save_attempted=true
			if not sim.save_game():
				ui.notice.text="ئەنجامی میشن پاشەکەوت نەکرا؛ بۆشایی ئامێرەکەت بپشکنە."
		world.sync(sim,dt)
		autosave+=dt
		if autosave>30:
			autosave=0
			sim.save_game()
	ui.update(sim)
	ghost.visible=started and placement_selected and CastleSim.FOOTPRINT.has(chosen) and sim.ended.is_empty()
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
	end_save_attempted=false
	started=false
	if FileAccess.file_exists(CastleSim.SAVE):
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(CastleSim.SAVE),ProjectSettings.globalize_path(CastleSim.SAVE+".previous"))!=OK:
			ui.intro.show()
			ui.notice.text="کۆپیی پاراستن دروست نەکرا؛ پاشەکەوتی کۆن نەگۆڕدرا. بۆشایی ئامێرەکەت بپشکنە."
			return
	started=true
	ui.intro.hide()

func rebuild_world() -> void:
	remove_child(world)
	world.queue_free()
	world=CastleWorld.new()
	add_child(world)
	world.setup(sim.mission_id)
	world.set_quality(quality_index)
	world.sync(sim,0)

func select_mission(index: int) -> void:
	if started or index<0 or index>=CastleMissions.IDS.size():
		return
	selected_mission=CastleMissions.IDS[index]
	sim=CastleSim.new(selected_mission)
	rebuild_world()
	ui.refresh_briefing()
	locate()

func restart() -> void:
	started=false
	paused=false
	autosave=0
	placement_selected=false
	chosen="stockpile"
	ui.finish.text=""
	ui.notice.text=""
	sim=CastleSim.new(selected_mission)
	rebuild_world()
	locate()
	ui.refresh_briefing()
	ui.intro.show()

func next_mission() -> void:
	var index=CastleMissions.IDS.find(sim.mission_id)+1
	if sim.ended!="victory" or index>=CastleMissions.IDS.size():
		return
	restart()
	select_mission(index)

func resume() -> void:
	if not sim.load_game():
		ui.notice.text="پاشەکەوتەکە ناگونجێت؛ گوندێکی نوێ دەست پێ بکە."
		return
	selected_mission=sim.mission_id
	rebuild_world()
	started=true
	locate()
	ui.intro.hide()

func choose(kind: String) -> void:
	placement_selected=false
	chosen=kind
	demolition_id=-1

func choose_rally() -> void:
	chosen=""
	ui.notice.text="شوێنی کۆبوونەوەی سوپا لە نەخشە دابگرە."

func placement_message() -> String:
	if not CastleSim.COSTS.has(chosen):
		return "سەرەتا جۆری بینا هەڵبژێرە."
	if paused:
		return "یاری وەستاوە؛ «بەردەوام بە» دابگرە."
	var cost: Array=CastleSim.COSTS[chosen]
	if sim.resources.wood<cost[0] or sim.resources.stone<cost[1]:
		return "سەرچاوە بەس نییە: %d دار و %d بەرد پێویستە." % [cost[0],cost[1]]
	if not placement_selected:
		return "شوێنێک لە نەخشە دابگرە، یان «شوێنی گونجاو» هەڵبژێرە."
	if not sim.can_build(chosen,placement):
		return "ئەم شوێنە ناگونجێت: ئاو، بینا یان یەکەیەکی لێیە؛ شوێنێکی تر هەڵبژێرە."
	return "شوێنەکە گونجاوە — «دروست بکە» دابگرە."

func suggest_site() -> void:
	if not started or paused or not sim.ended.is_empty() or not CastleSim.COSTS.has(chosen):
		return
	var cost: Array=CastleSim.COSTS[chosen]
	if sim.resources.wood<cost[0] or sim.resources.stone<cost[1]:
		ui.notice.text=placement_message()
		return
	var center=CastleSim.cell(focus)
	for radius in range(0,mini(40,sim.grid_size)):
		for y in range(center.y-radius,center.y+radius+1):
			for x in range(center.x-radius,center.x+radius+1):
				if maxi(absi(x-center.x),absi(y-center.y))!=radius:
					continue
				var p=Vector2i(x,y)
				if sim.can_build(chosen,p):
					placement=p
					placement_selected=true
					focus=CastleSim.world(Vector2(p)+Vector2.ONE*(CastleSim.FOOTPRINT[chosen]-1)*.5)
					ui.notice.text="شوێنێکی گونجاو هەڵبژێردرا؛ بۆ بنیاتنان «دروست بکە» دابگرە."
					return
	ui.notice.text="شوێنی بەتاڵی گونجاو نەدۆزرایەوە."

func cancel_build() -> void:
	choose("")
	ui.notice.text="بنیاتنان هەڵوەشێنرایەوە؛ هیچ سەرچاوەیەک کەم نەکرا."

func confirm_build() -> void:
	if not started or paused or not sim.ended.is_empty() or not CastleSim.COSTS.has(chosen):
		return
	if not placement_selected or not sim.can_build(chosen,placement):
		ui.notice.text=placement_message()
		return
	if sim.place(chosen,placement):
		ui.notice.text=CastleUI.NAMES[chosen]+" — بنیاتنان دەستی پێ کرد (٨ چرکە)."
		placement_selected=false

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
	focus=CastleSim.world(Vector2(CastleMissions.keep(sim.mission_id))+Vector2(1,2))
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
		placement_selected=true
		demolition_id=-1

func pan(delta: Vector2) -> void:
	var right=camera.global_basis.x
	var forward=camera.global_basis.z
	right.y=0
	forward.y=0
	focus-=right.normalized()*delta.x*distance*.0014
	focus-=forward.normalized()*delta.y*distance*.0014
	focus.x=clampf(focus.x,-46,(sim.grid_size-24)*3.0)
	focus.z=clampf(focus.z,-46,(sim.grid_size-24)*3.0)

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

func toggle_speed() -> void:
	speed=4 if speed==1 else 1
	ui.notice.text="خێرایی: %d×" % speed

func import_region() -> void:
	if region_importing:
		return
	paused=true
	region_importing=true
	ui.notice.text="فایلی .icregion هەڵبژێرە؛ ناوەڕاست: Realm-Region-2-2. دوای پشکنین بەردەوام بە."
	if Engine.has_singleton("DataPicker"):
		Engine.get_singleton("DataPicker").selectRegion()
	else:
		if region_picker==null:
			region_picker=FileDialog.new()
			region_picker.access=FileDialog.ACCESS_FILESYSTEM
			region_picker.file_mode=FileDialog.FILE_MODE_OPEN_FILE
			region_picker.filters=PackedStringArray(["*.icregion ; Realm terrain region"])
			region_picker.file_selected.connect(region_selected)
			region_picker.canceled.connect(func():region_importing=false)
			add_child(region_picker)
		region_picker.popup_centered(Vector2i(900,550))

func region_selected(path: String) -> void:
	ui.notice.text="پشکنینی SHA-256 و دامەزراندنی زەوی…"
	var error=await RealmRegions.install(path,get_tree())
	if path.ends_with("selected-region.part"):
		DirAccess.remove_absolute(path)
	if error.is_empty():
		print("IRON_REGION_INSTALLED")
	if Engine.has_singleton("DataPicker"):
		Engine.get_singleton("DataPicker").nextRegion(error.is_empty())
	else:
		region_importing=false
	if not error.is_empty():
		region_importing=false
	ui.notice.text="Data دامەزرا؛ بۆ یاری «بەردەوام بە» دابگرە." if error.is_empty() else error
