class_name ContentAssets
extends RefCounted

static var directory = ""
static var meshes: Dictionary = {}

static func path(resource: String) -> String:
	if directory.is_empty():
		return resource
	return directory+"/"+resource.trim_prefix("res://")

static func json(resource: String):
	return JSON.parse_string(FileAccess.get_file_as_string(path(resource)))

static func texture(resource: String) -> Texture2D:
	if directory.is_empty():
		return load(resource)
	var image = Image.load_from_file(path(resource))
	assert(image!=null and image.get_width()<=4096 and image.get_height()<=4096,"Invalid content image")
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

static func audio(resource: String) -> AudioStreamWAV:
	if directory.is_empty():
		return load(resource)
	return AudioStreamWAV.load_from_file(path(resource))

static func mesh(resource: String) -> Mesh:
	if meshes.has(resource):
		return meshes[resource]
	if directory.is_empty():
		meshes[resource] = load(resource)
		return meshes[resource]
	# Restricted Wavefront geometry reader: no materials, scripts, scene resources
	# or external references can be loaded from a custom content pack.
	var vertices: Array[Vector3] = []
	var uv: Array[Vector2] = []
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(0)
	var triangles = 0
	for line in FileAccess.get_file_as_string(path(resource)).split("\n"):
		var parts = line.strip_edges().split(" ",false)
		if parts.is_empty():
			continue
		if parts[0]=="v" and parts.size()==4:
			var v = Vector3(float(parts[1]),float(parts[2]),float(parts[3]))
			assert(v.is_finite() and v.length()<10 and vertices.size()<50000,"Invalid model vertex")
			vertices.append(v)
		elif parts[0]=="vt" and parts.size()>=3:
			assert(uv.size()<100000,"Too many texture coordinates")
			uv.append(Vector2(float(parts[1]),float(parts[2])))
		elif parts[0]=="f" and parts.size()>=4 and parts.size()<=9:
			for i in range(2,parts.size()-1):
				triangles += 1
				assert(triangles<=100000,"Model exceeds triangle budget")
				for index in [1,i+1,i]:
					var corner = parts[index].split("/")
					var vertex_id = int(corner[0])-1
					assert(vertex_id>=0 and vertex_id<vertices.size(),"Invalid model index")
					if corner.size()>1 and not corner[1].is_empty():
						var uv_id = int(corner[1])-1
						assert(uv_id>=0 and uv_id<uv.size(),"Invalid UV index")
						surface.set_uv(Vector2(uv[uv_id].x,1-uv[uv_id].y))
					surface.add_vertex(vertices[vertex_id])
	surface.index()
	surface.generate_normals()
	meshes[resource] = surface.commit()
	return meshes[resource]
