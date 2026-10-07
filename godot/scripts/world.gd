class_name MarchWorld
extends Node3D

var stone = FieldMaterials.surface("masonry",Color("b6b2a8"),.50)
var light_stone = FieldMaterials.surface("masonry",Color("c9c3b5"),.50)
var wood = FieldMaterials.surface("timber",Color.WHITE,.8)
var roof_mat = FieldMaterials.surface("roof",Color.WHITE,.7)
var dark_roof = FieldMaterials.surface("roof",Color("959892"),.7)
var plaster = FieldMaterials.surface("plaster",Color.WHITE,.8)
var leaf = FieldMaterials.cutout("leaves")
var light_leaf = MarchArt.material(Color("68704d"))
var dark_leaf = MarchArt.material(Color("3c4d3d"))
var dirt = FieldMaterials.surface("earth",Color.WHITE,.6)
var flag_mat = MarchArt.cloth(Color("414d4b"))
var noise = FastNoiseLite.new()
var grass: MultiMeshInstance3D

var rng = RandomNumberGenerator.new()

func build() -> void:
	rng.seed = 4197
	noise.seed = 9045
	noise.frequency = .027
	build_ground()
	# Stone gateway, crenellated walls, and an explorable street.
	tower(Vector3(-6,0,-25))
	tower(Vector3(6,0,-25))
	for side in [-1,1]:
		wall(Vector3(side*13,0,-25),10)
		MarchArt.box(self,Vector3(side*3.15,2.9,-25),Vector3(.9,5.8,1.4),stone)
		MarchArt.collider(self,Vector3(side*3.15,2.9,-25),Vector3(.9,5.8,1.4))
	MarchArt.box(self,Vector3(0,5.65,-25),Vector3(6.5,1.5,1.6),light_stone)
	for i in range(7):
		MarchArt.box(self,Vector3(-3+i,6.55,-25),Vector3(.52,.5,1.5),stone)
	banner(Vector3(0,5.9,-24.05),1.4)
	house(Vector3(-12,0,-15),Vector3(5,3.2,6),-.12)
	house(Vector3(11,0,-17),Vector3(5.7,4.2,6.5),.16)
	house(Vector3(-7,0,-33),Vector3(4.5,3,5),0)
	house(Vector3(8,0,-35),Vector3(5,3.6,5),0)
	# Watchtower beyond the wall, copper-red roofs, banner poles.
	MarchArt.box(self,Vector3(0,5,-41),Vector3(6,10,6),stone)
	MarchArt.roof(self,Vector3(0,10,-41),7.2,7.2,3.4,dark_roof)
	for y in [3,6,8]:
		MarchArt.box(self,Vector3(0,y,-37.98),Vector3(.6,1.1,.06),wood)
	# Village market awning, crates, barrels, cart and camp props.
	for x in [8,13]:
		MarchArt.cylinder(self,Vector3(x,1.2,-11),.07,2.4,wood,.07)
	MarchArt.box(self,Vector3(10.5,2.5,-11.7),Vector3(5.3,.10,2.1),FieldMaterials.surface("cloth",Color("a9a088"),2)).rotation.x = -.13
	for i in range(4):
		crate(Vector3(8.8+i*.9,0,-12.0))
	for i in range(6):
		var point = Vector3(-8.0+(i%3)*.8,.48,-15.0+(i/3)*.8)
		MarchArt.cylinder(self,point,.34,.94,wood,.29,10)
		MarchArt.cylinder(self,point+Vector3(0,.29,0),.353,.075,dark_roof,.353,10)
		MarchArt.cylinder(self,point-Vector3(0,.29,0),.353,.075,dark_roof,.353,10)
	# One continuous, subdued stream, not overlapping colored discs.
	var stream = SurfaceTool.new()
	stream.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(38):
		var z = -50+i*2.5
		for v in [Vector2(-2,0),Vector2(2,2.5),Vector2(-2,2.5),Vector2(-2,0),Vector2(2,0),Vector2(2,2.5)]:
			var p = Vector3(29+sin((z+v.y)*.09)*3+v.x,.016,z+v.y)
			stream.set_normal(Vector3.UP)
			stream.add_vertex(p)
	var water = MarchArt.material(Color("566961"),.15)
	water.roughness = .36
	MarchArt.mesh(self,stream.commit(),Vector3.ZERO,water)
	# Vegetation is clear of the central combat arena.
	for i in range(76):
		var x = rng.randf_range(-49,49)
		var z = rng.randf_range(-53,40)
		if (absf(x)<18 and z>-43 and z<27) or (x>23 and x<35):
			continue
		tree(Vector3(x,0,z),rng.randf_range(.8,1.7),i%3==0)
	for i in range(135):
		var point = Vector3(rng.randf_range(-26,24),.035,rng.randf_range(-23,28))
		var pebble = MarchArt.sphere(self,point,Vector3(.08,.04,.11)*rng.randf_range(.7,2.1),stone)
		pebble.rotation.y = rng.randf()*TAU
	build_grass()
	# Training racks and banners identify the player's side.
	for side in [-1,1]:
		MarchArt.cylinder(self,Vector3(side*7,1.7,12),.065,3.4,wood,.065)
		banner(Vector3(side*7+.4,2.8,12),.8)
		for i in range(3):
			MarchArt.box(self,Vector3(side*10+i*.6,.55,11),Vector3(.08,1.1,.1),wood)
	# Batch static scenery into a small set of material draw calls.
	MarchArt.batch_static(self)

