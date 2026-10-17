// Translated by tools/fx_shaders.py from the game's shader, do not edit:
//   Shader Graphs/Fx_Grp_ScreenFliter_AppUse  []
shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

uniform vec4 material[3];  // UnityPerMaterial
uniform sampler2D vertex_data : filter_nearest, repeat_disable;  // see FxVertexStreams
uniform int vertex_data_slots = 1;
uniform int normal_slot = -1;  // -1: facing the camera
uniform sampler2D global_GrabbedTexture : hint_screen_texture, filter_linear;
uniform sampler2D tex_MainTex : hint_default_white, repeat_disable, filter_linear;

varying vec4 io_interp0;
varying vec4 io_interp1;
varying vec4 io_interp2;
varying vec4 io_interp3;
varying vec4 io_interp4;
varying vec4 io_interp5;

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
	vec4 v6 = COLOR;
	vec4 r0 = vec4(0.0), r1 = vec4(0.0);
	vec4 o0 = vec4(0.0), o1 = vec4(0.0), o2 = vec4(0.0), o3 = vec4(0.0), o4 = vec4(0.0), o5 = vec4(0.0), o6 = vec4(0.0);
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
	o5.xyz = r0.xyz;
	o0.xyzw = (r1.xyzw + cb0_82.xyzw);
	o1.xyzw = v3.xyzw;
	o2.xyzw = v4.xyzw;
	o3.xyzw = v5.xyzw;
	o4.xyzw = v6.xyzw;
	r0.x = dot(v1.xyz, cb1_4.xyz);
	r0.y = dot(v1.xyz, cb1_5.xyz);
	r0.z = dot(v1.xyz, cb1_6.xyz);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = max(r0.w, 0.0);
	r0.w = inversesqrt(r0.w);
	o6.xyz = (r0.www * r0.xyz);
	// ret
	io_interp0 = o1;
	io_interp1 = o2;
	io_interp2 = o3;
	io_interp3 = o4;
	io_interp4 = o5;
	io_interp5 = o6;
}

