class_name CrownSim
extends RefCounted
const SAVE="user://crown-campaign-v1.json"
const TYPES=["levy","infantry","guard","cavalry"]
const POWER={"levy":1,"infantry":2,"guard":4,"cavalry":5}
const WAGE={"levy":1,"infantry":2,"guard":3,"cavalry":4}
const RANKS=["ڕێبوار","سەرکردەی دەستە","فەرماندە","پەیماندار","والی"]
var world: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campaign/world.json"))
var state: Dictionary
var message=""
func _init() -> void:
	state={"schema":1,"day":1,"location":2,"gold":80,"food":6,"renown":0,"morale":80,"health":100,"oath":-1,"governed":-1,"completed":0,"rng":20261020,"name":"ڕێبوار","party":{"levy":0,"infantry":0,"guard":0,"cavalry":0},"relations":[0,0,0,0],"owners":[],"garrisons":[],"population":[],"houses":[],"homes":[],"audiences":[],"wars":[true,true],"contract":{},"journal":[]}
	for town in world.settlements:
		for pair in [["owners","faction"],["garrisons","garrison"],["population","population"],["houses","houses"]]:
			state[pair[0]].append(int(town[pair[1]]))
	record_event("بە ٨٠ زێڕ و ٦ خواردن، لە گوندی بەهار دەستت پێ کرد؛ هیچ قەڵا و سوپایەکت نییە.")
func record_event(text: String) -> void:
	message=text
	state.journal.append("ڕۆژی %d: %s" % [state.day,text])
	while state.journal.size()>50:
		state.journal.pop_front()
func rank() -> int:
	if state.governed>=0:
		return 4
	if state.oath>=0:
		return 3 if state.renown>=45 and state.completed>=3 and not state.homes.is_empty() else 2
	return 1 if state.renown>=8 else 0
func count() -> int:
	var n=0
	for kind in TYPES:
		n+=int(state.party[kind])
	return n
func capacity() -> int:
	return [8,16,32,48,80][rank()]
func power() -> int:
	var n=2+rank()*2
	for kind in TYPES:
		n+=int(state.party[kind])*POWER[kind]
	return int(n*(.5+state.morale/200.0))
func wages() -> int:
	var n=0
	for kind in TYPES:
		n+=int(state.party[kind])*WAGE[kind]
	return n
func owner(id: int=-1) -> int:
	return int(state.owners[state.location if id<0 else id])
func war(a: int,b: int) -> bool:
	return (mini(a,b)==0 and maxi(a,b)==1 and state.wars[0]) or (mini(a,b)==2 and maxi(a,b)==3 and state.wars[1])
func hostile(id: int=-1) -> bool:
	return state.oath>=0 and war(state.oath,owner(id))
func next_random() -> int:
	state.rng=(int(state.rng)*1664525+1013904223)%4294967296
	return int(state.rng)
func lose(n: int) -> void:
	for kind in TYPES:
		var taken=mini(int(state.party[kind]),n)
		state.party[kind]-=taken
		n-=taken
func advance(days: int=1) -> void:
	for day in days:
		state.day+=1
		var need=maxi(1,ceili((count()+1)/6.0))
		if state.food<need:
			state.food=0
			state.morale=maxi(0,state.morale-12)
			lose(1)
			record_event("خواردن بەس نەبوو؛ ڕەزامەندی دابەزی و سەربازێک ڕۆیشت.")
		else:
			state.food-=need
			state.morale=mini(100,state.morale+2)
		state.health=mini(100,state.health+5)
		if int(state.day)%7==0:
			state.gold+=state.homes.filter(func(id):return not hostile(id)).size()*14+(120 if state.governed>=0 else 0)
			var due=wages()
			if state.gold<due:
				lose(maxi(1,ceili(count()*.2)))
				state.morale=maxi(0,state.morale-15)
				record_event("مووچەی هەفتانە نەدرا؛ بەشێک لە سوپا ڕۆیشت.")
			state.gold=maxi(0,state.gold-due)
		if int(state.day)%6==0:
			var attacker=next_random()%4
			var rival=attacker^1
			var target=rival*3+1
			if war(attacker,rival) and owner(target)==rival:
				state.garrisons[target]=maxi(0,state.garrisons[target]-6)
				record_event("هێرشی سنووری بۆ "+world.settlements[target].name+"؛ پاسەوان کەم بووەوە.")
				if state.garrisons[target]==0:
					state.owners[target]=attacker
					state.garrisons[target]=8
					record_event("قەڵاکە کەوتە دەستی "+world.factions[attacker].name)
					if state.governed==target:state.governed=-1
		if int(state.day)%12==0:
			var pair=(int(state.day)/12-1)%2
			state.wars[pair]=not state.wars[pair]
			record_event("پەیمانی سنووری گۆڕا: "+("شەڕ" if state.wars[pair] else "ئاشتی"))
		if not state.contract.is_empty() and state.day>state.contract.deadline:
			state.relations[state.contract.faction]=maxi(-100,state.relations[state.contract.faction]-5)
			state.contract={}
			record_event("کاتی ئەرکەکە تێپەڕی؛ متمانە کەم بووەوە.")
