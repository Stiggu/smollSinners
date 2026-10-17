class_name FxColorCurve
extends RefCounted
## A Unity MinMaxGradient from fx.json: a colour, a gradient, a random pick between two
## colours or two gradients, or a random colour from a gradient.

enum Mode { COLOR, GRADIENT, TWO_COLORS, TWO_GRADIENTS, RANDOM_FROM_GRADIENT }

var mode := Mode.COLOR
var color := Color.WHITE
var min_color := Color.WHITE
var gradient: FxGradient
var min_gradient: FxGradient


static func from_json(data: Dictionary) -> FxColorCurve:
	var parsed := FxColorCurve.new()
	parsed.mode = int(data.get("mode", Mode.COLOR)) as Mode
	parsed.color = FxUnity.color(data.get("color", [1.0, 1.0, 1.0, 1.0]))
	if data.has("min_color"):
		parsed.min_color = FxUnity.color(data.min_color)
	if data.has("gradient"):
		parsed.gradient = FxGradient.from_json(data.gradient)
	if data.has("min_gradient"):
		parsed.min_gradient = FxGradient.from_json(data.min_gradient)
	return parsed


static func optional(data: Dictionary, key: String) -> FxColorCurve:
	return from_json(data[key]) if data.has(key) else null


## The colour at t (0..1); `pick` (0..1) chooses between the two colours or gradients.
func sample(t: float, pick: float) -> Color:
	match mode:
		Mode.GRADIENT:
			return gradient.sample(t)
		Mode.TWO_COLORS:
			return min_color.lerp(color, pick)
		Mode.TWO_GRADIENTS:
			return min_gradient.sample(t).lerp(gradient.sample(t), pick)
		Mode.RANDOM_FROM_GRADIENT:
			return gradient.sample(pick)
	return color