func ground_height(x: float, z: float) -> float:
	var outside = smoothstep(0,22,maxf(absf(x)-27,absf(z)-43))
	var valley = smoothstep(3,7,absf(x-(29+sin(z*.09)*3)))
	return outside*valley*(8+noise.get_noise_2d(x,z)*11+pow(maxf(0,sin(x*.045+z*.034)),2)*15)

func build_ground() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	for zi in range(80):
		for xi in range(80):
			for corner in [Vector2(0,0),Vector2(2.5,2.5),Vector2(0,2.5),Vector2(0,0),Vector2(2.5,0),Vector2(2.5,2.5)]:
				var x = -100+xi*2.5+corner.x
				var z = -100+zi*2.5+corner.y
				st.set_uv(Vector2(x,z)*.32)
				st.add_vertex(Vector3(x,ground_height(x,z),z))
	st.generate_normals()
	st.generate_tangents()
	var mesh = MarchArt.mesh(self,st.commit(),Vector3.ZERO,FieldMaterials.ground())
	mesh.create_trimesh_collision()

func build_grass() -> void:
	var blade = QuadMesh.new()
	blade.size = Vector2(.45,.50)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(blade,0,Transform3D(Basis.IDENTITY,Vector3(0,.25,0)))
	st.append_from(blade,0,Transform3D(Basis(Vector3.UP,PI/2),Vector3(0,.25,0)))
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = st.commit()
	multimesh.instance_count = 1800
	for i in range(1800):
		var x = rng.randf_range(-35,35)
		var z = rng.randf_range(-42,32)
		while absf(x-sin(z*.055)*2.5)<3.8 or (x>24 and x<35):
			x = rng.randf_range(-35,35)
		var scale_value = rng.randf_range(.55,1.25)
		var basis_value = Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_value)
		multimesh.set_instance_transform(i,Transform3D(basis_value,Vector3(x,ground_height(x,z),z)))
		multimesh.set_instance_color(i,Color(rng.randf_range(.8,1),rng.randf_range(.8,1),.85))
	grass = MultiMeshInstance3D.new()
	grass.multimesh = multimesh
	var material = FieldMaterials.cutout("grass")
	material.vertex_color_use_as_albedo = true
	grass.material_override = material
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(grass)
	grass.multimesh.visible_instance_count = 600

func tree(at: Vector3, size: float, _fir: bool) -> void:
	at.y = ground_height(at.x,at.z)
	MarchArt.cylinder(self,at+Vector3(0,2.0*size,0),.18*size,4.0*size,wood,.085*size,12)
	for branch in range(6):
		var direction = Vector3(sin(branch*2.4)*1.3,1.2,cos(branch*2.4)*1.3)*size
		var base = at+Vector3(0,(1.6+branch*.32)*size,0)
		var twig = MarchArt.cylinder(self,base+direction*.5,.065*size,direction.length(),wood,.02*size,8)
		twig.quaternion = Quaternion(Vector3.UP,direction.normalized())
	for cluster in range(28):
		var angle = rng.randf()*TAU
		var distance = rng.randf_range(.3,1.8)*size
		var p = at+Vector3(sin(angle)*distance,rng.randf_range(2.8,5.0)*size,cos(angle)*distance)
		var shape = QuadMesh.new()
		shape.size = Vector2(1.4,1.4)*size
		var foliage = MarchArt.mesh(self,shape,p,leaf)
		foliage.rotation = Vector3(rng.randf_range(-.5,.5),rng.randf()*TAU,rng.randf_range(-.3,.3))
	if absf(at.x)<30 and at.z>-28:
		MarchArt.collider(self,at+Vector3(0,1.6,0),Vector3(.4,3.2,.4))

