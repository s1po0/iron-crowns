class_name CrownStory
extends RefCounted
const IDS=["arrival","work","contract","family","service","vassal","governor","war"]
const CACHE="user://crown-chronicle.json"
static func valid(value) -> bool:
	if not value is Dictionary or value.get("schema")!=1 or value.get("id")!="court-road-v1" or not CastleSim.valid_number(value.get("revision"),1,100000) or value.revision!=int(value.revision):
		return false
	if not value.get("title") is String or value.title.length()>100 or not value.get("chapters") is Array or value.chapters.size()!=8:
		return false
	var seen={}
	for c in value.chapters:
		if not c is Dictionary or not c.get("id") in IDS or seen.has(c.id):
			return false
		for key in ["title","text"]:
			if not c.get(key) is String or c[key].is_empty() or c[key].length()>(800 if key=="text" else 100):
				return false
		seen[c.id]=true
	return true
static func load_pack() -> Dictionary:
	var base=JSON.parse_string(FileAccess.get_file_as_string("res://campaign/chronicle.json"))
	var file=FileAccess.open(CACHE,FileAccess.READ)
	if file!=null and file.get_length()<=131072:
		var cached=JSON.parse_string(file.get_as_text())
		file.close()
		if valid(cached) and cached.revision>=base.revision:
			return cached
	return base
static func accept(value) -> bool:
	if not valid(value) or value.revision<load_pack().revision:
		return false
	var f=FileAccess.open(CACHE+".tmp",FileAccess.WRITE)
	if f==null:
		return false
	f.store_string(JSON.stringify(value))
	f.flush()
	var ok=f.get_error()==OK
	f.close()
	return ok and DirAccess.rename_absolute(CACHE+".tmp",CACHE)==OK
