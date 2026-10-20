extends Node3D
var sim=CrownSim.new()
var town: CrownTown
var cloud=CrownCloud.new()
var story: Dictionary
var picked=2
var tab="daily"
var page="town"
var map: CrownMap
var stats: Label
var info: Label
var notice: Label
var remote: Label
var detail: RichTextLabel
var actions: GridContainer
var body: Control
var buttons: Dictionary={}
var capture_clock=0.0
var new_confirm_until=0
var save_locked=false
func _ready() -> void:
	Input.emulate_mouse_from_touch=true
	Engine.max_fps=30
	get_viewport().scaling_3d_scale=.7
	get_viewport().msaa_3d=Viewport.MSAA_DISABLED
	story=CrownStory.load_pack()
	if FileAccess.file_exists(CrownSim.SAVE) and not sim.restore():
		save_locked=true
		sim.message="پاشەکەوتەکە نەخوێندرایەوە؛ فایلە کۆنەکە پارێزراوە. بۆ دەستپێکی نوێ پشتڕاست بکەرەوە."
	picked=sim.state.location
	add_child(cloud)
	cloud.completed.connect(func(ok,text):
		remote.text=text
		if ok:story=CrownStory.load_pack()
		refresh())
	make_ui()
	rebuild_town()
	refresh()
	if not "--crown-offline" in OS.get_cmdline_user_args():cloud.refresh()
	print("IRON_CROWN_READY")
func label(text: String,parent: Node,width: int=0) -> Label:
	var node=Label.new();node.text=text;node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if width>0:node.custom_minimum_size.x=width
	parent.add_child(node);return node
func button(text: String,call: Callable,parent: Node,width: int=120,key: String="") -> Button:
	var b=Button.new();b.text=text;b.custom_minimum_size=Vector2(width,44);b.pressed.connect(call);parent.add_child(b)
	if not key.is_empty():buttons[key]=b
	return b
func panel(parent: Node,rect: Rect2) -> VBoxContainer:
	var p=PanelContainer.new();p.position=rect.position;p.size=rect.size;parent.add_child(p)
	var box=VBoxContainer.new();p.add_child(box);return box
func make_ui() -> void:
	var canvas=CanvasLayer.new();add_child(canvas)
	body=Control.new();body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);body.mouse_filter=Control.MOUSE_FILTER_IGNORE
	body.layout_direction=Control.LAYOUT_DIRECTION_RTL
	var theme=Theme.new();theme.default_font=load("res://assets/fonts/vazirmatn.ttf");theme.default_font_size=17
	var style=StyleBoxFlat.new();style.bg_color=Color("142526f2");style.border_color=Color("b19a60");style.set_border_width_all(1);style.set_content_margin_all(12)
	theme.set_stylebox("panel","PanelContainer",style)
	for state in ["normal","hover","pressed","focus"]:
		var box=style.duplicate();box.bg_color=Color("405048") if state=="hover" else Color("253734");theme.set_stylebox(state,"Button",box)
	body.theme=theme;canvas.add_child(body)
	var top=panel(body,Rect2(12,8,1256,76));stats=label("",top,1220)
	var left=panel(body,Rect2(12,94,652,68));var links=HBoxContainer.new();left.add_child(links)
	for entry in [["town","شوێن"],["map","نەخشە"],["court","خانەدان"],["story","چیرۆک"]]:
		button(entry[1],func():page=entry[0];refresh(),links,145,entry[0])
	map=CrownMap.new();map.game=self;map.position=Vector2(18,175);body.add_child(map)
	detail=RichTextLabel.new();detail.position=Vector2(20,180);detail.size=Vector2(630,400);detail.add_theme_stylebox_override("normal",style);detail.bbcode_enabled=false;detail.scroll_active=true;body.add_child(detail)
	var right=panel(body,Rect2(682,94,586,485))
	info=label("",right,554);info.custom_minimum_size.y=98
	var tabs=HBoxContainer.new();right.add_child(tabs)
	for entry in [["daily","ڕۆژانە"],["army","سوپا"],["court","دربار"],["quest","ئەرک"]]:button(entry[1],func():tab=entry[0];refresh(),tabs,130,"tab_"+entry[0])
	actions=GridContainer.new();actions.columns=2;right.add_child(actions)
	var foot=panel(body,Rect2(12,590,1256,118));notice=label("",foot,1220);notice.custom_minimum_size.y=38
	var row=HBoxContainer.new();foot.add_child(row)
	button("پاشەکەوت",save_campaign,row,125,"save")
	button("قەڵا · بەشی کۆن",castle,row,170,"castle")
	button("دەستپێکی نوێ",new_campaign,row,140,"new")
	button("چیرۆکی Supabase",func():remote.text="پەیوەندی…";cloud.refresh(),row,190,"cloud")
	remote=label("چیرۆکی ئۆفلاین · v%d" % story.revision,row,510)
