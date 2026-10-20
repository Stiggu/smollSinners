// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Fx_Team/Fx_Grp_Compact_Shader  [_R_W_CONVERT _SURFACE_TYPE_TRANSPARENT _USE_CENTERNOISE _USE_STABLERANDOM]
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[9];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
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

// Unity samples with v up, Godot with v down.
vec2 unity_uv(vec2 uv) { return vec2(uv.x, 1.0 - uv.y); }

vec4 vertex_input(int vertex, int slot) {
	return texelFetch(vertex_data, ivec2((vertex % VERTICES_PER_ROW) * vertex_data_slots + slot, vertex / VERTICES_PER_ROW), 0);
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
	vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	vec4 cb0_19 = vec4(TIME, sin(TIME), cos(TIME), 0.0);
	r0.xyzw = (cb0_19.xxxx * material[7].zwxy);
	r0.xyzw = fract(r0.xyzw);
	r0.xyzw = (r0.xyzw + v4.xyxy);
	r0.xy = (v1.xy * v3.xy + r0.xy);
	r0.xy = (r0.xy * material[4].xy + material[4].zw);
	r1.xyzw = texture(tex_Noise_Tex, unity_uv(r0.xy)).xyzw;
	r1.xyzw = (r1.xyxy + vec4(-0.5, -0.5, -0.5, -0.5));
	r1.xyzw = (r1.xyzw * v2.xxxx);
	r1.xyzw = (material[0].zzyy * r1.xyzw + vec4(1.0, 1.0, 1.0, 1.0));
	r2.xyzw = (v1.xyxy + vec4(-0.5, -0.5, -0.5, -0.5));
	r1.xyzw = (r2.xyzw * r1.xyzw + vec4(0.5, 0.5, 0.5, 0.5));
	r0.xy = (r1.zw * v3.zw + r0.zw);
	r0.zw = (r1.xy * material[2].xy + material[2].zw);
	r1.xyzw = texture(tex_MainTex, unity_uv(r0.zw)).xyzw;
	r0.xy = (r0.xy * material[6].xy + material[6].zw);
	r0.xyzw = texture(tex_Dissolve_Tex, unity_uv(r0.xy)).xyzw;
	r0.x = (r1.x * r0.x + v2.y);
	r0.x = (r0.x + (-material[8].x));
	r0.y = ((-material[8].x) + 1.0);
	r0.y = (1.0 / r0.y);
	r0.x = clamp((r0.y * r0.x), 0.0, 1.0);
	r0.y = (r0.x * -2.0 + 3.0);
	r0.x = (r0.x * r0.x);
	r0.x = (r0.x * r0.y);
	r0.x = (r1.x * r0.x);
	r0.x = (r0.x * v5.w);
	r0.y = max(v2.y, 1.0);
	r0.y = min(r0.y, 100.0);
	o0.w = clamp((r0.y * r0.x), 0.0, 1.0);
	r0.xyzw = max(v2.zwzw, vec4(-999999988484154753734934528.0, -999999988484154753734934528.0, 0.0, 0.0));
	r0.xyzw = min(r0.xyzw, vec4(0.0, 0.0, 999999988484154753734934528.0, 999999988484154753734934528.0));
	r0.xz = ((-r0.yw) + r0.xz);
	r0.xy = (r1.xx * r0.xz + r0.yw);
	o0.xyz = (r0.yyy * v5.xyz + r0.xxx);
	// ret
	COLOR = vec4(max(o0.rgb, vec3(0.0)), clamp(o0.a, 0.0, 1.0));
}
