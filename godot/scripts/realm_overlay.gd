class_name RealmOverlay
extends RefCounted

static func draw(h) -> void:
	var g = h.game
	var r = g.realm
	# Restrained bronze/parchment typography over actual relief, not a flat schematic.
	h.panel(Rect2(20,18,345,84),Color(.055,.075,.073,.92),7,Color(.64,.55,.36,.5))
	h.label("THE ASHEN MARCHES",Vector2(39,53),25,h.white,h.heading)
	h.label("CAMPAIGN  /  32 SETTLEMENTS  /  4 REALMS",Vector2(40,80),11,h.gold)
	h.panel(Rect2(385,18,583,55),Color(.055,.075,.073,.91),7)
	h.label("DAY "+str(r.day),Vector2(405,52),17,h.white)
	h.label(str(g.gold)+" GOLD",Vector2(505,52),16,h.gold)
	h.label(str(r.food)+" FOOD",Vector2(650,52),16,h.white)
	h.label(str(g.living(0))+" TROOPS",Vector2(790,52),16,h.white)
	h.button("field","FIELD CAMP",Rect2(988,18,188,55))
	h.button("pause","II",Rect2(1192,18,66,55))
	# Town names at overview; castles and villages appear as the camera zooms in.
	var occupied: Array = []
	for i in range(r.settlements.size()):
		var s = r.settlements[i]
		if s.kind=="Village" and r.zoom>350 and i!=r.selected:
			continue
		if s.kind=="Castle" and r.zoom>620 and i!=r.selected:
			continue
		var world = r.position+r.terrain_point(s.at,8)
		if g.camera.is_position_behind(world):
			continue
		var at = g.camera.unproject_position(world)*h.base/h.size
		if at.x<30 or at.x>1240 or at.y<118 or at.y>595 or (r.selected>=0 and at.x>956):
			continue
		var box = Rect2(at-Vector2(74,6),Vector2(148,35))
		var overlap = false
		for previous in occupied:
			if previous.intersects(box):
				overlap = true
		if overlap and i!=r.selected:
			continue
		occupied.append(box)
		var color = h.gold if r.holdings.has(i) else r.COLORS[s.faction]
		h.panel(Rect2(at-Vector2(77,8),Vector2(154,42)),Color(.05,.07,.07,.93 if i==r.selected else .78),5,color if i==r.selected else Color.TRANSPARENT)
		var font_size = 15 if s.kind=="Town" else 12
		h.centered(s.name.to_upper(),at+Vector2(1,9),font_size,Color(.04,.04,.03,.9),h.heading)
		h.centered(s.name.to_upper(),at+Vector2(0,8),font_size,h.white,h.heading)
		h.draw_line(at+Vector2(-24,15),at+Vector2(24,15),color,3)
		if s.kind=="Town" or i==r.selected:
			h.centered("YOUR FIEF" if r.holdings.has(i) else s.kind.to_upper(),at+Vector2(0,30),9,h.muted)
	# Animated road traffic is real campaign state, not decorative moving dots.
	if r.zoom<460:
		for npc in r.civilians:
			if not npc.active:
				continue
			var at = g.camera.unproject_position(r.position+npc.at+Vector3(0,10,0))*h.base/h.size
			if at.y>110 and at.y<595 and at.x>50 and at.x<940:
				h.centered(npc.kind+"  "+str(npc.men),at,11,h.red if npc.kind=="Raiders" else h.white)
	var captain = g.camera.unproject_position(r.position+r.party+Vector3(0,10,0))*h.base/h.size
	if captain.y>110 and captain.y<590 and captain.x>40 and captain.x<950:
		h.panel(Rect2(captain-Vector2(71,20),Vector2(142,27)),Color(.05,.07,.07,.88),5,h.gold)
		h.centered("YOUR COMPANY  "+str(g.living(0)),captain,11,h.gold)
	# Small atlas inset: the pale rectangle honestly represents the current camera focus.
	h.panel(Rect2(22,452,170,146),Color(.06,.09,.095,.90),8)
	h.label("ATLAS",Vector2(38,478),11,h.gold)
	h.draw_rect(Rect2(36,488,140,92),Color("68734f"))
	h.draw_rect(Rect2(36,488,13,92),Color("486974"))
	for center in r.ANCHORS:
		var p = Vector2(36+(center.x+450)/900*140,488+(center.y+340)/680*92)
		h.draw_circle(p,2.3,h.gold)
	var focus = Vector2(36+(r.map_focus.x+450)/900*140,488+(r.map_focus.z+340)/680*92)
	var marker_size = Vector2(clampf(r.zoom/900*140,24,140),clampf(r.zoom/680*75,20,92))
	h.draw_rect(Rect2(focus-marker_size/2,marker_size).intersection(Rect2(36,488,140,92)),Color(.9,.87,.73,.65),false,1)
	h.button("zoom_in","+",Rect2(22,310,54,49))
	h.button("zoom_out","−",Rect2(22,368,54,49))
	h.panel(Rect2(212,613,856,85),Color(.055,.075,.073,.94),9,Color(.64,.55,.36,.45))
	h.label("NEUTRAL COMPANY" if r.life.neutral else "COMPANY",Vector2(231,639),11,h.gold)
	h.button("journal","JOURNAL / JOBS",Rect2(231,650,211,34))
	h.button("locate","LOCATE",Rect2(460,635,108,45))
	h.button("time0","PAUSE",Rect2(580,635,112,45),r.speed==0)
	h.button("time1","1×",Rect2(704,635,70,45),r.speed==1)
	h.button("time2","2×",Rect2(786,635,70,45),r.speed==2)
	h.button("time4","4×",Rect2(868,635,70,45),r.speed==4)
	h.button("atlas","ATLAS",Rect2(950,635,98,45))
	if r.selected>=0:
		draw_settlement(h)
	elif r.pending=="":
		h.panel(Rect2(966,99,289,265),Color(.055,.075,.073,.91),8)
		h.label("A DIVIDED REALM",Vector2(984,130),18,h.white,h.heading)
		h.label("8 towns · 8 castles · 16 villages",Vector2(984,160),13,h.muted)
		for i in range(4):
			h.draw_circle(Vector2(992,194+i*36),5,r.COLORS[i])
			h.label(r.FACTIONS[i],Vector2(1008,199+i*36),14,h.white)
		h.panel(Rect2(236,557,680,40),Color(.05,.07,.07,.88),6)
		h.centered("Drag to pan · Pinch / scroll to zoom · Tap a settlement, then Travel",Vector2(576,583),13,h.white)
	if g.toast_time>0:
		h.panel(Rect2(297,92,625,36),Color(.05,.07,.07,.93),6)
		h.centered(g.toast,Vector2(609,116),12,h.gold)
	if r.pending!="":
		h.buttons.clear()
		h.draw_rect(Rect2(0,0,1280,720),Color(.025,.035,.04,.65))
		h.panel(Rect2(340,195,600,312),Color(.055,.075,.073,.98),12,h.gold)
		h.centered("ENCOUNTER ON THE ROAD",Vector2(640,249),25,h.white,h.heading)
		h.centered(r.pending,Vector2(640,295),17,h.muted)
		h.centered("Fight in the 3D arena, or pay up to 25 gold to pass.",Vector2(640,334),14,h.white)
		h.button("fight_party","TO BATTLE",Rect2(376,383,249,57),true)
		h.button("avoid_party","PAY AND PASS",Rect2(651,383,249,57))

