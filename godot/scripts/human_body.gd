class_name HumanBody
extends Node3D

static var cached_mesh: ArrayMesh
static var definition: Dictionary = {}
var skeleton: Skeleton3D

static func validate(value) -> bool:
	if not value is Dictionary or value.get("schema")!=1 or not value.get("bones") is Array or value.bones.size()!=20 or not value.get("surfaces") is Array or value.surfaces.size()!=4:
		return false
	var names: Array = []
	for i in range(value.bones.size()):
		var bone = value.bones[i]
		if not bone is Dictionary or not bone.get("name") is String or bone.name in names or not bone.get("parent") is float and not bone.get("parent") is int:
			return false
		if not is_finite(float(bone.parent)) or bone.parent!=int(bone.parent) or int(bone.parent)< -1 or int(bone.parent)>=i or not vector_valid(bone.get("rest"),3,3):
			return false
		names.append(bone.name)
	for required in ["spine01","upperarm01_L","upperarm01_R","lowerarm01_L","lowerarm01_R","upperleg01_L","upperleg01_R","lowerleg01_L","lowerleg01_R","wrist_L","wrist_R","head"]:
		if not required in names:
			return false
	var kinds: Array = []
	var total = 0
	for surface in value.surfaces:
		if not surface is Dictionary or not surface.get("kind") in ["skin","coat","trousers","boots"] or surface.kind in kinds or not surface.get("positions") is Array:
			return false
		kinds.append(surface.kind)
		var count = surface.positions.size()
		total += count
		if count<3 or total>30000:
			return false
		for key in ["normals","uv","joints","weights"]:
			if not surface.get(key) is Array or surface[key].size()!=count:
				return false
		for i in range(count):
			if not vector_valid(surface.positions[i],3,3) or not vector_valid(surface.normals[i],3,1.01) or not vector_valid(surface.uv[i],2,10) or not vector_valid(surface.joints[i],4,19) or not vector_valid(surface.weights[i],4,1):
				return false
			var weight_sum = 0.0
			for j in range(4):
				if surface.joints[i][j]<0 or surface.joints[i][j]!=int(surface.joints[i][j]) or surface.weights[i][j]<0:
					return false
				weight_sum += surface.weights[i][j]
			if absf(weight_sum-1)>.002:
				return false
		if not surface.get("indices") is Array or surface.indices.size()%3!=0 or surface.indices.size()>90000:
			return false
		for index in surface.indices:
			if not (index is float or index is int) or index<0 or index>=count or index!=int(index):
				return false
	if not vector_valid(value.get("head_origin"),3,3) or not value.get("eyes") is Array or value.eyes.size()!=2:
		return false
	return vector_valid(value.eyes[0],3,3) and vector_valid(value.eyes[1],3,3)

static func vector_valid(value, count: int, limit: float) -> bool:
	if not value is Array or value.size()!=count:
		return false
	for component in value:
		if not (component is float or component is int) or not is_finite(float(component)) or absf(component)>limit:
			return false
	return true

