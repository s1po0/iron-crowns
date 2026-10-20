class_name CastleWorld
extends Node3D
var mission_id="valley"
var models: Dictionary={}
var structures: Dictionary={}
var actors: Dictionary={}
var rotating: Array=[]
var quality=1
var sun: DirectionalLight3D
var environment: WorldEnvironment
var chunks: Node3D
var trees: MultiMeshInstance3D

func setup(map_id: String="valley") -> void:
	mission_id=map_id
	models=ContentAssets.json("res://assets/content/rts/models.json")
	environment=WorldEnvironment.new()
	var env=Environment.new()
	env.background_mode=Environment.BG_SKY
	var sky=Sky.new()
	var sky_material=ProceduralSkyMaterial.new()
	sky_material.sky_top_color=Color("66859a")
	sky_material.sky_horizon_color=Color("d5d8c1")
	sky.sky_material=sky_material
	env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("b9c6cd")
	env.ambient_light_energy=.45
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	env.fog_enabled=true
	env.fog_light_color=Color("aebcb3")
	env.fog_density=.0015
	environment.environment=env
	add_child(environment)
	sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-48,-35,0)
	sun.light_color=Color("ffe0b0")
	sun.light_energy=1.1
	sun.directional_shadow_max_distance=90
	sun.shadow_enabled=true
	add_child(sun)
	if CastleMissions.size_for(mission_id)>40:
		chunks=RealmTerrain.new()
		add_child(chunks)
		chunks.setup(mission_id)
	else:
		landscape()
	forest()
	var m=CastleMissions.data(mission_id)
	var center=CastleSim.world(CastleMissions.bridge_center(mission_id))
	var length=(m.bridge[1]-m.bridge[0]+1)*3.0
	var along_x=m.axis=="x"
	MarchArt.box(self,center+Vector3(0,.35,0),Vector3(12,.7,length) if along_x else Vector3(length,.7,12),FieldMaterials.surface("masonry",Color("9b9886"),.5))
	for side in [-1,1]:
		var offset=Vector3(0,1,side*length*.5) if along_x else Vector3(side*length*.5,1,0)
		MarchArt.box(self,center+offset,Vector3(12,.8,.4) if along_x else Vector3(.4,.8,12),FieldMaterials.surface("masonry",Color("9b9886"),.5))
	# Roads follow the same navigable grid as gameplay, not an unrelated painted route.
	var road_sim=CastleSim.new(mission_id)
	var road=road_sim.navigation.get_id_path(CastleMissions.keep(mission_id)+Vector2i(3,1),Vector2i(CastleMissions.bridge_center(mission_id)))
	for cell in road:
		if not CastleMissions.channel(Vector2(cell),mission_id):
			MarchArt.box(self,CastleSim.world(Vector2(cell))+Vector3(0,.025,0),Vector3(2.8,.05,2.8),FieldMaterials.surface("earth",Color("b9a688"),1))
	for key in ["wood","quarry"]:
		var label=Label3D.new()
		label.text="دارستان" if key=="wood" else "کانگەی بەرد"
		label.font=load("res://assets/fonts/vazirmatn.ttf")
		label.font_size=40
		label.pixel_size=.025
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.position=CastleSim.world(Vector2(CastleMissions.point(mission_id,key)))+Vector3(0,6,0)
		add_child(label)

func model(key: String) -> Node3D:
	var root=Node3D.new()
	for part in models.models[key]:
		var material=StandardMaterial3D.new()
		material.roughness=.9
		if part.has("texture"):
			material.albedo_texture=ContentAssets.texture(part.texture)
		material.albedo_color=Color(part.color[0],part.color[1],part.color[2])
		var instance=MeshInstance3D.new()
		instance.mesh=ContentAssets.mesh(part.mesh)
		instance.material_override=material
		root.add_child(instance)
	return root

func height_at(x: float,z: float) -> float:
	var edge=maxf(absf(x),absf(z))
	var h=maxf(0,(edge-43)/12)*(2.5+sin(x*.1)*1.7+cos(z*.12)*1.4)
	if CastleMissions.channel(Vector2(x/CastleSim.TILE+20,z/CastleSim.TILE+20),mission_id):
		h=-.7
	return h

