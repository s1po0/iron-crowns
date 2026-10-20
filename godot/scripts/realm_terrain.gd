class_name RealmTerrain
extends Node3D
const CHUNK=16
var mission_id="realm_valley"
var loaded: Dictionary={}
var quality=-1
var generation=-1
var fallback: Material
func setup(id: String) -> void:
	mission_id=id
	fallback=FieldMaterials.surface("earth",Color("778260"),1)
	# Coarse 400²-cell base stays visible while near-camera detail streams in.
	var m=CastleMissions.data(id)
	for span in [[-.5,m.river[0]-.5],[m.river[1]+.5,399.5]]:
		var ground=MeshInstance3D.new()
		var slab=PlaneMesh.new()
		slab.size=Vector2((span[1]-span[0])*3,1200) if m.axis=="x" else Vector2(1200,(span[1]-span[0])*3)
		ground.mesh=slab
		var middle=(span[0]+span[1])*.5
		ground.position=CastleSim.world(Vector2(middle,199.5) if m.axis=="x" else Vector2(199.5,middle))+Vector3(0,-.025,0)
		ground.material_override=fallback
		add_child(ground)
	var river=MeshInstance3D.new()
	var plane=PlaneMesh.new()
	plane.size=Vector2(9,1200) if m.axis=="x" else Vector2(1200,9)
	river.mesh=plane
	var center=CastleSim.world(Vector2(199.5,199.5))
	var bridge=CastleSim.world(CastleMissions.bridge_center(id))
	river.position=Vector3(bridge.x,-.3,center.z) if m.axis=="x" else Vector3(center.x,-.3,bridge.z)
	var material=StandardMaterial3D.new()
	material.albedo_color=Color("416b70")
	material.roughness=.25
	river.material_override=material
	add_child(river)
func mesh_for(origin: Vector2i,width: int,material: Material,offset: float=0) -> MeshInstance3D:
	var s=SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Flat, navigable terrain; only the riverbed is depressed.
	var step=1 if width==CHUNK else 4
	for y in range(origin.y,origin.y+width,step):
		for x in range(origin.x,origin.x+width,step):
			for p in [Vector2(x-.5,y-.5),Vector2(x+step-.5,y-.5),Vector2(x-.5,y+step-.5),Vector2(x+step-.5,y-.5),Vector2(x+step-.5,y+step-.5),Vector2(x-.5,y+step-.5)]:
				s.set_uv((p-Vector2(origin)+Vector2(.5,.5))/width)
				var pos=CastleSim.world(p)
				pos.y=(-.7 if CastleMissions.channel(p,mission_id) else 0.0)+offset
				s.add_vertex(pos)
	s.generate_normals()
	s.generate_tangents()
	var node=MeshInstance3D.new()
	node.mesh=s.commit()
	node.material_override=material
	return node
func stream(focus: Vector3,level: int) -> void:
	if level!=quality or generation!=RealmRegions.generation:
		for node in loaded.values():
			node.queue_free()
		loaded.clear()
		quality=level
		generation=RealmRegions.generation
	var cell=CastleSim.cell(focus)
	var center=Vector2i(clampi(int(cell.x/CHUNK),0,24),clampi(int(cell.y/CHUNK),0,24))
	var radius=2
	for key in loaded.keys():
		if maxi(absi(key.x-center.x),absi(key.y-center.y))>radius:
			loaded[key].queue_free()
			loaded.erase(key)
	# Nearest first; only one bounded chunk upload per frame. No permanent texture cache.
	for ring in range(radius+1):
		for y in range(maxi(0,center.y-ring),mini(25,center.y+ring+1)):
			for x in range(maxi(0,center.x-ring),mini(25,center.x+ring+1)):
				var key=Vector2i(x,y)
				if loaded.has(key):
					continue
				var color=RealmRegions.texture(x,y,"albedo",quality)
				var material: Material=fallback
				if color!=null:
					var detail=StandardMaterial3D.new()
					detail.albedo_texture=color
					detail.roughness=.95
					detail.normal_texture=RealmRegions.texture(x,y,"normal",quality)
					detail.normal_enabled=detail.normal_texture!=null
					material=detail
				var node=mesh_for(key*CHUNK,CHUNK,material)
				add_child(node)
				for site in CastleMissions.outposts(mission_id):
					if Vector2i(int(site.x/CHUNK),int(site.y/CHUNK))==key:
						var pos=CastleSim.world(Vector2(site))
						MarchArt.box(node,pos+Vector3(0,2,0),Vector3(.3,4,.3),FieldMaterials.surface("timber",Color("62513b"),1))
						MarchArt.box(node,pos+Vector3(1,3.5,0),Vector3(2,1,.08),MarchArt.material(Color("c58d43")))
						var label=Label3D.new()
						label.text="پۆستی بازرگانی · ٣ سەرباز"
						label.font=load("res://assets/fonts/vazirmatn.ttf")
						label.position=pos+Vector3(0,5,0)
						label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
						node.add_child(label)
				loaded[key]=node
				return
