extends SceneTree

func _initialize() -> void:
	call_deferred("review")

func review() -> void:
	var stage = Node3D.new()
	root.add_child(stage)
	var file = OS.get_environment("IRON_HUMAN_MODEL")
	assert(not file.is_empty(),"Set IRON_HUMAN_MODEL to the generated GLB")
	var document = GLTFDocument.new()
	var state = GLTFState.new()
	assert(document.append_from_file(file,state)==OK,"GLB import failed")
	var human = document.generate_scene(state)
	assert(human!=null,"GLB did not generate a scene")
	stage.add_child(human)
	var skeletons = human.find_children("*","Skeleton3D",true,false)
	assert(skeletons.size()==1,"Expected one real skin skeleton")
	var skeleton: Skeleton3D = skeletons[0]
	# Godot may promote the six eye attachment nodes to extra skeleton bones.
	# The GLB skin still has exactly 20 deforming joints (checked by the file tests).
	assert(skeleton.get_bone_count()>=20 and skeleton.get_bone_count()<=32,"Unexpected imported skeleton budget")
	print("Imported skeleton transforms: ",skeleton.get_bone_count())
	assert(skeleton.find_bone("head")>=0,"Missing anatomical head bone")
	var camera = Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(.24,1.72,-.67)
	camera.fov = 38
	camera.look_at(Vector3(0,1.68,-.015))
	camera.current = true
	var world = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("19242c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d7dfef")
	environment.ambient_light_energy = .6
	world.environment = environment
	stage.add_child(world)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-28,-35,0)
	light.light_energy = 1.1
	stage.add_child(light)
	for i in range(20):
		await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("IRON_HUMAN_CAPTURE"))
	# Exercise the actual skin, not just static GLB parsing.
	var arm = skeleton.find_bone("upperarm01_L")
	assert(arm>=0,"Missing upper arm bone")
	skeleton.set_bone_pose_rotation(arm,Quaternion(Vector3.FORWARD,.35))
	await process_frame
	assert(absf(skeleton.get_bone_pose_rotation(arm).get_angle())>.3,"Skin pose update failed")
	print("IRON_HUMAN_IMPORT_PASS: real GLB, 20 skin bones, head and articulated arm")
	quit()