func house(at: Vector3, size: Vector3, angle: float) -> void:
	var house_node = Node3D.new()
	add_child(house_node)
	house_node.position = at
	house_node.rotation.y = angle
	MarchArt.box(house_node,Vector3(0,size.y/2,0),size,plaster)
	MarchArt.collider(house_node,Vector3(0,size.y/2,0),size)
	MarchArt.box(house_node,Vector3(0,.26,0),Vector3(size.x+.15,.52,size.z+.15),stone)
	MarchArt.roof(house_node,Vector3(0,size.y,0),size.x+1,size.z+1,size.y*.65,roof_mat)
	for side in [-1,1]:
		MarchArt.box(house_node,Vector3(side*(size.x/2-.06),size.y/2,size.z/2+.03),Vector3(.14,size.y,.1),wood)
		MarchArt.box(house_node,Vector3(side*size.x*.30,size.y*.63,size.z/2+.065),Vector3(.7,.8,.08),wood)
		MarchArt.box(house_node,Vector3(side*size.x*.30,size.y*.63,size.z/2+.11),Vector3(.51,.59,.045),FieldMaterials.surface("timber",Color("7f8074"),2))
		MarchArt.box(house_node,Vector3(side*size.x*.30,size.y*.63,size.z/2+.15),Vector3(.06,.7,.04),wood)
	MarchArt.box(house_node,Vector3(0,size.y*.52,size.z/2+.10),Vector3(size.x,.17,.15),wood)
	MarchArt.box(house_node,Vector3(0,.85,size.z/2+.08),Vector3(.95,1.7,.12),wood)
	MarchArt.box(house_node,Vector3(size.x*.26,size.y+1.3,-size.z*.2),Vector3(.65,2.3,.7),stone)

func tower(at: Vector3) -> void:
	MarchArt.cylinder(self,at+Vector3(0,3.9,0),2.0,7.8,stone,2.0,10)
	MarchArt.cylinder(self,at+Vector3(0,.35,0),2.2,.7,light_stone,2.2,10)
	MarchArt.cylinder(self,at+Vector3(0,7.2,0),2.15,.45,light_stone,2.15,10)
	MarchArt.collider(self,at+Vector3(0,3.6,0),Vector3(3.8,7.2,3.8))
	for i in range(10):
		var angle = float(i)/10*TAU
		var block = MarchArt.box(self,at+Vector3(sin(angle)*1.85,8.05,cos(angle)*1.85),Vector3(.7,.8,.65),light_stone)
		block.rotation.y = angle
	MarchArt.box(self,at+Vector3(0,4.7,2.005),Vector3(.18,1.3,.025),wood)
	MarchArt.cylinder(self,at+Vector3(0,9.0,0),.055,2.0,wood,.055)
	banner(at+Vector3(.42,9.5,0),.85)

func wall(at: Vector3, width: float) -> void:
	MarchArt.box(self,at+Vector3(0,2,0),Vector3(width,4,1.2),stone)
	MarchArt.collider(self,at+Vector3(0,2,0),Vector3(width,4,1.2))
	MarchArt.box(self,at+Vector3(0,3.7,0),Vector3(width,.25,1.5),light_stone)
	for i in range(int(width)):
		MarchArt.box(self,at+Vector3(-width/2+i+.3,4.2,0),Vector3(.55,.6,1.3),light_stone)

func banner(at: Vector3, size: float) -> void:
	var shape = PlaneMesh.new()
	shape.size = Vector2(size,size*1.6)
	shape.subdivide_width = 2
	shape.subdivide_depth = 5
	var banner_mesh = MarchArt.mesh(self,shape,at,flag_mat)
	banner_mesh.rotation.x = PI/2
	MarchArt.box(self,at+Vector3(0,.2,.04),Vector3(size*.09,size*.65,.035),light_stone)
	MarchArt.box(self,at+Vector3(0,.32,.045),Vector3(size*.4,size*.09,.035),light_stone)

func crate(at: Vector3) -> void:
	MarchArt.box(self,at+Vector3(0,.35,0),Vector3(.66,.7,.65),wood)
	for y in [.08,.6]:
		MarchArt.box(self,at+Vector3(0,y,.335),Vector3(.7,.09,.04),dirt)
