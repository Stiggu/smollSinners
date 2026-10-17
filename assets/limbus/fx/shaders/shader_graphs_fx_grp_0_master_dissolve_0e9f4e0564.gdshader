// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Shader Graphs/FX_Grp_0_Master_Dissolve  []
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[13];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
uniform sampler2D tex_Tex_Main : hint_default_white, repeat_enable, filter_linear;
uniform sampler2D tex_Tex_Mask : hint_default_white, repeat_enable, filter_linear;
uniform sampler2D tex_Tex_Noise1 : hint_default_white, repeat_enable, filter_linear;
uniform sampler2D tex_Tex_Noise2 : hint_default_white, repeat_enable, filter_linear;

varying vec4 io_interp0;
varying vec4 io_interp1;
varying vec4 io_interp2;
varying vec4 io_interp3;
varying vec4 io_interp4;

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
	r0.x = (material[12].x * 0.017453);
	r0.x = sin(r0.x);
	r1.x = cos(r0.x);
	r2.x = (-r0.x);
	r2.y = r1.x;
	r2.z = r0.x;
	r0.xy = (v1.xy + vec2(-0.5, -0.5));
	r1.y = dot(r0.xy, r2.xy);
	r1.x = dot(r0.xy, r2.yz);
	r0.zw = (r1.xy + vec2(0.5, 0.5));
	r0.zw = (r0.zw * material[10].zw);
	r1.xyzw = texture(tex_Tex_Mask, unity_uv(r0.zw)).wxyz;
	r2.xyzw = texture(tex_Tex_Main, unity_uv(r0.zw)).xyzw;
	r1.x = clamp(r1.x, 0.0, 1.0);
	r0.z = ((-r1.y) + r1.x);
	r0.z = (material[12].y * r0.z + r1.y);
	r0.w = ((-v1.z) + material[6].x);
	r0.w = (material[6].z * r0.w + v1.z);
	r1.xyzw = (material[5].xyzw * cb0_19.xxxx + v2.xyxy);
	r1.xyzw = (v1.xyxy * material[4].xyzw + r1.xyzw);
	r3.xyzw = texture(tex_Tex_Noise1, unity_uv(r1.xy)).xyzw;
	r1.xyzw = texture(tex_Tex_Noise2, unity_uv(r1.zw)).xyzw;
	r0.w = (r3.x * r1.x + (-r0.w));
	r0.z = clamp((r0.w * r0.z), 0.0, 1.0);
	r0.w = (material[9].w * 0.017453);
	r3.x = sin(r0.w);
	r4.x = cos(r0.w);
	r4.y = r3.x;
	r0.x = dot(r0.xy, r4.xy);
	r0.x = (r0.x + 0.5);
	r0.y = ((-v1.w) + material[10].x);
	r0.y = (material[6].z * r0.y + v1.w);
	r0.x = (r0.x * material[10].y + r0.y);
	r0.x = clamp((r0.x * r1.x), 0.0, 1.0);
	r0.x = (r0.x + -1.0);
	r0.x = (material[9].z * r0.x + 1.0);
	r0.yw = (r0.zz * r0.xx + vec2(-0.250004, -0.2));
	r0.yw = clamp((r0.yw * vec2(1.33334, 1.25)), 0.0, 1.0);
	r0.yw = vec2(greaterThanEqual(r0.yw, vec2(0.01, 0.01)));
	r0.yw = mix(vec2(0.0), vec2(0.999999940395, 0.999999940395), notEqual(r0.yw, vec2(0.0)));
	r0.yw = ((-r0.zz) * r0.xx + r0.yw);
	r0.x = (r0.x * r0.z);
	r0.xy = (material[6].yy * r0.yw + r0.xx);
	r0.z = ((-r0.x) + 1.0);
	r1.xyz = log2(abs(material[8].xyz));
	r1.xyz = (r1.xyz * vec3(0.416667, 0.416667, 0.416667));
	r1.xyz = exp2(r1.xyz);
	r1.xyz = (r1.xyz * vec3(1.055, 1.055, 1.055) + vec3(-0.055, -0.055, -0.055));
	r3.xyz = vec3(greaterThanEqual(vec3(0.003131, 0.003131, 0.003131), material[8].xyz));
	r4.xyz = (material[8].xyz * vec3(12.92321, 12.92321, 12.92321));
	r1.xyz = mix(r1.xyz, r4.xyz, notEqual(r3.xyz, vec3(0.0)));
	r1.xyz = (r0.zzz * r1.xyz);
	r3.xyz = log2(abs(material[7].xyz));
	r3.xyz = (r3.xyz * vec3(0.416667, 0.416667, 0.416667));
	r3.xyz = exp2(r3.xyz);
	r3.xyz = (r3.xyz * vec3(1.055, 1.055, 1.055) + vec3(-0.055, -0.055, -0.055));
	r4.xyz = vec3(greaterThanEqual(vec3(0.003131, 0.003131, 0.003131), material[7].xyz));
	r5.xyz = (material[7].xyz * vec3(12.92321, 12.92321, 12.92321));
	r3.xyz = mix(r3.xyz, r5.xyz, notEqual(r4.xyz, vec3(0.0)));
	r4.xyz = (r2.xyz * r3.xyz);
	r0.xzw = (r4.xyz * r0.xxx + r1.xyz);
	r0.xzw = ((-r3.xyz) * r2.xyz + r0.xzw);
	o0.xyz = (material[9].xxx * r0.xzw + r4.xyz);
	r0.x = ((-v3.w) + material[9].y);
	r0.x = (material[6].z * r0.x + v3.w);
	o0.w = (r0.x * r0.y);
	// ret
	COLOR = vec4(tone_mapped(o0.rgb), clamp(o0.a, 0.0, 1.0));
}