func rebuild_town() -> void:
	if town!=null:
		town.visible=false;town.process_mode=Node.PROCESS_MODE_DISABLED;town.queue_free()
	town=CrownTown.new();add_child(town);town.setup(sim)
func act(action: Callable,rebuild: bool=false) -> void:
	if save_locked:
		sim.message="سەرەتا دەستپێکی نوێ پشتڕاست بکەرەوە؛ پاشەکەوتە کۆنەکە نانووسرێتەوە.";refresh();return
	var old=sim.state.location
	var ok=action.call()
	if ok:
		if not sim.save():sim.message+=" — پاشەکەوت نەکرا؛ بۆشایی ئامێر بپشکنە."
		if rebuild or old!=sim.state.location:rebuild_town()
	refresh()
func add_action(key: String,text: String,action: Callable,rebuild: bool=false) -> void:
	button(text,func():act(action,rebuild),actions,272,key)
func refresh() -> void:
	var s=sim.state
	stats.text="%s · %s   |   ڕۆژ %d   |   زێڕ %d   |   خواردن %d   |   ناوبانگ %d\nسوپا %d/%d · مووچەی هەفتانە %d · ڕەزامەندی %d%% · تەندروستی %d%%" % [s.name,CrownSim.RANKS[sim.rank()],s.day,s.gold,s.food,s.renown,sim.count(),sim.capacity(),sim.wages(),s.morale,s.health]
	var t=sim.world.settlements[s.location]
	info.text="ئێستا: %s — %s\nخەڵک %d · خانوو %d · پاسەوان %d\nخانەدان: %s · متمانە %d" % [t.name,sim.world.factions[sim.owner()].name,s.population[s.location],s.houses[s.location],s.garrisons[s.location],sim.world.factions[sim.owner()].house,s.relations[sim.owner()]]
	map.visible=page=="map";map.queue_redraw();detail.visible=page in ["court","story"]
	if page=="court":
		detail.text="خانەدانەکان و پەیوەندییەکان\n\n"
		for f in sim.world.factions:
			detail.text+=f.name+" — "+f.house+"\n"
			for person in f.members:detail.text+="%s · %s · %d ساڵ\n" % [person.name,person.role,person.age]
			detail.text+="\n"
		detail.text+="ئاگرین / شیناو: "+("شەڕ" if s.wars[0] else "ئاشتی")+"\nبەردەوان / ڕۆژهەڵات: "+("شەڕ" if s.wars[1] else "ئاشتی")
	elif page=="story":
		detail.text=story.title+"\n\n"
		for c in story.chapters:detail.text+=c.title+"\n"+c.text+"\n\n"
		detail.text+="تۆماری گەشت\n"+"\n".join(s.journal)
	for child in actions.get_children():actions.remove_child(child);child.queue_free()
	if page=="map":
		info.text+="\nمەبەست: "+sim.world.settlements[picked].name
		add_action("travel","گەشت بۆ مەبەست",func():return sim.travel(picked),true)
	if tab=="daily":
		add_action("work","کار · +٣٥ زێڕ",sim.work)
		add_action("rest","پشوودان · ١ ڕۆژ",sim.rest)
		add_action("food","١٠ خواردن · ٢٠ زێڕ",sim.buy_food)
		add_action("home","ماڵ · ٢٥٠ زێڕ",sim.buy_home)
		add_action("housing","خانووسازی · ١٢٠ زێڕ",sim.build_housing,true)
	elif tab=="army":
		info.text+="\nخۆبەخش %d · پیادە %d · پاسەوان %d · سوار %d · هێز %d" % [s.party.levy,s.party.infantry,s.party.guard,s.party.cavalry,sim.power()]
		add_action("recruit","٣ خۆبەخش · ٤٥ زێڕ",sim.recruit,true)
		add_action("train","٤ پیادە · ٤٠ زێڕ",func():return sim.train("infantry"))
		add_action("guard","٤ پاسەوان · ١٠٠ زێڕ",func():return sim.train("guard"))
		add_action("cavalry","٤ سوار · ١٠٠ زێڕ",func():return sim.train("cavalry"))
		add_action("reinforce","٨ پاسەوانی قەڵا · ٤٠ زێڕ",sim.reinforce)
		add_action("attack","هێرش · بەرگری %d" % (s.garrisons[s.location]*2),sim.attack,true)
	elif tab=="court":
		add_action("audience","دیداری خانەدان",sim.audience)
		add_action("gift","دیاری · ٢٠ زێڕ",sim.gift)
		add_action("swear","سوێندی خزمەت",sim.swear,true)
		add_action("petition","داوای والیبوون",sim.petition,true)
	else:
		add_action("courier","نامە · ئەرکی نوێ",func():return sim.take_contract("courier"))
		add_action("escort","پاراستنی کاروان",func():return sim.take_contract("escort"))
		add_action("relief","گەیاندنی خواردن",func():return sim.take_contract("relief"))
		add_action("deliver","تەواوکردنی ئەرک",sim.deliver)
		if not s.contract.is_empty():info.text+="\nئەرک: %s · تا ڕۆژی %d" % [sim.world.settlements[s.contract.destination].name,s.contract.deadline]
	notice.text=sim.message if not sim.message.is_empty() else "لە شوێنی سێ‌ڕەهەندی دابگرە بۆ ڕۆیشتنی کەسەکەت؛ لە نەخشە مەبەست هەڵبژێرە بۆ گەشت."
