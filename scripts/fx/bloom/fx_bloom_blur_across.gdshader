// Bloom (URP): halves the level above, 9-tap gaussian across.
shader_type canvas_item;
render_mode unshaded, blend_disabled;

const int TAPS_EACH_SIDE = 4;
const float WEIGHTS[5] = {0.22702703, 0.19459459, 0.12162162, 0.05405405, 0.01621622};

uniform sampler2D source : filter_linear, repeat_disable;  // the level above, twice the size

void fragment() {
	float step_x = 2.0 / float(textureSize(source, 0).x);
	vec3 color = texture(source, UV).rgb * WEIGHTS[0];
	for (int tap = 1; tap <= TAPS_EACH_SIDE; tap++) {
		vec2 offset = vec2(step_x * float(tap), 0.0);
		color += (texture(source, UV - offset).rgb + texture(source, UV + offset).rgb) * WEIGHTS[tap];
	}
	COLOR = vec4(color, 1.0);
}
