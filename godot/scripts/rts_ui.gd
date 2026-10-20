class_name CastleUI
extends CanvasLayer
const NAMES={"keep":"قەڵای سەرەکی","stockpile":"کۆگا","woodcutter":"داربڕ","farm":"کێڵگە","mill":"ئاش","bakery":"نانەواخانە","quarry":"کانگە","house":"ماڵ","wall":"دیوار","gate":"دەروازە","barracks":"سەربازگە"}
const STEPS=["١ — کۆگایەک لە نزیک قەڵاکە دابنێ؛ کرێکارەکان بەرهەمەکانیان بۆ ئەوێ دەهێنن.","٢ — داربڕێک دروست بکە. کرێکار دەچێتە دارستان، دار دەبڕێت و دەیگەڕێنێتەوە.","٣ — کێڵگەیەک بنیات بنێ. گەنم سەرەتای زنجیرەی نانە.","٤ — ئاشێک دروست بکە بۆ گۆڕینی گەنم بۆ ئارد.","٥ — نانەواخانە دروست بکە؛ ئارد دەبێتە نان و دەگەڕێتەوە کۆگا.","٦ — سێ بەشی دیوار دروست بکە. ڕێگای کرێکارەکان مەبەستە؛ دەروازە ڕێگا دەهێڵێتەوە.","٧ — سەربازگە بنیات بنێ؛ بەرگری بە سوپا تەواو دەبێت.","٨ — شەش سەرباز ڕابهێنە و چاوەڕێی یەکەم نانی نانەواخانە بکە.","٩ — هێرش دەستی پێ کرد! فەرمانی سوپا هەڵبژێرە، شوێنی بەرگری دابگرە و قەڵاکە بپارێزە.","سەرکەوتوو بوویت — یەکەم گوندت بنیاد نا و هێرشەکەت ڕاگرت."]
var root: Control
var stats: Label
var tutorial: Label
var notice: Label
var intro: PanelContainer
var selected: Label
var controller: Node
var quality: OptionButton
var finish: Label

func button(text: String, action: Callable, parent: Node, width: float=100) -> Button:
	var b=Button.new()
	b.text=text
	b.custom_minimum_size=Vector2(width,46)
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func setup(game: Node) -> void:
	controller=game
	root=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.layout_direction=Control.LAYOUT_DIRECTION_RTL
	var theme=Theme.new()
	theme.default_font=load("res://assets/fonts/vazirmatn.ttf")
	theme.default_font_size=17
	var panel=StyleBoxFlat.new()
	panel.bg_color=Color("172326ed")
	panel.border_color=Color("a18c58")
	panel.set_border_width_all(1)
	panel.set_content_margin_all(12)
	panel.set_corner_radius_all(4)
	theme.set_stylebox("panel","PanelContainer",panel)
	for state in ["normal","hover","pressed","focus"]:
		var style=panel.duplicate()
		style.bg_color=Color("34413b") if state=="hover" else Color("243230")
		theme.set_stylebox(state,"Button",style)
	root.theme=theme
	add_child(root)
	var top=PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom=68
	root.add_child(top)
	var row=HBoxContainer.new()
	top.add_child(row)
	stats=Label.new()
	stats.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(stats)
	quality=OptionButton.new()
	for name in ["Low · ٤ GB","Medium · ٦–٨ GB","High · ٨ GB+"]:
		quality.add_item(name)
	quality.selected=game.quality_index
	quality.item_selected.connect(game.set_quality)
	row.add_child(quality)
	button("پاشەکەوت",game.save_game,row)
	button("وەستان",game.toggle_pause,row)
	button("دەنگ",game.toggle_sound,row)
	var objective=PanelContainer.new()
	objective.position=Vector2(16,82)
	objective.size=Vector2(520,92)
	root.add_child(objective)
	tutorial=Label.new()
	tutorial.custom_minimum_size=Vector2(490,58)
	tutorial.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	objective.add_child(tutorial)
	var bottom=PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top=-154
	root.add_child(bottom)
	var column=VBoxContainer.new()
	bottom.add_child(column)
	var actions=HBoxContainer.new()
	column.add_child(actions)
	selected=Label.new()
	selected.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	actions.add_child(selected)
	button("بنیاتی بنێ",game.confirm_build,actions,130)
	button("فەرمانی سوپا",game.choose_rally,actions,140)
	button("سەرباز · ٢٠ زێڕ",game.train,actions,160)
	button("+",func():game.zoom(-5),actions,50)
	button("−",func():game.zoom(5),actions,50)
	button("⌂",game.locate,actions,50)
	var scroll=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y=65
	column.add_child(scroll)
	var choices=HBoxContainer.new()
	scroll.add_child(choices)
	for kind in CastleSim.COSTS:
		var cost: Array=CastleSim.COSTS[kind]
		button(NAMES[kind]+"\n"+str(cost[0])+" دار · "+str(cost[1])+" بەرد",func():game.choose(kind),choices,120)
	notice=Label.new()
	notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	notice.position=Vector2(240,510)
	notice.size=Vector2(800,45)
	notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(notice)
	intro=PanelContainer.new()
	intro.position=Vector2(330,180)
	intro.size=Vector2(620,330)
	root.add_child(intro)
	var box=VBoxContainer.new()
	box.add_theme_constant_override("separation",14)
	intro.add_child(box)
	var title=Label.new()
	title.text="تاجە ئاسنینەکان — بناغەی قەڵا"
	title.add_theme_font_size_override("font_size",29)
	box.add_child(title)
	var description=Label.new()
	description.text="ئەم دۆڵە ماڵی تۆیە. کۆگا، داربڕ و زنجیرەی نان بنیات بنێ؛ پاشان سوپا ئامادە بکە بۆ ڕاگرتنی یەکەم هێرش.\nنەخشەکە ڕابکێشە بۆ جوڵاندن، بە دوو پەنجە نزیک و دووری بکەرەوە. بینا هەڵبژێرە، شوێن دیاری بکە، پاشان «بنیاتی بنێ» دابگرە."
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size=Vector2(560,140)
	box.add_child(description)
	if FileAccess.file_exists(CastleSim.SAVE):
		button("بەردەوام بە",game.resume,box)
	button("دەستپێکردنی گوندی نوێ",game.new_game,box)
	finish=Label.new()
	finish.position=Vector2(420,250)
	finish.size=Vector2(440,120)
	finish.add_theme_font_size_override("font_size",30)
	finish.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(finish)

func update(sim: CastleSim) -> void:
	stats.text="دار %d   بەرد %d   گەنم %d   ئارد %d   نان %d   زێڕ %d" % [sim.resources.wood,sim.resources.stone,sim.resources.grain,sim.resources.flour,sim.resources.bread,sim.resources.gold]
	tutorial.text=STEPS[sim.stage]
	selected.text=NAMES.get(controller.chosen,"فەرمانی سوپا")+" — شوێنێک لە نەخشە دیاری بکە"
	if not sim.ended.is_empty():
		finish.text="گوندەکەت پاراست!" if sim.ended=="victory" else "قەڵاکەت ڕووخا"
