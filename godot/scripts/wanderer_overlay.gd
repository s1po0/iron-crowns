class_name WandererOverlay
extends RefCounted

static func creation(h) -> void:
	h.buttons.clear()
	h.draw_rect(Rect2(0,0,1280,720),Color(.025,.05,.055,.94))
	h.label("IRON CROWNS  /  THE OPEN ROAD",Vector2(84,66),13,h.gold)
	h.label("NO KING. NO OATH. YOUR JOURNEY.",Vector2(82,119),34,h.white,h.heading)
	h.label("Samir Farroad grew up among caravans. War took the family business, not his freedom.",Vector2(84,163),18,h.muted)
	h.label("Choose the life you led before the road. All origins begin neutral, with eight soldiers.",Vector2(84,192),16,h.muted)
	var descriptions = [
		["THE MERCHANT", "A ledger, a blade, a fresh beginning.", "180 starting gold / 35 food", "Grain prices reduced by 1 gold", "Build wealth without owning land.", "Trade and courier contracts"],
		["THE PATHFINDER", "You know the roads others overlook.", "120 starting gold / 50 food", "15% faster campaign travel", "Explore all four original realms.", "Scouting and long journeys"],
		["THE FREEBLADE", "Your sword has a price. You do not.", "120 starting gold / 35 food", "220 maximum health (normally 180)", "Fight bandits, never peaceful towns.", "Combat and road protection"]
	]
	for i in range(3):
		var x = 84+i*376
		var active = h.origin_choice==i
		h.panel(Rect2(x,226,358,340),Color(.045,.09,.095,.98),12,h.gold if active else Color(.3,.4,.4,.5))
		h.label("0"+str(i+1)+"  /  ORIGIN",Vector2(x+23,261),12,h.gold)
		h.label(descriptions[i][0],Vector2(x+22,305),23,h.white,h.heading)
		for j in range(1,6):
			h.label(descriptions[i][j],Vector2(x+23,327+j*34),14,h.white if j in [2,3] else h.muted)
		h.button("origin_"+str(i),"SELECTED" if active else "CHOOSE ORIGIN",Rect2(x+22,501,314,43),active)
	h.button("origin_back","BACK",Rect2(84,612,150,55))
	h.button("origin_begin","START MY JOURNEY",Rect2(448,608,384,59),true)
	h.label("Original world. No faction pledge. No conquest required.",Vector2(84,703),12,h.muted)

static func journal(h) -> void:
	var r = h.game.realm
	var life = r.life
	h.buttons.clear()
	h.draw_rect(Rect2(0,0,1280,720),Color(.015,.03,.035,.73))
	h.panel(Rect2(130,70,1020,594),Color(.045,.075,.078,.99),14,Color(.7,.6,.4,.8))
	h.label("THE OPEN ROAD COMPANY",Vector2(166,112),12,h.gold)
	h.label("SAMIR FARROAD" if life.origin!="Veteran" else "THE VETERAN CAPTAIN",Vector2(165,150),29,h.white,h.heading)
	h.label(life.origin.to_upper()+"  /  "+("NO KINGDOM ALLEGIANCE" if life.neutral else "LEGACY CAMPAIGN"),Vector2(166,179),13,h.muted)
	h.label(str(h.game.gold)+" GOLD  /  DAY "+str(r.day),Vector2(853,146),17,h.gold)
	h.button("journal_close","×",Rect2(1092,87,39,39))
	var tabs = ["LOGBOOK","COURIER JOBS","COMPANIONS","BUSINESSES"]
	for i in range(4):
		h.button("journal_tab_"+str(i),tabs[i],Rect2(166+i*240,199,228,43),h.journal_tab==i)
	match h.journal_tab:
		0: logbook(h)
		1: jobs(h)
		2: companions(h)
		3: businesses(h)
	var note = h.game.toast if h.game.toast_time>0 else "Campaign time is paused. Close this journal to continue your journey."
	h.draw_line(Vector2(166,613),Vector2(1112,613),Color(.4,.46,.4,.45),1)
	h.centered(note,Vector2(640,642),13,h.gold)

static func logbook(h) -> void:
	var r = h.game.realm
	var l = r.life
	h.label("THE ROAD IS MY HOMELAND",Vector2(171,285),21,h.white,h.heading)
	var story = ["Born between destinations; raised by traders and guards.","When war broke the family business, no king came to help.","Now your loyalty belongs to the people who travel with you.","Sell your skill. Keep your freedom."]
	for i in range(story.size()):
		h.label(story[i],Vector2(172,325+i*29),16,h.muted)
	h.label("A SIMPLE BEGINNING",Vector2(172,465),13,h.gold)
	h.label("1. Take sealed letters from the Courier Jobs board.",Vector2(172,493),15,h.white)
	h.label("2. Travel to the destination, then hand over the letters.",Vector2(172,522),15,h.white)
	h.label("3. Trade grain; hire help; save for a caravan or grain mill.",Vector2(172,551),15,h.white)
	h.panel(Rect2(747,266,364,325),Color(.065,.12,.12,.8),9)
	h.label("YOUR STORY SO FAR",Vector2(769,302),18,h.gold,h.heading)
	var stats = [str(l.regions_seen())+" / 4 realms explored",str(l.visited.size())+" / 32 settlements visited",str(l.completed)+" deliveries completed",str(l.trade_profit)+" profitable grain-trading gold",str(l.companions.size())+" trusted companions",str(l.business_income-l.business_cost)+" net business / companion gold"]
	for i in range(stats.size()):
		h.label(stats[i],Vector2(770,342+i*36),15,h.white)

