class_name WandererLife
extends RefCounted

# Original small-company sandbox. All economy values use Iron Crowns gold,
# not Bannerlord denars. No kingdom membership or paid faction wars here.
const ORIGINS = ["Merchant", "Pathfinder", "Freeblade"]
const COMPANIONS = [
	{"name":"Mara Reed", "role":"Scout", "home":0, "cost":60},
	{"name":"Torren Vale", "role":"Steward", "home":8, "cost":70},
	{"name":"Nadia Saffron", "role":"Trader", "home":24, "cost":80},
	{"name":"Edda Grey", "role":"Guard", "home":16, "cost":70}
]
var realm
var origin = ""
var neutral = true
var visited: Array = []
var companions: Array = []
var delivery: Dictionary = {}
var cooldowns: Dictionary = {}
var workshops: Array = []
var caravan: Dictionary = {}
var completed = 0
var trade_profit = 0
var cargo_cost = 0.0
var business_income = 0
var business_cost = 0
var last_report = "No businesses yet. Earn seed gold through deliveries and trade."

func _init(owner) -> void:
	realm = owner

func choose_origin(index: int) -> bool:
	if origin!="" or index<0 or index>=ORIGINS.size():
		return false
	origin = ORIGINS[index]
	neutral = true
	if index==0:
		realm.game.gold += 60
	elif index==1:
		realm.food += 15
	apply_traits()
	realm.game.hero.hp = realm.game.hero.maximum_hp
	visit(0)
	realm.game.save_progress()
	return true

func apply_traits() -> void:
	if realm.game.hero!=null:
		realm.game.hero.maximum_hp = 220.0 if origin=="Freeblade" else 180.0
		realm.game.hero.hp = minf(realm.game.hero.hp,realm.game.hero.maximum_hp)

func travel_multiplier() -> float:
	return (1.15 if origin=="Pathfinder" else 1.0)*(1.10 if has_role("Scout") else 1.0)

func has_role(role: String) -> bool:
	for id in companions:
		if COMPANIONS[id].role==role and int(caravan.get("companion",-1))!=id:
			return true
	return false

func visit(id: int) -> void:
	if id>=0 and id<32 and not visited.has(id):
		visited.append(id)

func regions_seen() -> int:
	var regions: Array = []
	for id in visited:
		var faction = realm.settlements[id].faction
		if not regions.has(faction):
			regions.append(faction)
	return regions.size()

func fail(message: String) -> bool:
	realm.game.announce(message)
	return false

func local_access(town_only: bool = false) -> bool:
	if not realm.near_settlement(realm.selected):
		return fail("Travel to the selected settlement first.")
	var s = realm.settlements[realm.selected]
	if realm.relations[s.faction]<0:
		return fail("Local services are unavailable while this faction is hostile.")
	if town_only and s.kind!="Town":
		return fail("Taverns and businesses are available in towns only.")
	return true

func accept_delivery() -> bool:
	if not local_access():
		return false
	if not delivery.is_empty():
		return fail("Finish or abandon your current delivery first.")
	var home = realm.selected
	if realm.day<int(cooldowns.get(str(home),0)):
		return fail("This courier board refreshes on day "+str(cooldowns[str(home)])+".")
	var target = (home+1)%32
	delivery = {"from":home,"to":target,"reward":45+(home%4)*10,"due":realm.day+4}
	cooldowns[str(home)] = realm.day+2
	realm.game.save_progress()
	realm.game.announce("Sealed letters for "+realm.settlements[target].name+". No allegiance required.")
	return true

func claim_delivery() -> bool:
	if delivery.is_empty():
		return fail("No delivery is active.")
	if realm.day>int(delivery.due):
		delivery.clear()
		realm.game.save_progress()
		return fail("Delivery expired. You can take another contract.")
	if not realm.near_settlement(int(delivery.to)):
		return fail("Reach "+realm.settlements[int(delivery.to)].name+" to hand over the letters.")
	var reward = int(delivery.reward)
	delivery.clear() # Consume before crediting: no duplicate payouts.
	completed += 1
	realm.game.gold += reward
	realm.game.save_progress()
	realm.game.announce("Delivery complete: +"+str(reward)+" gold. Your clan remains independent.")
	return true

func abandon_delivery() -> void:
	delivery.clear()
	realm.game.save_progress()
	realm.game.announce("Letters returned by courier. Board cooldown still applies.")

func hire(id: int) -> bool:
	if id<0 or id>=COMPANIONS.size() or not local_access(true):
		return false
	var person = COMPANIONS[id]
	if companions.has(id):
		return fail("This companion already works with you.")
	if realm.selected!=person.home:
		return fail(person.name+" is waiting in "+realm.settlements[person.home].name+".")
	if realm.game.gold<person.cost:
		return fail("Not enough gold for the hiring fee.")
	realm.game.gold -= person.cost
	companions.append(id)
	realm.game.save_progress()
	realm.game.announce(person.name+" joined your company. Upkeep: 2 gold per day.")
	return true

func found_caravan(leader: int = -1) -> bool:
	if not local_access(true):
		return false
	if not caravan.is_empty():
		return fail("This preview supports one owned caravan.")
	if companions.is_empty():
		return fail("Hire a tavern companion to lead the caravan first.")
	if realm.game.gold<400:
		return fail("A caravan costs 400 gold. Keep a reserve for provisions.")
	if leader<0:
		leader = companions[0]
	if not companions.has(leader):
		return fail("Choose a hired companion as caravan leader.")
	realm.game.gold -= 400
	caravan = {"companion":leader,"home":realm.selected,"last_stop":realm.selected,"paid":0}
	bind_caravan()
	realm.game.save_progress()
	realm.game.announce("Caravan launched: earns on arrivals, costs 6 gold per day. Leader leaves your escort.")
	return true