static func draw_settlement(h) -> void:
	var r = h.game.realm
	var s = r.settlements[r.selected]
	var near = r.near_settlement(r.selected)
	var color = h.gold if r.holdings.has(r.selected) else r.COLORS[s.faction]
	h.panel(Rect2(965,98,293,505),Color(.055,.075,.073,.96),9,color)
	h.label(s.kind.to_upper(),Vector2(984,128),11,h.gold)
	h.label(s.name.to_upper(),Vector2(984,158),19,h.white,h.heading)
	h.label("Your holding" if r.holdings.has(r.selected) else r.FACTIONS[s.faction],Vector2(984,185),14,color.lightened(.25))
	h.label("Garrison "+str(s.garrison)+"  ·  Prosperity "+str(s.prosperity),Vector2(984,215),12,h.muted)
	h.label("Standing: "+("HOSTILE" if r.relations[s.faction]<0 else "NEUTRAL"),Vector2(984,240),12,h.red if r.relations[s.faction]<0 else h.muted)
	h.button("select_close","×",Rect2(1207,108,36,32))
	if not near:
		var distance = r.party.distance_to(r.terrain_point(s.at))
		h.label("Road journey · supplies required",Vector2(984,278),13,h.white)
		h.label("Direct distance: "+str(int(distance))+" map units",Vector2(984,306),12,h.muted)
		h.button("travel","TRAVEL TO "+s.kind.to_upper(),Rect2(984,340,254,54),true)
		h.label("Party follows connected roads.",Vector2(984,424),13,h.muted)
		h.label("Time pauses when you arrive.",Vector2(984,449),13,h.muted)
		h.label("Courier work needs no allegiance." if r.life.neutral else "Castles can become income fiefs.",Vector2(984,492),12,h.gold)
	else:
		h.label("YOUR COMPANY IS HERE",Vector2(984,273),12,h.gold)
		if r.relations[s.faction]<0 and not r.holdings.has(r.selected):
			h.button("truce","NEGOTIATE TRUCE · 100",Rect2(984,295,254,45),true)
		else:
			h.button("food","20 FOOD · 20 GOLD",Rect2(984,295,254,44),true)
		h.button("realm_recruit","RECRUIT 3 · 30 GOLD",Rect2(984,349,254,43))
		h.button("buy_grain","BUY GRAIN · "+str(r.buy_price(r.selected)),Rect2(984,401,124,43))
		h.button("sell_grain","SELL · "+str(r.sell_price(r.selected)),Rect2(1116,401,122,43))
		if s.kind=="Castle" and not r.holdings.has(r.selected) and not r.life.neutral:
			h.button("assault","CHALLENGE GARRISON",Rect2(984,453,254,44))
			h.label("Field battle; no siege interiors yet.",Vector2(984,520),11,h.muted)
		elif r.holdings.has(r.selected):
			h.label("YOUR FIEF · +18 GOLD / DAY",Vector2(984,481),13,h.gold)
		else:
			h.button("quest","ROADWARDEN CONTRACT",Rect2(984,453,254,44))
			h.label("Defeat raiders · 120 gold reward",Vector2(984,520),12,h.gold)
		h.label("Grain "+str(r.grain)+" / 20  ·  Local stock: "+str(s.stock),Vector2(984,542),12,h.muted)

	h.button("select_previous","‹ PREVIOUS",Rect2(984,558,122,34))
	h.button("select_next","NEXT ›",Rect2(1116,558,122,34))
