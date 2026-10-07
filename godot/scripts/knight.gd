class_name MarchKnight
extends CharacterBody3D

var team = 0
var player = false
var hp = 100.0
var maximum_hp = 100.0
var cooldown = 0.0
var swing = 0.0
var hurt = 0.0
var gait = 0.0
var block = false
var dead = false
var fall = 0.0
var speed = 0.0
var visual: Node3D
var torso: Node3D
var right_arm: Node3D
var left_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var cape: MeshInstance3D
var ring: MeshInstance3D
var target: MarchKnight
var think = 0.0

func setup(faction: int, is_player: bool) -> void:
	team = faction
	player = is_player
	maximum_hp = 180 if player else 90
	hp = maximum_hp
	collision_layer = 2
	collision_mask = 1
	var collision = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.33
	capsule.height = 1.85
	collision.shape = capsule
	collision.position.y = 0.95
	add_child(collision)
	build_character()

func build_character() -> void:
	visual = Node3D.new()
	add_child(visual)
	var steel = MarchArt.material(Color("a8b5b6"), 0.65)
	var bright = MarchArt.material(Color("dce3db"), 0.65)
	var dark = MarchArt.material(Color("293941"), 0.2)
	var gold = MarchArt.material(Color("e6b86b"), 0.55)
	var leather = MarchArt.material(Color("493f36"))
	var color = Color("236d79") if team == 0 else Color("a94632")
	if player:
		color = Color("244957")
	var cloth_mat = MarchArt.material(color)
	torso = Node3D.new()
	visual.add_child(torso)
	MarchArt.cylinder(torso, Vector3(0,1.31,0), .31, .64, steel, .39, 6).scale.z = .67
	MarchArt.box(torso, Vector3(0,1.34,-.225), Vector3(.35,.49,.05), cloth_mat)
	MarchArt.box(torso, Vector3(0,1.34,-.255), Vector3(.045,.34,.012), gold)
	MarchArt.box(torso, Vector3(0,1.40,-.261), Vector3(.2,.045,.01), gold)
	MarchArt.cylinder(torso, Vector3(0,.995,0), .32, .12, leather, .32).scale.z = .72
	MarchArt.box(torso, Vector3(0,1,-.25), Vector3(.13,.12,.06), gold)
	# Split armored skirt and a tabard: human silhouette, not an abstract marker.
	for side in [-1,1]:
		var plate = MarchArt.box(torso,Vector3(side*.21,.88,0),Vector3(.27,.3,.37),steel)
		plate.rotation.z = side * .14
	MarchArt.box(torso,Vector3(0,.82,-.215),Vector3(.24,.38,.035),cloth_mat)
	# Closed helmet, brow, visor, nose guard and crest.
	MarchArt.cylinder(torso,Vector3(0,1.79,0),.235,.36,steel,.20,8)
	MarchArt.sphere(torso,Vector3(0,1.98,0),Vector3(.23,.16,.23),bright)
	MarchArt.box(torso,Vector3(0,1.85,-.224),Vector3(.32,.055,.035),dark)
	MarchArt.box(torso,Vector3(0,1.82,-.25),Vector3(.042,.22,.04),gold if player else steel)
	MarchArt.box(torso,Vector3(0,1.96,-.22),Vector3(.37,.045,.04),gold if player else bright)
	for side in [-1,1]:
		for slot in range(2):
			MarchArt.box(torso,Vector3(side*(.08+slot*.06),1.74,-.224),Vector3(.018,.06,.025),dark)
	if player:
		MarchArt.box(torso,Vector3(0,2.13,.045),Vector3(.09,.23,.30),cloth_mat)
	# Articulated shoulders and arm pivots.
	for side in [-1,1]:
		var arm = Node3D.new()
		arm.position = Vector3(side*.40,1.52,0)
		torso.add_child(arm)
		MarchArt.sphere(arm,Vector3(side*.025,0,0),Vector3(.22,.18,.24),gold if player else steel)
		MarchArt.box(arm,Vector3(0,-.23,0),Vector3(.18,.31,.20),dark)
		MarchArt.box(arm,Vector3(0,-.40,-.02),Vector3(.21,.27,.23),steel)
		MarchArt.sphere(arm,Vector3(0,-.57,-.025),Vector3(.11,.13,.12),leather)
		if side == 1:
			right_arm = arm
			MarchArt.cylinder(arm,Vector3(0,-.65,-.035),.045,.22,leather,.045,6)
			MarchArt.box(arm,Vector3(0,-.76,-.035),Vector3(.32,.055,.065),gold)
			MarchArt.box(arm,Vector3(0,-1.13,-.035),Vector3(.083,.72,.027),bright)
			MarchArt.box(arm,Vector3(0,-1.13,-.053),Vector3(.012,.65,.008),steel)
		else:
			left_arm = arm
			var shield = MarchArt.cylinder(arm,Vector3(-.08,-.35,-.20),.32,.085,gold,.32,8)
			shield.rotation.x = PI / 2
			shield.scale.z = 1.25
			var face = MarchArt.cylinder(arm,Vector3(-.08,-.35,-.251),.277,.035,cloth_mat,.277,8)
			face.rotation.x = PI / 2
			face.scale.z = 1.25
			MarchArt.box(arm,Vector3(-.08,-.35,-.28),Vector3(.045,.55,.015),gold)
			MarchArt.box(arm,Vector3(-.08,-.32,-.283),Vector3(.4,.045,.016),gold)
	for side in [-1,1]:
		var leg = Node3D.new()
		leg.position = Vector3(side*.17,.88,0)
		visual.add_child(leg)
		MarchArt.box(leg,Vector3(0,-.20,0),Vector3(.23,.36,.26),dark)
		MarchArt.sphere(leg,Vector3(0,-.40,-.10),Vector3(.145,.14,.13),steel)
		MarchArt.box(leg,Vector3(0,-.58,0),Vector3(.21,.30,.24),steel)
		MarchArt.box(leg,Vector3(0,-.78,-.07),Vector3(.25,.16,.42),leather)
		if side == 1:
			right_leg = leg
		else:
			left_leg = leg
	var cloth_mesh = PlaneMesh.new()
	cloth_mesh.size = Vector2(.65,1.03)
	cloth_mesh.subdivide_width = 2
	cloth_mesh.subdivide_depth = 5
	cape = MarchArt.mesh(torso,cloth_mesh,Vector3(0,1.16,.32),MarchArt.cloth(color))
	cape.rotation.x = PI / 2 + .12
	var circle_mesh = TorusMesh.new()
	circle_mesh.inner_radius = .35 if player else .30
	circle_mesh.outer_radius = .40 if player else .32
	circle_mesh.rings = 16
	circle_mesh.ring_segments = 6
	ring = MarchArt.mesh(self,circle_mesh,Vector3(0,.018,0),MarchArt.material(Color("ebc985") if player else color))

