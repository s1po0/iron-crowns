class_name ContentBundle
extends RefCounted

const ACTIVE = "user://content/active.json"
const LIMIT = 256*1024*1024
const FILE_LIMIT = 16*1024*1024
const EXTENSIONS = ["png","jpg","wav","obj","json","txt"]
var error = ""
var manifest: Dictionary = {}
var required = ["assets/content/catalog.json","assets/content/world.json","assets/content/humans/human-head.obj","assets/materials/meadow.jpg","assets/audio/wind.wav"]

func _init() -> void:
	for name in ["cloth","earth","masonry","meadow","plaster","roof","steel","timber"]:
		required.append("assets/materials/"+name+".jpg")
		required.append("assets/materials/"+name+"-normal.png")
	for name in ["grass","leaves"]:
		required.append("assets/materials/"+name+".png")
	for name in ["step","swing","clang","impact"]:
		required.append("assets/audio/"+name+".wav")

func validate_manifest(value) -> bool:
	if not value is Dictionary or value.get("api",0)!=1 or value.get("world_id","")!="ashen-marches" or int(value.get("revision",0))<1:
		error = "Unsupported Data API, world or revision."
		return false
	var files = value.get("files",[])
	if not files is Array or files.size()<5 or files.size()>256:
		error = "Invalid Data file table."
		return false
	var names: Dictionary = {}
	var total = 0
	for item in files:
		if not item is Dictionary:
			return false
		var name = str(item.get("path",""))
		var length = int(item.get("bytes",-1))
		if not (name.begins_with("assets/materials/") or name.begins_with("assets/audio/") or name.begins_with("assets/content/")) or ".." in name or "/./" in name or "//" in name or "\u0000" in name or "\\" in name or ":" in name or name in names or not name.get_extension() in EXTENSIONS or length<0 or length>FILE_LIMIT or str(item.get("sha256","")).length()!=64:
			error = "Data contains an unsafe path, unsupported file or invalid size."
			return false
		names[name] = true
		total += length
	if total>LIMIT:
		error = "Data exceeds the supported size budget."
		return false
	for name in required:
		if not names.has(name):
			error = "Required Data resources are missing."
			return false
	manifest = value
	return true

