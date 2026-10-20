// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Universal Render Pipeline/Particles/Unlit  [_SURFACE_TYPE_TRANSPARENT]
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[8];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
uniform sampler2D tex_BaseMap : hint_default_white, repeat_enable, filter_linear;

varying vec4 io_texcoord0;
varying vec4 io_color0;
varying vec4 io_texcoord1;
varying vec4 io_texcoord2;
varying vec4 io_texcoord3;
varying vec4 io_texcoord8;

const float PX_PER_UNIT = 60.0;
const int VERTICES_PER_ROW = 256;

// Unity samples with v up, Godot with v down.
vec2 unity_uv(vec2 uv) { return vec2(uv.x, 1.0 - uv.y); }

vec4 vertex_input(int vertex, int slot) {
	return texelFetch(vertex_data, ivec2((vertex % VERTICES_PER_ROW) * vertex_data_slots + slot, vertex / VERTICES_PER_ROW), 0);
}

void vertex() {
	vec4 v0 = vec4(VERTEX.x / PX_PER_UNIT, -VERTEX.y / PX_PER_UNIT, 0.0, 1.0);
	vec4 v1 = COLOR;
	vec4 v2 = vertex_input(VERTEX_ID, 0);
	vec4 v3 = (normal_slot < 0 ? vec4(0.0, 0.0, -1.0, 0.0) : vertex_input(VERTEX_ID, normal_slot));
	vec4 v4 = vec4(1.0, 0.0, 0.0, 1.0);
	vec4 r0 = vec4(0.0), r1 = vec4(0.0);
	vec4 o0 = vec4(0.0), o1 = vec4(0.0), o2 = vec4(0.0), o3 = vec4(0.0), o4 = vec4(0.0), o5 = vec4(0.0), o6 = vec4(0.0);
	vec4 cb0_21 = vec4(vec4(0.0, 0.0, -10.0, 0.0).x, vec4(0.0, 0.0, -10.0, 0.0).y, vec4(0.0, 0.0, -10.0, 0.0).z, 0.0);
	vec4 cb0_25 = vec4(5.0, 5.0, 0.0, 0.0);
	vec4 cb0_67 = vec4(1.0, 0.0, 0.0, 0.0);
	vec4 cb0_68 = vec4(0.0, 1.0, 0.0, 0.0);
	vec4 cb0_69 = vec4(0.0, 0.0, 1.0, 0.0);
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
	o0.xyzw = (r1.xyzw + cb0_82.xyzw);
	o1.xy = v2.xy;
	o2.xyzw = v1.xyzw;
	o3.xyz = r0.xyz;
	r0.xyz = ((-r0.xyz) + cb0_21.xyz);
	o3.w = 0.0;
	r1.x = dot(v3.xyz, cb1_4.xyz);
	r1.y = dot(v3.xyz, cb1_5.xyz);
	r1.z = dot(v3.xyz, cb1_6.xyz);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = max(r0.w, 0.0);
	r0.w = inversesqrt(r0.w);
	o4.xyz = (r0.www * r1.xyz);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = inversesqrt(r0.w);
	r0.xyz = (r0.www * r0.xyz);
	r0.w = float(cb0_25.w == 0.0);
	o5.x = ((r0.w != 0.0) ? r0.x : cb0_67.z);
	o5.y = ((r0.w != 0.0) ? r0.y : cb0_68.z);
	o5.z = ((r0.w != 0.0) ? r0.z : cb0_69.z);
	o6.xyz = vec3(0.0, 0.0, 0.0);
	// ret
	io_texcoord0 = o1;
	io_color0 = o2;
	io_texcoord1 = o3;
	io_texcoord2 = o4;
	io_texcoord3 = o5;
	io_texcoord8 = o6;
}

void fragment() {
	vec4 v0 = vec4(FRAGCOORD.xy, 0.5, 1.0);
	vec4 v1 = io_texcoord0;
	vec4 v2 = io_color0;
	vec4 v3 = io_texcoord1;
	vec4 v4 = io_texcoord2;
	vec4 v5 = io_texcoord3;
	vec4 v6 = io_texcoord8;
	vec4 r0 = vec4(0.0), r1 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	r0.xyzw = texture(tex_BaseMap, unity_uv(v1.xy)).xyzw;
	r0.xyzw = (r0.xyzw * material[4].xyzw);
	r0.xyzw = (r0.xyzw * v2.xyzw);
	r1.x = float(material[7].w == 1.0);
	o0.w = ((r1.x != 0.0) ? r0.w : 1.0);
	o0.xyz = r0.xyz;
	// ret
	COLOR = vec4(max(o0.rgb, vec3(0.0)), clamp(o0.a, 0.0, 1.0));
}
