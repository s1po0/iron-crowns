extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var args=OS.get_cmdline_user_args()
	assert(args.size()==2)
	var error=await RealmRegions.install(args[0],self)
	assert(error.is_empty(),error)
	assert(RealmRegions.texture(12,12,"albedo",0).get_width()==512)
	assert(RealmRegions.texture(12,12,"normal",1).get_width()==1024)
	var original=RealmRegions.generation
	# Damage a small fixture without loading the production region into memory.
	var bytes=FileAccess.get_file_as_bytes(args[1])
	bytes[bytes.size()-1]^=1
	var corrupt=FileAccess.open("user://broken.icregion",FileAccess.WRITE)
	corrupt.store_buffer(bytes)
	corrupt.close()
	assert(not (await RealmRegions.install("user://broken.icregion",self)).is_empty())
	assert(RealmRegions.generation==original)
	assert(RealmRegions.texture(12,12,"albedo",1)!=null)
	var sim=CastleSim.new("realm_valley")
	assert(sim.grid_size*sim.grid_size==CastleSim.SIZE*CastleSim.SIZE*100)
	var site=CastleMissions.outposts(sim.mission_id)[0]
	for i in 3:
		sim.add_unit("soldier",site+Vector2i(i,0))
	sim.order(site)
	var wood=sim.resources.wood
	sim.step(.1)
	assert(sim.claimed==[0] and sim.resources.wood==wood+120)
	sim.step(.1)
	assert(sim.resources.wood==wood+120,"Outpost reward must not be farmable")
	assert(sim.save_game("user://realm-save.json"))
	var restored=CastleSim.new()
	assert(restored.load_game("user://realm-save.json") and restored.claimed==[0] and restored.grid_size==400)
	var terrain=RealmTerrain.new()
	root.add_child(terrain)
	terrain.setup(sim.mission_id)
	for i in 30:
		terrain.stream(CastleSim.world(Vector2(198,196)),0)
		await process_frame
	assert(terrain.loaded.size()==25)
	terrain.stream(CastleSim.world(Vector2(350,350)),0)
	await process_frame
	assert(terrain.loaded.size()==1,"Distant chunks/textures must unload")
	print("IRON_REALM_TEST_PASS")
	quit()
