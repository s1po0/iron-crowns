class_name CrownMap
extends Control
var game: Node
func _ready() -> void:
	custom_minimum_size=Vector2(630,420)
	size=custom_minimum_size
	mouse_filter=Control.MOUSE_FILTER_STOP
func point(town: Dictionary) -> Vector2:
	return Vector2(35+town.at[0]*1.42,20+town.at[1]*1.05)
func _draw() -> void:
	if game==null:return
	draw_rect(Rect2(Vector2.ZERO,size),Color("162626ee"))
	for faction in 4:
		var base=faction*3
		for i in [1,2]:draw_line(point(game.sim.world.settlements[base]),point(game.sim.world.settlements[base+i]),Color("7c7955"),2)
	var font=load("res://assets/fonts/vazirmatn.ttf")
	for t in game.sim.world.settlements:
		var pos=point(t)
		var color=Color(game.sim.world.factions[game.sim.owner(t.id)].color)
		draw_circle(pos,10 if t.kind=="town" else 7,color)
		if t.id==game.picked:draw_circle(pos,15,Color("efd48d"),false,2)
		if t.id==game.sim.state.location:draw_circle(pos,19,Color("8fedd9"),false,2)
		draw_string(font,pos+Vector2(-30,-18),t.name,HORIZONTAL_ALIGNMENT_CENTER,110,16,Color("f0e8cf"))
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		for t in game.sim.world.settlements:
			if event.position.distance_to(point(t))<23:
				game.picked=t.id
				game.refresh()
				accept_event()
				return
