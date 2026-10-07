class_name MarchWorld
extends Node3D

var stone = MarchArt.material(Color("c4bea4"))
var light_stone = MarchArt.material(Color("e2d7b6"))
var wood = MarchArt.material(Color("584939"))
var roof_mat = MarchArt.material(Color("a65039"))
var dark_roof = MarchArt.material(Color("644f45"))
var plaster = MarchArt.material(Color("e9d9b0"))
var leaf = MarchArt.material(Color("527e45"))
var light_leaf = MarchArt.material(Color("75904b"))
var dark_leaf = MarchArt.material(Color("365f47"))
var dirt = MarchArt.material(Color("b9a175"))
var flag_mat = MarchArt.cloth(Color("286778"))
var rng = RandomNumberGenerator.new()

func build() -> void:
	rng.seed = 4197
	# Warm, legible diorama terrain; distant faceted hills frame the village.
	MarchArt.box(self,Vector3(0,-.65,0),Vector3(180,1.3,180),MarchArt.material(Color("80955a")))
	MarchArt.collider(self,Vector3(0,-.6,0),Vector3(180,1.2,180))
	for i in range(22):
		var angle = float(i)/22*TAU
		var point = Vector3(sin(angle)*rng.randf_range(66,86),0,cos(angle)*rng.randf_range(66,86))
		var mountain_height = rng.randf_range(12,24)
		MarchArt.cylinder(self,point+Vector3(0,mountain_height*.34,0),rng.randf_range(16,24),mountain_height,MarchArt.material(Color("587d78") if i%2==0 else Color("6b856e")),0,7)
	# A path of overlapping low polygon discs gives an irregular, winding road.
	for i in range(31):
		var z = 23-i*2.0
		var x = sin(z*.055)*2.5
		MarchArt.cylinder(self,Vector3(x,.018,z),2.9,.035,dirt,2.9,10)
	for i in range(14):
		MarchArt.cylinder(self,Vector3(1+i*1.4,.023,-7-i*.45),2.1,.025,dirt,2.1,10)
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
	MarchArt.box(self,Vector3(10.5,2.5,-11.7),Vector3(5.3,.10,2.1),MarchArt.material(Color("d4b86b"))).rotation.x = -.13
	for i in range(4):
		crate(Vector3(8.8+i*.9,0,-12.0))
	for i in range(6):
		var point = Vector3(-8.0+(i%3)*.8,.48,-15.0+(i/3)*.8)
		MarchArt.cylinder(self,point,.34,.94,wood,.29,10)
		MarchArt.cylinder(self,point+Vector3(0,.29,0),.353,.075,dark_roof,.353,10)
		MarchArt.cylinder(self,point-Vector3(0,.29,0),.353,.075,dark_roof,.353,10)
	# A sunlit brook with banks lies along the right edge of the playable meadow.
	var water = MarchArt.material(Color("69a8a6"))
	water.roughness = .25
	for i in range(22):
		var z = -38+i*3.0
		var x = 29+sin(z*.09)*3
		MarchArt.cylinder(self,Vector3(x,.005,z),3.3,.02,water,3.3,12)
		for side in [-1,1]:
			MarchArt.sphere(self,Vector3(x+side*3.4,0,z),Vector3(.7,.35,.6),stone)
	# Vegetation is clear of the central combat arena.
	for i in range(76):
		var x = rng.randf_range(-49,49)
		var z = rng.randf_range(-53,40)
		if (absf(x)<18 and z>-43 and z<27) or (x>23 and x<35):
			continue
		tree(Vector3(x,0,z),rng.randf_range(.8,1.7),i%3==0)
	for i in range(100):
		var point = Vector3(rng.randf_range(-32,26),.03,rng.randf_range(-22,28))
		if absf(point.x)<4 or (absf(point.x)<7 and point.z<12):
			continue
		if i%5==0:
			MarchArt.sphere(self,point,Vector3(.4,.25,.3),stone)
		else:
			var grass = MarchArt.cylinder(self,point+Vector3(0,.14,0),.13,.3,light_leaf,0,4)
			grass.rotation.z = rng.randf_range(-.25,.25)
			if i%4==0:
				MarchArt.sphere(self,point+Vector3(0,.3,0),Vector3(.10,.06,.10),plaster)
	# Training racks and banners identify the player's side.
	for side in [-1,1]:
		MarchArt.cylinder(self,Vector3(side*7,1.7,12),.065,3.4,wood,.065)
		banner(Vector3(side*7+.4,2.8,12),.8)
		for i in range(3):
			MarchArt.box(self,Vector3(side*10+i*.6,.55,11),Vector3(.08,1.1,.1),wood)
	# Batch static scenery into a small set of material draw calls.
	MarchArt.batch_static(self)

func tree(at: Vector3, size: float, fir: bool) -> void:
	var trunk_height = 2.4*size
	MarchArt.cylinder(self,at+Vector3(0,trunk_height/2,0),.19*size,trunk_height,wood,.12*size)
	if fir:
		for i in range(3):
			MarchArt.cylinder(self,at+Vector3(0,(2.1+i*.9)*size,0),(1.5-i*.3)*size,2.3*size,dark_leaf,0,7)
	else:
		MarchArt.sphere(self,at+Vector3(0,3.1*size,0),Vector3(1.8,1.6,1.6)*size,leaf)
		MarchArt.sphere(self,at+Vector3(.9*size,3.7*size,0),Vector3(1.2,1.1,1.3)*size,light_leaf)
	if absf(at.x)<30 and at.z>-28:
		MarchArt.collider(self,at+Vector3(0,1,0),Vector3(.4,2,.4))

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
		MarchArt.box(house_node,Vector3(side*size.x*.30,size.y*.63,size.z/2+.11),Vector3(.51,.59,.045),MarchArt.material(Color("c6a55b")))
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