func number_in(value, minimum: float, maximum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=minimum and float(value)<=maximum

func vector_in(value, count: int, limit: float) -> bool:
	if not value is Array or value.size()!=count:
		return false
	for component in value:
		if not number_in(component,-limit,limit):
			return false
	return true

func color_value(value) -> bool:
	return value is String and str(value).length()<=9 and Color.html_is_valid(str(value))

func validate_definitions(directory: String) -> bool:
	var world = JSON.parse_string(FileAccess.get_file_as_string(directory+"/assets/content/world.json"))
	var catalog = JSON.parse_string(FileAccess.get_file_as_string(directory+"/assets/content/catalog.json"))
	if not world is Dictionary or not catalog is Dictionary:
		return false
	if not number_in(world.get("width"),900,6000) or not number_in(world.get("depth"),680,4000):
		return false
	if world.get("schema",0)!=1 or world.get("id","")!="ashen-marches" or float(world.get("width",0))<900 or float(world.get("width",0))>6000 or float(world.get("depth",0))<680 or float(world.get("depth",0))>4000:
		return false
	if not world.get("settlements") is Array or world.settlements.size()<32 or world.settlements.size()>96 or not world.get("factions") is Array or world.factions.size()<4 or world.factions.size()>8:
		return false
	for i in range(world.settlements.size()):
		var s = world.settlements[i]
		if not s is Dictionary or int(s.get("id",-1))!=i or not s.get("at") is Array or s.at.size()!=2 or int(s.get("faction",-1))<0 or int(s.faction)>=world.factions.size() or not s.get("kind","") in ["Town","Castle","Village"]:
			return false
		if not s.get("name") is String or str(s.name).length()>64 or not vector_in(s.at,2,3000):
			return false
		if absf(float(s.at[0]))>float(world.width)*.5 or absf(float(s.at[1]))>float(world.depth)*.5:
			return false
	for faction in world.factions:
		if not faction is Dictionary:
			return false
		if not color_value(faction.get("color")):
			return false
		for key in ["name","color","clan","leader","description"]:
			if not faction.get(key) is String or str(faction[key]).length()>120:
				return false
	if not world.get("anchors") is Array or world.anchors.size()>32 or not world.get("ridges") is Array or world.ridges.size()>64 or not world.get("roads") is Array or world.roads.size()>256:
		return false
	for anchor in world.anchors:
		if not vector_in(anchor,2,3000):
			return false
	for ridge in world.ridges:
		if not vector_in(ridge,3,3000) or not number_in(ridge[2],0,200):
			return false
	var reached: Dictionary = {0:true}
	for edge in world.roads:
		if not edge is Array or edge.size()!=2 or int(edge[0])<0 or int(edge[1])<0 or int(edge[0])>=world.settlements.size() or int(edge[1])>=world.settlements.size():
			return false
	for iteration in range(world.settlements.size()):
		for edge in world.roads:
			if reached.has(int(edge[0])) or reached.has(int(edge[1])):
				reached[int(edge[0])] = true
				reached[int(edge[1])] = true
	if reached.size()!=world.settlements.size():
		return false
	if not catalog.get("equipment") is Array or catalog.equipment.is_empty() or catalog.equipment.size()>64 or not catalog.get("regions") is Array or catalog.regions.is_empty() or not catalog.get("horse") is Dictionary:
		return false
	for outfit in catalog.equipment:
		if not outfit is Dictionary or not outfit.get("armor") is String or not outfit.get("coat") is String or not outfit.get("steel") is bool or not outfit.get("helmet","") in ["closed","open","hood"]:
			return false
		if not color_value(outfit.armor) or not color_value(outfit.coat):
			return false
	for region in catalog.regions:
		if not region is Dictionary or not color_value(region.get("color")):
			return false
	for key in ["walk","trot","canter","health"]:
		if not number_in(catalog.horse.get(key),.01,1000):
			return false
	if not color_value(catalog.horse.get("coat")):
		return false
	var listed: Dictionary = {}
	for item in manifest.files:
		listed["res://"+str(item.path)] = true
	if catalog.get("id","")!="marches-content-v1" or not catalog.get("humans") is Array or catalog.humans.is_empty() or catalog.humans.size()>32:
		return false
	for human in catalog.humans:
		if not human is Dictionary or not listed.has(str(human.get("mesh",""))) or not str(human.mesh).ends_with(".obj") or not listed.has(str(human.get("scalp",""))) or not str(human.scalp).ends_with(".obj"):
			return false
		for key in ["skin","hair","eyes"]:
			if not color_value(human.get(key)):
				return false
		if not number_in(human.get("width",1),.65,1.35):
			return false
	if FileAccess.file_exists(directory+"/assets/content/humans/human-body.json") and not HumanBody.validate(JSON.parse_string(FileAccess.get_file_as_string(directory+"/assets/content/humans/human-body.json"))):
		return false
	for item in manifest.files:
		if str(item.path).ends_with(".obj") and not ContentAssets.validate_obj(FileAccess.get_file_as_string(directory+"/"+str(item.path))):
			return false
	return true

func install(source: String, tree: SceneTree, progress: Callable) -> bool:
	var file = FileAccess.open(source,FileAccess.READ)
	if file==null or file.get_length()>LIMIT or file.get_length()<12 or file.get_buffer(8).get_string_from_ascii()!="ICDATA01":
		error = "Not a supported .icdata file. The old .pck format is not compatible."
		return false
	var length = file.get_32()
	if length<2 or length>131072:
		error = "Invalid Data header."
		return false
	var header = file.get_buffer(length)
	if not validate_manifest(JSON.parse_string(header.get_string_from_utf8())):
		return false
	var expected = 12+length
	for item in manifest.files:
		expected += int(item.bytes)
	if expected!=file.get_length():
		error = "Truncated Data or unexpected trailing bytes."
		return false
	var name = "bundle-"+str(Time.get_unix_time_from_system()).replace(".","-")+"-"+str(randi())
	var directory = "user://content/"+name
	for i in range(manifest.files.size()):
		var item = manifest.files[i]
		var bytes = file.get_buffer(int(item.bytes))
		var digest = HashingContext.new()
		digest.start(HashingContext.HASH_SHA256)
		digest.update(bytes)
		if bytes.size()!=int(item.bytes) or digest.finish().hex_encode()!=str(item.sha256):
			error = "Corrupt Data: "+str(item.path)
			remove_directory(directory)
			return false
		var target_path = directory+"/"+str(item.path)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_path.get_base_dir()))
		var target = FileAccess.open(target_path,FileAccess.WRITE)
		if target==null:
			error = "Cannot write Data. Check free storage."
			remove_directory(directory)
			return false
		target.store_buffer(bytes)
		target.flush()
		var failed = target.get_error()!=OK
		target.close()
		if failed:
			error = "Storage write failed. Existing Data is unchanged."
			remove_directory(directory)
			return false
		progress.call(int(float(i+1)/manifest.files.size()*100))
		await tree.process_frame
	file.close()
	if not validate_definitions(directory):
		error = "Invalid model/world definitions. Existing Data is unchanged."
		remove_directory(directory)
		return false
	var pointer = FileAccess.open(ACTIVE+".tmp",FileAccess.WRITE)
	if pointer==null:
		error = "Cannot activate the Data pack."
		remove_directory(directory)
		return false
	pointer.store_string(JSON.stringify({"directory":name,"manifest":manifest}))
	pointer.flush()
	var failed = pointer.get_error()!=OK
	pointer.close()
	if failed or DirAccess.rename_absolute(ProjectSettings.globalize_path(ACTIVE+".tmp"),ProjectSettings.globalize_path(ACTIVE))!=OK:
		error = "Cannot activate Data. Previous installation is unchanged."
		remove_directory(directory)
		return false
	return true

func installed(tree: SceneTree) -> bool:
	if not FileAccess.file_exists(ACTIVE):
		return false
	var pointer = JSON.parse_string(FileAccess.get_file_as_string(ACTIVE))
	if not pointer is Dictionary or not validate_manifest(pointer.get("manifest")):
		return false
	var name = str(pointer.get("directory",""))
	if not name.begins_with("bundle-") or "/" in name or "\\" in name or ".." in name or ":" in name:
		return false
	var directory = "user://content/"+name
	for item in manifest.files:
		var path = directory+"/"+str(item.path)
		var file = FileAccess.open(path,FileAccess.READ)
		if file==null or file.get_length()!=int(item.bytes):
			return false
		file.close()
		if FileAccess.get_sha256(path)!=str(item.sha256):
			return false
		await tree.process_frame
	if not validate_definitions(directory):
		return false
	ContentAssets.directory = directory
	return true

func remove_directory(path: String) -> void:
	if not path.begins_with("user://content/bundle-"):
		return
	var dir = DirAccess.open(path)
	if dir==null:
		return
	for name in dir.get_files():
		dir.remove(name)
	for name in dir.get_directories():
		remove_directory(path+"/"+name)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
