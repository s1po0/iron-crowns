class_name CastleMapsTest
extends RefCounted
static func run() -> void:
	var signatures=[]
	for id in CastleMissions.IDS:
		var sim=CastleSim.new(id)
		var signature=""
		for y in CastleSim.SIZE:
			for x in CastleSim.SIZE:
				var p=Vector2i(x,y)
				var blocked=CastleMissions.blocked(p,id)
				signature+="1" if blocked else "0"
				if sim.at_building(p).is_empty():
					assert(sim.navigation.is_point_solid(p)==blocked,"Visual map mask and pathfinding must agree")
		assert(not signature in signatures,"Maps must differ in navigable layout, not just name")
		signatures.append(signature)
		for key in ["wood","quarry","spawn"]:
			var p=CastleMissions.point(id,key)
			var path=sim.navigation.get_id_path(p,Vector2i(21,17))
			assert(not path.is_empty() and path[-1]==Vector2i(21,17),"Resource and attack locations must connect to the keep")
		assert(not sim.terrain_blocked(Vector2i(CastleMissions.bridge_center(id))))
		sim.resources.wood=2000
		sim.resources.stone=2000
		for entry in [["stockpile",14,20],["woodcutter",14,12],["farm",23,19],["mill",23,23],["bakery",26,23],["quarry",23,28]]:
			assert(sim.place(entry[0],Vector2i(entry[1],entry[2])))
		for i in 2000:
			sim.step(.2)
		assert(sim.baked>0 and sim.deliveries>0,"Every map must support a real production chain")
		var path="user://map-"+id+".json"
		assert(sim.save_game(path))
		var restored=CastleSim.new()
		assert(restored.load_game(path) and restored.mission_id==id and restored.baked==sim.baked)
		var bad=JSON.parse_string(FileAccess.get_file_as_string(path))
		bad.mission_id="unknown"
		assert(not CastleSim.valid(bad))
		if id=="valley":
			var legacy=JSON.parse_string(FileAccess.get_file_as_string(path))
			legacy.schema=2
			legacy.erase("mission_id")
			var file=FileAccess.open("user://map-legacy-v2.json",FileAccess.WRITE)
			file.store_string(JSON.stringify(legacy))
			file.close()
			assert(restored.load_game("user://map-legacy-v2.json") and restored.mission_id=="valley")
			assert(FileAccess.file_exists("user://map-legacy-v2.json.v2-backup"))
		var battle=CastleSim.new(id)
		battle.spawn_wave()
		assert(battle.units.size()==CastleMissions.data(id).waves[0])
		for u in battle.units:
			assert(not battle.terrain_blocked(Vector2i(u.at)))
		print("IRON_MAP_TEST_PASS "+id)
