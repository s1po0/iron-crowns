extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var args=OS.get_cmdline_user_args()
	assert(args.size()==1)
	var bundle=ContentBundle.new()
	assert(await bundle.install(args[0],self,func(_n):pass),bundle.error)
	assert(bundle.manifest.api==3 and bundle.manifest.files.size()==1306)
	assert(await bundle.installed(self))
	assert(ContentBundle.complete)
	for cell in [Vector2i(0,0),Vector2i(12,12),Vector2i(24,24)]:
		for kind in ["albedo","normal"]:
			assert(RealmRegions.texture(cell.x,cell.y,kind,0).get_width()==512)
	var bad=bundle.manifest.duplicate(true)
	bad.files.pop_back()
	assert(not bundle.validate_manifest(bad))
	bad=bundle.manifest.duplicate(true)
	bad.files[-1].path="assets/content/realm/../escape.webp"
	assert(not bundle.validate_manifest(bad))
	var before=FileAccess.get_file_as_string(ContentBundle.ACTIVE)
	var invalid=FileAccess.open("user://broken-complete.icdata",FileAccess.WRITE)
	invalid.store_buffer("ICDATA03".to_utf8_buffer())
	invalid.store_32(999999)
	invalid.close()
	assert(not await bundle.install("user://broken-complete.icdata",self,func(_n):pass))
	assert(FileAccess.get_file_as_string(ContentBundle.ACTIVE)==before)
	# Do not leave an extra 1.7 GB test installation beside the emulator.
	bundle.remove_directory(ContentAssets.directory)
	DirAccess.remove_absolute(ContentBundle.ACTIVE)
	ContentAssets.directory=""
	ContentBundle.complete=false
	print("IRON_COMPLETE_DATA_TEST_PASS")
	quit()
