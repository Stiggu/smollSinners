// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Fx_Team/Fx_Grp_Outline_ColorMask_Shader  [_SURFACE_TYPE_TRANSPARENT _USE_DEPTHFADE _USE_STABLERANDOM]
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[18];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
uniform sampler2D tex_Color_Tex : hint_default_white, repeat_enable, filter_linear;
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
	vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0), r3 = vec4(0.0), r4 = vec4(0.0), r5 = vec4(0.0), r6 = vec4(0.0), r7 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	vec4 cb0_19 = vec4(TIME, sin(TIME), cos(TIME), 0.0);
	r0.z = (cb0_19.x * material[12].y);
	r0.yw = (cb0_19.xx * material[2].yx);
	r0.zw = fract(r0.zw);
	r0.zw = (r0.zw + material[1].zw);
	r0.zw = (r0.zw + v4.xy);
	r0.x = (cb0_19.x * material[15].x);
	r0.xy = fract(r0.xy);
	r0.xy = (r0.xy + material[14].zw);
	r1.x = (material[17].y * 0.017453);
	r1.x = sin(r1.x);
	r2.x = cos(r1.x);
	r3.x = (-r1.x);
	r3.y = r2.x;
	r3.z = r1.x;
	r1.xy = (v1.xy + vec2(-0.5, -0.5));
	r2.z = dot(r1.xy, r3.xy);
	r2.y = dot(r1.xy, r3.yz);
	r2.yz = (r2.yz + vec2(0.5, 0.5));
	r2.x = (r2.z * material[0].y + r2.y);
	r0.xy = (r2.xz * material[14].xy + r0.xy);
	r2.xyzw = texture(tex_Noise_Tex, unity_uv(r0.xy)).xyzw;
	r0.xy = (r2.xy + vec2(-0.5, -0.5));
	r0.xy = (r0.xy * v2.xx);
	r2.xyz = (material[16].wyz * vec3(0.017453, 0.017453, 0.017453));
	r3.x = sin(r2.z);
	r4.x = cos(r2.z);
	r5.x = (-r3.x);
	r5.y = r4.x;
	r5.z = r3.x;
	r3.y = dot(r1.xy, r5.yz);
	r3.z = dot(r1.xy, r5.xy);
	r3.yz = (r3.yz + vec2(0.5, 0.5));
	r3.x = (r3.z * material[0].x + r3.y);
	r1.zw = (r0.xy * material[15].zz + r3.xz);
	r0.zw = (r1.zw * material[1].xy + r0.zw);
	r3.xyzw = texture(tex_Dissolve_Tex, unity_uv(r0.zw)).xyzw;
	r4.x = sin(r2.y);
	r5.x = cos(r2.y);
	r2.x = sin(r2.x);
	r6.x = cos(r2.x);
	r7.x = (-r4.x);
	r7.y = r5.x;
	r7.z = r4.x;
	r2.y = dot(r1.xy, r7.yz);
	r2.z = dot(r1.xy, r7.xy);
	r4.yz = (r2.yz + vec2(0.5, 0.5));
	r4.x = (r4.z * material[0].x + r4.y);
	r0.zw = (r0.xy * material[15].yy + r4.xz);
	r4.z = (cb0_19.x * material[10].x);
	r4.yw = (cb0_19.xx * material[4].xy);
	r1.zw = fract(r4.zw);
	r1.zw = (r1.zw + v3.xy);
	r0.zw = (r0.zw * v3.zw + r1.zw);
	r5.xyzw = texture(tex_MainTex, unity_uv(r0.zw)).xyzw;
	r0.z = ((-v2.y) + 1.0);
	r0.w = (r0.z + r0.z);
	r0.w = (r5.x * r3.x + (-r0.w));
	r0.w = (r0.w + 1.0);
	r1.z = (r0.z + material[7].x);
	r0.z = (r5.x * r0.w + (-r0.z));
	r0.w = (r5.x * r0.w + (-r1.z));
	r1.zw = ((-material[9].xy) + vec2(1.0, 1.0));
	r1.zw = (vec2(1.0, 1.0) / r1.zw);
	r0.zw = clamp((r0.zw * r1.wz), 0.0, 1.0);
	r1.z = (r0.w * -2.0 + 3.0);
	r0.w = (r0.w * r0.w);
	r0.w = ((-r1.z) * r0.w + 1.0);
	r0.w = (r0.w * material[8].w);
	r3.x = (-r2.x);
	r3.y = r6.x;
	r3.z = r2.x;
	r2.y = dot(r1.xy, r3.yz);
	r2.z = dot(r1.xy, r3.xy);
	r1.yz = (r2.yz + vec2(0.5, 0.5));
	r1.x = (r1.z * material[17].x + r1.y);
	r0.xy = (r0.xy * material[15].ww + r1.xz);
	r4.x = (cb0_19.x * material[12].x);
	r1.xy = fract(r4.xy);
	r1.xy = (r1.xy + material[11].zw);
	r1.xy = (r1.xy + v4.xy);
	r0.xy = (r0.xy * material[11].xy + r1.xy);
	r1.xyzw = texture(tex_Color_Tex, unity_uv(r0.xy)).xyzw;
	r0.x = (material[9].z + -0.5);
	r0.y = (r0.x + material[9].w);
	r0.x = (r0.x + (-material[9].w));
	r0.x = (r0.x + 1.0);
	r0.x = ((-r0.y) + r0.x);
	r1.xyzw = ((-r0.yyyy) + r1.xxyz);
	r0.x = (1.0 / r0.x);
	r1.xyzw = clamp((r0.xxxx * r1.xyzw), 0.0, 1.0);
	r2.xyzw = (r1.yyzw * vec4(-2.0, -2.0, -2.0, -2.0) + vec4(3.0, 3.0, 3.0, 3.0));
	r1.xyzw = (r1.xyzw * r1.xyzw);
	r1.xyzw = (r1.xyzw * r2.xyzw);
	r2.xyzw = max(v2.zwzw, vec4(-10000.0, -10000.0, 0.0, 0.0));
	r2.xyzw = min(r2.xyzw, vec4(0.0, 0.0, 10000.0, 10000.0));
	r3.xyzw = ((-r2.ywww) + r2.xzzz);
	r1.xyzw = (r1.xyzw * r3.xyzw + r2.ywww);
	r1.xyz = (r1.yzw * v5.xyz + r1.xxx);
	r2.xyz = log2(abs(material[8].xyz));
	r2.xyz = (r2.xyz * vec3(0.416667, 0.416667, 0.416667));
	r2.xyz = exp2(r2.xyz);
	r2.xyz = (r2.xyz * vec3(1.055, 1.055, 1.055) + vec3(-0.055, -0.055, -0.055));
	r3.xyz = vec3(greaterThanEqual(vec3(0.003131, 0.003131, 0.003131), material[8].xyz));
	r4.xyz = (material[8].xyz * vec3(12.92321, 12.92321, 12.92321));
	r2.xyz = mix(r2.xyz, r4.xyz, notEqual(r3.xyz, vec3(0.0)));
	r2.xyz = ((-r1.xyz) + r2.xyz);
	o0.xyz = (r0.www * r2.xyz + r1.xyz);
	r0.x = (r0.z * -2.0 + 3.0);
	r0.y = (r0.z * r0.z);
	r0.x = (r0.y * r0.x);
	r0.x = min(r0.x, 1.0);
	r0.x = (r0.x * v5.w);
	r0.y = clamp(dot(v6.yy, material[16].xx), 0.0, 1.0);
	o0.w = (r0.y * r0.x);
	// ret
	COLOR = vec4(max(o0.rgb, vec3(0.0)), clamp(o0.a, 0.0, 1.0));
}