func animate(delta: float) -> void:
	cooldown = maxf(0,cooldown-delta)
	hurt = maxf(0,hurt-delta)
	if dead:
		fall = minf(1,fall+delta*2)
		visual.rotation.z = fall * 1.43
		visual.position.y = -fall*.5
		ring.visible = false
		return
	gait += delta * (speed*2.2+1)
	var amount = clampf(speed/4,0,1)
	left_leg.rotation.x = sin(gait)*.60*amount
	right_leg.rotation.x = -sin(gait)*.60*amount
	torso.position.y = absf(sin(gait))*.045*amount
	if swing > 0:
		swing = maxf(0,swing-delta)
		var progress = 1-swing/.48
		right_arm.rotation.x = -sin(progress*PI)*2.6
		right_arm.rotation.z = -.25+sin(progress*PI)*.65
	else:
		right_arm.rotation.x = -.15-sin(gait)*.25*amount
		right_arm.rotation.z = -.10
	left_arm.rotation.x = -1.05 if block else sin(gait)*.22*amount
	left_arm.rotation.z = -.2 if block else .1
	visual.rotation.z = sin(hurt*60)*.08 if hurt>0 else 0.0

func damage(amount: float) -> bool:
	if dead:
		return false
	hp = maxf(0,hp-amount*(.22 if block else 1.0))
	hurt = .2
	if hp<=0:
		dead = true
		collision_layer = 0
		return true
	return false
