class_name MarchCatalog
extends RefCounted

static var cache: Dictionary = {}

static func data() -> Dictionary:
	if cache.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/content/catalog.json"))
		assert(parsed is Dictionary and parsed.get("id","")=="marches-riders-0.6","Matching game data is required")
		cache = parsed
	return cache

static func equipment(index: int) -> Dictionary:
	return data().equipment[posmod(index,data().equipment.size())]
