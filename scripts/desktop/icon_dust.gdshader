shader_type canvas_item;
// A defeated icon's grains: INSTANCE_CUSTOM.x is when one lets go (s), .yz its centre (px).

uniform float elapsed = 0.0;                    // seconds since the blow
uniform vec2 picture_size = vec2(1.0);          // px
uniform vec2 wind = vec2(70.0, -45.0);          // px/s (x is flipped away from the blow)
uniform float scatter = 35.0;                   // px/s of random push per grain
uniform float rise = 30.0;                      // px/s² upwards: the dust lifts as it goes
uniform float swirl = 5.0;                      // px of wobble
uniform float swirl_speed = 6.0;                // radians/s
uniform float lifetime = 1.2;                   // seconds from letting go to gone
uniform float ember_lead = 0.15;                // seconds a grain glows before letting go
uniform float ember_strength = 0.8;             // 0 to 1: how far it turns ember-coloured
uniform vec4 ember_colour : source_color = vec4(1.0, 0.55, 0.2, 1.0);
uniform vec4 ash_colour : source_color = vec4(0.22, 0.2, 0.2, 1.0);

varying float age;  // seconds since its grain let go; negative while it's still in place

float random(vec2 seed, float salt) {
	return fract(sin(dot(seed, vec2(12.9898, 78.233)) + salt) * 43758.5453);
}

void vertex() {
	vec2 home = INSTANCE_CUSTOM.yz;
	UV = (home + VERTEX) / picture_size;
	age = elapsed - INSTANCE_CUSTOM.x;
	float flown = max(age, 0.0);
	vec2 push = (vec2(random(home, 1.0), random(home, 2.0)) * 2.0 - 1.0) * scatter;
	float phase = random(home, 3.0) * TAU;
	vec2 wobble = vec2(sin(flown * swirl_speed + phase), cos(flown * swirl_speed * 0.8 + phase)) * swirl * min(flown * 2.0, 1.0);
	vec2 drift = (wind + push) * flown + vec2(0.0, -rise) * flown * flown + wobble;
	float size = 1.0 - smoothstep(0.0, lifetime, flown);
	VERTEX = home + VERTEX * size + drift;
}

void fragment() {
	vec4 picture = texture(TEXTURE, UV);
	float glow = age < 0.0 ? smoothstep(-ember_lead, 0.0, age) : 1.0 - smoothstep(0.0, ember_lead * 2.0, age);
	vec3 colour = mix(picture.rgb, ember_colour.rgb, glow * ember_strength);
	colour = mix(colour, ash_colour.rgb, smoothstep(0.0, lifetime, age));
	COLOR = vec4(colour, picture.a * (1.0 - smoothstep(lifetime * 0.5, lifetime, age)));
}
