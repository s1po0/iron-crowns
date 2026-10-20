class_name CastleUI
extends CanvasLayer
const NAMES={"keep":"قەڵای سەرەکی","stockpile":"کۆگا","woodcutter":"داربڕ","farm":"کێڵگە","mill":"ئاش","bakery":"نانەواخانە","quarry":"کانگە","house":"ماڵ","wall":"دیوار","gate":"دەروازە","barracks":"سەربازگە"}
const STEPS=["١ — کۆگایەک لە نزیک قەڵاکە دابنێ؛ کرێکارەکان بەرهەمەکانیان بۆ ئەوێ دەهێنن.","٢ — داربڕێک دروست بکە. کرێکار دەچێتە دارستان، دار دەبڕێت و دەیگەڕێنێتەوە.","٣ — کێڵگەیەک بنیات بنێ. گەنم سەرەتای زنجیرەی نانە.","٤ — ئاشێک دروست بکە بۆ گۆڕینی گەنم بۆ ئارد.","٥ — نانەواخانە دروست بکە؛ ئارد دەبێتە نان و دەگەڕێتەوە کۆگا.","٦ — سێ بەشی دیوار دروست بکە. ڕێگای کرێکارەکان مەبەستە؛ دەروازە ڕێگا دەهێڵێتەوە.","٧ — سەربازگە بنیات بنێ؛ بەرگری بە سوپا تەواو دەبێت.","٨ — ماڵێک دروست بکە (+٤ شوێن)، شەش سەرباز ڕابهێنە و ٤ نان بەرهەم بهێنە.","٩ — هێرش دەستی پێ کرد! فەرمانی سوپا هەڵبژێرە، شوێنی بەرگری دابگرە و قەڵاکە بپارێزە.","سەرکەوتوو بوویت — گوندەکەت لە سێ هێرش پاراست."]
var root: Control
var stats: Label
var tutorial: Label
var notice: Label
var intro: PanelContainer
var selected: Label
var controller: Node
var quality: OptionButton
var finish: Label
var restart: Button
var management: HBoxContainer
var management_info: Label
var pause_button: Button
var build_button: Button
var save_button: Button
var train_button: Button
var placement_panel: PanelContainer
var placement_help: Label
var suggest_button: Button
var cancel_button: Button
var building_buttons: Dictionary={}
var mission_buttons: Array[Button]=[]
var briefing: Label
var next_button: Button
var minimap: CastleMinimap

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
	stats.clip_text=true
	stats.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(stats)
	quality=OptionButton.new()
	for name in ["Low · ٤ GB","Medium · ٦–٨ GB","High · ٨ GB+"]:
		quality.add_item(name)
	quality.selected=game.quality_index
	quality.item_selected.connect(game.set_quality)
	row.add_child(quality)
	save_button=button("پاشەکەوت",game.save_game,row)
	pause_button=button("وەستان",game.toggle_pause,row)
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
	bottom.offset_top=-214
	root.add_child(bottom)
	var column=VBoxContainer.new()
	bottom.add_child(column)
	var actions=HBoxContainer.new()
	column.add_child(actions)
	selected=Label.new()
	selected.clip_text=true
	selected.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	actions.add_child(selected)
	button("فەرمانی سوپا",game.choose_rally,actions,140)
	button("بەڕێوەبردن",game.inspect,actions,120)
	train_button=button("سەرباز · ٢٠ زێڕ",game.train,actions,160)
	button("+",func():game.zoom(-5),actions,50)
	button("−",func():game.zoom(5),actions,50)
	button("⌂",game.locate,actions,50)
	var choices=GridContainer.new()
	choices.columns=5
	column.add_child(choices)
	for kind in CastleSim.COSTS:
		var cost: Array=CastleSim.COSTS[kind]
		var choice=button(NAMES[kind]+" · "+str(cost[0])+" دار · "+str(cost[1])+" بەرد",func():game.choose(kind),choices,160)
		choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		choice.add_theme_font_size_override("font_size",16)
		building_buttons[kind]=choice
	placement_panel=PanelContainer.new()
	placement_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	placement_panel.offset_top=-304
	placement_panel.offset_bottom=-220
	root.add_child(placement_panel)
	var placement_row=HBoxContainer.new()
	placement_panel.add_child(placement_row)
	build_button=button("دروست بکە",game.confirm_build,placement_row,250)
	build_button.custom_minimum_size.y=56
	build_button.add_theme_font_size_override("font_size",24)
	var build_style=panel.duplicate()
	build_style.bg_color=Color("386d49")
	build_style.border_color=Color("d6bb73")
	build_button.add_theme_stylebox_override("normal",build_style)
	suggest_button=button("شوێنی گونجاو",game.suggest_site,placement_row,180)
	cancel_button=button("هەڵوەشاندنەوە",game.cancel_build,placement_row,160)
	placement_help=Label.new()
	placement_help.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	placement_help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	placement_help.custom_minimum_size.x=220
	placement_row.add_child(placement_help)
	management=HBoxContainer.new()
	management.size=Vector2(540,60)
	management.position=Vector2(16,435)
	root.add_child(management)
	button("دەروازە: کردنەوە / داخستن",func():game.manage("gate"),management,240)
	button("چاککردنەوە",func():game.manage("repair"),management,145)
	button("ڕووخاندن",func():game.manage("demolish"),management,125)
	management_info=Label.new()
	management_info.size=Vector2(1000,40)
	management_info.position=Vector2(20,490)
	management_info.add_theme_color_override("font_color",Color("fff1c5"))
	root.add_child(management_info)
	notice=Label.new()
	notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	notice.position=Vector2(120,365)
	notice.size=Vector2(1040,45)
	notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(notice)
	intro=PanelContainer.new()
	intro.position=Vector2(240,90)
	intro.size=Vector2(800,510)
	root.add_child(intro)
	var box=VBoxContainer.new()
	box.add_theme_constant_override("separation",14)
	intro.add_child(box)
	var title=Label.new()
	title.text="تاجە ئاسنینەکان — بناغەی قەڵا"
	title.add_theme_font_size_override("font_size",29)
	box.add_child(title)
	var map_row=HBoxContainer.new()
	box.add_child(map_row)
	for index in CastleMissions.IDS.size():
		var id=CastleMissions.IDS[index]
		var pick=button(CastleMissions.data(id).title,func():game.select_mission(index),map_row,240)
		pick.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		mission_buttons.append(pick)
	var description=Label.new()
	briefing=description
	description.text="ئەم دۆڵە ماڵی تۆیە. کۆگا، داربڕ و زنجیرەی نان بنیات بنێ؛ پاشان سوپا ئامادە بکە بۆ ڕاگرتنی سێ هێرش.\nنەخشەکە ڕابکێشە بۆ جوڵاندن، بە دوو پەنجە نزیک و دووری بکەرەوە. بینا هەڵبژێرە، «شوێنی گونجاو» دابگرە، پاشان دوگمەی سەوزی «دروست بکە» دابگرە."
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size=Vector2(760,200)
	box.add_child(description)
	refresh_briefing()
	if FileAccess.file_exists(CastleSim.SAVE):
		button("بەردەوام بە",game.resume,box)
	button("دەستپێکردنی میشن",game.new_game,box)
	finish=Label.new()
	finish.position=Vector2(420,250)
	finish.size=Vector2(440,120)
	finish.add_theme_font_size_override("font_size",30)
	finish.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(finish)
	restart=button("هەڵبژاردنی نەخشە",game.restart,root,220)
	restart.position=Vector2(420,380)
	restart.visible=false
	next_button=button("میشنی داهاتوو",game.next_mission,root,220)
	next_button.position=Vector2(650,380)
	next_button.visible=false
	minimap=CastleMinimap.new()
	minimap.game=game
	minimap.size=Vector2(160,160)
	minimap.position=Vector2(18,190)
	root.add_child(minimap)