func landscape() -> void:
	var surface=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-72,72,3):
		for x in range(-72,72,3):
			for p in [Vector2(x,z),Vector2(x+3,z),Vector2(x,z+3),Vector2(x+3,z),Vector2(x+3,z+3),Vector2(x,z+3)]:
				surface.set_uv(p/9)
				surface.add_vertex(Vector3(p.x,height_at(p.x,p.y),p.y))
	surface.generate_normals()
	var terrain=MeshInstance3D.new()
	terrain.mesh=surface.commit()
	terrain.material_override=FieldMaterials.ground().duplicate(true)
	terrain.material_override.shader.code=terrain.material_override.shader.code.replace("NORMAL_MAP =", "ALBEDO *= vec3(%f,%f,%f); NORMAL_MAP =" % [Color(CastleMissions.data(mission_id).tint).r,Color(CastleMissions.data(mission_id).tint).g,Color(CastleMissions.data(mission_id).tint).b])
	add_child(terrain)
	var water=MeshInstance3D.new()
	var plane=PlaneMesh.new()
	plane.size=Vector2(9,150) if CastleMissions.data(mission_id).axis=="x" else Vector2(150,9)
	water.mesh=plane
	var river_center=CastleSim.world(CastleMissions.bridge_center(mission_id))
	water.position=Vector3(river_center.x,-.3,0) if CastleMissions.data(mission_id).axis=="x" else Vector3(0,-.3,river_center.z)
	var shader=Shader.new()
	shader.code="shader_type spatial; void fragment(){float wave=sin(UV.y*180.0+TIME)*sin(UV.x*30.0-TIME*.6); ALBEDO=mix(vec3(.14,.27,.28),vec3(.26,.39,.36),wave*.18+.5); ROUGHNESS=.3; SPECULAR=.6;}"
	var material=ShaderMaterial.new()
	material.shader=shader
	water.material_override=material
	add_child(water)
	for i in 24:
		var p=CastleSim.world(Vector2(CastleMissions.point(mission_id,"quarry")))+Vector3(sin(i*2.3)*5,.3,cos(i*1.7)*5)
		var stone=SphereMesh.new()
		stone.radial_segments=7
		stone.rings=4
		stone.radius=.7+(i%4)*.25
		stone.height=stone.radius*1.3
		var rock=MeshInstance3D.new()
		rock.mesh=stone
		rock.position=p
		rock.scale=Vector3(1.4,1,1)
		rock.material_override=FieldMaterials.surface("masonry",Color("939488"),1)
		add_child(rock)

func forest() -> void:
	var leaf=QuadMesh.new()
	leaf.size=Vector2(3.6,3.6)
	# Crossed textured canopy cards instead of cone symbols. One draw per crossed layer.
	for layer in 3:
		var multi=MultiMesh.new()
		multi.transform_format=MultiMesh.TRANSFORM_3D
		if layer==2:
			var trunk=CylinderMesh.new()
			trunk.top_radius=.12
			trunk.bottom_radius=.3
			trunk.height=4
			trunk.radial_segments=6
			multi.mesh=trunk
		else:
			multi.mesh=leaf
		var factor=1 if layer==2 else 6
		multi.instance_count=220*factor
		for instance in multi.instance_count:
			var i=int(instance/factor)
			var cluster=instance%factor
			var angle=i*2.399
			var p=CastleSim.world(Vector2(CastleMissions.point(mission_id,"wood")))+Vector3(sin(angle)*9,3.8,cos(angle)*12)
			if CastleMissions.blocked(CastleSim.cell(p),mission_id):
				p=CastleSim.world(Vector2(CastleMissions.point(mission_id,"wood")))+Vector3(sin(angle)*3,3.8,cos(angle)*3)
			if layer==2:
				p.y=2
			else:
				p+=Vector3(cos(cluster*2.4)*1.4,1+sin(cluster*2.4)*.8,sin(cluster*2.4)*1.4)
			var basis=Basis(Vector3.UP,layer*PI*.5+sin(i)*.3).scaled(Vector3.ONE*(.65+(i%7)*.08))
			multi.set_instance_transform(instance,Transform3D(basis,p))
		var node=MultiMeshInstance3D.new()
		node.multimesh=multi
		node.set_meta("density",factor)
		node.material_override=FieldMaterials.surface("timber",Color("605342"),1) if layer==2 else FieldMaterials.cutout("leaves")
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		if layer==0:
			trees=node

