class_name FxGradient
extends RefCounted
## A Unity Gradient from fx.json: colour keys and alpha keys, each on their own times,
## linear between keys.

const MIN_KEY_SPAN := 0.0001

var _colour_times := PackedFloat32Array()
var _colours := PackedColorArray()
var _alphas := PackedVector2Array()  ## (time, alpha) keys


## data: {"c": [[time, [r, g, b]], ...], "a": [[time, alpha], ...]}.
static func from_json(data: Dictionary) -> FxGradient:
	var gradient := FxGradient.new()
	for key: Array in data.get("c", []):
		gradient._colour_times.append(key[0])
		gradient._colours.append(FxUnity.color(key[1]))
	gradient._alphas = FxCurve.keys_from(data.get("a", []))
	return gradient


func sample(t: float) -> Color:
	var colour := _colour_at(t)
	colour.a = FxCurve.keyed(_alphas, t, 1.0)
	return colour


func _colour_at(t: float) -> Color:
	if _colours.is_empty():
		return Color.WHITE
	if t <= _colour_times[0]:
		return _colours[0]
	for i in _colours.size() - 1:
		if t < _colour_times[i + 1]:
			var weight := (t - _colour_times[i]) / maxf(_colour_times[i + 1] - _colour_times[i], MIN_KEY_SPAN)
			return _colours[i].lerp(_colours[i + 1], weight)
	return _colours[-1]
