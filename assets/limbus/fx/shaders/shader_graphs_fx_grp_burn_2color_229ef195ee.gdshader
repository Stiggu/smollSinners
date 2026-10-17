// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Shader Graphs/FX_Grp_Burn_2Color  []
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[2];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera

varying vec4 io_interp0;
varying vec4 io_interp1;
varying vec4 io_interp2;
varying vec4 io_interp3;

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
	vec4 v3 = vertex_input(VERTEX_ID, 0);
	vec4 v4 = COLOR;
	vec4 r0 = vec4(0.0), r1 = vec4(0.0);
	vec4 o0 = vec4(0.0), o1 = vec4(0.0), o2 = vec4(0.0), o3 = vec4(0.0), o4 = vec4(0.0);
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
	o3.xyz = r0.xyz;
	o0.xyzw = (r1.xyzw + cb0_82.xyzw);
	o1.xyzw = v3.xyzw;
	o2.xyzw = v4.xyzw;
	r0.x = dot(v1.xyz, cb1_4.xyz);
	r0.y = dot(v1.xyz, cb1_5.xyz);
	r0.z = dot(v1.xyz, cb1_6.xyz);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = max(r0.w, 0.0);
	r0.w = inversesqrt(r0.w);
	o4.xyz = (r0.www * r0.xyz);
	// ret
	io_interp0 = o1;
	io_interp1 = o2;
	io_interp2 = o3;
	io_interp3 = o4;
}

void fragment() {
	vec4 v0 = vec4(FRAGCOORD.xy, 0.5, 1.0);
	vec4 v1 = io_interp0;
	vec4 v2 = io_interp1;
	vec4 v3 = io_interp2;
	vec4 v4 = io_interp3;
	vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0), r3 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	r0.x = clamp(((-v1.x) + 1.0), 0.0, 1.0);
	r0.x = (r0.x + -0.500008);
	r0.x = (r0.x * 2.000031);
	r0.x = max(r0.x, 0.0);
	r0.y = log2(r0.x);
	r0.y = (r0.y * 0.416667);
	r0.y = exp2(r0.y);
	r0.y = (r0.y * 1.055 + -0.055);
	r0.z = float(0.003131 >= r0.x);
	r0.x = (r0.x * 12.92321);
	r0.x = ((r0.z != 0.0) ? r0.x : r0.y);
	r0.yzw = log2(abs(material[0].xyz));
	r0.yzw = (r0.yzw * vec3(0.416667, 0.416667, 0.416667));
	r0.yzw = exp2(r0.yzw);
	r0.yzw = (r0.yzw * vec3(1.055, 1.055, 1.055) + vec3(-0.055, -0.055, -0.055));
	r1.xyz = vec3(greaterThanEqual(vec3(0.003131, 0.003131, 0.003131), material[0].xyz));
	r2.xyz = (material[0].xyz * vec3(12.92321, 12.92321, 12.92321));
	r0.yzw = mix(r0.yzw, r2.xyz, notEqual(r1.xyz, vec3(0.0)));
	r0.xyz = (r0.yzw * r0.xxx);
	r0.w = clamp(v1.x, 0.0, 1.0);
	r0.w = (r0.w + -0.332998);
	r0.w = clamp((r0.w * 5.987664), 0.0, 1.0);
	r1.x = log2(r0.w);
	r1.x = (r1.x * 0.416667);
	r1.x = exp2(r1.x);
	r1.x = (r1.x * 1.055 + -0.055);
	r1.y = float(0.003131 >= r0.w);
	r0.w = (r0.w * 12.92321);
	r0.w = ((r1.y != 0.0) ? r0.w : r1.x);
	r1.xyz = log2(abs(material[1].xyz));
	r1.xyz = (r1.xyz * vec3(0.416667, 0.416667, 0.416667));
	r1.xyz = exp2(r1.xyz);
	r1.xyz = (r1.xyz * vec3(1.055, 1.055, 1.055) + vec3(-0.055, -0.055, -0.055));
	r2.xyz = vec3(greaterThanEqual(vec3(0.003131, 0.003131, 0.003131), material[1].xyz));
	r3.xyz = (material[1].xyz * vec3(12.92321, 12.92321, 12.92321));
	r1.xyz = mix(r1.xyz, r3.xyz, notEqual(r2.xyz, vec3(0.0)));
	o0.xyz = (r1.xyz * r0.www + r0.xyz);
	r0.xy = (v1.xy + vec2(-0.5, -0.5));
	r0.x = dot(r0.xy, r0.xy);
	r0.x = sqrt(r0.x);
	r0.x = ((-r0.x) * 2.0 + 1.0);
	r0.x = max(r0.x, 0.0);
	r0.x = ((-r0.x) + 1.0);
	r0.x = dot(r0.xxx, r0.xxx);
	r0.x = sqrt(r0.x);
	r0.x = (r0.x + (-v2.y));
	r0.y = max(v2.z, 0.00001);
	r0.x = (r0.x / r0.y);
	r0.x = clamp(((-r0.x) + 1.0), 0.0, 1.0);
	o0.w = (r0.x * v2.w);
	// ret
	COLOR = vec4(tone_mapped(o0.rgb), clamp(o0.a, 0.0, 1.0));
}
