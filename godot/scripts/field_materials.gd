class_name FieldMaterials
extends RefCounted

static var cache: Dictionary = {}

static func surface(name: String, tint: Color = Color.WHITE, scale_value: float = 1.0, metal: float = 0.0) -> StandardMaterial3D:
	var key = name+tint.to_html()+str(scale_value)+str(metal)
	if cache.has(key):
		return cache[key]
	var m = StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/materials/"+name+".jpg")
	m.normal_enabled = true
	m.normal_texture = load("res://assets/materials/"+name+"-normal.png")
	m.normal_scale = .55
	m.albedo_color = tint
	m.roughness = .92 if metal==0 else .52
	m.metallic = metal
	m.metallic_specular = .3
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE*scale_value
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	cache[key] = m
	return m

static func cutout(name: String) -> StandardMaterial3D:
	if cache.has(name):
		return cache[name]
	var m = StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/materials/"+name+".png")
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = .45
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 1.0
	cache[name] = m
	return m

static func ground() -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D meadow : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soil : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D detail_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world;
void vertex(){ world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment(){
 vec2 uv = world.xz * 0.32;
 float road = 1.0-smoothstep(1.65,4.3,abs(world.x-sin(world.z*.055)*2.5));
 float yard = (1.0-smoothstep(5.0,8.0,abs(world.x)))*(1.0-smoothstep(5.0,11.0,abs(world.z+23.0)));
 float blend = max(road,yard*.85);
 ALBEDO = mix(texture(meadow,uv).rgb,texture(soil,uv*1.4).rgb,blend);
 NORMAL_MAP = texture(detail_normal,uv).rgb;
 NORMAL_MAP_DEPTH = .45;
 ROUGHNESS = .97;
 SPECULAR = .18;
}"""
	var m = ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("meadow",load("res://assets/materials/meadow.jpg"))
	m.set_shader_parameter("soil",load("res://assets/materials/earth.jpg"))
	m.set_shader_parameter("detail_normal",load("res://assets/materials/meadow-normal.png"))
	return m
