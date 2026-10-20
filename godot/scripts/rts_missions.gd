class_name CastleMissions
extends RefCounted
const IDS=["valley","crossing","ridge"]
const MAPS={
 "valley":{"title":"١ — دۆڵی سەوز","story":"گوندێکی نوێ لە پەنای ڕووبار بنیاد بنێ. سەرەتا کۆگا و زنجیرەی نان ئامادە بکە؛ پاشان بەرگری لە هێرشەکانی باکوور بکە.","axis":"x","river":[30,32],"bridge":[16,18],"wood":[8,10],"quarry":[8,28],"spawn":[26,7],"waves":[8,12,16],"soldiers":6,"bread":4,"wood_start":220,"stone_start":150,"tint":"aebfae"},
 "crossing":{"title":"٢ — پردی باشوور","story":"ڕووبار گوندەکەت لە کانگەکە جیا دەکاتەوە. پردەکە ڕێگای بەرد و هێرشەکانی باشوورە؛ ڕێگای کرێکاران مەبەستە و بەرگری لە سەری پرد بکە.","axis":"y","river":[25,27],"bridge":[18,21],"wood":[8,10],"quarry":[8,30],"spawn":[6,30],"waves":[10,14,18],"soldiers":8,"bread":8,"wood_start":280,"stone_start":150,"tint":"c5bf9d"},
 "ridge":{"title":"٣ — دەروازەی ڕۆژئاوا","story":"لە زەوییە بەردینەکان قەڵاکەت بنیاد بنێ. دارستان لە لای بەرامبەری ڕووبارە؛ کرێکار و دوژمن هەردووکیان بە پردی ڕۆژئاوا دێن. خواردن و سوپای زیاتر ئامادە بکە.","axis":"x","river":[10,12],"bridge":[14,17],"wood":[7,10],"quarry":[28,28],"spawn":[5,5],"waves":[12,16,20],"soldiers":10,"bread":12,"wood_start":320,"stone_start":200,"tint":"bcb7ab"}
}
static func data(id: String) -> Dictionary:
	return MAPS.get(id,MAPS.valley)
static func point(id: String, key: String) -> Vector2i:
	var p: Array=data(id)[key]
	return Vector2i(p[0],p[1])
static func channel(p: Vector2, id: String) -> bool:
	var m=data(id)
	var axis=p.x if m.axis=="x" else p.y
	return axis>=m.river[0]-.5 and axis<=m.river[1]+.5
static func blocked(p: Vector2i, id: String) -> bool:
	if p.x<3 or p.y<3 or p.x>=37 or p.y>=37:
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
