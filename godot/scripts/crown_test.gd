extends SceneTree
func _initialize() -> void:call_deferred("run")
func feed(sim: CrownSim) -> void:
	while sim.state.food<15 and sim.state.gold>=20:assert(sim.buy_food())
func run() -> void:
	var sim=CrownSim.new()
	assert(sim.rank()==0 and sim.count()==0 and sim.state.homes.is_empty() and sim.state.governed==-1)
	assert(not sim.petition() and not sim.attack() and not sim.swear())
	for i in 10:
		feed(sim);assert(sim.work())
	assert(sim.rank()==1)
	assert(sim.recruit() and sim.count()==3)
	# Earn progression through actual work and courier actions, not edited renown.
	for i in 12:
		feed(sim)
		assert(sim.take_contract("courier"))
		assert(sim.travel(sim.state.contract.destination))
		assert(sim.deliver())
	assert(sim.state.completed==12 and sim.state.renown>=80)
	if sim.state.location!=0:assert(sim.travel(0))
	assert(sim.audience())
	var renown=sim.state.renown
	assert(sim.audience() and sim.state.renown==renown,"Repeated court visits cannot farm the first-audience reward")
	assert(sim.swear() and sim.rank()==2)
	feed(sim);assert(sim.buy_home() and sim.rank()==3)
	assert(sim.petition() and sim.rank()==4)
	assert(sim.travel(1))
	var houses=sim.state.houses[1]
	assert(sim.build_housing() and sim.state.houses[1]==houses+4)
	assert(sim.save("user://crown-test.json"))
	var restored=CrownSim.new()
	assert(restored.restore("user://crown-test.json") and restored.state==sim.state)
	var bad=sim.state.duplicate(true);bad.gold=-1;assert(not CrownSim.valid(bad))
	bad=sim.state.duplicate(true);bad.party.levy=100000;assert(not CrownSim.valid(bad))
	bad=sim.state.duplicate(true);bad.owners[0]=99;assert(not CrownSim.valid(bad))
	bad=sim.state.duplicate(true);bad.homes.append(bad.homes[0]);assert(not CrownSim.valid(bad))
	var hungry=CrownSim.new();hungry.state.party.levy=3;hungry.state.food=0;hungry.advance();assert(hungry.count()==2)
	var expiry=CrownSim.new();expiry.take_contract("courier");expiry.advance(13);assert(expiry.state.contract.is_empty())
	var battle=CrownSim.new();battle.state.oath=0;battle.state.renown=30;battle.state.location=4;battle.state.party.guard=20;battle.state.food=100
	assert(battle.attack() and battle.owner()==0)
	assert(not battle.attack(),"Cannot attack a friendly castle")
	var peaceful=CrownSim.new();peaceful.state.wars=[false,false];peaceful.state.oath=0;peaceful.state.renown=30;peaceful.state.party.guard=20;peaceful.state.location=4
	assert(not peaceful.attack())
	var pack=CrownStory.load_pack();assert(CrownStory.valid(pack))
	var broken=pack.duplicate(true);broken.chapters[0].text="x".repeat(801);assert(not CrownStory.valid(broken))
	broken=pack.duplicate(true);broken.chapters[1].id=broken.chapters[0].id;assert(not CrownStory.valid(broken))
	# Real HTTP/RLS public-content request. Offline fallback is independently exercised by capture.
	var cloud=CrownCloud.new();root.add_child(cloud);cloud.refresh()
	var response=await cloud.completed
	assert(response[0],response[1])
	assert(CrownStory.load_pack().revision>=2)
	cloud.queue_free()
	var game=load("res://campaign.tscn").instantiate();root.add_child(game)
	await process_frame;await process_frame
	var points={"viewport":[root.size.x,root.size.y]}
	for key in ["work","food","save","castle","tab_army","map","story"]:
		var b=game.buttons[key];assert(root.get_visible_rect().encloses(b.get_global_rect()),"Campaign action outside physical viewport: "+key)
		var p=b.get_global_rect().get_center();points[key]=[p.x,p.y]
	var before=game.sim.state.gold
	await tap(game.buttons.work.get_global_rect().get_center())
	assert(game.sim.state.gold==before+35 and game.sim.state.day==2)
	await tap(game.buttons.tab_army.get_global_rect().get_center())
	var recruit=game.buttons.recruit.get_global_rect().get_center();points.recruit=[recruit.x,recruit.y]
	await tap(recruit);assert(game.sim.count()==3)
	await tap(game.buttons.map.get_global_rect().get_center())
	var p=game.map.get_global_rect().position+game.map.point(game.sim.world.settlements[0]);points.capital=[p.x,p.y]
	await tap(p);assert(game.picked==0)
	var travel=game.buttons.travel.get_global_rect().get_center();points.travel=[travel.x,travel.y]
	await tap(travel);assert(game.sim.state.location==0)
	for key in ["tab_court","tab_quest"]:
		await tap(game.buttons[key].get_global_rect().get_center())
		for child in game.actions.get_children():assert(root.get_visible_rect().encloses(child.get_global_rect()))
	var output=FileAccess.open("/tmp/crown-touch-points.json",FileAccess.WRITE);output.store_string(JSON.stringify(points));output.close()
	var target=Vector2i(32,34)
	assert(not game.town.navigation.is_point_solid(target))
	game.town.path=game.town.navigation.get_id_path(Vector2i(30,34),target)
	for i in 30:game.town._process(.1)
	assert(game.town.hero_position.x>0,"Avatar must actually walk in the town")
	game.queue_free();await process_frame
	DirAccess.remove_absolute(CrownSim.SAVE)
	print("IRON_CROWN_TEST_PASS");quit()
func tap(point: Vector2) -> void:
	for pressed in [true,false]:
		var event=InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=pressed;Input.parse_input_event(event);Input.flush_buffered_events();await process_frame
	await process_frame