func save_campaign() -> void:
	if save_locked:return
	sim.message="کەمپەین پاشەکەوت کرا." if sim.save() else "پاشەکەوت نەکرا؛ فایلە کۆنەکە نەگۆڕدرا."
	refresh()
func new_campaign() -> void:
	if Time.get_ticks_msec()>new_confirm_until:
		new_confirm_until=Time.get_ticks_msec()+5000
		sim.message="بۆ دەستپێکی نوێ دووبارە لە ٥ چرکەدا دابگرە؛ کۆپیی پاشەکەوتی کۆن دەپارێزرێت.";refresh();return
	if FileAccess.file_exists(CrownSim.SAVE) and DirAccess.copy_absolute(CrownSim.SAVE,CrownSim.SAVE+".backup-"+str(Time.get_ticks_msec()))!=OK:
		sim.message="کۆپی نەکرا؛ کەمپەینەکە نەگۆڕدرا.";refresh();return
	sim=CrownSim.new();picked=2;new_confirm_until=0;save_locked=false
	sim.save();rebuild_town();refresh()
func castle() -> void:
	if not save_locked and not sim.save():sim.message="پاشەکەوت نەکرا؛ بەشەکە نەگۆڕدرا.";refresh();return
	get_tree().change_scene_to_file("res://rts.tscn")
func _unhandled_input(event: InputEvent) -> void:
	if page=="town" and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:town.walk(event.position)
func _process(dt: float) -> void:
	if "--crown-capture" in OS.get_cmdline_user_args():
		capture_clock+=dt
		if capture_clock>4:
			get_viewport().get_texture().get_image().save_png("/tmp/iron-crown-campaign.png")
			print("IRON_CROWN_RENDER_PASS");get_tree().quit()
func _notification(what: int) -> void:
	if not save_locked and what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_WM_CLOSE_REQUEST]:sim.save()
