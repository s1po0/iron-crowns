extends SceneTree

func _initialize() -> void:
	call_deferred("test_bundle")

func test_bundle() -> void:
	var source = OS.get_environment("IRON_TEST_DATA")
	assert(FileAccess.file_exists(source),"Content test fixture missing")
	var bundle = ContentBundle.new()
	assert(await bundle.install(source,self,func(_percent): pass),bundle.error)
	assert(await bundle.installed(self),"Installed content validation failed")
	assert(ContentAssets.mesh("res://assets/content/humans/human-head.obj").get_surface_count()>0,"Runtime raw OBJ loading failed")
	var normals = ContentAssets.mesh("res://assets/content/humans/human-head.obj").surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	assert(not normals.is_empty(),"Human mesh normals missing")
	var normal_length = 0.0
	for normal in normals:
		normal_length += normal.length()
	assert(normal_length/normals.size()>.95,"Human mesh normals invalid")
	assert(ContentAssets.audio("res://assets/audio/step.wav")!=null,"Runtime raw WAV loading failed")
	assert(ContentAssets.texture("res://assets/materials/meadow.jpg")!=null,"Runtime raw image loading failed")
	var original = FileAccess.get_file_as_string(ContentBundle.ACTIVE)
	var corrupt = FileAccess.get_file_as_bytes(source)
	corrupt[corrupt.size()-1] = corrupt[corrupt.size()-1]^1
	var temp = FileAccess.open("user://corrupt-test.icdata",FileAccess.WRITE)
	temp.store_buffer(corrupt)
	temp.close()
	assert(not await bundle.install("user://corrupt-test.icdata",self,func(_percent): pass),"Corrupt Data accepted")
	assert(FileAccess.get_file_as_string(ContentBundle.ACTIVE)==original,"Failed update changed active content")
	assert(await bundle.installed(self),"Previous data must remain usable after failed update")
	var valid = bundle.manifest.duplicate(true)
	for path in ["assets/content/../evil.json","assets/content/test.gd","assets/content/test.tscn","assets/content/test.res","/tmp/evil.obj"]:
		var malicious = valid.duplicate(true)
		malicious.files.append({"path":path,"bytes":1,"sha256":"0".repeat(64)})
		assert(not bundle.validate_manifest(malicious),"Unsafe file accepted: "+path)
	var incompatible = valid.duplicate(true)
	incompatible.api = 999
	assert(not bundle.validate_manifest(incompatible),"Incompatible API accepted")
	assert(not ContentAssets.validate_obj("v 0 0 0\nf 1 2 9000\n"),"Bad model indices accepted")
	DirAccess.remove_absolute("user://corrupt-test.icdata")
	print("IRON_CONTENT_PASS: raw assets, integrity, atomic replacement, old-pack recovery, path/code restrictions, API checks")
	quit()
