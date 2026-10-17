// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Legacy Shaders/Particles/Alpha Blended Premultiply  []
// approximated: global _MainTex_ST
shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

uniform vec4 material[1];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
uniform sampler2D tex_MainTex : hint_default_white, repeat_enable, filter_linear;

varying vec4 io_color0;
varying vec4 io_texcoord0;

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
	vec4 v1 = COLOR;
	vec4 v2 = vertex_input(VERTEX_ID, 0);
	vec4 r0 = vec4(0.0), r1 = vec4(0.0);
	vec4 o0 = vec4(0.0), o1 = vec4(0.0), o2 = vec4(0.0);
	vec4 cb0_3 = vec4(0.0, 0.0, 0.0, 0.0);
	vec4 cb1_0 = vec4(1.0, 0.0, 0.0, 0.0);
	vec4 cb1_1 = vec4(0.0, 1.0, 0.0, 0.0);
	vec4 cb1_2 = vec4(0.0, 0.0, 1.0, 0.0);
	vec4 cb1_3 = vec4(0.0, 0.0, 0.0, 1.0);
	vec4 cb2_17 = vec4(1.0, 0.0, 0.0, 0.0);
	vec4 cb2_18 = vec4(0.0, 1.0, 0.0, 0.0);
	vec4 cb2_19 = vec4(0.0, 0.0, 1.0, 0.0);
	vec4 cb2_20 = vec4(0.0, 0.0, 0.0, 1.0);
	r0.xyzw = (v0.yyyy * cb1_1.xyzw);
	r0.xyzw = (cb1_0.xyzw * v0.xxxx + r0.xyzw);
	r0.xyzw = (cb1_2.xyzw * v0.zzzz + r0.xyzw);
	r0.xyzw = (r0.xyzw + cb1_3.xyzw);
	r1.xyzw = (r0.yyyy * cb2_18.xyzw);
	r1.xyzw = (cb2_17.xyzw * r0.xxxx + r1.xyzw);
	r1.xyzw = (cb2_19.xyzw * r0.zzzz + r1.xyzw);
	o0.xyzw = (cb2_20.xyzw * r0.wwww + r1.xyzw);
	o1.xyzw = v1.xyzw;
	o2.xy = (v2.xy * cb0_3.xy + cb0_3.zw);
	// ret
	io_color0 = o1;
	io_texcoord0 = o2;
}

void fragment() {
	vec4 v0 = vec4(FRAGCOORD.xy, 0.5, 1.0);
	vec4 v1 = io_color0;
	vec4 v2 = io_texcoord0;
	vec4 r0 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	r0.xyzw = texture(tex_MainTex, unity_uv(v2.xy)).xyzw;
	r0.xyzw = (r0.xyzw * v1.xyzw);
	o0.xyzw = (r0.xyzw * v1.wwww);
	// ret
	COLOR = vec4(tone_mapped(o0.rgb), clamp(o0.a, 0.0, 1.0));
}
