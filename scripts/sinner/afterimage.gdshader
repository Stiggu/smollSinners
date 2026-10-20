// The game's SpriteAdditiveShader (SpRendererMaterial_Trail), ported: the sprite's grey lit in tint, added as light.
shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

uniform vec3 tint = vec3(1.81231, 0.07583, 5.35849);  // the game material's _AddColor, HDR
uniform float strength = 0.10196;  // ... and its alpha

varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

// Unity's linear-to-sRGB, which the game's shader applies to its colour.
vec3 to_srgb(vec3 c) {
	return mix(pow(abs(c), vec3(1.0 / 2.4)) * 1.055 - 0.055, c * 12.92321, lessThanEqual(c, vec3(0.003131)));
}

void fragment() {
	vec4 sprite = texture(TEXTURE, UV);
	float grey = (sprite.r + sprite.g + sprite.b) / 3.0;
	float alpha = sprite.a * vertex_color.a * strength;
	vec3 light = clamp(to_srgb(tint) * grey * vertex_color.rgb * alpha, vec3(0.0), vec3(1.0));
	// the brightest channel as coverage, so the light shows on the transparent overlay (as FxStage's composite does)
	COLOR = vec4(light, max(light.r, max(light.g, light.b)));
}
