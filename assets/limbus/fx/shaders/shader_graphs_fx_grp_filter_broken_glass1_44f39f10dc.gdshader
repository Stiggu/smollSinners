// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Shader Graphs/FX_Grp_Filter_Broken_Glass1  []
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[2];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera

varying vec4 io_interp0;
varying vec4 io_interp1;
varying vec4 io_interp2;

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
	vec4 r0 = vec4(0.0), r1 = vec4(0.0);
	vec4 o0 = vec4(0.0), o1 = vec4(0.0), o2 = vec4(0.0), o3 = vec4(0.0);
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
	o2.xyz = r0.xyz;
	o0.xyzw = (r1.xyzw + cb0_82.xyzw);
	o1.xyzw = v3.xyzw;
	r0.x = dot(v1.xyz, cb1_4.xyz);
	r0.y = dot(v1.xyz, cb1_5.xyz);
	r0.z = dot(v1.xyz, cb1_6.xyz);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = max(r0.w, 0.0);
	r0.w = inversesqrt(r0.w);
	o3.xyz = (r0.www * r0.xyz);
	// ret
	io_interp0 = o1;
	io_interp1 = o2;
	io_interp2 = o3;
}

void fragment() {
	vec4 v0 = vec4(FRAGCOORD.xy, 0.5, 1.0);
	vec4 v1 = io_interp0;
	vec4 v2 = io_interp1;
	vec4 v3 = io_interp2;
	vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0), r3 = vec4(0.0), r4 = vec4(0.0), r5 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	r0.xy = (v1.xy + vec2(-0.5, -0.5));
	r0.z = dot(r0.xy, r0.xy);
	r0.z = sqrt(r0.z);
	r0.z = (r0.z + r0.z);
	r0.w = min(abs(r0.y), abs(r0.x));
	r1.x = max(abs(r0.y), abs(r0.x));
	r1.x = (1.0 / r1.x);
	r0.w = (r0.w * r1.x);
	r1.x = (r0.w * r0.w);
	r1.y = (r1.x * 0.020835 + -0.085133);
	r1.y = (r1.x * r1.y + 0.180141);
	r1.y = (r1.x * r1.y + -0.330299);
	r1.x = (r1.x * r1.y + 0.999866);
	r1.y = (r0.w * r1.x);
	r1.z = float(abs(r0.y) < abs(r0.x));
	r1.y = (r1.y * -2.0 + 1.570796);
	r1.y = ((r1.z) != 0.0 ? (r1.y) : 0.0);
	r0.w = (r0.w * r1.x + r1.y);
	r1.x = float(r0.y < (-r0.y));
	r1.x = ((r1.x) != 0.0 ? (-3.141592741013) : 0.0);
	r0.w = (r0.w + r1.x);
	r1.x = min(r0.y, r0.x);
	r0.x = max(r0.y, r0.x);
	r0.y = float(r1.x < (-r1.x));
	r0.x = float(r0.x >= (-r0.x));
	r0.x = ((r0.x) != 0.0 ? (r0.y) : 0.0);
	r0.x = ((r0.x != 0.0) ? (-r0.w) : r0.w);
	r1.xyz = (r0.zzx * material[0].xwy);
	r0.xy = (r1.xz * vec2(5.0, 7.961783));
	r0.zw = floor(r0.xy);
	r0.xy = fract(r0.xy);
	r2.xy = (-r0.xy);
	r3.z = 0.5;
	r3.w = r2.y;
	r2.z = 0.5;
	r0.xy = vec2(0.0, 8.0);
	r1.x = -1.0;
	for (int loop_guard = 0; loop_guard < 1024; loop_guard++) {
		r1.z = float(1.0 < r1.x);
		if (r1.z != 0.0) break;
		r3.y = (r1.x);
		r1.zw = r0.xy;
		r2.y = -1.0;
		for (int loop_guard = 0; loop_guard < 1024; loop_guard++) {
			r2.w = float(1.0 < r2.y);
			if (r2.w != 0.0) break;
			r3.x = (r2.y);
			r4.xy = (r0.zw + r3.xy);
			r2.w = dot(r4.xy, vec2(15.27, 99.410004));
			r4.x = dot(r4.xy, vec2(47.630001, 89.980003));
			r5.y = sin(r2.w);
			r5.x = sin(r4.x);
			r4.xy = fract(r5.xy);
			r4.xy = (r4.xy + r4.xy);
			r5.x = sin(r4.x);
			r5.y = cos(r4.y);
			r4.xy = (r5.xy * vec2(0.5, 0.5) + r3.zy);
			r4.yw = (r3.xw + r4.xy);
			r4.yw = (r2.xz + r4.yw);
			r2.w = dot(r4.yw, r4.yw);
			r4.z = sqrt(r2.w);
			r2.w = float(r4.z < r1.w);
			r1.zw = mix(r1.zw, r4.xz, notEqual(r2.ww, vec2(0.0)));
			r2.y = (r2.y + 1.0);
		}
		r0.xy = r1.zw;
		r1.x = (r1.x + 1.0);
	}
	r0.x = (abs(r1.y) + r0.x);
	r0.y = ((-abs(r1.y)) + 1.0);
	r0.y = max(r0.y, 0.0);
	r0.z = (r0.y * r0.y);
	r0.z = (r0.z * r0.z);
	r0.y = (r0.z * r0.y);
	r0.x = clamp((r0.x * r0.y + (-material[0].w)), 0.0, 1.0);
	r0.xyz = (r0.xxx + vec3(-0.700008, -0.8, -0.900008));
	r0.xyz = (r0.xyz * vec3(10.000761, 9.999241, 10.000761));
	r0.xy = clamp(r0.xy, 0.0, 1.0);
	r0.xy = vec2(greaterThanEqual(r0.xy, vec2(0.01, 0.01)));
	r0.yw = mix(vec2(0.0), vec2(0.330000013113, 1.0), notEqual(r0.xy, vec2(0.0)));
	r0.x = ((r0.x != 0.0) ? 0.33 : 0.66);
	r0.x = (r0.w * r0.x + r0.y);
	r0.y = max(r0.z, 0.0);
	r0.y = float(r0.y >= 0.01);
	r0.y = r0.y;
	r0.z = ((-r0.x) + 1.0);
	r0.x = (r0.y * r0.z + r0.x);
	o0.w = (r0.x * material[1].x);
	o0.xyz = vec3(0.0, 0.0, 0.0);
	// ret
	COLOR = vec4(max(o0.rgb, vec3(0.0)), clamp(o0.a, 0.0, 1.0));
}
