// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Shader Graphs/FX_Grp_Water1  []
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[8];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
uniform sampler2D tex_SampleTexture2D_6bbf23ae47ab4a84be8e4df80eed1b50_Texture_1_Texture2D : hint_default_white, repeat_enable, filter_linear;
uniform sampler2D tex_SampleTexture2D_af1d31ba580448ffb9ffe6b554a18621_Texture_1_Texture2D : hint_default_white, repeat_enable, filter_linear;
uniform sampler2D tex_SampleTexture2D_fa4d718fd0c441d89f92f543fec97e24_Texture_1_Texture2D : hint_default_white, repeat_enable, filter_linear;
uniform sampler2D tex_Tex_WaterMask : hint_default_white, repeat_disable, filter_linear;

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
	r0.xyz = vec3(greaterThanEqual(vec3(0.003131, 0.003131, 0.003131), material[3].xyz));
	r1.xyz = (material[3].xyz * vec3(12.92321, 12.92321, 12.92321));
	r2.xyz = log2(abs(material[3].xyz));
	r2.xyz = (r2.xyz * vec3(0.416667, 0.416667, 0.416667));
	r2.xyz = exp2(r2.xyz);
	r2.xyz = (r2.xyz * vec3(1.055, 1.055, 1.055) + vec3(-0.055, -0.055, -0.055));
	r0.xyz = mix(r2.xyz, r1.xyz, notEqual(r0.xyz, vec3(0.0)));
	r0.w = (v1.y * material[7].z + (-material[7].x));
	r1.xy = (cb0_19.xx * material[4].xy);
	r1.xy = (v1.xy * vec2(2.0, 1.0) + r1.xy);
	r1.xyzw = texture(tex_SampleTexture2D_af1d31ba580448ffb9ffe6b554a18621_Texture_1_Texture2D, unity_uv(r1.xy)).xyzw;
	r1.yz = (material[4].zw * cb0_19.xx + v1.xy);
	r2.xyzw = texture(tex_SampleTexture2D_fa4d718fd0c441d89f92f543fec97e24_Texture_1_Texture2D, unity_uv(r1.yz)).xyzw;
	r1.y = (r2.x * 0.8);
	r1.x = (r1.x * 0.8 + r1.y);
	r0.w = clamp((r0.w + r1.x), 0.0, 1.0);
	r2.xyzw = texture(tex_Tex_WaterMask, unity_uv(v1.xy)).xyzw;
	r1.y = ((-r2.x) + 1.0);
	r1.x = (r1.y * r1.x + (-r0.w));
	r0.w = (material[7].w * r1.x + r0.w);
	r1.xy = clamp((r0.ww * vec2(5.0, 6.74367)), 0.0, 1.0);
	r1.xy = (r1.xy * vec2(0.8, 0.34) + vec2(0.2, 0.66));
	r2.xyzw = (cb0_19.xxxx * material[6].xyzw);
	r2.xyzw = (v1.xyxy * material[5].xyzw + r2.xyzw);
	r1.zw = (r2.xy * vec2(5.0, 5.0));
	r2.xy = floor(r1.zw);
	r1.zw = fract(r1.zw);
	r3.xyz = vec3(0.0, 8.0, -1.0);
	for (int loop_guard = 0; loop_guard < 1024; loop_guard++) {
		r3.w = float(1.0 < r3.z);
		if (r3.w != 0.0) break;
		r4.y = (r3.z);
		r4.zw = r3.xy;
		r3.w = -1.0;
		for (int loop_guard = 0; loop_guard < 1024; loop_guard++) {
			r5.x = float(1.0 < r3.w);
			if (r5.x != 0.0) break;
			r4.x = (r3.w);
			r5.xy = (r2.xy + r4.xy);
			r5.z = dot(r5.xy, vec2(15.27, 99.410004));
			r5.x = dot(r5.xy, vec2(47.630001, 89.980003));
			r6.xy = sin(r5.xz);
			r5.xy = fract(r6.xy);
			r5.xy = (r5.xy + r5.xy);
			r6.x = sin(r5.x);
			r6.y = cos(r5.y);
			r5.xy = (r6.xy * vec2(0.5, 0.5) + r4.xy);
			r5.xy = ((-r1.zw) + r5.xy);
			r5.xy = (r5.xy + vec2(0.5, 0.5));
			r4.x = dot(r5.xy, r5.xy);
			r4.x = sqrt(r4.x);
			r5.x = float(r4.x < r4.w);
			r4.zw = mix(r4.zw, r4.xx, notEqual(r5.xx, vec2(0.0)));
			r3.w = (r3.w + 1.0);
		}
		r3.xy = r4.zw;
		r3.z = (r3.z + 1.0);
	}
	r2.xyzw = texture(tex_SampleTexture2D_6bbf23ae47ab4a84be8e4df80eed1b50_Texture_1_Texture2D, unity_uv(r2.zw)).xyzw;
	r1.z = (r2.x * r3.x);
	r1.w = clamp((r3.x * r2.x + -0.475), 0.0, 1.0);
	r1.z = (r1.z * 0.0525 + r1.w);
	r1.z = (r1.z + 0.1);
	r2.yzw = (r0.xyz * r1.zzz);
	r0.xyz = (r0.xyz * r1.xxx + r2.yzw);
	r1.x = ((-r3.x) * r2.x + 1.0);
	r2.xyz = (r1.xxx * vec3(0.5, 0.5, 0.5) + r0.xyz);
	o0.xyz = (r0.xyz * r2.xyz);
	r0.x = (r0.w + -0.148287);
	r0.x = clamp((r0.x * 103.204552), 0.0, 1.0);
	r0.x = (r0.x * (-r1.y) + r1.y);
	r0.y = (r1.z + r0.x);
	r0.x = (r0.y * r0.x);
	o0.w = clamp((r0.x * material[7].y), 0.0, 1.0);
	// ret
	COLOR = vec4(tone_mapped(o0.rgb), clamp(o0.a, 0.0, 1.0));
}