static func jobs(h) -> void:
	var r = h.game.realm
	var l = r.life
	h.label("CIVILIAN WORK. NO BANNER REQUIRED.",Vector2(173,286),21,h.white,h.heading)
	if not l.delivery.is_empty():
		var job = l.delivery
		h.label("SEALED LETTERS  /  ACTIVE CONTRACT",Vector2(174,331),13,h.gold)
		h.label(r.settlements[int(job.from)].name+"  →  "+r.settlements[int(job.to)].name,Vector2(174,372),27,h.white,h.heading)
		h.label("Reward: "+str(job.reward)+" gold  /  Deliver by the end of day "+str(job.due),Vector2(175,414),17,h.muted)
		h.label("Letters are quest cargo, separate from your grain capacity.",Vector2(175,449),15,h.muted)
		h.button("delivery_route","TRAVEL TO RECIPIENT",Rect2(174,486,294,53),true)
		h.button("delivery_claim","HAND OVER LETTERS",Rect2(490,486,294,53))
		h.button("delivery_abandon","ABANDON",Rect2(807,486,294,53))
		h.label("Payment is available only after you physically reach the destination.",Vector2(175,580),14,h.gold)
	elif r.selected<0 or not r.near_settlement(r.selected):
		h.label("Arrive at a settlement and select it to browse its courier board.",Vector2(174,351),18,h.muted)
		h.label("You can read an active contract and plot its route from anywhere.",Vector2(174,393),16,h.white)
	else:
		var home = r.selected
		var target = (home+1)%32
		h.label("BOARD: "+r.settlements[home].name.to_upper(),Vector2(174,335),13,h.gold)
		h.label("Carry letters to "+r.settlements[target].name,Vector2(174,379),25,h.white,h.heading)
		h.label("Reward: "+str(45+(home%4)*10)+" gold  /  Four days to deliver  /  No deposit",Vector2(174,421),17,h.muted)
		var available = r.day>=int(l.cooldowns.get(str(home),0))
		h.label("Board available" if available else "Board refreshes on day "+str(l.cooldowns[str(home)]),Vector2(174,461),16,h.gold)
		h.button("delivery_accept","ACCEPT DELIVERY",Rect2(174,492,340,56),available)
		h.label("One active delivery at a time. Repeated claims never pay twice.",Vector2(174,584),14,h.muted)

static func companions(h) -> void:
	var r = h.game.realm
	var l = r.life
	var effects = ["Escort: +10% travel speed", "Escort: saves 1 food / day", "Caravan leader: +12 gold / arrival", "Caravan leader: reduced weekly bandit toll"]
	for i in range(4):
		var person = l.COMPANIONS[i]
		var y = 262+i*79
		h.panel(Rect2(166,y,944,70),Color(.06,.11,.115,.8),7)
		h.label(person.name+"  /  "+person.role,Vector2(182,y+25),18,h.white,h.heading)
		h.label(r.settlements[person.home].name+"  ·  "+effects[i],Vector2(182,y+52),14,h.muted)
		var hired = l.companions.has(i)
		var text = "CARAVAN LEADER" if int(l.caravan.get("companion",-1))==i else "IN COMPANY" if hired else "HIRE · "+str(person.cost)
		h.button("companion_"+str(i),text,Rect2(886,y+12,207,45),not hired and r.near_settlement(person.home))
	h.label("Support specialists, not extra combat models. Hire locally; upkeep is 2 gold each per day.",Vector2(172,597),13,h.gold)

static func businesses(h) -> void:
	var r = h.game.realm
	var l = r.life
	h.panel(Rect2(166,262,460,302),Color(.06,.11,.115,.8),9)
	h.panel(Rect2(644,262,466,302),Color(.06,.11,.115,.8),9)
	h.label("A CARAVAN OF YOUR OWN",Vector2(183,298),20,h.white,h.heading)
	h.label("One caravan. Real road travel; paid on arrivals.",Vector2(184,329),14,h.muted)
	h.label("6 gold / day, including its companion's salary.",Vector2(184,355),14,h.muted)
	h.label("Weekly bandit toll: 30 gold; Guard leader: 12.",Vector2(184,381),14,h.muted)
	if l.caravan.is_empty():
		if l.companions.is_empty():
			h.label("Hire a tavern companion before launching.",Vector2(184,430),15,h.gold)
		else:
			var id = l.companions[h.caravan_choice%l.companions.size()]
			h.button("caravan_leader","LEADER: "+l.COMPANIONS[id].name+"  ›",Rect2(182,408,427,44))
		h.button("caravan_buy","LAUNCH AT THIS TOWN · 400",Rect2(182,478,427,53),true)
	else:
		h.label("Leader: "+l.COMPANIONS[int(l.caravan.companion)].name,Vector2(184,429),17,h.gold)
		h.label("Arrival revenue: "+str(l.caravan.paid)+" gold",Vector2(184,465),16,h.white)
		h.label("Marked YOUR CARAVAN when the map is zoomed in.",Vector2(184,509),12,h.muted)
	h.label("GRAIN MILLS / NO FIEF NEEDED",Vector2(661,298),19,h.white,h.heading)
	h.label("Cost: 500 each. Limit: three, in different towns.",Vector2(662,329),14,h.muted)
	h.label("Consumes 6 local grain; about 14–18 gold / day.",Vector2(662,355),14,h.muted)
	for i in range(l.workshops.size()):
		var id = l.workshops[i]
		h.label(r.settlements[id].name+"  +"+str(l.workshop_income(id))+" / day",Vector2(662,397+i*29),15,h.gold)
	if l.workshops.is_empty():
		h.label("No mills owned. Visit a town to invest.",Vector2(662,411),15,h.muted)
	h.button("workshop_buy","BUY AT THIS TOWN · 500",Rect2(661,498,432,44))
	h.label(l.last_report,Vector2(173,592),13,h.gold)
