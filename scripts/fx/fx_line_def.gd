class_name FxLineDef
extends FxSystemDef
## A line from fx.json (a Unity LineRenderer): it runs from the caster to the target, here
## zigzagging like lightning, its width and colour by its curves along it. See FxLine.

const MIN_POINTS := 2

var points := MIN_POINTS  ## along the line, ends included
var width := 0.0  ## Unity units
var width_curve := PackedVector2Array()  ## (along 0..1, multiplier) keys
var color_along: FxGradient


func instantiate(rng: RandomNumberGenerator, source: Vector2, target: Vector2) -> Node2D:
	var line := FxLine.new()
	line.setup(self, rng, source, target)
	return line


## Its width (Unity units) `along` of the way from the caster (0) to the target (1).
func width_at(along: float) -> float:
	return width * FxCurve.keyed(width_curve, along, 1.0)


func color_at(along: float) -> Color:
	return color_along.sample(along) if color_along else Color.WHITE


func _read(data: Dictionary) -> void:
	points = maxi(int(data.points), MIN_POINTS)
	width = data.width
	width_curve = FxCurve.keys_from(data.get("width_curve", []))
	if data.has("color_over_length"):
		color_along = FxGradient.from_json(data.color_over_length)
