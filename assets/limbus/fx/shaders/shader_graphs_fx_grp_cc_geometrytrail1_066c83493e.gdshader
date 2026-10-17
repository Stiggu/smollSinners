// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Shader Graphs/FX_Grp_CC_GeometryTrail1  []
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[7];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
uniform sampler2D tex_SampleTexture2D_74d125b2ae39404b80b409bf551798ec_Texture_1_Texture2D : hint_default_white, repeat_enable, filter_linear;
uniform sampler2D tex_SampleTexture2D_c373feb3962b4e7888fad7c9aef90f4a_Texture_1_Texture2D : hint_default_white, repeat_disable, filter_linear;

varying vec4 io_interp0;
varying vec4 io_interp1;
varying vec4 io_interp2;

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
	vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0), r3 = vec4(0.0), r4 = vec4(0.0), r5 = vec4(0.0), r6 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	vec4 cb0_19 = vec4(TIME, sin(TIME), cos(TIME), 0.0);
	r0.xy = (v1.xy + v1.xy);
	r0.zw = floor(r0.xy);
	r1.xy = fract(r0.xy);
	r1.xy = (-r1.xy);
	r2.z = 0.5;
	r2.w = r1.y;
	r1.z = 0.5;
	r1.yw = vec2(0.0, 8.0);
	r3.x = -1.0;
	for (int loop_guard = 0; loop_guard < 1024; loop_guard++) {
		r3.y = float(1.0 < r3.x);
		if (r3.y != 0.0) break;
		r2.y = (r3.x);
		r3.yz = r1.yw;
		r3.w = -1.0;
		for (int loop_guard = 0; loop_guard < 1024; loop_guard++) {
			r4.x = float(1.0 < r3.w);
			if (r4.x != 0.0) break;
			r2.x = (r3.w);
			r4.xy = (r0.zw + r2.xy);
			r4.z = dot(r4.xy, vec2(15.27, 99.410004));
			r4.x = dot(r4.xy, vec2(47.630001, 89.980003));
			r5.xy = sin(r4.xz);
			r4.xy = fract(r5.xy);
			r4.xy = (r4.xy * vec2(5.0, 5.0));
			r5.x = sin(r4.x);
			r5.y = cos(r4.y);
			r4.xy = (r5.xy * vec2(0.5, 0.5) + r2.zy);
			r4.yw = (r2.xw + r4.xy);
			r4.yw = (r1.xz + r4.yw);
			r2.x = dot(r4.yw, r4.yw);
			r4.z = sqrt(r2.x);
			r2.x = float(r4.z < r3.z);
			r3.yz = mix(r3.yz, r4.xz, notEqual(r2.xx, vec2(0.0)));
			r3.w = (r3.w + 1.0);
		}
		r1.yw = r3.yz;
		r3.x = (r3.x + 1.0);
	}
	r0.zw = (cb0_19.xx * material[4].yz + v1.xy);
	r2.xyzw = (r0.zwzw * vec4(25.0, 25.0, 12.5, 12.5));
	r3.xyzw = floor(r2.xyzw);
	r2.xyzw = fract(r2.xyzw);
	r4.xyzw = (r2.xyzw * r2.xyzw);
	r2.xyzw = ((-r2.xyzw) * vec4(2.0, 2.0, 2.0, 2.0) + vec4(3.0, 3.0, 3.0, 3.0));
	r2.xyzw = (r2.xyzw * r4.xyzw);
	r4.xyzw = (r3.xyxy + vec4(1.0, 0.0, 0.0, 1.0));
	r5.xyzw = (r3.xyzw + vec4(1.0, 1.0, 1.0, 0.0));
	r1.x = dot(r3.xy, vec2(12.9898, 78.233002));
	r1.x = sin(r1.x);
	r1.x = (r1.x * 43758.546875);
	r1.z = dot(r4.xy, vec2(12.9898, 78.233002));
	r1.z = sin(r1.z);
	r1.z = (r1.z * 43758.546875);
	r1.w = dot(r4.zw, vec2(12.9898, 78.233002));
	r1.w = sin(r1.w);
	r1.w = (r1.w * 43758.546875);
	r1.xzw = fract(r1.xzw);
	r3.x = dot(r5.xy, vec2(12.9898, 78.233002));
	r3.x = sin(r3.x);
	r3.x = (r3.x * 43758.546875);
	r3.x = fract(r3.x);
	r1.z = ((-r1.x) + r1.z);
	r1.x = (r2.x * r1.z + r1.x);
	r1.z = ((-r1.w) + r3.x);
	r1.z = (r2.x * r1.z + r1.w);
	r1.z = ((-r1.x) + r1.z);
	r1.x = (r2.y * r1.z + r1.x);
	r4.xyzw = (r3.zwzw + vec4(0.0, 1.0, 1.0, 1.0));
	r1.z = dot(r3.zw, vec2(12.9898, 78.233002));
	r1.z = sin(r1.z);
	r1.z = (r1.z * 43758.546875);
	r1.w = dot(r5.zw, vec2(12.9898, 78.233002));
	r1.w = sin(r1.w);
	r1.w = (r1.w * 43758.546875);
	r1.zw = fract(r1.zw);
	r2.x = dot(r4.xy, vec2(12.9898, 78.233002));
	r2.x = sin(r2.x);
	r2.x = (r2.x * 43758.546875);
	r2.y = dot(r4.zw, vec2(12.9898, 78.233002));
	r2.y = sin(r2.y);
	r2.y = (r2.y * 43758.546875);
	r2.xy = fract(r2.xy);
	r1.w = ((-r1.z) + r1.w);
	r1.z = (r2.z * r1.w + r1.z);
	r1.w = ((-r2.x) + r2.y);
	r1.w = (r2.z * r1.w + r2.x);
	r1.w = ((-r1.z) + r1.w);
	r1.z = (r2.w * r1.w + r1.z);
	r1.z = (r1.z * 0.25);
	r1.x = (r1.x * 0.125 + r1.z);
	r0.zw = (r0.zw * vec2(6.25, 6.25));
	r1.zw = floor(r0.zw);
	r0.zw = fract(r0.zw);
	r2.xy = (r0.zw * r0.zw);
	r0.zw = ((-r0.zw) * vec2(2.0, 2.0) + vec2(3.0, 3.0));
	r0.zw = (r0.zw * r2.xy);
	r2.xyzw = (r1.zwzw + vec4(1.0, 0.0, 0.0, 1.0));
	r3.xy = (r1.zw + vec2(1.0, 1.0));
	r1.z = dot(r1.zw, vec2(12.9898, 78.233002));
	r1.z = sin(r1.z);
	r1.z = (r1.z * 43758.546875);
	r1.w = dot(r2.xy, vec2(12.9898, 78.233002));
	r1.w = sin(r1.w);
	r1.w = (r1.w * 43758.546875);
	r1.zw = fract(r1.zw);
	r2.x = dot(r2.zw, vec2(12.9898, 78.233002));
	r2.x = sin(r2.x);
	r2.x = (r2.x * 43758.546875);
	r2.y = dot(r3.xy, vec2(12.9898, 78.233002));
	r2.y = sin(r2.y);
	r2.y = (r2.y * 43758.546875);
	r2.xy = fract(r2.xy);
	r1.w = ((-r1.z) + r1.w);
	r1.z = (r0.z * r1.w + r1.z);
	r1.w = ((-r2.x) + r2.y);
	r0.z = (r0.z * r1.w + r2.x);
	r0.z = ((-r1.z) + r0.z);
	r0.z = (r0.w * r0.z + r1.z);
	r0.z = (r0.z * 0.5 + r1.x);
	r0.z = (r0.z + r1.y);
	r0.z = (r0.z * 0.5);
	r1.xyzw = texture(tex_SampleTexture2D_74d125b2ae39404b80b409bf551798ec_Texture_1_Texture2D, unity_uv(r0.zz)).xyzw;
	r2.xyz = vec3(greaterThanEqual(vec3(0.003131, 0.003131, 0.003131), material[3].xyz));
	r3.xyz = (material[3].xyz * vec3(12.92321, 12.92321, 12.92321));
	r4.xyz = log2(abs(material[3].xyz));
	r4.xyz = (r4.xyz * vec3(0.416667, 0.416667, 0.416667));
	r4.xyz = exp2(r4.xyz);
	r4.xyz = (r4.xyz * vec3(1.055, 1.055, 1.055) + vec3(-0.055, -0.055, -0.055));
	r2.xyz = mix(r4.xyz, r3.xyz, notEqual(r2.xyz, vec3(0.0)));
	r0.xy = (cb0_19.xx * material[4].yz + r0.xy);
	r0.xy = (r0.xy * vec2(5.0, 5.0));
	r0.zw = floor(r0.xy);
	r0.xy = fract(r0.xy);
	r3.xy = (-r0.xy);
	r4.z = 0.5;
	r4.w = r3.y;
	r3.z = 0.5;
	r0.xy = vec2(0.0, 8.0);
	r1.w = -1.0;
	for (int loop_guard = 0; loop_guard < 1024; loop_guard++) {
		r2.w = float(1.0 < r1.w);
		if (r2.w != 0.0) break;
		r4.y = (r1.w);
		r3.yw = r0.xy;
		r2.w = -1.0;
		for (int loop_guard = 0; loop_guard < 1024; loop_guard++) {
			r5.x = float(1.0 < r2.w);
			if (r5.x != 0.0) break;
			r4.x = (r2.w);
			r5.xy = (r0.zw + r4.xy);
			r5.z = dot(r5.xy, vec2(15.27, 99.410004));
			r5.x = dot(r5.xy, vec2(47.630001, 89.980003));
			r6.xy = sin(r5.xz);
			r5.xy = fract(r6.xy);
			r5.xy = (r5.xy + r5.xy);
			r6.x = sin(r5.x);
			r6.y = cos(r5.y);
			r5.xy = (r6.xy * vec2(0.5, 0.5) + r4.zy);
			r5.yw = (r4.xw + r5.xy);
			r5.yw = (r3.xz + r5.yw);
			r4.x = dot(r5.yw, r5.yw);
			r5.z = sqrt(r4.x);
			r4.x = float(r5.z < r3.w);
			r3.yw = mix(r3.yw, r5.xz, notEqual(r4.xx, vec2(0.0)));
			r2.w = (r2.w + 1.0);
		}
		r0.xy = r3.yw;
		r1.w = (r1.w + 1.0);
	}
	r0.yzw = (r0.xxx * r1.xyz);
	r1.xy = (v1.xy * material[2].xy);
	r1.xyzw = texture(tex_SampleTexture2D_c373feb3962b4e7888fad7c9aef90f4a_Texture_1_Texture2D, unity_uv(r1.xy)).xyzw;
	r0.x = (r0.x * r1.x);
	r1.xy = (v1.xy * material[6].xy);
	r1.xy = (r1.xy * vec2(5.0, 5.0));
	r1.zw = floor(r1.xy);
	r1.xy = fract(r1.xy);
	r3.xy = (-r1.xy);
	r4.z = 0.5;
	r4.w = r3.y;
	r3.z = 0.5;
	r1.xy = vec2(0.0, 8.0);
	r2.w = -1.0;
	for (int loop_guard = 0; loop_guard < 1024; loop_guard++) {
		r3.y = float(1.0 < r2.w);
		if (r3.y != 0.0) break;
		r4.y = (r2.w);
		r3.yw = r1.xy;
		r5.x = -1.0;
		for (int loop_guard = 0; loop_guard < 1024; loop_guard++) {
			r5.y = float(1.0 < r5.x);
			if (r5.y != 0.0) break;
			r4.x = (r5.x);
			r5.yz = (r1.zw + r4.xy);
			r5.w = dot(r5.yz, vec2(15.27, 99.410004));
			r5.y = dot(r5.yz, vec2(47.630001, 89.980003));
			r6.xy = sin(r5.yw);
			r5.yz = fract(r6.xy);
			r5.yz = (r5.yz + r5.yz);
			r6.x = sin(r5.y);
			r6.y = cos(r5.z);
			r6.xy = (r6.xy * vec2(0.5, 0.5) + r4.zy);
			r5.yz = (r4.xw + r6.xy);
			r5.yz = (r3.xz + r5.yz);
			r4.x = dot(r5.yz, r5.yz);
			r6.z = sqrt(r4.x);
			r4.x = float(r6.z < r3.w);
			r3.yw = mix(r3.yw, r6.xz, notEqual(r4.xx, vec2(0.0)));
			r5.x = (r5.x + 1.0);
		}
		r1.xy = r3.yw;
		r2.w = (r2.w + 1.0);
	}
	r1.x = (r1.x + (-material[4].x));
	r1.xyz = (r0.xxx * r1.xxx + vec3(-0.2, -0.2, -0.500008));
	r1.xyz = clamp((r1.xyz * vec3(1000000000000000019884624838656.0, 3.333248, 2.000031)), 0.0, 1.0);
	r0.x = (r1.x * -2.0 + 3.0);
	r1.x = (r1.x * r1.x);
	r0.x = (r0.x * r1.x);
	r0.xyz = (r0.xxx * r0.yzw);
	o0.xyz = (r0.xyz * r2.xyz);
	r0.xy = vec2(greaterThanEqual(r1.yz, vec2(0.01, 0.01)));
	r0.yz = mix(vec2(0.0), vec2(0.5, 1.0), notEqual(r0.xy, vec2(0.0)));
	r0.x = ((r0.x != 0.0) ? 0.5 : 1.0);
	o0.w = (r0.z * r0.x + r0.y);
	// ret
	COLOR = vec4(tone_mapped(o0.rgb), clamp(o0.a, 0.0, 1.0));
}