func reject(text: String) -> bool:
	message=text
	return false
func travel(id: int) -> bool:
	if id<0 or id>=12 or id==state.location:
		return reject("مەبەستێکی تر لە نەخشە هەڵبژێرە.")
	var a=world.settlements[state.location].at
	var b=world.settlements[id].at
	var days=maxi(1,ceili(Vector2(a[0],a[1]).distance_to(Vector2(b[0],b[1]))/90))
	advance(days)
	state.location=id
	if next_random()%100<18 and count()<3:
		state.gold=maxi(0,state.gold-20)
		state.morale=maxi(0,state.morale-8)
		record_event("ڕێگرەکان لە ڕێگادا زێڕیان برد؛ دەستەیەکی پارێزەر کۆ بکەرەوە.")
	record_event("گەیشتیت بە %s؛ گەشت %d ڕۆژی خایاند." % [world.settlements[id].name,days])
	return true
func work() -> bool:
	if hostile():return reject("لە خاکی دوژمن کار نادرێت.")
	advance()
	state.gold+=35
	state.renown+=1
	state.relations[owner()]=mini(100,state.relations[owner()]+1)
	record_event("یەک ڕۆژ کارت کرد: ٣٥ زێڕ، ١ ناوبانگ و ١ متمانە.")
	return true
func rest() -> bool:
	advance()
	state.health=mini(100,state.health+(20 if state.location in state.homes else 10))
	record_event("پشووت دا؛ خواردن و مووچە بە پێی کات ژمێردران.")
	return true
func buy_food() -> bool:
	if hostile() or state.gold<20 or state.food>990:return reject("٢٠ زێڕ و بازاڕێکی نادوژمن پێویستە.")
	state.gold-=20
	state.food+=10
	record_event("١٠ خواردنت بە ٢٠ زێڕ کڕی.")
	return true
func recruit() -> bool:
	if hostile() or state.gold<45 or count()+3>capacity():return reject("٤٥ زێڕ و سێ شوێنی بەتاڵ لە دەستەکە پێویستن.")
	state.gold-=45
	state.party.levy+=3
	advance()
	record_event("سێ خۆبەخشی ناوخۆییت دامەزراند؛ خواردن و مووچەیان لەبیر مەکە.")
	return true
func train(kind: String="infantry") -> bool:
	var source="levy" if kind=="infantry" else "infantry"
	var cost=40 if kind=="infantry" else 100
	if not kind in ["infantry","guard","cavalry"] or hostile() or state.gold<cost or state.party[source]<4:
		return reject("چوار سەربازی پلەی خوارەوە و زێڕی ڕاهێنان پێویستن.")
	if kind!="infantry" and rank()<2:return reject("سەرەتا فەرماندە ببە.")
	state.gold-=cost
	state.party[source]-=4
	state.party[kind]+=4
	advance()
	record_event("چوار سەرباز ڕاهێنران؛ هێز و مووچەیان زیاد بوو.")
	return true
func take_contract(kind: String) -> bool:
	if hostile() or not state.contract.is_empty() or not kind in ["courier","escort","relief"]:
		return reject("سەرەتا ئەرکی ئێستات تەواو بکە؛ لە خاکی دوژمن ئەرک نادرێت.")
	if kind=="escort" and count()<3:return reject("کاروان سێ پارێزەری دەوێت.")
	var faction=owner()
	var destination=faction*3+(1 if kind=="relief" else 0)
	if destination==state.location:destination=faction*3+2
	state.contract={"kind":kind,"destination":destination,"faction":faction,"deadline":state.day+12}
	record_event("ئەرک وەرگیرا؛ بڕۆ بۆ "+world.settlements[destination].name+" و «تەواوکردن» دابگرە.")
	return true
