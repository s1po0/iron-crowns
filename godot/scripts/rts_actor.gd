class_name CastleActor
extends Node3D
var anatomy: HumanBody
var animation: AnimationPlayer
var carrying: MeshInstance3D
var fallen = false

func setup(kind: String, index: int) -> void:
	anatomy=HumanBody.new()
	anatomy.name="Body"
	add_child(anatomy)
	var outfit=MarchCatalog.equipment(index).duplicate(true)
	outfit.coat="#8b7152" if kind=="worker" else "#516e69" if kind=="soldier" else "#8d493c"
	var people=MarchCatalog.data().humans
	anatomy.build(outfit,people[posmod(index,people.size())])
	if kind=="worker":
		for n in anatomy.skeleton.get_children():
			if n is BoneAttachment3D and n.bone_name in ["wrist_R","wrist_L"]:
				n.queue_free()
	carrying=MarchArt.box(self,Vector3(0,1,-.4),Vector3(.55,.4,.4),FieldMaterials.surface("timber",Color.WHITE,1))
	carrying.visible=false
	animation=AnimationPlayer.new()
	animation.root_node=NodePath("../Body")
	add_child(animation)
	var library=AnimationLibrary.new()
	for name in ["idle","walk","carry","work","attack"]:
		var clip=Animation.new()
		clip.length=1.0
		clip.loop_mode=Animation.LOOP_LINEAR
		for bone in ["upperarm01_R","upperarm01_L","lowerarm01_R","lowerarm01_L","upperleg01_R","upperleg01_L","lowerleg01_R","lowerleg01_L","spine01"]:
			var track=clip.add_track(Animation.TYPE_ROTATION_3D)
			clip.track_set_path(track,NodePath("Skeleton:"+bone))
			for frame in 9:
				var phase=float(frame)/8
				var swing=sin(phase*TAU)*(1.0 if bone.ends_with("R") else -1.0)
				var angles=Vector3.ZERO
				if bone.begins_with("upperarm"):
					angles.z=-.67 if bone.ends_with("R") else .67
					angles.x=swing*.38 if name=="walk" else -.8 if name=="carry" else (-.7+sin(phase*TAU)*.65 if name in ["work","attack"] else .06*sin(phase*TAU))
				elif bone.begins_with("upperleg") and name in ["walk","carry"]:
					angles.x=swing*.52
				elif bone.begins_with("lowerleg") and name in ["walk","carry"]:
					angles.x=maxf(0,-swing)*.7
				elif bone.begins_with("lowerarm"):
					angles.x=-.7 if name in ["carry","work","attack"] else -.12
				elif bone=="spine01":
					angles.x=.13 if name=="work" else 0.0
				clip.rotation_track_insert_key(track,phase,Quaternion.from_euler(angles))
		library.add_animation(name,clip)
	animation.add_animation_library("",library)
	animation.play("idle")

func update(unit: Dictionary, dt: float) -> void:
	position=CastleSim.world(unit.at)
	rotation.y=lerp_angle(rotation.y,float(unit.facing),minf(1,dt*12))
	if unit.hp<=0:
		fallen=true
		animation.pause()
		anatomy.rotation.z=lerpf(anatomy.rotation.z,1.5,minf(1,dt*5))
		carrying.visible=false
		return
	var name="idle"
	if unit.walking:
		name="carry" if not str(unit.carry).is_empty() else "walk"
	elif unit.attack>.5:
		name="attack"
	elif unit.wait>0:
		name="work"
	animation.speed_scale=1.35 if name in ["walk","carry"] else 1.0
	if animation.current_animation!=name:
		animation.play(name,.18)
	carrying.visible=not str(unit.carry).is_empty()
