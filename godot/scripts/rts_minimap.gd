class_name CastleMinimap
extends Control
var game: Node
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	custom_minimum_size=Vector2(160,160)
	size=custom_minimum_size
func _process(_dt: float) -> void:
	visible=game!=null and game.started
	if visible:
		queue_redraw()
func _draw() -> void:
	if game==null:
		return
	for y in CastleSim.SIZE:
		for x in CastleSim.SIZE:
			var p=Vector2i(x,y)
			draw_rect(Rect2(Vector2(p)*4,Vector2(4,4)),Color("3d7989") if CastleMissions.blocked(p,game.sim.mission_id) else Color("657457"))
	for b in game.sim.buildings:
		draw_rect(Rect2(Vector2(b.x,b.y)*4,Vector2.ONE*CastleSim.FOOTPRINT[b.kind]*4),Color("dfc786"))
	for key in ["wood","quarry"]:
		draw_circle(Vector2(CastleMissions.point(game.sim.mission_id,key))*4,4,Color("1c4528") if key=="wood" else Color("c4c3ba"))
	for u in game.sim.units:
		if u.hp>0:
			draw_circle(u.at*4,2,Color("e76b5d") if u.kind=="raider" else Color("a2e6de"))
	draw_circle(Vector2(CastleSim.cell(game.focus))*4,6,Color.WHITE,false,1.5)
	draw_rect(Rect2(Vector2.ZERO,size),Color("d6bb73"),false,2)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		game.focus=CastleSim.world((event.position/4).clamp(Vector2(3,3),Vector2(36,36)))
		accept_event()