void fragment() {
	vec4 screen_texel = vec4(0.0);
	float screen_alpha = 0.0;
	vec4 v0 = vec4(FRAGCOORD.xy, 0.5, 1.0);
	vec4 v1 = io_interp0;
	vec4 v2 = io_interp1;
	vec4 v3 = io_interp2;
	vec4 v4 = io_interp3;
	vec4 v5 = io_interp4;
	vec4 v6 = io_interp5;
	vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0), r3 = vec4(0.0), r4 = vec4(0.0), r5 = vec4(0.0), r6 = vec4(0.0);
	vec4 o0 = vec4(0.0);
	vec4 cb0_3 = vec4(1.0 / SCREEN_PIXEL_SIZE, 1.0 + SCREEN_PIXEL_SIZE);
	vec4 cb0_22 = vec4(1.0, 0.3, 1000.0, 0.001);
	r0.x = (v3.x + (-material[2].y));
	r0.x = (material[1].w * r0.x + material[2].y);
	r0.yz = (v2.xy + (-material[1].yz));
	r0.yz = (material[1].ww * r0.yz + material[1].yz);
	r0.w = float(cb0_22.x < 0.0);
	r1.x = ((-v0.y) + cb0_3.y);
	r1.y = ((r0.w != 0.0) ? r1.x : v0.y);
	r1.x = v0.x;
	r1.xy = (r1.xy / cb0_3.xy);
	r1.z = ((-r1.y) + 1.0);
	r1.yw = ((-r1.xz) + vec2(0.5, 0.5));
	r1.yw = (r0.yz * r1.yw);
	r0.yz = (r0.yz * vec2(0.05, 0.05) + (-r1.yw));
	r0.yz = (r0.xx * r0.yz + r1.yw);
	r1.yw = (r0.yz * vec2(0.2, 0.2) + r1.xz);
	screen_texel = texture(global_GrabbedTexture, unity_uv(r1.yw));
	screen_alpha = max(screen_alpha, screen_texel.a);
	r2.xyzw = screen_texel.xyzw;
	r3.xyz = (r2.xyz * vec3(0.1, 0.1, 0.1));
	r4.xyzw = (r0.yzyz * vec4(-0.1, -0.1, 0.1, 0.1) + r1.xzxz);
	r5.xyzw = (r0.yzyz * vec4(-0.05, 0.05, -0.2, -0.2) + r1.xzxz);
	screen_texel = texture(global_GrabbedTexture, unity_uv(r4.zw));
	screen_alpha = max(screen_alpha, screen_texel.a);
	r6.xyzw = screen_texel.xyzw;
	screen_texel = texture(global_GrabbedTexture, unity_uv(r4.xy));
	screen_alpha = max(screen_alpha, screen_texel.a);
	r4.xyzw = screen_texel.xyzw;
	r0.yzw = (r4.xyz * vec3(0.2, 0.2, 0.2));
	r3.xyz = (r6.xyz * vec3(0.2, 0.2, 0.2) + r3.xyz);
	screen_texel = texture(global_GrabbedTexture, unity_uv(r5.zw));
	screen_alpha = max(screen_alpha, screen_texel.a);
	r4.xyzw = screen_texel.xyzw;
	screen_texel = texture(global_GrabbedTexture, unity_uv(r5.xy));
	screen_alpha = max(screen_alpha, screen_texel.a);
	r5.xyzw = screen_texel.xyzw;
	r0.yzw = (r4.xyz * vec3(0.1, 0.1, 0.1) + r0.yzw);
	r2.x = r4.x;
	r0.yzw = (r3.xyz + r0.yzw);
	r0.yzw = (r5.xyz * vec3(0.4, 0.4, 0.4) + r0.yzw);
	r2.y = r5.y;
	r2.xyz = ((-r0.yzw) + r2.xyz);
	r0.xyz = (r0.xxx * r2.xyz + r0.yzw);
	r2.xyzw = (v2.zwzw + (-material[0].xyxy));
	r2.xyzw = (material[1].wwww * r2.xyzw + material[0].xyxy);
	r1.xyzw = (r2.xyzw * vec4(0.1, 0.1, -0.1, -0.1) + r1.xzxz);
	r2.xy = (v1.xy + vec2(-0.5, -0.5));
	r0.w = (material[2].x * 0.017453);
	r3.x = sin(r0.w);
	r4.x = cos(r0.w);
	r4.y = r3.x;
	r0.w = dot(r2.xy, r4.xy);
	r0.w = (r0.w + 0.5);
	r0.w = float(r0.w >= 0.5);
	r2.x = ((r0.w != 0.0) ? 0.0 : 1.0);
	r0.w = r0.w;
	r1.zw = (r1.zw * r2.xx);
	r1.xy = (r1.xy * r0.ww + r1.zw);
	screen_texel = texture(global_GrabbedTexture, unity_uv(r1.xy));
	screen_alpha = max(screen_alpha, screen_texel.a);
	r1.xyzw = screen_texel.xyzw;
	r0.xyz = (r0.xyz + (-r1.xyz));
	r0.w = (v3.y + (-material[1].x));
	r0.w = (material[1].w * r0.w + material[1].x);
	r0.xyz = (r0.www * r0.xyz + r1.xyz);
	r1.xyz = ((-abs(r0.xyz)) + vec3(1.0, 1.0, 1.0));
	r0.w = dot((-r0.xyz), (-r0.xyz));
	r0.w = sqrt(r0.w);
	r0.w = ((-r0.w) * 0.571429 + 1.0);
	r0.w = max(r0.w, 0.0);
	r1.xyz = ((-r0.www) + r1.xyz);
	r2.xy = (v3.zw + (-material[0].zw));
	r2.xy = (material[1].ww * r2.xy + material[0].zw);
	r1.xyz = (r2.yyy * r1.xyz + r0.www);
	r1.xyz = ((-r0.xyz) + r1.xyz);
	o0.xyz = (r2.xxx * r1.xyz + r0.xyz);
	r0.x = (v4.w + (-material[2].z));
	r0.x = (material[1].w * r0.x + material[2].z);
	r1.xyzw = texture(tex_MainTex, unity_uv(v1.xy)).xyzw;
	o0.w = (r0.x * r1.x);
	// ret
	COLOR = vec4(clamp(o0.rgb, vec3(0.0), vec3(1.0)), screen_alpha);
}
