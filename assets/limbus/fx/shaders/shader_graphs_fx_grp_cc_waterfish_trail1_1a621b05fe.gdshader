// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Shader Graphs/FX_Grp_CC_WaterFish_Trail1  []
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[6];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
uniform sampler2D tex_SampleTexture2D_8faaaf7bea204f8c9bd1407bdc218d93_Texture_1_Texture2D : hint_default_white, repeat_disable, filter_linear;

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
	vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0), r3 = vec4(0.0), r4 = vec4(0.0), r5 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	vec4 cb0_19 = vec4(TIME, sin(TIME), cos(TIME), 0.0);
	r0.xyz = vec3(greaterThanEqual(vec3(0.003131, 0.003131, 0.003131), material[2].xyz));
	r1.xyz = (material[2].xyz * vec3(12.92321, 12.92321, 12.92321));
	r2.xyz = log2(abs(material[2].xyz));
	r2.xyz = (r2.xyz * vec3(0.416667, 0.416667, 0.416667));
	r2.xyz = exp2(r2.xyz);
	r2.xyz = (r2.xyz * vec3(1.055, 1.055, 1.055) + vec3(-0.055, -0.055, -0.055));
	r0.xyz = mix(r2.xyz, r1.xyz, notEqual(r0.xyz, vec3(0.0)));
	r1.xy = (v1.xy * material[1].xy);
	r1.xyzw = texture(tex_SampleTexture2D_8faaaf7bea204f8c9bd1407bdc218d93_Texture_1_Texture2D, unity_uv(r1.xy)).xyzw;
	r1.yz = (cb0_19.xx * material[3].zw);
	r1.yz = (v1.xy * material[3].xy + r1.yz);
	r2.xyzw = (r1.yzyz * vec4(15.0, 15.0, 7.5, 7.5));
	r3.xyzw = floor(r2.xyzw);
	r2.xyzw = fract(r2.xyzw);
	r4.xyzw = (r2.xyzw * r2.xyzw);
	r2.xyzw = ((-r2.xyzw) * vec4(2.0, 2.0, 2.0, 2.0) + vec4(3.0, 3.0, 3.0, 3.0));
	r2.xyzw = (r2.xyzw * r4.xyzw);
	r4.xyzw = (r3.xyxy + vec4(1.0, 0.0, 0.0, 1.0));
	r5.xyzw = (r3.xyzw + vec4(1.0, 1.0, 1.0, 0.0));
	r0.w = dot(r3.xy, vec2(12.9898, 78.233002));
	r0.w = sin(r0.w);
	r0.w = (r0.w * 43758.546875);
	r0.w = fract(r0.w);
	r1.w = dot(r4.xy, vec2(12.9898, 78.233002));
	r1.w = sin(r1.w);
	r1.yzw = (r1.yzw * vec3(3.75, 3.75, 43758.546875));
	r1.w = fract(r1.w);
	r3.x = dot(r4.zw, vec2(12.9898, 78.233002));
	r3.x = sin(r3.x);
	r3.y = dot(r5.xy, vec2(12.9898, 78.233002));
	r3.y = sin(r3.y);
	r3.xy = (r3.xy * vec2(43758.546875, 43758.546875));
	r3.xy = fract(r3.xy);
	r1.w = ((-r0.w) + r1.w);
	r0.w = (r2.x * r1.w + r0.w);
	r1.w = ((-r3.x) + r3.y);
	r1.w = (r2.x * r1.w + r3.x);
	r1.w = ((-r0.w) + r1.w);
	r0.w = (r2.y * r1.w + r0.w);
	r4.xyzw = (r3.zwzw + vec4(0.0, 1.0, 1.0, 1.0));
	r1.w = dot(r3.zw, vec2(12.9898, 78.233002));
	r1.w = sin(r1.w);
	r1.w = (r1.w * 43758.546875);
	r1.w = fract(r1.w);
	r2.x = dot(r5.zw, vec2(12.9898, 78.233002));
	r2.x = sin(r2.x);
	r2.y = dot(r4.xy, vec2(12.9898, 78.233002));
	r2.y = sin(r2.y);
	r2.xy = (r2.xy * vec2(43758.546875, 43758.546875));
	r2.xy = fract(r2.xy);
	r3.x = dot(r4.zw, vec2(12.9898, 78.233002));
	r3.x = sin(r3.x);
	r3.x = (r3.x * 43758.546875);
	r3.x = fract(r3.x);
	r2.x = ((-r1.w) + r2.x);
	r1.w = (r2.z * r2.x + r1.w);
	r2.x = ((-r2.y) + r3.x);
	r2.x = (r2.z * r2.x + r2.y);
	r2.x = ((-r1.w) + r2.x);
	r1.w = (r2.w * r2.x + r1.w);
	r1.w = (r1.w * 0.25);
	r0.w = (r0.w * 0.125 + r1.w);
	r2.xy = floor(r1.yz);
	r1.yz = fract(r1.yz);
	r2.zw = (r1.yz * r1.yz);
	r1.yz = ((-r1.yz) * vec2(2.0, 2.0) + vec2(3.0, 3.0));
	r1.yz = (r1.yz * r2.zw);
	r3.xyzw = (r2.xyxy + vec4(1.0, 0.0, 0.0, 1.0));
	r2.zw = (r2.xy + vec2(1.0, 1.0));
	r1.w = dot(r2.xy, vec2(12.9898, 78.233002));
	r1.w = sin(r1.w);
	r1.w = (r1.w * 43758.546875);
	r1.w = fract(r1.w);
	r2.x = dot(r3.xy, vec2(12.9898, 78.233002));
	r2.x = sin(r2.x);
	r2.x = (r2.x * 43758.546875);
	r2.y = dot(r3.zw, vec2(12.9898, 78.233002));
	r2.y = sin(r2.y);
	r2.y = (r2.y * 43758.546875);
	r2.z = dot(r2.zw, vec2(12.9898, 78.233002));
	r2.z = sin(r2.z);
	r2.z = (r2.z * 43758.546875);
	r2.xyz = fract(r2.xyz);
	r2.x = ((-r1.w) + r2.x);
	r1.w = (r1.y * r2.x + r1.w);
	r2.x = ((-r2.y) + r2.z);
	r1.y = (r1.y * r2.x + r2.y);
	r1.y = ((-r1.w) + r1.y);
	r1.y = (r1.z * r1.y + r1.w);
	r0.w = (r1.y * 0.5 + r0.w);
	r1.yz = (cb0_19.xx * material[4].zw);
	r1.yz = (v1.xy * material[4].xy + r1.yz);
	r1.yz = (r1.yz * vec2(10.0, 10.0));
	r2.xy = floor(r1.yz);
	r1.yz = fract(r1.yz);
	r2.zw = vec2(0.0, 8.0);
	r1.w = -1.0;
	for (int loop_guard = 0; loop_guard < 1024; loop_guard++) {
		r3.x = float(1.0 < r1.w);
		if (r3.x != 0.0) break;
		r3.y = (r1.w);
		r3.zw = r2.zw;
		r4.x = -1.0;
		for (int loop_guard = 0; loop_guard < 1024; loop_guard++) {
			r4.y = float(1.0 < r4.x);
			if (r4.y != 0.0) break;
			r3.x = (r4.x);
			r4.yz = (r2.xy + r3.xy);
			r4.w = dot(r4.yz, vec2(15.27, 99.410004));
			r4.y = dot(r4.yz, vec2(47.630001, 89.980003));
			r5.xy = sin(r4.yw);
			r4.yz = fract(r5.xy);
			r4.yz = (r4.yz + r4.yz);
			r5.x = sin(r4.y);
			r5.y = cos(r4.z);
			r4.yz = (r5.xy * vec2(0.5, 0.5) + r3.xy);
			r4.yz = ((-r1.yz) + r4.yz);
			r4.yz = (r4.yz + vec2(0.5, 0.5));
			r3.x = dot(r4.yz, r4.yz);
			r3.x = sqrt(r3.x);
			r4.y = float(r3.x < r3.w);
			r3.zw = mix(r3.zw, r3.xx, notEqual(r4.yy, vec2(0.0)));
			r4.x = (r4.x + 1.0);
		}
		r2.zw = r3.zw;
		r1.w = (r1.w + 1.0);
	}
	r1.y = ((-r2.z) + 1.0);
	r0.w = (r0.w * r1.y + 0.1);
	r1.y = (v2.x + -0.5);
	r1.y = (r1.y * 2.0 + (-material[5].x));
	r1.y = (material[5].y * r1.y + material[5].x);
	r1.y = (r1.x * r0.w + (-r1.y));
	r1.yz = (r1.yy + vec2(-0.089998, -0.099855));
	r1.yz = clamp((r1.yz * vec2(101.447304, 4.289221)), 0.0, 1.0);
	r1.w = ((-r1.y) + 0.25);
	r1.y = clamp((r1.z * r1.w + r1.y), 0.0, 1.0);
	r1.z = (r1.x * r1.x + r1.y);
	r0.w = (r0.w * 0.285714 + r1.z);
	o0.xyz = (r0.www * r0.xyz);
	r0.x = (r1.y + r1.x);
	r0.x = clamp((r1.y * r0.x), 0.0, 1.0);
	r0.y = (v2.w + (-material[5].z));
	r0.y = (material[5].y * r0.y + material[5].z);
	o0.w = (r0.y * r0.x);
	// ret
	COLOR = vec4(tone_mapped(o0.rgb), clamp(o0.a, 0.0, 1.0));
}
