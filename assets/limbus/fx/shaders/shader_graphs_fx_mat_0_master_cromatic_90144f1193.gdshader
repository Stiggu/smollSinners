// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Shader Graphs/FX_Mat_0_Master_Cromatic  []
shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

uniform vec4 material[1];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
uniform sampler2D global_GrabbedTexture : hint_screen_texture, filter_linear;

varying vec4 io_interp0;
varying vec4 io_interp1;

const float PX_PER_UNIT = 60.0;
const int VERTICES_PER_ROW = 256;
const float TONEMAP_EXPOSURE = 0.7;

// Unity samples with v up, Godot with v down.
vec2 unity_uv(vec2 uv) { return vec2(uv.x, 1.0 - uv.y); }

vec4 vertex_input(int vertex, int slot) {
	return texelFetch(vertex_data, ivec2((vertex % VERTICES_PER_ROW) * vertex_data_slots + slot, vertex / VERTICES_PER_ROW), 0);
}

// HDR colours as the game's camera shows them: each channel saturates on its own.
vec3 tone_mapped(vec3 rgb) {
	float brightest = max(rgb.r, max(rgb.g, rgb.b));
	if (brightest <= 1.0) return max(rgb, vec3(0.0));
	vec3 mapped = vec3(1.0) - exp(-max(rgb, vec3(0.0)) * TONEMAP_EXPOSURE);
	return mapped / (1.0 - exp(-brightest * TONEMAP_EXPOSURE));
}

void vertex() {
	vec4 v0 = vec4(VERTEX.x / PX_PER_UNIT, -VERTEX.y / PX_PER_UNIT, 0.0, 1.0);
	vec4 v1 = (normal_slot < 0 ? vec4(0.0, 0.0, -1.0, 0.0) : vertex_input(VERTEX_ID, normal_slot));
	vec4 v2 = vec4(1.0, 0.0, 0.0, 1.0);
	vec4 r0 = vec4(0.0), r1 = vec4(0.0);
	vec4 o0 = vec4(0.0), o1 = vec4(0.0), o2 = vec4(0.0);
	vec4 cb0_79 = vec4(1.0, 0.0, 0.0, 0.0);
	vec4 cb0_80 = vec4(0.0, 1.0, 0.0, 0.0);
	vec4 cb0_81 = vec4(0.0, 0.0, 1.0, 0.0);
	vec4 cb0_82 = vec4(0.0, 0.0, 0.0, 1.0);
	vec4 cb1_0 = vec4(1.0, 0.0, 0.0, 0.0);
	vec4 cb1_1 = vec4(0.0, 1.0, 0.0, 0.0);
	vec4 cb1_2 = vec4(0.0, 0.0, 1.0, 0.0);
	vec4 cb1_3 = vec4(0.0, 0.0, 0.0, 1.0);
	vec4 cb1_4 = vec4(1.0, 0.0, 0.0, 0.0);
	vec4 cb1_5 = vec4(0.0, 1.0, 0.0, 0.0);
	vec4 cb1_6 = vec4(0.0, 0.0, 1.0, 0.0);
	r0.xyz = (v0.yyy * cb1_1.xyz);
	r0.xyz = (cb1_0.xyz * v0.xxx + r0.xyz);
	r0.xyz = (cb1_2.xyz * v0.zzz + r0.xyz);
	r0.xyz = (r0.xyz + cb1_3.xyz);
	r1.xyzw = (r0.yyyy * cb0_80.xyzw);
	r1.xyzw = (cb0_79.xyzw * r0.xxxx + r1.xyzw);
	r1.xyzw = (cb0_81.xyzw * r0.zzzz + r1.xyzw);
	o1.xyz = r0.xyz;
	o0.xyzw = (r1.xyzw + cb0_82.xyzw);
	r0.x = dot(v1.xyz, cb1_4.xyz);
	r0.y = dot(v1.xyz, cb1_5.xyz);
	r0.z = dot(v1.xyz, cb1_6.xyz);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = max(r0.w, 0.0);
	r0.w = inversesqrt(r0.w);
	o2.xyz = (r0.www * r0.xyz);
	// ret
	io_interp0 = o1;
	io_interp1 = o2;
}

void fragment() {
	vec4 screen_texel = vec4(0.0);
	float screen_alpha = 0.0;
	vec4 v0 = vec4(FRAGCOORD.xy, 0.5, 1.0);
	vec4 v1 = io_interp0;
	vec4 v2 = io_interp1;
	vec4 r0 = vec4(0.0), r1 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	vec4 cb0_3 = vec4(1.0 / SCREEN_PIXEL_SIZE, 1.0 + SCREEN_PIXEL_SIZE);
	vec4 cb0_22 = vec4(1.0, 0.3, 1000.0, 0.001);
	r0.x = float(cb0_22.x < 0.0);
	r0.y = ((-v0.y) + cb0_3.y);
	r0.y = ((r0.x != 0.0) ? r0.y : v0.y);
	r0.x = v0.x;
	r0.xy = (r0.xy / cb0_3.xy);
	r0.z = ((-r0.y) + 1.0);
	r0.xy = ((-r0.xz) + vec2(0.5, 0.5));
	r0.zw = ((-r0.xy) + vec2(0.5, 0.5));
	r1.xyzw = (material[0].xyxy * vec4(0.01, 0.01, -0.01, -0.01) + (-r0.xyxy));
	r1.xyzw = (r1.xyzw + vec4(0.5, 0.5, 0.5, 0.5));
	screen_texel = texture(global_GrabbedTexture, unity_uv(r0.zw));
	screen_alpha = max(screen_alpha, screen_texel.a);
	r0.xyzw = screen_texel.xyzw;
	o0.y = r0.y;
	screen_texel = texture(global_GrabbedTexture, unity_uv(r1.xy));
	screen_alpha = max(screen_alpha, screen_texel.a);
	r0.xyzw = screen_texel.xyzw;
	screen_texel = texture(global_GrabbedTexture, unity_uv(r1.zw));
	screen_alpha = max(screen_alpha, screen_texel.a);
	r1.xyzw = screen_texel.xyzw;
	o0.z = r1.z;
	o0.x = r0.x;
	o0.w = 1.0;
	// ret
	COLOR = vec4(clamp(o0.rgb, vec3(0.0), vec3(1.0)), screen_alpha);
}
