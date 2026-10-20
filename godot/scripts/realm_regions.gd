class_name RealmRegions
extends RefCounted
# Separate API 2 regions. API 1 base Data remains unchanged and compatible.
const ROOT="user://realm-regions/"
const MAX_BYTES=96*1024*1024
const BLOCK=65536
static var generation=0
static var busy=false
static func fail(input: FileAccess, pending: String, message: String) -> String:
	input.close()
	clean(pending)
	busy=false
	return message
static func clean(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for name in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path+"/"+name)
	DirAccess.remove_absolute(path)
static func install(path: String, tree: SceneTree) -> String:
	if busy:
		return "Another region is being verified."
	var input=FileAccess.open(path,FileAccess.READ)
	if input==null:
		return "Cannot read region."
	busy=true
	var pending=ROOT+"pending"
	clean(pending)
	if input.get_length()>MAX_BYTES or input.get_length()<12 or input.get_buffer(8).get_string_from_ascii()!="ICREG002":
		return fail(input,pending,"Invalid region format or size.")
	var length=input.get_32()
	if length<2 or length>32768 or length>input.get_length()-12:
		return fail(input,pending,"Invalid manifest length.")
	var m=JSON.parse_string(input.get_buffer(length).get_string_from_utf8())
	if not m is Dictionary or m.get("api")!=2 or m.get("world")!="realm-400-v1" or m.get("resolution")!=1024 or m.get("revision")!=1:
		return fail(input,pending,"Unsupported realm manifest.")
	if not m.get("region") is Array or m.region.size()!=2 or not m.get("files") is Array or m.files.size()!=50:
		return fail(input,pending,"Incomplete region.")
	for v in m.region:
		if not CastleSim.valid_number(v,0,4) or v!=int(v):
			return fail(input,pending,"Invalid region coordinates.")
	var rx=int(m.region[0])
	var ry=int(m.region[1])
	var expected={}
	for y in range(ry*5,ry*5+5):
		for x in range(rx*5,rx*5+5):
			for kind in ["albedo","normal"]:
				expected["%d_%d_%s.png" % [x,y,kind]]=true
	var total=12+length
	for entry in m.files:
		if not entry is Dictionary or not entry.get("name") is String or not expected.has(entry.name):
			return fail(input,pending,"Unknown or duplicate texture path.")
		expected.erase(entry.name)
		if not CastleSim.valid_number(entry.get("bytes"),33,8*1024*1024) or entry.bytes!=int(entry.bytes) or not entry.get("sha256") is String or entry.sha256.length()!=64:
			return fail(input,pending,"Invalid texture metadata.")
		total+=int(entry.bytes)
	if total!=input.get_length():
		return fail(input,pending,"Truncated region or trailing data.")
	if DirAccess.make_dir_recursive_absolute(pending)!=OK:
		return fail(input,pending,"Cannot create region storage.")
	for entry in m.files:
		var output=FileAccess.open(pending+"/"+entry.name,FileAccess.WRITE)
		if output==null:
			return fail(input,pending,"Cannot write terrain texture.")
		var hash=HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		var remaining=int(entry.bytes)
		var first=true
		while remaining>0:
			var bytes=input.get_buffer(mini(BLOCK,remaining))
			if bytes.is_empty():
				output.close()
				return fail(input,pending,"Unexpected end of texture.")
			if first:
				# PNG dimensions checked BEFORE decompression; reject zip/image bombs.
				if bytes.size()<33 or bytes.slice(0,8).hex_encode()!="89504e470d0a1a0a" or bytes.slice(12,16).get_string_from_ascii()!="IHDR" or bytes.slice(16,24).hex_encode()!="0000040000000400" or bytes[24]!=8 or bytes[25]!=2:
					output.close()
					return fail(input,pending,"Expected 1024 square RGB PNG.")
				first=false
			hash.update(bytes)
			output.store_buffer(bytes)
			remaining-=bytes.size()
			if output.get_error()!=OK:
				output.close()
				return fail(input,pending,"Storage full or write error.")
			if remaining % (1024*1024)<BLOCK:
				await tree.process_frame
		output.close()
		if hash.finish().hex_encode()!=entry.sha256:
			return fail(input,pending,"Texture checksum mismatch.")
		var image=Image.new()
		if image.load(pending+"/"+entry.name)!=OK or image.get_size()!=Vector2i(1024,1024):
			return fail(input,pending,"Invalid PNG payload.")
	input.close()
	var name="region_%d_%d" % [rx,ry]
	var active=ROOT+name
	var backup=active+".previous"
	clean(backup)
	if DirAccess.dir_exists_absolute(active) and DirAccess.rename_absolute(active,backup)!=OK:
		busy=false
		clean(pending)
		return "Cannot preserve installed region."
	if DirAccess.rename_absolute(pending,active)!=OK:
		if DirAccess.dir_exists_absolute(backup):
			DirAccess.rename_absolute(backup,active)
		busy=false
		return "Cannot activate verified region."
	clean(backup)
	busy=false
	generation+=1
	return ""
static func texture(x: int,y: int,kind: String,quality: int) -> Texture2D:
	var dir=ROOT+"region_%d_%d" % [int(x/5),int(y/5)]
	# Recover a previous generation if the app was killed during replacement.
	if not DirAccess.dir_exists_absolute(dir) and DirAccess.dir_exists_absolute(dir+".previous"):
		DirAccess.rename_absolute(dir+".previous",dir)
	var path=dir+"/%d_%d_%s.png" % [x,y,kind]
	var unified=ContentAssets.directory+"/assets/content/realm/%d_%d_%s.webp" % [x,y,kind]
	if ContentBundle.complete:
		path=unified
	if not FileAccess.file_exists(path):
		return null
	var image=Image.new()
	if image.load(path)!=OK:
		return null
	if quality==0:
		image.resize(512,512,Image.INTERPOLATE_BILINEAR)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
