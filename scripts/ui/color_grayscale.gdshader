shader_type canvas_item;
// The game's ColorGrayscale material (2DxFX_Extra_Shaders/ColorGrayScale), which a clash
// badge's skill art and attack icon carry: fades the sprite towards its own luminance.

uniform float grayscale_fade : hint_range(0.0, 1.0) = 0.0; // 1: fully grey

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	float luminance = dot(texel.rgb, vec3(0.3, 0.59, 0.11));
	COLOR = vec4(mix(texel.rgb, vec3(luminance), grayscale_fade), texel.a) * COLOR;
}
