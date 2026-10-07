class_name MarchKnight
extends CharacterBody3D

var team = 0
var player = false
var hp = 100.0
var maximum_hp = 100.0
var cooldown = 0.0
var swing = 0.0
var strike_clock = -1.0
var stagger = 0.0
var guard_time = 0.0
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
var right_elbow: Node3D
var left_elbow: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_knee: Node3D
var right_knee: Node3D
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
	capsule.radius = .27
	capsule.height = 1.84
	collision.shape = capsule
	collision.position.y = .92
	add_child(collision)
	build_character()

# Smooth oval sections give armor a human silhouette instead of block limbs.
# Each ring is (height, half-width, half-depth); explicit radial normals prevent facets.
func armor(parent: Node3D, rings: Array, mat: Material, offset: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments = 20
	for row in range(rings.size()-1):
		for side in range(segments):
			for corner in [Vector2i(0,0),Vector2i(1,1),Vector2i(1,0),Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)]:
				var ring_data: Vector3 = rings[row+corner.y]
				var angle = TAU*float(side+corner.x)/segments
				var slope = (rings[row].y-rings[row+1].y)/maxf(.01,rings[row+1].x-rings[row].x)
				surface.set_normal(Vector3(cos(angle),slope,sin(angle)*ring_data.y/maxf(.01,ring_data.z)).normalized())
				surface.set_uv(Vector2(float(side+corner.x)/segments,ring_data.x))
				surface.add_vertex(Vector3(cos(angle)*ring_data.y,ring_data.x,sin(angle)*ring_data.z)+offset)
	surface.generate_tangents()
	return MarchArt.mesh(parent,surface.commit(),Vector3.ZERO,mat)

func rounded(parent: Node3D, at: Vector3, scale_value: Vector3, mat: Material) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radial_segments = 20
	mesh.rings = 10
	mesh.radius = 1
	mesh.height = 2
	var result = MarchArt.mesh(parent,mesh,at,mat)
	result.scale = scale_value
	return result

func shield(parent: Node3D, mat: Material, factor: float, z: float, back: bool = false) -> void:
	var outline = [Vector2(-.23,.27),Vector2(.23,.27),Vector2(.22,.02),Vector2(.13,-.23),Vector2(0,-.36),Vector2(-.13,-.23),Vector2(-.22,.02)]
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(outline.size()):
		var points = [Vector2.ZERO,outline[i]*factor,outline[(i+1)%outline.size()]*factor]
		if back:
			points.reverse()
		for p in points:
			st.set_normal(Vector3(0,0,1 if back else -1))
			st.set_uv(p+Vector2(.5,.5))
			st.add_vertex(Vector3(p.x-.07,p.y-.20,z-(.03 if p==Vector2.ZERO else 0)))
	st.generate_tangents()
	MarchArt.mesh(parent,st.commit(),Vector3.ZERO,mat)