func deliver() -> bool:
	var c=state.contract
	if c.is_empty() or state.location!=c.destination or state.day>=c.deadline:return reject("لە مەبەست و پێش کۆتایی کات ئەرکەکە تەواو بکە.")
	if hostile() or (c.kind=="escort" and count()<3) or (c.kind=="relief" and state.food<12):return reject("پارێزەر یان خواردن بەس نییە، یان شوێنەکە دوژمنە.")
	if c.kind=="relief":state.food-=10
	state.contract={}
	advance()
	state.gold+=60 if c.kind=="courier" else 110
	state.renown+=6 if c.kind=="courier" else 10
	state.relations[c.faction]=mini(100,state.relations[c.faction]+6)
	state.completed+=1
	record_event("ئەرک تەواو بوو؛ زێڕ، ناوبانگ و متمانەت زیاد بوون.")
	return true
func audience() -> bool:
	var f=owner()
	if hostile() or world.settlements[state.location].kind!="town" or state.renown<8:return reject("بۆ دیداری دربار ٨ ناوبانگ و پایتەختێکی نادوژمن پێویستە.")
	if f not in state.audiences:
		state.audiences.append(f)
		state.renown+=3
		state.relations[f]=mini(100,state.relations[f]+3)
	record_event("درباری "+world.factions[f].house+" ناسیت؛ شاه داوای خزمەت و وەزیر داوای بەڵگەی متمانە دەکات.")
	return true
func gift() -> bool:
	if hostile() or state.gold<20 or world.settlements[state.location].kind!="town":return reject("لە پایتەخت، ٢٠ زێڕ بۆ دیاری پێویستە.")
	state.gold-=20
	advance()
	state.relations[owner()]=mini(100,state.relations[owner()]+4)
	record_event("دیاریت پێشکەش کرد؛ متمانەی خانەدان ٤ پلە زیاد بوو.")
	return true
func swear() -> bool:
	if state.oath>=0 or state.renown<25 or state.relations[owner()]<10 or world.settlements[state.location].kind!="town":return reject("٢٥ ناوبانگ، ١٠ متمانە و دیداری پایتەخت پێویستن؛ تەنها یەک سوێند هەیە.")
	state.oath=owner()
	record_event("سوێندت بۆ "+world.factions[state.oath].name+" خوارد؛ ئێستا فەرماندەیت و شەڕەکانیان کاریگەریت لێ دەکەن.")
	return true
func buy_home() -> bool:
	if hostile() or state.gold<250 or state.location in state.homes:return reject("ماڵ ٢٥٠ زێڕە؛ لە هەر شوێنێک تەنها یەک ماڵ دەتوانیت بکڕیت.")
	state.gold-=250
	state.homes.append(int(state.location))
	record_event("ماڵەکە بۆ تۆیە؛ پشووی باشتر و ١٤ زێڕ داهاتی هەفتانە هەیە.")
	return true
func petition() -> bool:
	if rank()!=3 or state.renown<80 or state.completed<5 or state.relations[owner()]<35 or owner()!=state.oath or state.location!=state.oath*3:
		return reject("٨٠ ناوبانگ، پێنج ئەرک، ماڵ، ٣٥ متمانە و پلەی پەیماندار پێویستن؛ بڕۆ پایتەختی خۆت.")
	var castle=state.oath*3+1
	if owner(castle)!=state.oath:return reject("سەرەتا قەڵاکە لە دوژمن وەربگرەوە.")
	state.governed=castle
	record_event("بە والیی "+world.settlements[castle].name+" دانرایت؛ ١٢٠ زێڕ داهاتی هەفتانە و مافی خانووسازی.")
	return true
func build_housing() -> bool:
	if state.governed!=state.location or owner()!=state.oath or state.gold<120:return reject("لە قەڵای ژێر دەستی خۆت ١٢٠ زێڕ پێویستە.")
	state.gold-=120
	state.houses[state.location]+=4
	state.population[state.location]+=20
	advance(2)
	record_event("چوار خانوو زیاد کران؛ ٢٠ کەس نیشتەجێ بوون.")
	return true
func reinforce() -> bool:
	if state.governed!=state.location or owner()!=state.oath or state.gold<40 or state.garrisons[state.location]>992:return reject("٤٠ زێڕ و قەڵای ژێر دەستی خۆت پێویستن.")
	state.gold-=40
	state.garrisons[state.location]+=8
	record_event("هەشت پاسەوان بۆ پاراستنی قەڵاکەت دامەزران.")
	return true
