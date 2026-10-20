// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Shader Graphs/FX_Grp_Smoke4  []
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 material[5];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
uniform sampler2D tex_SampleTexture2D_97be4e56cada4d8a8832a9cd24a3925e_Texture_1_Texture2D : hint_default_white, repeat_enable, filter_linear;

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
	vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0), r3 = vec4(0.0), r4 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	vec4 cb0_19 = vec4(TIME, sin(TIME), cos(TIME), 0.0);
	r0.x = (material[3].w * 0.017453);
	r0.x = sin(r0.x);
	r1.x = cos(r0.x);
	r2.x = (-r0.x);
	r0.yz = (v1.xy + vec2(-0.5, -0.5));
	r2.y = r1.x;
	r2.z = r0.x;
	r1.x = dot(r0.yz, r2.yz);
	r1.y = dot(r0.yz, r2.xy);
	r0.xy = (r1.xy + vec2(0.5, 0.5));
	r0.zw = (cb0_19.xx * material[2].zw);
	r1.xy = (r0.xy * material[3].xy + r0.zw);
	r0.yz = (r0.xy * material[2].xy + r0.zw);
	r2.xyzw = texture(tex_SampleTexture2D_97be4e56cada4d8a8832a9cd24a3925e_Texture_1_Texture2D, unity_uv(r0.yz)).xyzw;
	r3.xyzw = (r1.xyxy * vec4(25.0, 25.0, 12.5, 12.5));
	r0.yz = (r1.xy * vec2(6.25, 6.25));
	r1.xyzw = floor(r3.xyzw);
	r3.xyzw = fract(r3.xyzw);
	r4.xyzw = (r1.zwzw + vec4(0.0, 1.0, 1.0, 1.0));
	r0.w = dot(r4.zw, vec2(12.9898, 78.233002));
	r2.y = dot(r4.xy, vec2(12.9898, 78.233002));
	r2.y = sin(r2.y);
	r2.y = (r2.y * 43758.546875);
	r2.y = fract(r2.y);
	r0.w = sin(r0.w);
	r0.w = (r0.w * 43758.546875);
	r0.w = fract(r0.w);
	r0.w = ((-r2.y) + r0.w);
	r4.xyzw = (r3.xyzw * r3.xyzw);
	r3.xyzw = ((-r3.xyzw) * vec4(2.0, 2.0, 2.0, 2.0) + vec4(3.0, 3.0, 3.0, 3.0));
	r3.xyzw = (r3.xyzw * r4.xyzw);
	r0.w = (r3.z * r0.w + r2.y);
	r4.xyzw = (r1.xyzw + vec4(1.0, 1.0, 1.0, 0.0));
	r2.y = dot(r4.zw, vec2(12.9898, 78.233002));
	r2.z = dot(r4.xy, vec2(12.9898, 78.233002));
	r2.yz = sin(r2.yz);
	r2.yz = (r2.yz * vec2(43758.546875, 43758.546875));
	r2.yz = fract(r2.yz);
	r1.z = dot(r1.zw, vec2(12.9898, 78.233002));
	r1.z = sin(r1.z);
	r1.z = (r1.z * 43758.546875);
	r1.z = fract(r1.z);
	r1.w = ((-r1.z) + r2.y);
	r1.z = (r3.z * r1.w + r1.z);
	r0.w = (r0.w + (-r1.z));
	r0.w = (r3.w * r0.w + r1.z);
	r0.w = (r0.w * 0.25);
	r4.xyzw = (r1.xyxy + vec4(1.0, 0.0, 0.0, 1.0));
	r1.x = dot(r1.xy, vec2(12.9898, 78.233002));
	r1.x = sin(r1.x);
	r1.x = (r1.x * 43758.546875);
	r1.y = dot(r4.zw, vec2(12.9898, 78.233002));
	r1.z = dot(r4.xy, vec2(12.9898, 78.233002));
	r1.yz = sin(r1.yz);
	r1.yz = (r1.yz * vec2(43758.546875, 43758.546875));
	r1.xyz = fract(r1.xyz);
	r1.z = ((-r1.x) + r1.z);
	r1.x = (r3.x * r1.z + r1.x);
	r1.z = ((-r1.y) + r2.z);
	r1.y = (r3.x * r1.z + r1.y);
	r1.y = ((-r1.x) + r1.y);
	r1.x = (r3.y * r1.y + r1.x);
	r0.w = (r1.x * 0.125 + r0.w);
	r1.xy = floor(r0.yz);
	r0.yz = fract(r0.yz);
	r1.zw = (r1.xy + vec2(1.0, 1.0));
	r1.z = dot(r1.zw, vec2(12.9898, 78.233002));
	r1.z = sin(r1.z);
	r1.z = (r1.z * 43758.546875);
	r3.xyzw = (r1.xyxy + vec4(1.0, 0.0, 0.0, 1.0));
	r1.x = dot(r1.xy, vec2(12.9898, 78.233002));
	r1.x = sin(r1.x);
	r1.x = (r1.x * 43758.546875);
	r1.y = dot(r3.zw, vec2(12.9898, 78.233002));
	r1.w = dot(r3.xy, vec2(12.9898, 78.233002));
	r1.yw = sin(r1.yw);
	r1.yw = (r1.yw * vec2(43758.546875, 43758.546875));
	r1.xyzw = fract(r1.xyzw);
	r1.zw = ((-r1.yx) + r1.zw);
	r2.yz = (r0.yz * r0.yz);
	r0.yz = ((-r0.yz) * vec2(2.0, 2.0) + vec2(3.0, 3.0));
	r0.yz = (r0.yz * r2.yz);
	r1.y = (r0.y * r1.z + r1.y);
	r0.y = (r0.y * r1.w + r1.x);
	r1.x = ((-r0.y) + r1.y);
	r0.y = (r0.z * r1.x + r0.y);
	r0.y = (r0.y * 0.5 + r0.w);
	r0.y = (r0.y + (-material[3].z));
	r0.z = clamp(r0.x, 0.0, 1.0);
	r0.x = ((-r0.x) + 1.0);
	r0.x = clamp((r0.x * 3.0), 0.0, 1.0);
	r0.y = (r0.z * r0.x + r0.y);
	r0.x = (r0.x * r0.y);
	r0.x = clamp((r2.x * r0.x), 0.0, 1.0);
	r0.yzw = (r0.xxx + vec3(-0.500008, -0.8, -0.500008));
	r0.yzw = (r0.yzw * vec3(3.333418, 5.0, 2.000031));
	r0.y = clamp(r0.y, 0.0, 1.0);
	r0.zw = max(r0.zw, vec2(0.0, 0.0));
	r0.zw = vec2(greaterThanEqual(r0.zw, vec2(0.01, 0.01)));
	r0.y = float(r0.y >= 0.01);
	r1.xy = mix(vec2(0.33, 0.67), vec2(0.66, 0.34), notEqual(r0.yy, vec2(0.0)));
	r0.yz = mix(vec2(0.0), vec2(1.0, 1.0), notEqual(r0.zw, vec2(0.0)));
	r0.w = ((r0.w != 0.0) ? -1.0 : -0.0);
	r0.w = (r0.w + r0.x);
	r0.z = (material[4].y * r0.w + r0.z);
	r0.y = (r0.y * r1.y + r1.x);
	o0.w = (r0.z * material[4].x);
	r0.x = ((-r0.y) + r0.x);
	r0.x = (material[4].y * r0.x + r0.y);
	r0.yzw = log2(abs(material[1].xyz));
	r0.yzw = (r0.yzw * vec3(0.416667, 0.416667, 0.416667));
	r0.yzw = exp2(r0.yzw);
	r0.yzw = (r0.yzw * vec3(1.055, 1.055, 1.055) + vec3(-0.055, -0.055, -0.055));
	r1.xyz = vec3(greaterThanEqual(vec3(0.003131, 0.003131, 0.003131), material[1].xyz));
	r2.xyz = (material[1].xyz * vec3(12.92321, 12.92321, 12.92321));
	r0.yzw = mix(r0.yzw, r2.xyz, notEqual(r1.xyz, vec3(0.0)));
	o0.xyz = (r0.xxx * r0.yzw);
	// ret
	COLOR = vec4(max(o0.rgb, vec3(0.0)), clamp(o0.a, 0.0, 1.0));
}
