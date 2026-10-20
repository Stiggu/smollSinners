// Bloom (URP) bright pass, with URP's soft knee.
shader_type canvas_item;
render_mode unshaded, blend_disabled;

const float KNEE_SHARE = 0.5;  // URP's knee: half the threshold either side of it
const float EPSILON = 1e-4;

uniform sampler2D source : filter_linear, repeat_disable;
uniform float threshold = 1.0;  // the brightest channel where glowing starts
uniform float clamp_max = 65472.0;  // caps broken, absurdly bright pixels

void fragment() {
	vec3 color = min(texture(source, UV).rgb, vec3(clamp_max));
	float knee = threshold * KNEE_SHARE;
	float brightness = max(color.r, max(color.g, color.b));
	float softness = clamp(brightness - threshold + knee, 0.0, 2.0 * knee);
	softness = softness * softness / (4.0 * knee + EPSILON);
	float multiplier = max(brightness - threshold, softness) / max(brightness, EPSILON);
	COLOR = vec4(max(color * multiplier, vec3(0.0)), 1.0);
}
