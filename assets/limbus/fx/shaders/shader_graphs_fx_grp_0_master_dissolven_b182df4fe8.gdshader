// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Shader Graphs/FX_Grp_0_Master_DissolveN  []
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[12];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
uniform sampler2D tex_MainTex : hint_default_white, repeat_disable, filter_linear;
uniform sampler2D tex_Tex_Noise1 : hint_default_white, repeat_enable, filter_linear;
uniform sampler2D tex_Tex_Noise2 : hint_default_white, repeat_enable, filter_linear;

varying vec4 io_interp0;
varying vec4 io_interp1;
varying vec4 io_interp2;
varying vec4 io_interp3;
varying vec4 io_interp4;

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
	vec4 v5 = COLOR;
	vec4 r0 = vec4(0.0), r1 = vec4(0.0);
	vec4 o0 = vec4(0.0), o1 = vec4(0.0), o2 = vec4(0.0), o3 = vec4(0.0), o4 = vec4(0.0), o5 = vec4(0.0);
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
	o4.xyz = r0.xyz;
	o0.xyzw = (r1.xyzw + cb0_82.xyzw);
	o1.xyzw = v3.xyzw;
	o2.xyzw = v4.xyzw;
	o3.xyzw = v5.xyzw;
	r0.x = dot(v1.xyz, cb1_4.xyz);
	r0.y = dot(v1.xyz, cb1_5.xyz);
	r0.z = dot(v1.xyz, cb1_6.xyz);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = max(r0.w, 0.0);
	r0.w = inversesqrt(r0.w);
	o5.xyz = (r0.www * r0.xyz);
	// ret
	io_interp0 = o1;
	io_interp1 = o2;
	io_interp2 = o3;
	io_interp3 = o4;
	io_interp4 = o5;
}

void fragment() {
	vec4 v0 = vec4(FRAGCOORD.xy, 0.5, 1.0);
	vec4 v1 = io_interp0;
	vec4 v2 = io_interp1;
	vec4 v3 = io_interp2;
	vec4 v4 = io_interp3;
	vec4 v5 = io_interp4;
	vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0), r3 = vec4(0.0), r4 = vec4(0.0), r5 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	vec4 cb0_19 = vec4(TIME, sin(TIME), cos(TIME), 0.0);
	r0.xyz = log2(abs(material[7].xyz));
	r0.xyz = (r0.xyz * vec3(0.416667, 0.416667, 0.416667));
	r0.xyz = exp2(r0.xyz);
	r0.xyz = (r0.xyz * vec3(1.055, 1.055, 1.055) + vec3(-0.055, -0.055, -0.055));
	r1.xyz = vec3(greaterThanEqual(vec3(0.003131, 0.003131, 0.003131), material[7].xyz));
	r2.xyz = (material[7].xyz * vec3(12.92321, 12.92321, 12.92321));
	r0.xyz = mix(r0.xyz, r2.xyz, notEqual(r1.xyz, vec3(0.0)));
	r0.w = ((-v1.w) + material[9].y);
	r0.w = (material[5].y * r0.w + v1.w);
	r0.w = (r0.w * material[9].x);
	r1.x = (material[8].w * 0.017453);
	r1.x = sin(r1.x);
	r2.x = cos(r1.x);
	r2.y = r1.x;
	r1.xy = (v1.xy + vec2(-0.5, -0.5));
	r1.z = dot(r1.xy, r2.xy);
	r1.z = (r1.z + 0.5);
	r0.w = (r1.z * material[9].x + r0.w);
	r2.xyzw = (material[4].xyzw * cb0_19.xxxx + v2.xyxy);
	r2.xyzw = (v1.xyxy * material[3].xyzw + r2.xyzw);
	r3.xyzw = texture(tex_Tex_Noise1, unity_uv(r2.xy)).xyzw;
	r2.xyzw = texture(tex_Tex_Noise2, unity_uv(r2.zw)).xyzw;
	r0.w = clamp((r3.x * r2.x + r0.w), 0.0, 1.0);
	r0.w = (r0.w + -1.0);
	r0.w = (material[8].z * r0.w + 1.0);
	r1.z = ((-v1.z) + material[5].x);
	r1.z = (material[5].y * r1.z + v1.z);
	r1.z = (r3.x * r2.x + (-r1.z));
	r1.w = (material[11].x * 0.017453);
	r2.x = sin(r1.w);
	r3.x = cos(r1.w);
	r4.x = (-r2.x);
	r4.y = r3.x;
	r4.z = r2.x;
	r2.x = dot(r1.xy, r4.yz);
	r2.y = dot(r1.xy, r4.xy);
	r1.xy = (r2.xy + vec2(0.5, 0.5));
	r1.xy = (r1.xy * material[9].zw);
	r2.xyzw = texture(tex_MainTex, unity_uv(r1.xy)).xyzw;
	r1.xyw = ((-r2.xyz) + r2.www);
	r1.xyw = (material[11].yyy * r1.xyw + r2.xyz);
	r1.xyz = clamp((r1.zzz * r1.xyw), 0.0, 1.0);
	r1.yzw = (r1.xyz * r0.www + vec3(-0.6, -0.6, -0.6));
	r0.w = (r1.x * r0.w + (-material[11].z));
	r1.xyz = clamp((r1.yzw * vec3(-9.999998, -9.999998, -9.999998)), 0.0, 1.0);
	r3.xyz = (r1.xyz * vec3(-2.0, -2.0, -2.0) + vec3(3.0, 3.0, 3.0));
	r1.xyz = (r1.xyz * r1.xyz);
	r4.xyz = (r1.xyz * r3.xyz);
	r1.xyz = ((-r3.xyz) * r1.xyz + vec3(1.0, 1.0, 1.0));
	r0.xyz = (r0.xyz * r4.xyz);
	r3.xyz = log2(abs(material[6].xyz));
	r3.xyz = (r3.xyz * vec3(0.416667, 0.416667, 0.416667));
	r3.xyz = exp2(r3.xyz);
	r3.xyz = (r3.xyz * vec3(1.055, 1.055, 1.055) + vec3(-0.055, -0.055, -0.055));
	r4.xyz = vec3(greaterThanEqual(vec3(0.003131, 0.003131, 0.003131), material[6].xyz));
	r5.xyz = (material[6].xyz * vec3(12.92321, 12.92321, 12.92321));
	r3.xyz = mix(r3.xyz, r5.xyz, notEqual(r4.xyz, vec3(0.0)));
	r4.xyz = (r2.xyz * r3.xyz);
	r0.xyz = (r4.xyz * r1.xyz + r0.xyz);
	r0.xyz = ((-r3.xyz) * r2.xyz + r0.xyz);
	o0.xyz = (material[8].xxx * r0.xyz + r4.xyz);
	r0.x = (material[0].x + (-material[11].z));
	r0.x = (1.0 / r0.x);
	r0.x = clamp((r0.x * r0.w), 0.0, 1.0);
	r0.y = (r0.x * -2.0 + 3.0);
	r0.x = (r0.x * r0.x);
	r0.x = (r0.x * r0.y);
	r0.y = ((-v3.w) + material[8].y);
	r0.y = (material[5].y * r0.y + v3.w);
	o0.w = (r0.y * r0.x);
	// ret
	COLOR = vec4(max(o0.rgb, vec3(0.0)), clamp(o0.a, 0.0, 1.0));
}
