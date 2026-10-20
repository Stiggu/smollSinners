// Effects + bloom (added in linear light like URP in gamma space), clamped; light covers by brightness.
shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

const float SRGB_KNEE = 0.04045;
const float LINEAR_KNEE = 0.0031308;
const float SRGB_SLOPE = 12.92;
const float SRGB_GAMMA = 2.4;
const float SRGB_OFFSET = 0.055;

uniform sampler2D bloom : filter_linear, repeat_disable;  // FxBloom's glow
uniform float intensity = 2.0;  // the profile's bloom intensity
uniform vec3 tint = vec3(1.0);  // the profile's bloom tint, by its luminance

vec3 srgb_to_linear(vec3 c) {
	vec3 curve = pow((c + SRGB_OFFSET) / (1.0 + SRGB_OFFSET), vec3(SRGB_GAMMA));
	return mix(c / SRGB_SLOPE, curve, step(vec3(SRGB_KNEE), c));
}

vec3 linear_to_srgb(vec3 c) {
	vec3 curve = (1.0 + SRGB_OFFSET) * pow(c, vec3(1.0 / SRGB_GAMMA)) - SRGB_OFFSET;
	return mix(c * SRGB_SLOPE, curve, step(vec3(LINEAR_KNEE), c));
}

void fragment() {
	vec4 effects = texture(TEXTURE, UV);
	vec3 glow = texture(bloom, UV).rgb;
	vec3 light = srgb_to_linear(max(effects.rgb, vec3(0.0))) + glow * glow * intensity * tint;
	vec3 color = clamp(linear_to_srgb(light), 0.0, 1.0);
	float coverage = max(clamp(effects.a, 0.0, 1.0), max(color.r, max(color.g, color.b)));
	COLOR = vec4(color, coverage);
}