func bind_caravan() -> void:
	if caravan.is_empty() or realm.civilians.is_empty():
		return
	var npc = realm.civilians[0]
	var home = int(caravan.home)
	npc.kind = "Your caravan"
	npc.goal = home
	npc.at = realm.graph.get_point_position(home)
	npc.node.position = npc.at
	npc.route.clear()
	realm.plan_npc(0)

func caravan_arrival(npc_id: int, stop: int) -> void:
	if npc_id!=0 or caravan.is_empty() or stop==int(caravan.last_stop):
		return
	caravan.last_stop = stop
	var reward = 32+int(realm.settlements[stop].prosperity/3)
	if COMPANIONS[int(caravan.companion)].role=="Trader":
		reward += 12
	caravan.paid = int(caravan.paid)+reward
	business_income += reward
	realm.game.gold += reward
	last_report = "Caravan reached "+realm.settlements[stop].name+": +"+str(reward)+" gold."
	realm.game.save_progress()

func buy_workshop() -> bool:
	if not local_access(true):
		return false
	if workshops.has(realm.selected):
		return fail("You already own a workshop here.")
	if workshops.size()>=3:
		return fail("Workshop limit reached: three businesses.")
	if realm.game.gold<500:
		return fail("A workshop costs 500 gold. No land or oath is required.")
	realm.game.gold -= 500
	workshops.append(realm.selected)
	realm.game.save_progress()
	realm.game.announce("Grain mill purchased. Daily income depends on local grain stock and prosperity.")
	return true

func workshop_income(id: int) -> int:
	var s = realm.settlements[id]
	if realm.relations[s.faction]<0 or s.stock<6:
		return 0
	return 10+int(s.prosperity/8)

func daily() -> void:
	if not delivery.is_empty() and realm.day>int(delivery.due):
		delivery.clear()
		realm.game.announce("Delivery deadline missed. The letters contract has expired.")
	var income = 0
	for id in workshops:
		var amount = workshop_income(id)
		income += amount
		if amount>0:
			realm.settlements[id].stock -= 6
	var costs = companions.size()*2
	if not caravan.is_empty():
		costs += 4 # Leader's two-gold salary is already included above.
		if realm.day%7==0 and not (realm.defeated.has(12) and realm.defeated.has(13) and realm.defeated.has(14) and realm.defeated.has(15)):
			var toll = 12 if COMPANIONS[int(caravan.companion)].role=="Guard" else 30
			costs += toll
			last_report = "Bandit toll: "+str(toll)+" gold. Defeat all four raider parties to end tolls."
	business_income += income
	business_cost += costs
	realm.game.gold = maxi(0,realm.game.gold+income-costs)

func serialize() -> Dictionary:
	return {"origin":origin,"neutral":neutral,"visited":visited.duplicate(),"companions":companions.duplicate(),"delivery":delivery.duplicate(),"cooldowns":cooldowns.duplicate(),"workshops":workshops.duplicate(),"caravan":caravan.duplicate(),"completed":completed,"trade_profit":trade_profit,"cargo_cost":cargo_cost,"business_income":business_income,"business_cost":business_cost,"last_report":last_report}

func ids(value, limit: int, towns: bool = false) -> Array:
	var result: Array = []
	if value is Array:
		for item in value:
			if not (item is int or item is float):
				continue
			var id = int(item)
			if id>=0 and id<limit and not result.has(id) and (not towns or id%4==0):
				result.append(id)
	return result

func restore(data: Dictionary) -> void:
	origin = str(data.get("origin",""))
	if not ORIGINS.has(origin) and origin!="Veteran":
		origin = ""
	neutral = origin!="Veteran"
	visited = ids(data.get("visited",[]),32)
	companions = ids(data.get("companions",[]),4)
	workshops = ids(data.get("workshops",[]),32,true).slice(0,3)
	var job = data.get("delivery",{})
	if job is Dictionary and job.has_all(["from","to","reward","due"]):
		if int(job.from)>=0 and int(job.from)<32 and int(job.to)>=0 and int(job.to)<32 and int(job.due)>=realm.day:
			delivery = {"from":int(job.from),"to":int(job.to),"reward":clampi(int(job.reward),0,75),"due":clampi(int(job.due),realm.day,realm.day+4)}
	var saved_cooldowns = data.get("cooldowns",{})
	if saved_cooldowns is Dictionary:
		for key in saved_cooldowns:
			if str(key).is_valid_int() and int(key)>=0 and int(key)<32:
				cooldowns[str(key)] = clampi(int(saved_cooldowns[key]),0,realm.day+2)
	var c = data.get("caravan",{})
	if c is Dictionary and c.has_all(["companion","home","last_stop","paid"]):
		if companions.has(int(c.companion)) and int(c.home)>=0 and int(c.home)<32 and int(c.home)%4==0:
			caravan = {"companion":int(c.companion),"home":int(c.home),"last_stop":clampi(int(c.last_stop),0,31),"paid":clampi(int(c.paid),0,1000000)}
	completed = clampi(int(data.get("completed",0)),0,1000000)
	trade_profit = clampi(int(data.get("trade_profit",0)),0,1000000)
	cargo_cost = clampf(float(data.get("cargo_cost",0)),0,10000)
	business_income = clampi(int(data.get("business_income",0)),0,1000000)
	business_cost = clampi(int(data.get("business_cost",0)),0,1000000)
	last_report = str(data.get("last_report",last_report)).left(120)
	apply_traits()
