// Bloom (URP): 5 bilinear taps down (a 9-tap gaussian).
shader_type canvas_item;
render_mode unshaded, blend_disabled;

const int TAPS_EACH_SIDE = 2;
const float OFFSETS[3] = {0.0, 1.38461538, 3.23076923};  // texels from the centre
const float WEIGHTS[3] = {0.22702703, 0.31621622, 0.07027027};

uniform sampler2D source : filter_linear, repeat_disable;  // this level, blurred across

void fragment() {
	float texel_y = 1.0 / float(textureSize(source, 0).y);
	vec3 color = texture(source, UV).rgb * WEIGHTS[0];
	for (int tap = 1; tap <= TAPS_EACH_SIDE; tap++) {
		vec2 offset = vec2(0.0, texel_y * OFFSETS[tap]);
		color += (texture(source, UV - offset).rgb + texture(source, UV + offset).rgb) * WEIGHTS[tap];
	}
	COLOR = vec4(color, 1.0);
}