func building(b: Dictionary) -> Node3D:
	var root=Node3D.new()
	var n: int=CastleSim.FOOTPRINT[b.kind]
	root.position=CastleSim.world(Vector2(b.x,b.y))+Vector3((n-1)*1.5,0,(n-1)*1.5)
	if b.kind in ["house","woodcutter","mill","bakery","barracks"]:
		root.add_child(model("house_long" if b.kind=="barracks" else "house_small"))
	elif b.kind=="stockpile":
		root.add_child(model("yard_corner"))
	elif b.kind=="quarry":
		root.add_child(model("yard_corner"))
		MarchArt.box(root,Vector3(1,.8,1),Vector3(2,1.6,2),FieldMaterials.surface("masonry",Color.WHITE,1))
	elif b.kind=="farm":
		MarchArt.box(root,Vector3(0,.04,0),Vector3(8,.08,8),FieldMaterials.surface("earth",Color.WHITE,1))
		var crop=MultiMeshInstance3D.new()
		var plants=MultiMesh.new()
		plants.transform_format=MultiMesh.TRANSFORM_3D
		var stalk=QuadMesh.new()
		stalk.size=Vector2(.7,.8)
		plants.mesh=stalk
		plants.instance_count=144
		for i in 144:
			plants.set_instance_transform(i,Transform3D(Basis(Vector3.UP,(i%3)*.7),Vector3(-3.6+(i%12)*.65,.4,-3.6+int(i/12)*.65)))
		crop.multimesh=plants
		crop.material_override=FieldMaterials.cutout("grass").duplicate()
		crop.material_override.albedo_color=Color("d5b879")
		root.add_child(crop)
	elif b.kind in ["wall","gate"]:
		for x in [-1.0,1.0] if b.kind=="gate" else [0.0]:
			MarchArt.box(root,Vector3(x,1.5,0),Vector3(.8 if b.kind=="gate" else 3,3,.8),FieldMaterials.surface("masonry",Color("aea58d"),.6))
		MarchArt.box(root,Vector3(0,2.9,0),Vector3(3,.5,1),FieldMaterials.surface("masonry",Color("aea58d"),.6))
		if b.kind=="gate":
			var door=MarchArt.box(root,Vector3(0,1.4,0),Vector3(1.4,2.8,.55),FieldMaterials.surface("timber",Color("746048"),1))
			door.name="GateDoor"
		for x in [-1,0,1]:
			MarchArt.box(root,Vector3(x,3.35,0),Vector3(.5,.5,1),FieldMaterials.surface("masonry",Color("aea58d"),.6))
	else:
		MarchArt.box(root,Vector3(0,2,0),Vector3(7,4,6),FieldMaterials.surface("masonry",Color("a9a38c"),.45))
		for x in [-3.5,3.5]:
			for z in [-3,3]:
				MarchArt.cylinder(root,Vector3(x,3.5,z),1.25,7,FieldMaterials.surface("masonry",Color("b8b299"),.5),1.25,12)
				for i in 6:
					MarchArt.box(root,Vector3(x+cos(i*TAU/6),7.2,z+sin(i*TAU/6)),Vector3(.5,.6,.5),FieldMaterials.surface("masonry",Color("b8b299"),.5))
		MarchArt.box(root,Vector3(0,1.2,3.1),Vector3(1.5,2.4,.1),FieldMaterials.surface("timber",Color("595044"),1))
	if b.kind=="mill":
		var sail=Node3D.new()
		sail.position=Vector3(0,3.5,2)
		root.add_child(sail)
		for angle in [0,PI*.5]:
			var beam=MarchArt.box(sail,Vector3.ZERO,Vector3(.3,5,.15),FieldMaterials.surface("timber",Color("b5a785"),1))
			beam.rotation.z=angle
		rotating.append(sail)
	var label=Label3D.new()
	label.text=CastleUI.NAMES.get(b.kind,"")
	label.font=load("res://assets/fonts/vazirmatn.ttf")
	label.font_size=40
	label.pixel_size=.022
	label.position=Vector3(0,8 if b.kind=="keep" else 6,0)
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate=Color("e7dec1")
	label.outline_size=10
	root.add_child(label)
	return root

func sync(sim: CastleSim, dt: float) -> void:
	for b in sim.buildings:
		if not structures.has(b.id):
			structures[b.id]=building(b)
			add_child(structures[b.id])
		structures[b.id].scale.y=.15+.85*b.built
		if b.kind=="gate":
			structures[b.id].get_node("GateDoor").visible=not b.get("open",true)
	for id in structures.keys():
		if not sim.buildings.any(func(b):return b.id==id):
			structures[id].queue_free()
			structures.erase(id)
	for u in sim.units:
		if not actors.has(u.id):
			var actor=CastleActor.new()
			add_child(actor)
			actor.setup(u.kind,u.id)
			actors[u.id]=actor
		actors[u.id].update(u,dt)
	for id in actors.keys():
		if not sim.units.any(func(u):return u.id==id):
			actors[id].queue_free()
			actors.erase(id)
	for sail in rotating:
		if is_instance_valid(sail):
			sail.rotation.z+=dt*.5

func set_quality(index: int) -> void:
	quality=clampi(index,0,2)
	Engine.max_fps=[30,30,45][quality]
	get_viewport().scaling_3d_scale=[.7,.85,1.0][quality]
	get_viewport().msaa_3d=Viewport.MSAA_DISABLED if quality==0 else Viewport.MSAA_2X
	sun.shadow_enabled=quality>0
	sun.directional_shadow_max_distance=[0,55,90][quality]
	for child in get_children():
		if child is MultiMeshInstance3D:
			child.multimesh.visible_instance_count=[85,150,220][quality]*int(child.get_meta("density",1))

func stream(focus: Vector3) -> void:
	if chunks!=null:
		chunks.stream(focus,quality)
