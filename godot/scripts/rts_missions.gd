class_name CastleMissions
extends RefCounted
const LEGACY_IDS=["valley","crossing","ridge"]
const IDS=["realm_valley","realm_crossing","realm_ridge"]
const MAPS={
 "valley":{"title":"١ — دۆڵی سەوز","story":"گوندێکی نوێ لە پەنای ڕووبار بنیاد بنێ. سەرەتا کۆگا و زنجیرەی نان ئامادە بکە؛ پاشان بەرگری لە هێرشەکانی باکوور بکە.","axis":"x","river":[30,32],"bridge":[16,18],"wood":[8,10],"quarry":[8,28],"spawn":[26,7],"waves":[8,12,16],"soldiers":6,"bread":4,"wood_start":220,"stone_start":150,"tint":"aebfae"},
 "crossing":{"title":"٢ — پردی باشوور","story":"ڕووبار گوندەکەت لە کانگەکە جیا دەکاتەوە. پردەکە ڕێگای بەرد و هێرشەکانی باشوورە؛ ڕێگای کرێکاران مەبەستە و بەرگری لە سەری پرد بکە.","axis":"y","river":[25,27],"bridge":[18,21],"wood":[8,10],"quarry":[8,30],"spawn":[6,30],"waves":[10,14,18],"soldiers":8,"bread":8,"wood_start":280,"stone_start":150,"tint":"c5bf9d"},
 "ridge":{"title":"٣ — دەروازەی ڕۆژئاوا","story":"لە زەوییە بەردینەکان قەڵاکەت بنیاد بنێ. دارستان لە لای بەرامبەری ڕووبارە؛ کرێکار و دوژمن هەردووکیان بە پردی ڕۆژئاوا دێن. خواردن و سوپای زیاتر ئامادە بکە.","axis":"x","river":[10,12],"bridge":[14,17],"wood":[7,10],"quarry":[28,28],"spawn":[5,5],"waves":[12,16,20],"soldiers":10,"bread":12,"wood_start":320,"stone_start":200,"tint":"bcb7ab"}
}
static var cache: Dictionary={}
static func data(id: String) -> Dictionary:
	if cache.has(id):
		return cache[id]
	if id.begins_with("realm_"):
		var m: Dictionary=MAPS.get(id.trim_prefix("realm_"),MAPS.valley).duplicate(true)
		m["size"]=400
		m["keep"]=[198,196]
		for key in ["wood","quarry","spawn"]:
			m[key]=[m[key][0]+180,m[key][1]+180]
		for key in ["river","bridge"]:
			m[key]=[m[key][0]+180,m[key][1]+180]
		m.title+=" — شانشینی فراوان"
		cache[id]=m
		return m
	return MAPS.get(id,MAPS.valley)
static func exists(id: String) -> bool:
	return id in IDS or MAPS.has(id)
static func size_for(id: String) -> int:
	return 400 if id in IDS else 40
static func keep(id: String) -> Vector2i:
	return Vector2i(198,196) if id in IDS else Vector2i(18,16)
static func point(id: String, key: String) -> Vector2i:
	var p: Array=data(id)[key]
	return Vector2i(p[0],p[1])
static func channel(p: Vector2, id: String) -> bool:
	var m=data(id)
	var axis=p.x if m.axis=="x" else p.y
	return axis>=m.river[0]-.5 and axis<=m.river[1]+.5
static func blocked(p: Vector2i, id: String) -> bool:
	if p.x<3 or p.y<3 or p.x>=size_for(id)-3 or p.y>=size_for(id)-3:
		return true
	var m=data(id)
	var axis=p.x if m.axis=="x" else p.y
	var cross=p.y if m.axis=="x" else p.x
	return axis>=m.river[0] and axis<=m.river[1] and not (cross>=m.bridge[0] and cross<=m.bridge[1])
static func bridge_center(id: String) -> Vector2:
	var m=data(id)
	var a=(m.river[0]+m.river[1])*.5
	var b=(m.bridge[0]+m.bridge[1])*.5
	return Vector2(a,b) if m.axis=="x" else Vector2(b,a)

static func outposts(id: String) -> Array[Vector2i]:
	var points: Array[Vector2i]=[]
	if size_for(id)==400:
		for p in [Vector2i(232,202),Vector2i(165,230),Vector2i(245,165),Vector2i(90,90),Vector2i(320,80),Vector2i(85,320),Vector2i(325,325),Vector2i(150,80),Vector2i(320,230),Vector2i(80,210),Vector2i(230,330),Vector2i(150,310)]:
			if not blocked(p,id):
				points.append(p)
	return points
