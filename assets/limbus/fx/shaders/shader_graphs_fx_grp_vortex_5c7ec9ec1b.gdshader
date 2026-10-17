// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Shader Graphs/FX_Grp_Vortex  []
shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

uniform vec4 material[4];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
uniform sampler2D global_CameraOpaqueTexture : hint_screen_texture, filter_linear;

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
	vec4 screen_texel = vec4(0.0);
	float screen_alpha = 0.0;
	vec4 v0 = vec4(FRAGCOORD.xy, 0.5, 1.0);
	vec4 v1 = io_interp0;
	vec4 v2 = io_interp1;
	vec4 v3 = io_interp2;
	vec4 v4 = io_interp3;
	vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0), r3 = vec4(0.0), r4 = vec4(0.0), r5 = vec4(0.0), r6 = vec4(0.0), r7 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	vec4 cb0_3 = vec4(1.0 / SCREEN_PIXEL_SIZE, 1.0 + SCREEN_PIXEL_SIZE);
	vec4 cb0_19 = vec4(TIME, sin(TIME), cos(TIME), 0.0);
	vec4 cb0_22 = vec4(1.0, 0.3, 1000.0, 0.001);
	vec4 cb0_28 = vec4(1.0);
	vec4 cb0_131 = vec4(SCREEN_PIXEL_SIZE, 1.0 / SCREEN_PIXEL_SIZE);
	r0.x = float(cb0_22.x < 0.0);
	r0.y = ((-v0.y) + cb0_3.y);
	r0.y = ((r0.x != 0.0) ? r0.y : v0.y);
	r0.x = v0.x;
	r0.xy = (r0.xy / cb0_3.xy);
	r1.xyz = vec3(greaterThanEqual(vec3(0.003131, 0.003131, 0.003131), material[0].xyz));
	r2.xyz = (material[0].xyz * vec3(12.92321, 12.92321, 12.92321));
	r3.xyz = log2(abs(material[0].xyz));
	r3.xyz = (r3.xyz * vec3(0.416667, 0.416667, 0.416667));
	r3.xyz = exp2(r3.xyz);
	r3.xyz = (r3.xyz * vec3(1.055, 1.055, 1.055) + vec3(-0.055, -0.055, -0.055));
	r1.xyz = mix(r3.xyz, r2.xyz, notEqual(r1.xyz, vec3(0.0)));
	r2.xy = (v1.yx + vec2(-0.5, -0.5));
	r0.w = dot(r2.xy, r2.xy);
	r0.w = sqrt(r0.w);
	r1.w = (r0.w + r0.w);
	r1.w = min(r1.w, 1.0);
	r2.z = (r0.w * 10.0);
	r3.x = sin(r2.z);
	r4.x = cos(r2.z);
	r2.zw = (r2.xy * r3.xx);
	r2.y = (r4.x * r2.y + (-r2.z));
	r2.x = (r4.x * r2.x + r2.w);
	r3.xy = (r2.yx + vec2(0.5, 0.5));
	r2.xy = (cb0_19.xx * material[2].zw);
	r2.xy = (r3.xy * material[2].xy + r2.xy);
	r4.xyzw = (r2.xyxy * vec4(25.0, 25.0, 12.5, 12.5));
	r5.xyzw = floor(r4.xyzw);
	r4.xyzw = fract(r4.xyzw);
	r6.xyzw = (r4.xyzw * r4.xyzw);
	r4.xyzw = ((-r4.xyzw) * vec4(2.0, 2.0, 2.0, 2.0) + vec4(3.0, 3.0, 3.0, 3.0));
	r4.xyzw = (r4.xyzw * r6.xyzw);
	r6.xyzw = (r5.xyxy + vec4(1.0, 0.0, 0.0, 1.0));
	r7.xyzw = (r5.xyzw + vec4(1.0, 1.0, 1.0, 0.0));
	r2.z = dot(r5.xy, vec2(12.9898, 78.233002));
	r2.z = sin(r2.z);
	r2.w = dot(r6.xy, vec2(12.9898, 78.233002));
	r2.w = sin(r2.w);
	r2.xyzw = (r2.xyzw * vec4(6.25, 6.25, 43758.546875, 43758.546875));
	r2.zw = fract(r2.zw);
	r3.z = dot(r6.zw, vec2(12.9898, 78.233002));
	r3.z = sin(r3.z);
	r3.w = dot(r7.xy, vec2(12.9898, 78.233002));
	r3.w = sin(r3.w);
	r3.zw = (r3.zw * vec2(43758.546875, 43758.546875));
	r3.zw = fract(r3.zw);
	r2.w = ((-r2.z) + r2.w);
	r2.z = (r4.x * r2.w + r2.z);
	r2.w = ((-r3.z) + r3.w);
	r2.w = (r4.x * r2.w + r3.z);
	r2.w = ((-r2.z) + r2.w);
	r2.z = (r4.y * r2.w + r2.z);
	r6.xyzw = (r5.zwzw + vec4(0.0, 1.0, 1.0, 1.0));
	r2.w = dot(r5.zw, vec2(12.9898, 78.233002));
	r2.w = sin(r2.w);
	r2.w = (r2.w * 43758.546875);
	r2.w = fract(r2.w);
	r3.z = dot(r7.zw, vec2(12.9898, 78.233002));
	r3.z = sin(r3.z);
	r3.w = dot(r6.xy, vec2(12.9898, 78.233002));
	r3.w = sin(r3.w);
	r3.zw = (r3.zw * vec2(43758.546875, 43758.546875));
	r3.zw = fract(r3.zw);
	r4.x = dot(r6.zw, vec2(12.9898, 78.233002));
	r4.x = sin(r4.x);
	r4.x = (r4.x * 43758.546875);
	r4.x = fract(r4.x);
	r3.z = ((-r2.w) + r3.z);
	r2.w = (r4.z * r3.z + r2.w);
	r3.z = ((-r3.w) + r4.x);
	r3.z = (r4.z * r3.z + r3.w);
	r3.z = ((-r2.w) + r3.z);
	r2.w = (r4.w * r3.z + r2.w);
	r2.w = (r2.w * 0.25);
	r2.z = (r2.z * 0.125 + r2.w);
	r3.zw = floor(r2.xy);
	r2.xy = fract(r2.xy);
	r4.xy = (r2.xy * r2.xy);
	r2.xy = ((-r2.xy) * vec2(2.0, 2.0) + vec2(3.0, 3.0));
	r2.xy = (r2.xy * r4.xy);
	r4.xyzw = (r3.zwzw + vec4(1.0, 0.0, 0.0, 1.0));
	r5.xy = (r3.zw + vec2(1.0, 1.0));
	r2.w = dot(r3.zw, vec2(12.9898, 78.233002));
	r2.w = sin(r2.w);
	r2.w = (r2.w * 43758.546875);
	r2.w = fract(r2.w);
	r3.z = dot(r4.xy, vec2(12.9898, 78.233002));
	r3.z = sin(r3.z);
	r3.z = (r3.z * 43758.546875);
	r3.w = dot(r4.zw, vec2(12.9898, 78.233002));
	r3.w = sin(r3.w);
	r3.w = (r3.w * 43758.546875);
	r3.zw = fract(r3.zw);
	r4.x = dot(r5.xy, vec2(12.9898, 78.233002));
	r4.x = sin(r4.x);
	r4.x = (r4.x * 43758.546875);
	r4.x = fract(r4.x);
	r3.z = ((-r2.w) + r3.z);
	r2.w = (r2.x * r3.z + r2.w);
	r3.z = ((-r3.w) + r4.x);
	r2.x = (r2.x * r3.z + r3.w);
	r2.x = ((-r2.w) + r2.x);
	r2.x = (r2.y * r2.x + r2.w);
	r2.x = (r2.x * 0.5 + r2.z);
	r2.yz = (cb0_19.xx * material[1].zw);
	r2.yz = (r3.xy * material[1].xy + r2.yz);
	r2.yz = (r2.yz * vec2(5.0, 5.0));
	r3.xy = floor(r2.yz);
	r2.yz = fract(r2.yz);
	r3.zw = vec2(0.0, 8.0);
	r2.w = -1.0;
	for (int loop_guard = 0; loop_guard < 1024; loop_guard++) {
		r4.x = float(1.0 < r2.w);
		if (r4.x != 0.0) break;
		r4.y = (r2.w);
		r4.zw = r3.zw;
		r5.x = -1.0;
		for (int loop_guard = 0; loop_guard < 1024; loop_guard++) {
			r5.y = float(1.0 < r5.x);
			if (r5.y != 0.0) break;
			r4.x = (r5.x);
			r5.yz = (r3.xy + r4.xy);
			r5.w = dot(r5.yz, vec2(15.27, 99.410004));
			r5.y = dot(r5.yz, vec2(47.630001, 89.980003));
			r6.xy = sin(r5.yw);
			r5.yz = fract(r6.xy);
			r5.yz = (r5.yz + r5.yz);
			r6.x = sin(r5.y);
			r6.y = cos(r5.z);
			r5.yz = (r6.xy * vec2(0.5, 0.5) + r4.xy);
			r5.yz = ((-r2.yz) + r5.yz);
			r5.yz = (r5.yz + vec2(0.5, 0.5));
			r4.x = dot(r5.yz, r5.yz);
			r4.x = sqrt(r4.x);
			r5.y = float(r4.x < r4.w);
			r4.zw = mix(r4.zw, r4.xx, notEqual(r5.yy, vec2(0.0)));
			r5.x = (r5.x + 1.0);
		}
		r3.zw = r4.zw;
		r2.w = (r2.w + 1.0);
	}
	r2.x = (r2.x * r3.z);
	r0.w = ((-r0.w) * 2.0 + 1.0);
	r0.w = max(r0.w, 0.0);
	r0.w = (r0.w * r2.x);
	r2.x = (v2.x + -0.5);
	r2.x = (r2.x * 2.0 + (-material[3].x));
	r2.x = (material[3].z * r2.x + material[3].x);
	r2.x = ((-r2.x) + r3.z);
	r0.w = clamp((r0.w * r2.x), 0.0, 1.0);
	r2.x = (r1.w * r0.w + -0.080003);
	r2.x = clamp((r2.x * 3.952655), 0.0, 1.0);
	r2.x = float(r2.x >= 0.01);
	r2.x = r2.x;
	r1.xyz = (r1.xyz * r2.xxx);
	r0.w = (r0.w * 3.003025);
	r0.w = min(r0.w, 1.0);
	r1.w = (r0.w * r1.w);
	r0.z = ((-r0.y) + 1.0);
	r0.xy = (material[3].yy * r1.ww + r0.xz);
	r2.xy = ((-cb0_131.xy) * vec2(0.5, 0.5) + vec2(1.0, 1.0));
	r0.xy = min(r0.xy, r2.xy);
	r0.xy = (r0.xy * cb0_28.xy);
	screen_texel = texture(global_CameraOpaqueTexture, unity_uv(r0.xy));
	screen_alpha = max(screen_alpha, screen_texel.a);
	r2.xyzw = screen_texel.xyzw;
	o0.xyz = (r1.xyz * r2.xyz);
	r0.x = (v2.w + (-material[3].w));
	r0.x = (material[3].z * r0.x + material[3].w);
	o0.w = (r0.x * r0.w);
	// ret
	COLOR = vec4(clamp(o0.rgb, vec3(0.0), vec3(1.0)), screen_alpha);
}
