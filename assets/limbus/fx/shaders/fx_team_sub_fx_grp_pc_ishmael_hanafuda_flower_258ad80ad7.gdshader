// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Fx_Team_Sub/Fx_Grp_PC_Ishmael_Hanafuda_Flower  [_SURFACE_TYPE_TRANSPARENT _USE_CENTERNOISE]
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[6];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
uniform sampler2D tex_MainTex : hint_default_white, repeat_disable, filter_linear;
uniform sampler2D tex_Noise_Tex : hint_default_white, repeat_enable, filter_linear;

varying vec4 io_interp0;
varying vec4 io_interp1;
varying vec4 io_interp2;
varying vec4 io_interp3;
varying vec4 io_interp4;
varying vec4 io_interp5;

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
	vec4 v6 = COLOR;
	vec4 r0 = vec4(0.0), r1 = vec4(0.0);
	vec4 o0 = vec4(0.0), o1 = vec4(0.0), o2 = vec4(0.0), o3 = vec4(0.0), o4 = vec4(0.0), o5 = vec4(0.0), o6 = vec4(0.0);
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
	o5.xyz = r0.xyz;
	o0.xyzw = (r1.xyzw + cb0_82.xyzw);
	o1.xyzw = v3.xyzw;
	o2.xyzw = v4.xyzw;
	o3.xyzw = v5.xyzw;
	o4.xyzw = v6.xyzw;
	r0.x = dot(v1.xyz, cb1_4.xyz);
	r0.y = dot(v1.xyz, cb1_5.xyz);
	r0.z = dot(v1.xyz, cb1_6.xyz);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = max(r0.w, 0.0);
	r0.w = inversesqrt(r0.w);
	o6.xyz = (r0.www * r0.xyz);
	// ret
	io_interp0 = o1;
	io_interp1 = o2;
	io_interp2 = o3;
	io_interp3 = o4;
	io_interp4 = o5;
	io_interp5 = o6;
}

void fragment() {
	vec4 v0 = vec4(FRAGCOORD.xy, 0.5, 1.0);
	vec4 v1 = io_interp0;
	vec4 v2 = io_interp1;
	vec4 v3 = io_interp2;
	vec4 v4 = io_interp3;
	vec4 v5 = io_interp4;
	vec4 v6 = io_interp5;
	vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0), r3 = vec4(0.0), r4 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	vec4 cb0_19 = vec4(TIME, sin(TIME), cos(TIME), 0.0);
	r0.xy = (material[5].wz * vec2(0.017453, 0.017453));
	r0.x = sin(r0.x);
	r1.x = cos(r0.x);
	r2.x = sin(r0.y);
	r3.x = cos(r0.y);
	r1.y = r0.x;
	r0.xy = (v1.xy + vec2(-0.5, -0.5));
	r0.z = dot(r0.xy, r1.xy);
	r0.z = (r0.z + 0.5);
	r0.w = float(0.5 >= r0.z);
	r0.z = float(r0.z >= 0.5);
	r1.x = ((r0.z != 0.0) ? -1.0 : -0.0);
	r0.zw = mix(vec2(0.0), vec2(1.0, 1.0), notEqual(r0.zw, vec2(0.0)));
	r0.w = (r1.x + r0.w);
	r0.z = (v3.x * r0.w + r0.z);
	r3.y = r2.x;
	r0.w = dot(r0.xy, r3.xy);
	r0.w = (r0.w + 0.5);
	r1.x = float(0.5 >= r0.w);
	r0.w = float(r0.w >= 0.5);
	r1.x = r1.x;
	r1.y = ((r0.w != 0.0) ? -1.0 : -0.0);
	r0.w = r0.w;
	r1.x = (r1.y + r1.x);
	r0.w = (v3.y * r1.x + r0.w);
	r0.z = (r0.w * r0.z);
	r1.xy = (cb0_19.xx * material[5].xy);
	r1.xy = fract(r1.xy);
	r1.xy = (v1.xy * v3.xy + r1.xy);
	r1.xy = (r1.xy * material[4].xy + material[4].zw);
	r1.xyzw = texture(tex_Noise_Tex, unity_uv(r1.xy)).xyzw;
	r1.xy = (r1.xy + vec2(-0.5, -0.5));
	r1.xy = (r1.xy * v2.xx);
	r1.xy = (material[0].xx * r1.xy + vec2(1.0, 1.0));
	r0.w = (v3.z * 0.017453);
	r2.x = sin(r0.w);
	r3.x = cos(r0.w);
	r4.x = (-r2.x);
	r4.y = r3.x;
	r4.z = r2.x;
	r2.x = dot(r0.xy, r4.yz);
	r2.y = dot(r0.xy, r4.xy);
	r0.xy = (r2.xy * r1.xy + vec2(0.5, 0.5));
	r0.xy = (r0.xy * material[2].xy + material[2].zw);
	r1.xyzw = texture(tex_MainTex, unity_uv(r0.xy)).xyzw;
	r0.x = (r0.z * r1.w);
	o0.w = clamp((r0.x * v4.w), 0.0, 1.0);
	r0.xyzw = max(v2.zwzw, vec4(-999999988484154753734934528.0, -999999988484154753734934528.0, 0.0, 0.0));
	r0.xyzw = min(r0.xyzw, vec4(0.0, 0.0, 999999988484154753734934528.0, 999999988484154753734934528.0));
	r2.xyzw = ((-r0.ywww) + r0.xzzz);
	r0.xyzw = (r1.xxyz * r2.xyzw + r0.ywww);
	o0.xyz = (r0.yzw * v4.xyz + r0.xxx);
	// ret
	COLOR = vec4(max(o0.rgb, vec3(0.0)), clamp(o0.a, 0.0, 1.0));
}
