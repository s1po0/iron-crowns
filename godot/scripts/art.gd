class_name MarchArt
extends RefCounted

static func material(color: Color, metal: float = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.83 if metal == 0.0 else 0.38
	m.metallic = metal
	return m

static func mesh(parent: Node3D, shape: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var instance = MeshInstance3D.new()
	instance.mesh = shape
	instance.material_override = mat
	instance.position = at
	parent.add_child(instance)
	return instance

static func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var shape = BoxMesh.new()
	shape.size = size
	return mesh(parent, shape, at, mat)

static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, mat: Material, top: float = -1.0, sides: int = 8) -> MeshInstance3D:
	var shape = CylinderMesh.new()
	shape.top_radius = radius if top < 0 else top
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = sides
	shape.rings = 1
	return mesh(parent, shape, at, mat)

static func sphere(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var shape = SphereMesh.new()
	shape.radial_segments = 8
	shape.rings = 4
	shape.radius = 1
	shape.height = 2
	var result = mesh(parent, shape, at, mat)
	result.scale = size
	return result

static func collider(parent: Node3D, at: Vector3, size: Vector3) -> void:
	var body = StaticBody3D.new()
	body.position = at
	var shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	parent.add_child(body)

static func roof(parent: Node3D, at: Vector3, width: float, depth: float, height: float, mat: Material) -> void:
	var a = Vector3(-width / 2, 0, -depth / 2)
	var b = Vector3(width / 2, 0, -depth / 2)
	var c = Vector3(0, height, -depth / 2)
	var d = Vector3(-width / 2, 0, depth / 2)
	var e = Vector3(width / 2, 0, depth / 2)
	var f = Vector3(0, height, depth / 2)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in [a,c,b,d,e,f,a,d,f,a,f,c,b,c,f,b,f,e]:
		st.add_vertex(point)
	st.generate_normals()
	mesh(parent, st.commit(), at, mat)

static func cloth(color: Color) -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = "shader_type spatial; render_mode cull_disabled; uniform vec4 tint : source_color; void vertex(){VERTEX.z += sin(TIME * 2.4 + VERTEX.y * 4.0 + VERTEX.x * 2.0) * 0.065 * UV.y;} void fragment(){ALBEDO=tint.rgb; ROUGHNESS=0.95;}"
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("tint", color)
	return mat

# Combine static scenery by material; keep individual collision bodies.
static func batch_static(root: Node3D) -> void:
	var groups = {}
	var objects = root.find_children("*", "MeshInstance3D", true, false)
	for object in objects:
		var instance = object as MeshInstance3D
		if instance.material_override is ShaderMaterial or instance.mesh == null:
			continue
		var mat = instance.material_override
		if mat == null:
			continue
		var key = mat.get_instance_id()
		if not groups.has(key):
			var surface = SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[key] = [surface,mat]
		groups[key][0].append_from(instance.mesh,0,root.global_transform.affine_inverse()*instance.global_transform)
		instance.queue_free()
	for entry in groups.values():
		mesh(root,entry[0].commit(),Vector3.ZERO,entry[1])
