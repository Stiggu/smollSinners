// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Fx_Team/Fx_Grp_Outline_ColorMask_Shader_N_Compact  [_SURFACE_TYPE_TRANSPARENT _USE_STABLERANDOM]
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[15];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
uniform sampler2D tex_Color_Tex : hint_default_white, repeat_enable, filter_linear;
uniform sampler2D tex_Dissolve_Tex : hint_default_white, repeat_enable, filter_linear;
uniform sampler2D tex_MainTex : hint_default_white, repeat_enable, filter_linear;
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
	vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0), r3 = vec4(0.0), r4 = vec4(0.0), r5 = vec4(0.0), r6 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	vec4 cb0_19 = vec4(TIME, sin(TIME), cos(TIME), 0.0);
	r0.xyz = log2(abs(material[7].xyz));
	r0.xyz = (r0.xyz * vec3(0.416667, 0.416667, 0.416667));
	r0.xyz = exp2(r0.xyz);
	r0.xyz = (r0.xyz * vec3(1.055, 1.055, 1.055) + vec3(-0.055, -0.055, -0.055));
	r1.xyz = vec3(greaterThanEqual(vec3(0.003131, 0.003131, 0.003131), material[7].xyz));
	r2.xyz = (material[7].xyz * vec3(12.92321, 12.92321, 12.92321));
	r0.xyz = mix(r0.xyz, r2.xyz, notEqual(r1.xyz, vec3(0.0)));
	r0.w = (material[8].z + -0.5);
	r1.x = (r0.w + (-material[8].w));
	r0.w = (r0.w + material[8].w);
	r1.x = (r1.x + 1.0);
	r1.x = ((-r0.w) + r1.x);
	r1.x = max(r1.x, 0.001);
	r1.x = min(r1.x, 100.0);
	r2.x = (cb0_19.x * material[11].x);
	r2.yw = (cb0_19.xx * material[3].xy);
	r1.yz = fract(r2.xy);
	r1.yz = (r1.yz + material[10].zw);
	r1.yz = (r1.yz + v4.xy);
	r3.x = (cb0_19.x * material[14].x);
	r3.yw = (cb0_19.xx * material[1].yx);
	r2.xy = fract(r3.xy);
	r2.xy = (r2.xy + material[13].zw);
	r2.xy = (r2.xy + v4.xy);
	r2.xy = (v1.xy * material[13].xy + r2.xy);
	r4.xyzw = texture(tex_Noise_Tex, unity_uv(r2.xy)).xyzw;
	r2.xy = (r4.xy + vec2(-0.5, -0.5));
	r2.xy = (r2.xy * v2.xx);
	r4.xyzw = (r2.xyxy * material[14].wwyy + v1.xyxy);
	r2.xy = (r2.xy * material[14].zz + v1.xy);
	r1.yz = (r4.xy * material[10].xy + r1.yz);
	r5.xyzw = texture(tex_Color_Tex, unity_uv(r1.yz)).xyzw;
	r5.xyzw = ((-r0.wwww) + r5.xxyz);
	r1.xyzw = clamp((r5.xyzw / r1.xxxx), 0.0, 1.0);
	r5.xyzw = max(v2.zwzw, vec4(-10000.0, -10000.0, 0.0, 0.0));
	r5.xyzw = min(r5.xyzw, vec4(0.0, 0.0, 10000.0, 10000.0));
	r6.xyzw = ((-r5.ywww) + r5.xzzz);
	r1.xyzw = (r1.xyzw * r6.xyzw + r5.ywww);
	r1.xyz = (r1.yzw * v5.xyz + r1.xxx);
	r0.xyz = (r0.xyz + (-r1.xyz));
	r3.z = (cb0_19.x * material[11].y);
	r3.xy = fract(r3.zw);
	r3.xy = (r3.xy + material[0].zw);
	r3.xy = (r3.xy + v4.xy);
	r2.xy = (r2.xy * material[0].xy + r3.xy);
	r3.xyzw = texture(tex_Dissolve_Tex, unity_uv(r2.xy)).xyzw;
	r2.z = (cb0_19.x * material[9].x);
	r2.xy = fract(r2.zw);
	r2.xy = (r2.xy + v3.xy);
	r2.xy = (r4.zw * v3.zw + r2.xy);
	r2.xyzw = texture(tex_MainTex, unity_uv(r2.xy)).xyzw;
	r0.w = ((-v2.y) + 1.0);
	r1.w = (r0.w + r0.w);
	r1.w = (r2.x * r3.x + (-r1.w));
	r1.w = (r1.w + 1.0);
	r2.y = (r0.w + material[6].x);
	r0.w = (r2.x * r1.w + (-r0.w));
	r1.w = (r2.x * r1.w + (-r2.y));
	r2.xy = ((-material[8].xy) + vec2(1.0, 1.0));
	r2.xy = max(r2.xy, vec2(0.001, 0.001));
	r2.xy = min(r2.xy, vec2(100.0, 100.0));
	r1.w = clamp((r1.w / r2.x), 0.0, 1.0);
	r0.w = clamp((r0.w / r2.y), 0.0, 1.0);
	o0.w = (r0.w * v5.w);
	r0.w = ((-r1.w) + 1.0);
	r0.w = (r0.w * material[7].w);
	o0.xyz = (r0.www * r0.xyz + r1.xyz);
	// ret
	COLOR = vec4(tone_mapped(o0.rgb), clamp(o0.a, 0.0, 1.0));
}
