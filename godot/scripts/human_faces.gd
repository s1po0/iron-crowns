class_name HumanFaces
extends RefCounted

# Actual imported anatomical mesh, with faces/styles selected from the Data catalog.
static func attach(parent: Node3D, definition: Dictionary) -> void:
	var skin = StandardMaterial3D.new()
	skin.albedo_color = Color(str(definition.skin))
	skin.roughness = .77
	skin.metallic_specular = .23
	var head = MarchArt.mesh(parent,ContentAssets.mesh(str(definition.mesh)),Vector3.ZERO,skin)
	head.scale = Vector3(float(definition.get("width",1)),1,1)
	var hair = FieldMaterials.surface("cloth",Color(str(definition.hair)),8)
	hair.roughness = 1
	MarchArt.mesh(parent,ContentAssets.mesh(str(definition.scalp)),Vector3.ZERO,hair)
	var white = MarchArt.material(Color("beb8a4"))
	var iris = MarchArt.material(Color(str(definition.eyes)))
	var black = MarchArt.material(Color("151a19"))
	for side in [-1,1]:
		var eye = Vector3(side*.03455,1.7345,-.1218)
		oval(parent,eye,Vector3(.014,.011,.012),white)
		oval(parent,eye+Vector3(0,0,-.011),Vector3(.006,.007,.002),iris)
		oval(parent,eye+Vector3(0,0,-.014),Vector3(.0035,.0045,.0015),black)
		var brow = oval(parent,eye+Vector3(0,.028,-.002),Vector3(.024,.004,.004),hair)
		brow.rotation.z = side*.09

static func oval(parent: Node3D, at: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var shape = SphereMesh.new()
	shape.radial_segments = 12
	shape.rings = 6
	shape.radius = 1
	shape.height = 2
	var part = MarchArt.mesh(parent,shape,at,material)
	part.scale = dimensions
	return part
