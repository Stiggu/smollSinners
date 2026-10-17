// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Shader Graphs/FX_Grp_WaterBubble1  []
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[3];  // UnityPerMaterial
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
	vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0), r3 = vec4(0.0), r4 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	vec4 cb0_19 = vec4(TIME, sin(TIME), cos(TIME), 0.0);
	r0.xyz = vec3(greaterThanEqual(vec3(0.003131, 0.003131, 0.003131), material[0].xyz));
	r1.xyz = (material[0].xyz * vec3(12.92321, 12.92321, 12.92321));
	r2.xyz = log2(abs(material[0].xyz));
	r2.xyz = (r2.xyz * vec3(0.416667, 0.416667, 0.416667));
	r2.xyz = exp2(r2.xyz);
	r2.xyz = (r2.xyz * vec3(1.055, 1.055, 1.055) + vec3(-0.055, -0.055, -0.055));
	o0.xyz = mix(r2.xyz, r1.xyz, notEqual(r0.xyz, vec3(0.0)));
	r0.xy = (v1.xy + vec2(-0.5, -0.5));
	r0.x = dot(r0.xy, r0.xy);
	r0.x = sqrt(r0.x);
	r0.y = (r0.x + r0.x);
	r0.y = (r0.y * r0.y);
	r0.y = (r0.y * r0.y + 0.2);
	r0.zw = (cb0_19.xx * material[1].xy);
	r0.zw = (v1.xy * material[1].zw + r0.zw);
	r0.zw = (r0.zw * vec2(5.0, 5.0));
	r1.xy = floor(r0.zw);
	r0.zw = fract(r0.zw);
	r1.zw = vec2(0.0, 8.0);
	r2.x = -1.0;
	for (int loop_guard = 0; loop_guard < 1024; loop_guard++) {
		r2.y = float(1.0 < r2.x);
		if (r2.y != 0.0) break;
		r3.y = (r2.x);
		r2.yz = r1.zw;
		r2.w = -1.0;
		for (int loop_guard = 0; loop_guard < 1024; loop_guard++) {
			r3.z = float(1.0 < r2.w);
			if (r3.z != 0.0) break;
			r3.x = (r2.w);
			r3.zw = (r1.xy + r3.xy);
			r4.x = dot(r3.zw, vec2(15.27, 99.410004));
			r3.z = dot(r3.zw, vec2(47.630001, 89.980003));
			r4.y = sin(r4.x);
			r4.x = sin(r3.z);
			r3.zw = fract(r4.xy);
			r3.zw = (r3.zw + r3.zw);
			r4.x = sin(r3.z);
			r4.y = cos(r3.w);
			r3.xz = (r4.xy * vec2(0.5, 0.5) + r3.xy);
			r3.xz = ((-r0.zw) + r3.xz);
			r3.xz = (r3.xz + vec2(0.5, 0.5));
			r3.x = dot(r3.xz, r3.xz);
			r3.x = sqrt(r3.x);
			r3.z = float(r3.x < r2.z);
			r2.yz = mix(r2.yz, r3.xx, notEqual(r3.zz, vec2(0.0)));
			r2.w = (r2.w + 1.0);
		}
		r1.zw = r2.yz;
		r2.x = (r2.x + 1.0);
	}
	r0.z = (r0.y + r1.z);
	r0.y = (r0.z * r0.y);
	r0.x = ((-r0.x) * 2.0 + 1.0);
	r0.x = clamp((r0.x * 1.999969), 0.0, 1.0);
	r0.z = ((-r1.z) + r0.x);
	r0.z = (r0.z + 1.0);
	r0.x = (r0.x * r0.z + -0.250004);
	r0.x = clamp((r0.x * 3.999939), 0.0, 1.0);
	r0.x = float(r0.x >= 0.01);
	r0.x = r0.x;
	r0.z = (r0.x * r0.y);
	r0.w = (v2.x + -0.5);
	r0.w = (r0.w * 2.0 + (-material[2].x));
	r0.w = (material[2].z * r0.w + material[2].x);
	r0.x = (r0.y * r0.x + (-r0.w));
	r0.x = clamp((r0.x * r0.z), 0.0, 1.0);
	r0.y = (v2.w + (-material[2].y));
	r0.y = (material[2].z * r0.y + material[2].y);
	o0.w = (r0.y * r0.x);
	// ret
	COLOR = vec4(tone_mapped(o0.rgb), clamp(o0.a, 0.0, 1.0));
}