func build_character() -> void:
	visual = Node3D.new()
	add_child(visual)
	var steel = FieldMaterials.surface("steel",Color("deded4"),3,.25)
	var dark = FieldMaterials.surface("steel",Color("92958b"),7,.12)
	var leather = FieldMaterials.surface("timber",Color("999080"),3)
	var cloth = FieldMaterials.surface("cloth",Color("414b4b") if team==0 else Color("655044"),4)
	for mat in [steel,dark,leather,cloth]:
		mat.uv1_triplanar = false
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	steel.roughness = .64
	dark.roughness = .8
	var black = MarchArt.material(Color("171c1b"))
	torso = Node3D.new()
	visual.add_child(torso)
	var body = Node3D.new()
	torso.add_child(body)
	# Gambeson, fitted cuirass, mail skirt and a plain leather belt.
	armor(body,[Vector3(.78,.19,.13),Vector3(.95,.20,.145),Vector3(1.13,.175,.125),Vector3(1.40,.245,.145),Vector3(1.49,.21,.13),Vector3(1.54,.095,.085)],cloth)
	armor(body,[Vector3(1.07,.178,.134),Vector3(1.18,.193,.158),Vector3(1.37,.25,.177),Vector3(1.47,.23,.15),Vector3(1.52,.105,.093)],steel)
	armor(body,[Vector3(.75,.24,.16),Vector3(.99,.185,.14)],dark)
	armor(body,[Vector3(1.015,.19,.149),Vector3(1.065,.189,.146)],leather)
	MarchArt.box(body,Vector3(.04,1.04,-.155),Vector3(.065,.043,.016),steel)
	# Human-sized closed bascinet: no oversized head, crest or decorative gold.
	armor(body,[Vector3(1.49,.105,.09),Vector3(1.61,.135,.13),Vector3(1.67,.13,.13)],dark)
	rounded(body,Vector3(0,1.762,0),Vector3(.15,.18,.15),steel)
	MarchArt.box(body,Vector3(0,1.715,-.14),Vector3(.229,.16,.035),steel)
	MarchArt.box(body,Vector3(0,1.766,-.151),Vector3(.227,.022,.012),black)
	MarchArt.box(body,Vector3(0,1.744,-.169),Vector3(.023,.14,.025),steel)
	for side in [-1,1]:
		for hole in range(3):
			rounded(body,Vector3(side*(.045+hole*.022),1.69,-.147),Vector3(.006,.011,.006),black)
	# A small scabbard lies beside the left hip rather than a fantasy ornament.
	var scabbard = MarchArt.box(body,Vector3(-.235,.76,.07),Vector3(.052,.64,.034),leather)
	scabbard.rotation.z = -.18
	MarchArt.batch_static(body)
	for side in [-1,1]:
		var arm = Node3D.new()
		arm.position = Vector3(side*.273,1.455,0)
		torso.add_child(arm)
		var upper = Node3D.new()
		arm.add_child(upper)
		rounded(upper,Vector3(side*.014,-.025,0),Vector3(.128,.074,.143),steel)
		armor(upper,[Vector3(-.31,.074,.078),Vector3(-.10,.095,.10)],dark)
		MarchArt.batch_static(upper)
		var elbow = Node3D.new()
		elbow.position.y = -.30
		arm.add_child(elbow)
		var fore = Node3D.new()
		elbow.add_child(fore)
		rounded(fore,Vector3(0,0,0),Vector3(.074,.051,.09),steel)
		armor(fore,[Vector3(-.245,.055,.06),Vector3(-.03,.075,.078)],steel)
		rounded(fore,Vector3(0,-.28,-.012),Vector3(.061,.072,.045),leather)
		if side==1:
			right_arm = arm
			right_elbow = elbow
			MarchArt.cylinder(fore,Vector3(0,-.32,0),.024,.17,leather,.024,12)
			MarchArt.box(fore,Vector3(0,-.415,0),Vector3(.235,.025,.036),steel)
			armor(fore,[Vector3(-1.13,.002,.002),Vector3(-1.03,.035,.009),Vector3(-.43,.039,.011)],steel)
			rounded(fore,Vector3(0,-.225,0),Vector3(.031,.035,.026),steel)
		else:
			left_arm = arm
			left_elbow = elbow
			shield(fore,leather,1.05,-.101,true)
			shield(fore,steel,1.05,-.11)
			shield(fore,cloth,1.0,-.123)
			for x in [-.15,.01]:
				rounded(fore,Vector3(x,-.02,-.14),Vector3(.012,.012,.008),steel)
		MarchArt.batch_static(fore)
	for side in [-1,1]:
		var leg = Node3D.new()
		leg.position = Vector3(side*.108,.94,0)
		visual.add_child(leg)
		armor(leg,[Vector3(-.39,.082,.088),Vector3(-.07,.107,.115),Vector3(0,.095,.09)],dark)
		var knee = Node3D.new()
		knee.position.y = -.415
		leg.add_child(knee)
		rounded(knee,Vector3(0,0,-.04),Vector3(.09,.072,.095),steel)
		armor(knee,[Vector3(-.35,.058,.065),Vector3(-.07,.081,.084)],steel)
		rounded(knee,Vector3(0,-.425,-.072),Vector3(.081,.068,.175),leather)
		if side==1:
			right_leg = leg
			right_knee = knee
		else:
			left_leg = leg
			left_knee = knee
	# A tapered, folded mantle hangs from the shoulders rather than a rigid rectangle.
	var cloth_surface = SurfaceTool.new()
	cloth_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	cloth_surface.set_smooth_group(0)
	for row in range(8):
		for col in range(8):
			for corner in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(0,1)]:
				var u = (col+corner.x)/8.0
				var v = (row+corner.y)/8.0
				var x = (u*2-1)*(.18+v*.065)
				cloth_surface.set_uv(Vector2(u,v))
				cloth_surface.add_vertex(Vector3(x,-v*.73,.04+v*.08+cos(u*TAU*3)*.014*(.25+v)))
	cloth_surface.generate_normals()
	cloth_surface.generate_tangents()
	var mantle = cloth.duplicate()
	mantle.cull_mode = BaseMaterial3D.CULL_DISABLED
	cape = MarchArt.mesh(torso,cloth_surface.commit(),Vector3(0,1.46,.13),mantle)
	cape.visible = player
	# Retained as a hidden compatibility handle; no toy-like colored foot rings.
	ring = MarchArt.mesh(self,TorusMesh.new(),Vector3.ZERO,black)
	ring.visible = false

