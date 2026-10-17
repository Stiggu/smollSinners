// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Fx_Team/Fx_Grp_Outline_ColorMask_ScreenSpace_Shader  [_SURFACE_TYPE_TRANSPARENT _USE_STABLERANDOM]
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[17];  // UnityPerMaterial
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
	vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0), r3 = vec4(0.0), r4 = vec4(0.0), r5 = vec4(0.0), r6 = vec4(0.0), r7 = vec4(0.0), r8 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	vec4 cb0_3 = vec4(1.0 / SCREEN_PIXEL_SIZE, 1.0 + SCREEN_PIXEL_SIZE);
	vec4 cb0_19 = vec4(TIME, sin(TIME), cos(TIME), 0.0);
	vec4 cb0_22 = vec4(1.0, 0.3, 1000.0, 0.001);
	r0.x = float(cb0_22.x < 0.0);
	r0.y = ((-v0.y) + cb0_3.y);
	r0.y = ((r0.x != 0.0) ? r0.y : v0.y);
	r0.x = v0.x;
	r0.xy = (r0.xy / cb0_3.xy);
	r0.z = ((-r0.y) + 1.0);
	r1.x = (cb0_19.x * material[12].x);
	r1.yw = (cb0_19.xx * material[4].xy);
	r0.yw = fract(r1.xy);
	r0.yw = (r0.yw + material[11].zw);
	r0.xy = (r0.xz * material[11].xy + r0.yw);
	r0.xyzw = texture(tex_Color_Tex, unity_uv(r0.xy)).xyzw;
	r0.w = (material[9].z + -0.5);
	r1.x = (r0.w + material[9].w);
	r0.w = (r0.w + (-material[9].w));
	r0.w = (r0.w + 1.0);
	r0.w = ((-r1.x) + r0.w);
	r2.xyzw = (r0.xxyz + (-r1.xxxx));
	r0.x = (1.0 / r0.w);
	r0.xyzw = clamp((r0.xxxx * r2.xyzw), 0.0, 1.0);
	r2.xyzw = (r0.yyzw * vec4(-2.0, -2.0, -2.0, -2.0) + vec4(3.0, 3.0, 3.0, 3.0));
	r0.xyzw = (r0.xyzw * r0.xyzw);
	r0.xyzw = (r0.xyzw * r2.xyzw);
	r2.xyzw = max(v2.zwzw, vec4(-10000.0, -10000.0, 0.0, 0.0));
	r2.xyzw = min(r2.xyzw, vec4(0.0, 0.0, 10000.0, 10000.0));
	r3.xyzw = ((-r2.ywww) + r2.xzzz);
	r0.xyzw = (r0.xyzw * r3.xyzw + r2.ywww);
	r0.xyz = (r0.yzw * v5.xyz + r0.xxx);
	r2.xyz = log2(abs(material[8].xyz));
	r2.xyz = (r2.xyz * vec3(0.416667, 0.416667, 0.416667));
	r2.xyz = exp2(r2.xyz);
	r2.xyz = (r2.xyz * vec3(1.055, 1.055, 1.055) + vec3(-0.055, -0.055, -0.055));
	r3.xyz = vec3(greaterThanEqual(vec3(0.003131, 0.003131, 0.003131), material[8].xyz));
	r4.xyz = (material[8].xyz * vec3(12.92321, 12.92321, 12.92321));
	r2.xyz = mix(r2.xyz, r4.xyz, notEqual(r3.xyz, vec3(0.0)));
	r2.xyz = ((-r0.xyz) + r2.xyz);
	r3.x = (cb0_19.x * material[15].x);
	r3.yw = (cb0_19.xx * material[2].yx);
	r1.xy = fract(r3.xy);
	r1.xy = (r1.xy + material[14].zw);
	r4.xyz = (material[16].ywz * vec3(0.017453, 0.017453, 0.017453));
	r3.x = sin(r4.y);
	r5.x = cos(r4.y);
	r6.x = (-r3.x);
	r6.y = r5.x;
	r6.z = r3.x;
	r3.xy = (v1.xy + vec2(-0.5, -0.5));
	r5.z = dot(r3.xy, r6.xy);
	r5.y = dot(r3.xy, r6.yz);
	r5.yz = (r5.yz + vec2(0.5, 0.5));
	r5.x = (r5.z * material[0].y + r5.y);
	r1.xy = (r5.xz * material[14].xy + r1.xy);
	r5.xyzw = texture(tex_Noise_Tex, unity_uv(r1.xy)).xyzw;
	r5.xyzw = (r5.xyxy + vec4(-0.5, -0.5, -0.5, -0.5));
	r5.xyzw = (r5.xyzw * v2.xxxx);
	r1.x = sin(r4.z);
	r6.x = cos(r4.z);
	r4.x = sin(r4.x);
	r7.x = cos(r4.x);
	r8.x = (-r1.x);
	r8.y = r6.x;
	r8.z = r1.x;
	r4.y = dot(r3.xy, r8.yz);
	r4.z = dot(r3.xy, r8.xy);
	r6.yz = (r4.yz + vec2(0.5, 0.5));
	r6.x = (r6.z * material[0].x + r6.y);
	r1.xy = (r5.zw * material[15].zz + r6.xz);
	r3.z = (cb0_19.x * material[12].y);
	r3.zw = fract(r3.zw);
	r3.zw = (r3.zw + material[1].zw);
	r3.zw = (r3.zw + v4.xy);
	r1.xy = (r1.xy * material[1].xy + r3.zw);
	r6.xyzw = texture(tex_Dissolve_Tex, unity_uv(r1.xy)).xyzw;
	r8.x = (-r4.x);
	r8.y = r7.x;
	r8.z = r4.x;
	r4.y = dot(r3.xy, r8.yz);
	r4.z = dot(r3.xy, r8.xy);
	r3.yz = (r4.yz + vec2(0.5, 0.5));
	r3.x = (r3.z * material[0].x + r3.y);
	r1.xy = (r5.xy * material[15].yy + r3.xz);
	r1.z = (cb0_19.x * material[10].x);
	r1.zw = fract(r1.zw);
	r1.zw = (r1.zw + v3.xy);
	r1.xy = (r1.xy * v3.zw + r1.zw);
	r1.xyzw = texture(tex_MainTex, unity_uv(r1.xy)).xyzw;
	r0.w = ((-v2.y) + 1.0);
	r1.y = (r0.w + r0.w);
	r1.y = (r1.x * r6.x + (-r1.y));
	r1.y = (r1.y + 1.0);
	r1.z = (r0.w + material[7].x);
	r0.w = (r1.x * r1.y + (-r0.w));
	r1.x = (r1.x * r1.y + (-r1.z));
	r1.yz = ((-material[9].xy) + vec2(1.0, 1.0));
	r1.yz = (vec2(1.0, 1.0) / r1.yz);
	r1.x = clamp((r1.y * r1.x), 0.0, 1.0);
	r0.w = clamp((r0.w * r1.z), 0.0, 1.0);
	r1.y = (r1.x * -2.0 + 3.0);
	r1.x = (r1.x * r1.x);
	r1.x = ((-r1.y) * r1.x + 1.0);
	r1.x = (r1.x * material[8].w);
	o0.xyz = (r1.xxx * r2.xyz + r0.xyz);
	r0.x = (r0.w * -2.0 + 3.0);
	r0.y = (r0.w * r0.w);
	r0.x = (r0.y * r0.x);
	r0.x = min(r0.x, 1.0);
	o0.w = (r0.x * v5.w);
	// ret
	COLOR = vec4(tone_mapped(o0.rgb), clamp(o0.a, 0.0, 1.0));
}
