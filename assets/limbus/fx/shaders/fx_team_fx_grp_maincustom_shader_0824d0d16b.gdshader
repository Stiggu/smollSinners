// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Fx_Team/Fx_Grp_MainCustom_Shader  [_SURFACE_TYPE_TRANSPARENT _USE_CENTERNOISE]
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[13];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
uniform sampler2D tex_Dissolve_Mask_Tex : hint_default_white, repeat_enable, filter_linear;
uniform sampler2D tex_Dissolve_Tex : hint_default_white, repeat_enable, filter_linear;
uniform sampler2D tex_MainTex : hint_default_white, repeat_disable, filter_linear;
uniform sampler2D tex_Noise_Tex : hint_default_white, repeat_enable, filter_linear;

varying vec4 io_interp0;
varying vec4 io_interp1;
varying vec4 io_interp2;
varying vec4 io_interp3;
varying vec4 io_interp4;
varying vec4 io_interp5;
varying vec4 io_interp6;

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
	vec4 v4 = vertex_input(VERTEX_ID, 1);
	vec4 v5 = vertex_input(VERTEX_ID, 2);
	vec4 v6 = vertex_input(VERTEX_ID, 3);
	vec4 v7 = COLOR;
	vec4 r0 = vec4(0.0), r1 = vec4(0.0);
	vec4 o0 = vec4(0.0), o1 = vec4(0.0), o2 = vec4(0.0), o3 = vec4(0.0), o4 = vec4(0.0), o5 = vec4(0.0), o6 = vec4(0.0), o7 = vec4(0.0);
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
	o6.xyz = r0.xyz;
	o0.xyzw = (r1.xyzw + cb0_82.xyzw);
	o1.xyzw = v3.xyzw;
	o2.xyzw = v4.xyzw;
	o3.xyzw = v5.xyzw;
	o4.xyzw = v6.xyzw;
	o5.xyzw = v7.xyzw;
	r0.x = dot(v1.xyz, cb1_4.xyz);
	r0.y = dot(v1.xyz, cb1_5.xyz);
	r0.z = dot(v1.xyz, cb1_6.xyz);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = max(r0.w, 0.0);
	r0.w = inversesqrt(r0.w);
	o7.xyz = (r0.www * r0.xyz);
	// ret
	io_interp0 = o1;
	io_interp1 = o2;
	io_interp2 = o3;
	io_interp3 = o4;
	io_interp4 = o5;
	io_interp5 = o6;
	io_interp6 = o7;
}