func build(outfit: Dictionary, face: Dictionary) -> void:
	if definition.is_empty():
		definition = ContentAssets.json("res://assets/content/humans/human-body.json")
		assert(validate(definition),"Invalid human skin")
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)
	for bone in definition.bones:
		var i = skeleton.get_bone_count()
		skeleton.add_bone(bone.name)
		skeleton.set_bone_parent(i,int(bone.parent))
		skeleton.set_bone_rest(i,Transform3D(Basis.IDENTITY,Vector3(bone.rest[0],bone.rest[1],bone.rest[2])))
	if cached_mesh==null:
		cached_mesh = ArrayMesh.new()
		for surface in definition.surfaces:
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			var vertices = PackedVector3Array()
			var normals = PackedVector3Array()
			var uv = PackedVector2Array()
			var joints = PackedInt32Array()
			var weights = PackedFloat32Array()
			for i in range(surface.positions.size()):
				var p: Array = surface.positions[i]
				var n: Array = surface.normals[i]
				vertices.append(Vector3(p[0],p[1],p[2]))
				normals.append(Vector3(n[0],n[1],n[2]))
				uv.append(Vector2(surface.uv[i][0],surface.uv[i][1]))
				for j in range(4):
					joints.append(int(surface.joints[i][j]))
					weights.append(float(surface.weights[i][j]))
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_NORMAL] = normals
			arrays[Mesh.ARRAY_TEX_UV] = uv
			arrays[Mesh.ARRAY_BONES] = joints
			arrays[Mesh.ARRAY_WEIGHTS] = weights
			arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(surface.indices)
			cached_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var model = MeshInstance3D.new()
	model.mesh = cached_mesh
	model.skin = skeleton.create_skin_from_rest()
	model.skeleton = NodePath("../Skeleton")
	add_child(model)
	for i in range(definition.surfaces.size()):
		var kind: String = definition.surfaces[i].kind
		var material: StandardMaterial3D
		if kind=="skin":
			material = MarchArt.material(Color(str(face.skin)))
			material.roughness = .78
		else:
			material = FieldMaterials.surface("cloth" if kind!="boots" else "timber",Color(str(outfit.coat)) if kind=="coat" else Color("4c443c") if kind=="trousers" else Color("322b25"),3)
		model.set_surface_override_material(i,material)
	var head = attachment("head")
	var origin: Array = definition.head_origin
	var at = Vector3(origin[0],origin[1],origin[2])
	var hair = MarchArt.mesh(head,ContentAssets.mesh(str(face.scalp)),-at+Vector3(0,0,-.01785),FieldMaterials.surface("cloth",Color(str(face.hair)),8))
	hair.scale = Vector3.ONE*(1.85/1.87)
	for center in definition.eyes:
		var eye = Vector3(center[0],center[1],center[2])-at
		HumanFaces.oval(head,eye,Vector3(.0125,.0125,.0125),MarchArt.material(Color("bdb8ac")))
		HumanFaces.oval(head,eye+Vector3(0,0,-.011),Vector3(.0055,.0055,.002),MarchArt.material(Color(str(face.eyes))))
		HumanFaces.oval(head,eye+Vector3(0,0,-.0125),Vector3(.0025,.0025,.001),MarchArt.material(Color("101510")))
	var hand = attachment("wrist_R")
	var steel = FieldMaterials.surface("steel",Color("b8b6aa"),3,.3)
	MarchArt.cylinder(hand,Vector3(0,-.08,0),.025,.17,MarchArt.material(Color("473b2d")),.025,10)
	MarchArt.box(hand,Vector3(0,-.17,0),Vector3(.22,.025,.035),steel)
	MarchArt.box(hand,Vector3(0,-.54,0),Vector3(.043,.73,.012),steel)
	var shield = attachment("wrist_L")
	MarchArt.box(shield,Vector3(0,-.08,-.12),Vector3(.42,.61,.05),FieldMaterials.surface("timber",Color(str(outfit.coat)),3))

func attachment(bone: String) -> BoneAttachment3D:
	var node = BoneAttachment3D.new()
	node.bone_name = bone
	skeleton.add_child(node)
	return node

func pose(knight: Node3D) -> void:
	for pair in [["upperarm01_R",knight.right_arm],["upperarm01_L",knight.left_arm],["lowerarm01_R",knight.right_elbow],["lowerarm01_L",knight.left_elbow],["upperleg01_R",knight.right_leg],["upperleg01_L",knight.left_leg],["lowerleg01_R",knight.right_knee],["lowerleg01_L",knight.left_knee],["spine01",knight.torso]]:
		var rotation_value: Vector3 = pair[1].rotation
		# Lower the anatomical A-pose arms into a relaxed combat stance.
		if pair[0]=="upperarm01_R":
			rotation_value.z -= .67
		elif pair[0]=="upperarm01_L":
			rotation_value.z += .67
		skeleton.set_bone_pose_rotation(skeleton.find_bone(pair[0]),Quaternion.from_euler(rotation_value))
