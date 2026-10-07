class_name FactionsOverlay
extends RefCounted

static func draw(h) -> void:
	var realm = h.game.realm
	h.buttons.clear()
	h.draw_rect(Rect2(0,0,1280,720),Color(.035,.055,.06,.96))
	h.label("PEOPLES OF THE MARCHES",Vector2(100,110),32,h.white,h.heading)
	h.label("Six original factions / clan leaders / settlement allegiance",Vector2(100,148),16,h.muted)
	h.button("factions_close","CLOSE",Rect2(1060,80,120,45))
	for i in range(realm.FACTIONS.size()):
		h.button("faction_"+str(i),realm.FACTIONS[i],Rect2(100,200+i*64,300,50),i==h.faction_choice)
	var selected: Dictionary = realm.world_definition.factions[h.faction_choice]
	h.label(str(selected.name).to_upper(),Vector2(465,240),26,realm.COLORS[h.faction_choice].lightened(.3),h.heading)
	h.label("CLAN: "+str(selected.clan),Vector2(465,300),20,h.white)
	h.label("LEADER: "+str(selected.leader),Vector2(465,345),20,h.white)
	h.label(str(selected.description),Vector2(465,399),16,h.muted)
	var count = 0
	for settlement in realm.settlements:
		if int(settlement.faction)==h.faction_choice:
			count += 1
	h.label(str(count)+" settlements / standing "+str(realm.relations[h.faction_choice]),Vector2(465,458),18,h.gold)
	h.label("You begin independent. These are campaign allegiances, not a forced oath.",Vector2(465,506),15,h.muted)
	h.label("Clan leaders are background profiles; marriage, heirs and dynasty simulation are not implemented.",Vector2(100,662),14,h.muted)
