class_name CastleMinimap
extends Control
var game: Node
var terrain: ImageTexture
var map_id=""
var clock=0.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	custom_minimum_size=Vector2(160,160)
	size=custom_minimum_size
func _process(dt: float) -> void:
	visible=game!=null and game.started
	clock+=dt
	if visible and clock>.1:
		clock=0
		queue_redraw()
func _draw() -> void:
	if game==null:
		return
	var n=game.sim.grid_size
	var scale=160.0/n
	if map_id!=game.sim.mission_id or terrain==null:
		map_id=game.sim.mission_id
		var image=Image.create(n,n,false,Image.FORMAT_RGB8)
		for y in n:
			for x in n:
				image.set_pixel(x,y,Color("3d7989") if CastleMissions.blocked(Vector2i(x,y),map_id) else Color("657457"))
		terrain=ImageTexture.create_from_image(image)
	draw_texture_rect(terrain,Rect2(Vector2.ZERO,size),false)
	for b in game.sim.buildings:
		draw_rect(Rect2(Vector2(b.x,b.y)*scale,Vector2.ONE*maxf(2,CastleSim.FOOTPRINT[b.kind]*scale)),Color("dfc786"))
	for key in ["wood","quarry"]:
		draw_circle(Vector2(CastleMissions.point(map_id,key))*scale,3,Color("1c4528") if key=="wood" else Color("c4c3ba"))
	var sites=CastleMissions.outposts(map_id)
	for i in sites.size():
		draw_circle(Vector2(sites[i])*scale,3,Color("73c98e") if i in game.sim.claimed else Color("ebaf60"))
	for u in game.sim.units:
		if u.hp>0:
			draw_circle(u.at*scale,2,Color("e76b5d") if u.kind=="raider" else Color("a2e6de"))
	draw_circle(Vector2(CastleSim.cell(game.focus))*scale,5,Color.WHITE,false,1.5)
	draw_rect(Rect2(Vector2.ZERO,size),Color("d6bb73"),false,2)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var n=game.sim.grid_size
		game.focus=CastleSim.world((event.position*n/160.0).clamp(Vector2(3,3),Vector2(n-4,n-4)))
		accept_event()
