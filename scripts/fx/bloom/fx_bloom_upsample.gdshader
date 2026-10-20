// Bloom (URP): blends a level with the summed level below by scatter.
shader_type canvas_item;
render_mode unshaded, blend_disabled;

uniform sampler2D high : filter_linear, repeat_disable;  // this level, blurred
uniform sampler2D low : filter_linear, repeat_disable;  // the level below, summed up, half the size
uniform float scatter = 0.77;  // URP's scatter, already taken into its 0.05..0.95 range

void fragment() {
	COLOR = vec4(mix(texture(high, UV).rgb, texture(low, UV).rgb, scatter), 1.0);
}
