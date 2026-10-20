class_name MarchHorse
extends CharacterBody3D

var pace = 1
var speed = 0.0
var stamina = 100.0
var hp = 220.0
var phase = 0.0
var legs: Array[Node3D] = []
var body: Node3D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var collider = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(.85,1.65,2.05)
	collider.shape = shape
	collider.position.y = .9
	add_child(collider)
	hp = float(MarchCatalog.data().horse.health)
	body = Node3D.new()
	add_child(body)
	var coat = FieldMaterials.surface("cloth",Color(str(MarchCatalog.data().horse.coat)),5)
	var leather = FieldMaterials.surface("timber",Color("453d33"),5)
	var black = MarchArt.material(Color("242822"))
	var metal = FieldMaterials.surface("steel",Color("99968a"),3)
	ellipsoid(body,Vector3(0,1.28,0),Vector3(.44,.49,1.0),coat)
	ellipsoid(body,Vector3(0,1.62,-.79),Vector3(.28,.64,.35),coat).rotation.x = -.4
	ellipsoid(body,Vector3(0,2.12,-1.06),Vector3(.23,.30,.42),coat).rotation.x = -.4
	ellipsoid(body,Vector3(0,1.98,-1.37),Vector3(.18,.17,.25),leather)
	for side in [-1,1]:
		ellipsoid(body,Vector3(side*.13,2.42,-.99),Vector3(.07,.19,.055),coat)
		ellipsoid(body,Vector3(side*.215,2.17,-1.14),Vector3(.025,.032,.035),black)
		# Bridle and reins, plus suspended iron stirrups.
		MarchArt.box(body,Vector3(side*.245,2.10,-1.03),Vector3(.027,.04,.6),leather)
		var rein = MarchArt.box(body,Vector3(side*.23,1.94,-.55),Vector3(.018,.018,.91),leather)
		rein.rotation.x = -.2
		MarchArt.box(body,Vector3(side*.43,1.26,.03),Vector3(.026,.65,.055),leather)
		MarchArt.box(body,Vector3(side*.45,.93,.03),Vector3(.17,.035,.17),metal)
	ellipsoid(body,Vector3(0,1.7,.06),Vector3(.46,.13,.45),leather)
	ellipsoid(body,Vector3(0,1.80,.40),Vector3(.43,.16,.10),leather)
	ellipsoid(body,Vector3(0,1.84,-.30),Vector3(.28,.13,.10),leather)
	ellipsoid(body,Vector3(0,1.04,1.02),Vector3(.09,.53,.11),black).rotation.x = -.3
	for z in [-.67,.65]:
		for side in [-1,1]:
			var leg = Node3D.new()
			leg.position = Vector3(side*.29,1.16,z)
			body.add_child(leg)
			ellipsoid(leg,Vector3(0,-.25,0),Vector3(.12,.33,.13),coat)
			MarchArt.cylinder(leg,Vector3(0,-.73,0),.065,.48,coat,.085,10)
			ellipsoid(leg,Vector3(0,-1.06,-.045),Vector3(.10,.075,.14),black)
			legs.append(leg)

func drive(input: Vector2, delta: float, ridden: bool) -> void:
	if hp<=0:
		body.rotation.z = 1.35
	var stats: Dictionary = MarchCatalog.data().horse
	var limit = float(stats.walk if pace==0 else stats.trot if pace==1 else stats.canter)
	if stamina<12:
		limit = minf(limit,float(stats.trot))
	var target_speed = -input.y*limit if ridden and hp>0 else 0.0
	target_speed = maxf(-2,target_speed)
	speed = move_toward(speed,target_speed,delta*(7 if absf(target_speed)<absf(speed) else 3.2))
	if ridden:
		rotation.y -= input.x*delta*lerpf(1.5,.6,clampf(absf(speed)/10,0,1))
	stamina = clampf(stamina+delta*(-7 if absf(speed)>7 else 9),0,100)
	velocity = -basis.z*speed+Vector3(0,velocity.y-24*delta,0)
	move_and_slide()
	position.x = clampf(position.x,-26,24)
	position.z = clampf(position.z,-36,24)
	phase += delta*absf(speed)*2.3
	for i in range(legs.size()):
		legs[i].rotation.x = sin(phase+(0 if i==0 or i==3 else PI))*.6*minf(1,absf(speed)/4)
	body.position.y = absf(sin(phase))*.045*minf(1,absf(speed)/4)
	if hp>0:
		body.rotation.z = lerpf(body.rotation.z,-input.x*speed*.008,delta*5)

func ellipsoid(parent: Node3D, at: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radial_segments = 20
	mesh.rings = 10
	mesh.radius = 1
	mesh.height = 2
	var result = MarchArt.mesh(parent,mesh,at,material)
	result.scale = dimensions
	return result
