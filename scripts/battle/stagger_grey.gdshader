// The game's SpRendererMaterial_Break (AllIn1SpriteShader, GREYSCALE_ON): a staggered unit drawn dark grey.
shader_type canvas_item;

uniform float blend = 0.713;  // _GreyscaleBlend
uniform float luminosity = -0.19;  // _GreyscaleLuminosity
uniform vec3 tint = vec3(0.4811);  // _GreyscaleTintColor

void fragment() {
	vec4 colour = texture(TEXTURE, UV) * COLOR;
	float grey = clamp(dot(colour.rgb, vec3(0.3, 0.59, 0.11)) + luminosity, 0.0, 1.0);
	COLOR = vec4(mix(colour.rgb, vec3(grey) * tint, blend), colour.a);
}