func animate(delta: float) -> void:
	cooldown = maxf(0,cooldown-delta)
	hurt = maxf(0,hurt-delta)
	stagger = maxf(0,stagger-delta)
	guard_time = maxf(0,guard_time-delta)
	ring.visible = false
	if dead:
		fall = minf(1,fall+delta*2.2)
		visual.rotation.z = fall*1.5
		visual.position.y = -fall*.45
		strike_clock = -1
		return
	gait += delta*(speed*2.0+.6)
	var amount = clampf(speed/4,0,1)
	left_leg.rotation.x = sin(gait)*.47*amount
	right_leg.rotation.x = -sin(gait)*.47*amount
	left_knee.rotation.x = -maxf(0,-sin(gait))*.8*amount
	right_knee.rotation.x = -maxf(0,sin(gait))*.8*amount
	torso.position.y = absf(sin(gait))*.018*amount
	if swing>0:
		swing = maxf(0,swing-delta)
		var progress = 1-swing/.64
		var cut = smoothstep(.25,.58,progress)
		right_arm.rotation.x = lerpf(-2.2,1.1,cut)
		right_arm.rotation.z = lerpf(-.65,.25,cut)
		right_elbow.rotation.x = -.35
		torso.rotation.y = sin(progress*TAU)*.16
	else:
		right_arm.rotation.x = .18-sin(gait)*.24*amount
		right_arm.rotation.z = -.08
		right_elbow.rotation.x = -.12
		torso.rotation.y = sin(gait)*.025*amount
	left_arm.rotation.x = .85 if block else sin(gait)*.20*amount
	left_arm.rotation.z = -.13 if block else .09
	left_elbow.rotation.x = .25 if block else -.18
	cape.rotation.x = -.04-amount*.07+sin(gait*.5)*.018
	visual.rotation.z = sin(hurt*45)*.045 if hurt>0 else 0.0
	visual.rotation.x = -.10 if stagger>0 else 0.0

func guarding_from(source: Vector3) -> bool:
	if not block or not source.is_finite():
		return false
	var direction = source-position
	direction.y = 0
	return (-basis.z).dot(direction.normalized())>.25

func damage(amount: float, source: Vector3 = Vector3.INF) -> bool:
	if dead:
		return false
	var guarded = guarding_from(source)
	hp = maxf(0,hp-amount*(0.0 if guarded and player and guard_time>0 else .18 if guarded else 1.0))
	hurt = .2
	if not guarded:
		stagger = .18
		strike_clock = -1
		swing = 0
	if hp<=0:
		dead = true
		collision_layer = 0
		return true
	return false