void fragment() {
	vec4 v0 = vec4(FRAGCOORD.xy, 0.5, 1.0);
	vec4 v1 = io_interp0;
	vec4 v2 = io_interp1;
	vec4 v3 = io_interp2;
	vec4 v4 = io_interp3;
	vec4 v5 = io_interp4;
	vec4 v6 = io_interp5;
	vec4 v7 = io_interp6;
	vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0), r3 = vec4(0.0), r4 = vec4(0.0), r5 = vec4(0.0), r6 = vec4(0.0), r7 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	vec4 cb0_19 = vec4(TIME, sin(TIME), cos(TIME), 0.0);
	r0.xy = (cb0_19.xx * material[4].xy);
	r0.xy = fract(r0.xy);
	r0.xy = (r0.xy + material[10].zw);
	r1.xyw = (cb0_19.xxx * material[5].yzx);
	r0.zw = fract(r1.xy);
	r0.zw = (r0.zw + material[9].zw);
	r2.xyz = (material[12].yzw * vec3(0.017453, 0.017453, 0.017453));
	r1.x = sin(r2.y);
	r3.x = cos(r2.y);
	r4.x = (-r1.x);
	r4.y = r3.x;
	r4.z = r1.x;
	r1.xy = (v1.xy + vec2(-0.5, -0.5));
	r3.z = dot(r1.xy, r4.xy);
	r3.y = dot(r1.xy, r4.yz);
	r3.yz = (r3.yz + vec2(0.5, 0.5));
	r3.x = (r3.z * material[4].z + r3.y);
	r0.zw = (r3.xz * material[9].xy + r0.zw);
	r3.xyzw = texture(tex_Noise_Tex, unity_uv(r0.zw)).xyzw;
	r3.xyzw = (r3.xyxy + vec4(-0.5, -0.5, -0.5, -0.5));
	r3.xyzw = (r3.xyzw * v2.xxxx);
	r3.xyzw = (material[0].yyxx * r3.xyzw + vec4(1.0, 1.0, 1.0, 1.0));
	r4.x = sin(r2.z);
	r5.x = cos(r2.z);
	r2.x = sin(r2.x);
	r6.x = cos(r2.x);
	r7.z = r4.x;
	r7.y = r5.x;
	r7.x = (-r4.x);
	r4.z = dot(r1.xy, r7.xy);
	r4.y = dot(r1.xy, r7.yz);
	r0.zw = (r4.yz + vec2(0.5, 0.5));
	r4.x = (r0.w * material[6].x + r0.z);
	r0.zw = (r4.xz + vec2(-0.5, 0.0));
	r0.zw = (r0.zw * r3.zw + vec2(0.5, 0.5));
	r0.xy = (r0.zw * material[10].xy + r0.xy);
	r0.xyzw = texture(tex_Dissolve_Tex, unity_uv(r0.xy)).xyzw;
	r0.y = (material[8].x * 0.017453);
	r4.x = sin(r0.y);
	r5.x = cos(r0.y);
	r7.x = (-r4.x);
	r7.y = r5.x;
	r7.z = r4.x;
	r4.x = dot(r1.xy, r7.yz);
	r4.y = dot(r1.xy, r7.xy);
	r0.yz = (r4.xy + vec2(0.5, 0.5));
	r0.yz = (r0.yz * material[11].xy + material[11].zw);
	r4.xyzw = texture(tex_Dissolve_Mask_Tex, unity_uv(r0.yz)).xyzw;
	r0.y = clamp((r4.x * material[8].y), 0.0, 1.0);
	r0.x = (r0.y * r0.x);
	r4.z = r2.x;
	r4.y = r6.x;
	r4.x = (-r2.x);
	r2.z = dot(r1.xy, r4.xy);
	r2.y = dot(r1.xy, r4.yz);
	r0.yz = (r2.yz + vec2(0.5, 0.5));
	r2.x = (r0.z * material[6].x + r0.y);
	r0.yz = (r2.xz + vec2(-0.5, 0.0));
	r0.yz = (r0.yz * r3.xy + vec2(0.5, 0.5));
	r1.z = (cb0_19.x * material[4].w);
	r1.xy = fract(r1.zw);
	r1.xy = (r1.xy + v3.xy);
	r0.yz = (r0.yz * v3.zw + r1.xy);
	r1.xyzw = texture(tex_MainTex, unity_uv(r0.yz)).xyzw;
	r0.x = (r1.w * r0.x + v2.y);
	r0.x = (r0.x + (-material[5].w));
	r0.y = ((-material[5].w) + 1.0);
	r0.y = (1.0 / r0.y);
	r0.x = clamp((r0.y * r0.x), 0.0, 1.0);
	r0.y = (r0.x * -2.0 + 3.0);
	r0.x = (r0.x * r0.x);
	r0.x = (r0.x * r0.y);
	r0.x = (r0.x * v5.w);
	r0.x = clamp((r1.w * r0.x), 0.0, 1.0);
	r0.y = max(v2.y, 1.0);
	r0.y = min(r0.y, 100.0);
	r0.x = (r0.y * r0.x);
	o0.w = min(r0.x, 1.0);
	r0.xyzw = max(v2.wzwz, vec4(-1000000013848427855085568.0, -1000000013848427855085568.0, 0.0, 0.0));
	r0.xyzw = min(r0.xyzw, vec4(0.0, 0.0, 1000000013848427855085568.0, 1000000013848427855085568.0));
	r2.xyzw = ((-r0.xzzz) + r0.ywww);
	r0.xyzw = (r1.xxyz * r2.xyzw + r0.xzzz);
	o0.xyz = (r0.yzw * v5.xyz + r0.xxx);
	// ret
	COLOR = vec4(tone_mapped(o0.rgb), clamp(o0.a, 0.0, 1.0));
}