func refresh_briefing() -> void:
	var m=CastleMissions.data(controller.selected_mission)
	for i in mission_buttons.size():
		mission_buttons[i].modulate=Color("ffe1a0") if CastleMissions.IDS[i]==controller.selected_mission else Color.WHITE
	briefing.text=m.story+"\n\nئامادەکاری: %d سەرباز و %d نانی بەرهەمهاتوو؛ سێ هێرش: %d / %d / %d.\nکۆگا ← داربڕ ← کێڵگە ← ئاش ← نانەواخانە.\nبینا هەڵبژێرە ← شوێنی گونجاو ← دوگمەی سەوزی دروست بکە. نەخشە بچووکەکە بۆ گواستنەوەی کامێرایە." % [m.soldiers,m.bread,m.waves[0],m.waves[1],m.waves[2]]

func update(sim: CastleSim) -> void:
	stats.text="دار %d   بەرد %d   گەنم %d   ئارد %d   نان %d   زێڕ %d" % [sim.resources.wood,sim.resources.stone,sim.resources.grain,sim.resources.flour,sim.resources.bread,sim.resources.gold]
	stats.text+="\nدانیشتووان %d/%d   ڕەزامەندی %d%%   قەڵا %d/600   هێرش %d/3" % [sim.population(),sim.capacity(),sim.morale,sim.buildings[0].hp,sim.wave]
	pause_button.text="بەردەوام بە" if controller.paused else "وەستان"
	placement_panel.visible=controller.started and CastleSim.COSTS.has(controller.chosen) and sim.ended.is_empty()
	build_button.disabled=not controller.started or controller.paused or not sim.ended.is_empty()
	suggest_button.disabled=build_button.disabled
	build_button.text="دروست بکە: "+NAMES.get(controller.chosen,"")
	placement_help.text=controller.placement_message()
	for kind in building_buttons:
		building_buttons[kind].modulate=Color("ffe1a0") if kind==controller.chosen else Color.WHITE
	train_button.disabled=not controller.started or controller.paused or not sim.ended.is_empty() or sim.population()>=sim.capacity() or sim.resources.gold<20 or sim.resources.bread<2 or sim.by_kind("barracks").is_empty()
	management.visible=controller.started and controller.chosen=="inspect" and sim.ended.is_empty()
	management_info.visible=management.visible
	management_info.text="بینایەک لە نەخشە هەڵبژێرە."
	if management.visible:
		var b=sim.at_building(controller.placement)
		if not b.is_empty():
			var missing=CastleSim.max_health(b.kind)-b.hp
			management_info.text="%s — تەندروستی %d/%d — بنیاتنان %d%% — چاککردنەوە: %d دار، %d بەرد" % [NAMES[b.kind],b.hp,CastleSim.max_health(b.kind),b.built*100,ceili(missing/40),ceili(missing/20)]
			if b.kind=="gate":
				management_info.text+=" — کراوە" if b.get("open",true) else " — داخراوە"
	tutorial.text=STEPS[sim.stage]
	if sim.stage==7:
		var m=CastleMissions.data(sim.mission_id)
		tutorial.text="ماڵ بۆ شوێنی نیشتەجێبوون دروست بکە؛ %d سەرباز و %d نانی بەرهەمهاتوو ئامادە بکە." % [m.soldiers,m.bread]
	if sim.stage==8 and not sim.units.any(func(u):return u.kind=="raider" and u.hp>0):
		tutorial.text="هێرشی داهاتوو: %d چرکە. بیناکان چاک بکەرەوە، نان کۆ بکەرەوە و سوپا زیاد بکە." % ceili(sim.wave_clock)
	elif sim.population()>=sim.capacity() and sim.stage<8:
		tutorial.text+="\nشوێن پڕە؛ ماڵێکی تر دروست بکە."
	selected.text=NAMES.get(controller.chosen,"بەڕێوەبردنی بینا" if controller.chosen=="inspect" else "فەرمانی سوپا")+" — شوێنێک لە نەخشە دیاری بکە"
	restart.visible=controller.started and not sim.ended.is_empty()
	next_button.visible=controller.started and sim.ended=="victory" and CastleMissions.IDS.find(sim.mission_id)<CastleMissions.IDS.size()-1
	if not sim.ended.is_empty():
		finish.text="گوندەکەت لە سێ هێرش پاراست!" if sim.ended=="victory" else "قەڵاکەت ڕووخا"
