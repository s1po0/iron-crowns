class_name CastleCampaignTest
extends RefCounted

static func run() -> void:
	var sim=CastleSim.new()
	sim.resources.wood=2000
	sim.resources.stone=2000
	sim.resources.gold=2000
	sim.resources.bread=500
	assert(sim.capacity()==8 and sim.population()==0)
	assert(sim.place("barracks",Vector2i(23,17)))
	sim.buildings[-1].built=1
	for i in 8:
		assert(sim.train())
	var gold=sim.resources.gold
	assert(not sim.train() and sim.resources.gold==gold,"Full housing cannot consume recruiting costs")
	assert(sim.place("house",Vector2i(12,20)))
	assert(sim.capacity()==8,"Unfinished housing gives no capacity")
	sim.buildings[-1].built=1
	assert(sim.capacity()==12 and sim.train())
	assert(sim.demolish(Vector2i(12,20)))
	assert(sim.population()==9 and sim.capacity()==8 and not sim.train(),"Housing loss preserves existing people but blocks recruitment")
	assert(not sim.demolish(Vector2i(18,16)),"Keep cannot be demolished")
	assert(sim.place("gate",Vector2i(25,12)))
	sim.buildings[-1].built=1
	assert(not sim.navigation.is_point_solid(Vector2i(25,12)))
	assert(sim.toggle_gate(Vector2i(25,12)))
	assert(sim.navigation.is_point_solid(Vector2i(25,12)))
	assert(sim.toggle_gate(Vector2i(25,12)))
	sim.add_unit("soldier",Vector2i(25,12))
	assert(not sim.toggle_gate(Vector2i(25,12)),"Closing a gate cannot trap a unit")
	sim.units.pop_back()
	assert(sim.toggle_gate(Vector2i(25,12)))
	var gate=sim.at_building(Vector2i(25,12))
	gate.hp=100
	var stone=sim.resources.stone
	var wood=sim.resources.wood
	assert(sim.repair(Vector2i(25,12)))
	assert(gate.hp==180 and sim.resources.stone==stone-4 and sim.resources.wood==wood-2)
	sim.add_unit("raider",Vector2i(26,12))
	gate.hp=100
	assert(not sim.repair(Vector2i(25,12)) and not sim.demolish(Vector2i(25,12)),"No instant repairs/demolition beside attackers")
	sim.units.pop_back()
	sim.morale=68
	sim.wave=1
	sim.wave_clock=37.5
	assert(sim.save_game("user://campaign-test.json"))
	var loaded=CastleSim.new()
	assert(loaded.load_game("user://campaign-test.json"))
	assert(loaded.morale==68 and loaded.wave_clock==37.5)
	assert(loaded.navigation.is_point_solid(Vector2i(25,12)),"Closed gate survives save/load")
	var raw=JSON.parse_string(FileAccess.get_file_as_string("user://campaign-test.json"))
	raw.buildings[-1].open="false"
	assert(not CastleSim.valid(raw))
	raw.buildings[-1].open=false
	raw.wave_clock=-1
	assert(not CastleSim.valid(raw))
	raw.wave_clock=30
	raw.stage=3.5
	assert(not CastleSim.valid(raw))
	raw.stage=0
	raw.schema=1
	raw.erase("wave_clock")
	raw.erase("morale")
	for b in raw.buildings:
		b.erase("open")
	var file=FileAccess.open("user://campaign-legacy.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(raw))
	file.close()
	assert(loaded.load_game("user://campaign-legacy.json"))
	assert(loaded.morale==100 and not loaded.navigation.is_point_solid(Vector2i(25,12)),"v1 gates migrate as open")
	var famine=CastleSim.new()
	famine.resources.bread=0
	for i in 5:
		famine.food_clock=30
		famine.step(.1)
	assert(famine.morale==20 and famine.resources.bread==0)
	famine.resources.bread=10
	famine.food_clock=30
	famine.step(.1)
	assert(famine.morale==28,"Food restores morale")
	var waves=CastleSim.new()
	waves.stage=8
	waves.step(.1)
	assert(waves.wave==1 and waves.units.size()==8)
	for number in 3:
		for u in waves.units:
			u.hp=0
		waves.step(.1)
		if number<2:
			assert(waves.ended.is_empty() and waves.wave==number+1)
			var reward=waves.resources.gold
			waves.step(.1)
			assert(waves.resources.gold==reward,"Rest reward paid once only")
			waves.wave_clock=.05
			waves.step(.1)
			assert(waves.wave==number+2 and waves.units.size()==CastleSim.WAVE_SIZES[number+1])
		else:
			assert(waves.ended=="victory" and waves.stage==9)
	var defeat=CastleSim.new()
	defeat.stage=8
	defeat.wave=3
	defeat.buildings[0].hp=0
	defeat.step(.1)
	assert(defeat.ended=="defeat","Keep destruction takes precedence over wave victory")
	assert(defeat.save_game("user://campaign-defeat.json"))
	assert(CastleSim.new().load_game("user://campaign-defeat.json"))
	print("IRON_RTS_CAMPAIGN_TEST_PASS")
