// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Fx_Team/Fx_Grp_Trail_Simple_Shader  [_SURFACE_TYPE_TRANSPARENT]
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[9];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
uniform sampler2D tex_MainTex : hint_default_white, repeat_enable, filter_linear;
uniform sampler2D tex_Noise_Tex : hint_default_white, repeat_enable, filter_linear;

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
	vec4 cb0_19 = vec4(TIME, sin(TIME), cos(TIME), 0.0);
	r0.x = (material[3].x * 0.017453);
	r0.x = sin(r0.x);
	r1.x = cos(r0.x);
	r2.x = (-r0.x);
	r2.y = r1.x;
	r2.z = r0.x;
	r0.xy = (v1.xy + vec2(-0.5, -0.5));
	r1.y = dot(r0.xy, r2.xy);
	r1.x = dot(r0.xy, r2.yz);
	r0.zw = (r1.xy + vec2(0.5, 0.5));
	r1.xzw = (cb0_19.xxx * material[3].wyz);
	r1.y = (cb0_19.x * material[4].x);
	r1.xyzw = fract(r1.xyzw);
	r1.xy = (r1.xy + material[5].zw);
	r1.zw = (r1.zw + material[7].zw);
	r0.zw = (r0.zw * material[5].xy + r1.xy);
	r2.xyzw = texture(tex_Noise_Tex, unity_uv(r0.zw)).xyzw;
	r0.z = (r2.x + -0.5);
	r0.w = (material[4].y * 0.017453);
	r1.x = sin(r0.w);
	r2.x = cos(r0.w);
	r3.x = (-r1.x);
	r3.y = r2.x;
	r3.z = r1.x;
	r1.x = dot(r0.xy, r3.yz);
	r1.y = dot(r0.xy, r3.xy);
	r0.xy = (r1.xy + vec2(0.5, 0.5));
	r0.xy = (r0.zz * material[8].xx + r0.xy);
	r0.xy = (r0.xy * material[7].xy + r1.zw);
	r0.xyzw = texture(tex_MainTex, unity_uv(r0.xy)).xyzw;
	r1.x = material[1].x;
	r1.y = material[6].x;
	r1.xyzw = max(r1.xyxy, vec4(-100.0, -100.0, 0.0, 0.0));
	r1.xyzw = min(r1.xyzw, vec4(0.0, 0.0, 100.0, 100.0));
	r1.yw = ((-r1.xz) + r1.yw);
	r1.xyzw = (r0.xxyz * r1.ywww + r1.xzzz);
	o0.w = clamp((r0.w * v2.w), 0.0, 1.0);
	o0.xyz = (r1.yzw * v2.xyz + r1.xxx);
	// ret
	COLOR = vec4(tone_mapped(o0.rgb), clamp(o0.a, 0.0, 1.0));
}
