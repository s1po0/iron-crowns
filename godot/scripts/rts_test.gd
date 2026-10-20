extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
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
	game.queue_free()
	await process_frame
	print("IRON_RTS_TEST_PASS")
	quit()