func attack() -> bool:
	if rank()<2 or not hostile() or count()<10 or state.health<30 or world.settlements[state.location].kind!="castle":return reject("بۆ هێرش: سوێند، دە سەرباز، تەندروستی و قەڵای ئیمپراتۆریەتێکی لە شەڕدا پێویستن.")
	advance()
	if not hostile():
		record_event("پەیمانی ئاشتی گەیشت؛ هێرش هەڵوەشایەوە.");return true
	var defense=state.garrisons[state.location]*2
	var strength=power()
	if strength>=defense:
		lose(maxi(1,ceili(count()*.2)))
		state.owners[state.location]=int(state.oath)
		state.garrisons[state.location]=8
		state.renown+=15
		state.relations[state.oath]=mini(100,state.relations[state.oath]+10)
		record_event("هەژمارکردنی جەنگی ستراتیژی: سەرکەوتیت؛ زیان درا و پاسەوانی ئیمپراتۆریەت گەیشت. ئەمە جەنگی دەستیی سێ‌ڕەهەندی نییە.")
	else:
		lose(maxi(2,ceili(count()*.5)))
		state.gold=int(state.gold*.5)
		state.health=25
		state.morale=30
		record_event("هەژمارکردنی جەنگی ستراتیژی: شکستت هێنا؛ نیوەی سوپا و زێڕ لەدەست چوون.")
	return true
func save(path: String=SAVE) -> bool:
	if not valid(state) or JSON.stringify(state).to_utf8_buffer().size()>131072:return false
	var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if f==null:return false
	f.store_string(JSON.stringify(state)); f.flush()
	var ok=f.get_error()==OK
	f.close()
	return ok and DirAccess.rename_absolute(path+".tmp",path)==OK
func restore(path: String=SAVE) -> bool:
	if not FileAccess.file_exists(path):return false
	var file=FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()>131072:return false
	var raw=JSON.parse_string(file.get_as_text());file.close()
	if not valid(raw):return false
	for key in ["day","location","gold","food","renown","morale","health","oath","governed","completed","rng"]:raw[key]=int(raw[key])
	for key in ["relations","owners","garrisons","population","houses","homes","audiences"]:raw[key]=raw[key].map(func(v):return int(v))
	for key in TYPES:raw.party[key]=int(raw.party[key])
	if not raw.contract.is_empty():
		for key in ["destination","faction","deadline"]:raw.contract[key]=int(raw.contract[key])
	raw.schema=1
	state=raw
	message="کەمپەینەکەت گەڕایەوە."
	return true
static func integer(v,low: int,high: int) -> bool:
	return CastleSim.valid_number(v,low,high) and v==int(v)
static func valid(s) -> bool:
	if not s is Dictionary or s.get("schema")!=1:return false
	for pair in [["day",1,100000],["location",0,11],["gold",0,10000000],["food",0,1000],["renown",0,1000000],["morale",0,100],["health",0,100],["oath",-1,3],["governed",-1,11],["completed",0,1000000],["rng",0,4294967295]]:
		if not integer(s.get(pair[0]),pair[1],pair[2]):return false
	if not s.get("name") is String or s.name.is_empty() or s.name.length()>32:return false
	if not s.get("party") is Dictionary or s.party.size()!=4:return false
	var total=0
	for key in TYPES:
		if not integer(s.party.get(key),0,80):return false
		total+=s.party[key]
	if total>80:return false
	for spec in [["relations",4,-100,100],["owners",12,0,3],["garrisons",12,0,1000],["population",12,0,100000],["houses",12,0,10000]]:
		if not s.get(spec[0]) is Array or s[spec[0]].size()!=spec[1]:return false
		for v in s[spec[0]]:
			if not integer(v,spec[2],spec[3]):return false
	for key in ["homes","audiences"]:
		if not s.get(key) is Array or s[key].size()>(12 if key=="homes" else 4):return false
		var seen={}
		for v in s[key]:
			if not integer(v,0,11 if key=="homes" else 3) or seen.has(v):return false
			seen[v]=true
	if not s.get("wars") is Array or s.wars.size()!=2:return false
	for v in s.wars:
		if not v is bool:return false
	if not s.get("journal") is Array or s.journal.size()>50:return false
	for v in s.journal:
		if not v is String or v.length()>1000:return false
	if not s.get("contract") is Dictionary:return false
	if not s.contract.is_empty():
		if not s.contract.get("kind") in ["courier","escort","relief"] or not integer(s.contract.get("destination"),0,11) or not integer(s.contract.get("faction"),0,3) or not integer(s.contract.get("deadline"),s.day,100012):return false
	return s.governed<0 or (s.oath>=0 and int(s.governed)==int(s.oath)*3+1 and s.owners[int(s.governed)]==s.oath)
