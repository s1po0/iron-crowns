class_name MarchCatalog
extends RefCounted

static var cache: Dictionary = {}

static func data() -> Dictionary:
	if cache.is_empty():
		var parsed = ContentAssets.json("res://assets/content/catalog.json")
		assert(parsed is Dictionary and parsed.get("id","")=="marches-content-v1","Matching game data is required")
		cache = parsed
	return cache

static func equipment(index: int) -> Dictionary:
	return data().equipment[posmod(index,data().equipment.size())]
