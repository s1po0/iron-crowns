extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	CastleCampaignTest.run()
	CastleMapsTest.run()
	var sim=CastleSim.new()
	assert(not sim.can_build("farm",Vector2i(31,10)))
	assert(not sim.place("stockpile",Vector2i(18,16)))
	assert(sim.place("stockpile",Vector2i(14,20)))
	var wood=sim.resources.wood
	assert(not sim.place("farm",Vector2i(14,20)))
	assert(sim.resources.wood==wood)
	assert(sim.place("woodcutter",Vector2i(12,12)))
	assert(sim.place("farm",Vector2i(14,26)))
	assert(sim.place("mill",Vector2i(19,24)))
	assert(sim.place("bakery",Vector2i(23,23)))
	for i in 2000:
		sim.step(.1)
	assert(sim.deliveries>0 and sim.baked>0,"Production chain must deliver real bread")
	assert(sim.save_game("user://rts-test.json"))
	var restored=CastleSim.new()
	assert(restored.load_game("user://rts-test.json"))
	assert(restored.baked==sim.baked and restored.resources==sim.resources)
	assert(not CastleSim.valid({"schema":99}))
	assert(sim.place("barracks",Vector2i(23,17)))
	for i in 100:
		sim.step(.1)
	sim.resources.bread=50
	sim.resources.gold=300
	assert(sim.train())
	assert(sim.order(Vector2i(25,14)))
	assert(not sim.order(Vector2i(31,10)))
	var enemy=sim.units[-1]
	sim.add_unit("raider",Vector2i(26,14))
	for i in 500:
		sim.step(.1)
	assert(sim.kills>0,"Soldiers must actually attack hostile parties")
	var game=load("res://rts.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	assert(Input.emulate_mouse_from_touch,"RTS Controls need touch-to-button translation")
	var column=game.ui.intro.get_child(0)
	var start_button=column.get_child(column.get_child_count()-1)
	print("Touch startup: button=",start_button.get_global_rect()," viewport=",root.get_visible_rect())
	for pressed in [true,false]:
		var touch=InputEventScreenTouch.new()
		touch.index=0
		touch.position=start_button.get_global_rect().get_center()
		touch.pressed=pressed
		Input.parse_input_event(touch)
		Input.flush_buffered_events()
		await process_frame
	assert(game.started,"A real touch event must activate New Game")
	await process_frame
	await process_frame
	var farm_button=game.ui.building_buttons["farm"]
	assert(farm_button.is_visible_in_tree() and root.get_visible_rect().encloses(farm_button.get_global_rect()),"Farm choice must be on screen, not in a hidden carousel")
	await tap(farm_button.get_global_rect().get_center())
	assert(game.chosen=="farm" and game.ui.build_button.is_visible_in_tree())
	var points={"viewport":[root.size.x,root.size.y]}
	for entry in [["start",start_button],["farm",farm_button],["build",game.ui.build_button],["suggest",game.ui.suggest_button],["save",game.ui.save_button],["mission",game.ui.mission_buttons[1]]]:
		var pos=entry[1].get_global_rect().get_center()
		points[entry[0]]=[pos.x,pos.y]
	var point_file=FileAccess.open("/tmp/rts-touch-points.json",FileAccess.WRITE)
	point_file.store_string(JSON.stringify(points))
	point_file.close()
	assert(not game.ui.build_button.disabled,"Invalid placement must explain itself, not hide the command")
	var original_wood=game.sim.resources.wood
	await tap(game.ui.build_button.get_global_rect().get_center())
	assert(game.sim.buildings.size()==1 and game.sim.resources.wood==original_wood,"Confirm without a location must not charge or build")
	var candidate=Vector2i(-1,-1)
	var screen=Vector2.ZERO
	for y in range(6,29):
		for x in range(6,29):
			var p=Vector2i(x,y)
			var projected=game.camera.unproject_position(CastleSim.world(Vector2(p)))
			if game.sim.can_build("farm",p) and Rect2(30,185,1220,160).has_point(projected) and not game.ui.minimap.get_global_rect().has_point(projected):
				candidate=p
				screen=projected
				break
		if candidate.x>=0:
			break
	assert(candidate.x>=0,"Fixture needs a genuinely visible empty plot")
	await tap(screen)
	assert(game.placement_selected and game.placement==candidate,"Raw map touch must select the actual plot")
	await tap(game.ui.build_button.get_global_rect().get_center())
	assert(game.sim.buildings.size()==2 and game.sim.buildings[-1].kind=="farm","Touch-only farm choice > map > Build must create a farm")
	assert(game.sim.resources.wood==original_wood-35)
	await tap(game.ui.build_button.get_global_rect().get_center())
	assert(game.sim.buildings.size()==2,"Repeated confirmation cannot charge twice")
	await tap(farm_button.get_global_rect().get_center())
	await tap(game.ui.suggest_button.get_global_rect().get_center())
	assert(game.placement_selected and game.sim.can_build("farm",game.placement))
	await tap(game.ui.cancel_button.get_global_rect().get_center())
	assert(game.chosen=="" and game.sim.buildings.size()==2 and game.sim.resources.wood==original_wood-35)
	await tap(farm_button.get_global_rect().get_center())
	await tap(game.ui.suggest_button.get_global_rect().get_center())
	await tap(game.ui.build_button.get_global_rect().get_center())
	assert(game.sim.buildings.size()==3 and game.sim.resources.wood==original_wood-70,"Suggested plot must build through touch controls too")
	await tap(game.ui.minimap.get_global_rect().position+Vector2(120,40))
	assert(game.focus.distance_to(CastleSim.world(Vector2(30,10)))<.1,"Minimap touch must move camera, not place a building")
	assert(game.sim.buildings.size()==3)
	game.locate()
	print("IRON_RTS_TOUCH_FARM_BUILD_PASS")
	assert(game.sim.place("gate",Vector2i(25,12)))
	game.sim.buildings[-1].built=1
	game.inspect()
	game.placement=Vector2i(25,12)
	await process_frame
	await process_frame
	var gate_button=game.ui.management.get_child(0)
	assert(gate_button.is_visible_in_tree())
	for pressed in [true,false]:
		var touch=InputEventScreenTouch.new()
		touch.index=0
		touch.position=gate_button.get_global_rect().get_center()
		touch.pressed=pressed
		Input.parse_input_event(touch)
		Input.flush_buffered_events()
		await process_frame
	assert(game.sim.navigation.is_point_solid(Vector2i(25,12)),"Touch management button must really close the selected gate")
	game.paused=true
	game.manage("gate")
	assert(game.sim.navigation.is_point_solid(Vector2i(25,12)),"Paused management cannot alter simulation")
	game.queue_free()
	await process_frame
	print("IRON_RTS_TEST_PASS")
	quit()

func tap(point: Vector2) -> void:
	for pressed in [true,false]:
		var touch=InputEventScreenTouch.new()
		touch.index=0
		touch.position=point
		touch.pressed=pressed
		Input.parse_input_event(touch)
		Input.flush_buffered_events()
		await process_frame
	await process_frame
