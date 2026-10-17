class_name FxCurve
extends RefCounted
## A Unity MinMaxCurve from fx.json: a constant, a curve, a random pick between two curves,
## or a random pick between two constants. Curves are (time, value) keys over 0..1, scaled by
## `scalar`, linear between keys (the game's are smoother; close enough).

enum Mode { CONSTANT, CURVE, TWO_CURVES, TWO_CONSTANTS }

var mode := Mode.CONSTANT
var scalar := 0.0
var min_scalar := 0.0
var curve := PackedVector2Array()  ## (time, value) keys
var min_curve := PackedVector2Array()


static func from_json(data: Dictionary) -> FxCurve:
	var parsed := FxCurve.new()
	parsed.mode = int(data.get("mode", Mode.CONSTANT)) as Mode
	parsed.scalar = data.get("scalar", 0.0)
	parsed.min_scalar = data.get("min_scalar", 0.0)
	parsed.curve = keys_from(data.get("curve", []))
	parsed.min_curve = keys_from(data.get("min_curve", []))
	return parsed


## The curve under `key` in a module's data, or null when it isn't there (the module or that
## axis is off).
static func optional(data: Dictionary, key: String) -> FxCurve:
	return from_json(data[key]) if data.has(key) else null


## [[time, value], ...] as (time, value) keys.
static func keys_from(json_keys: Array) -> PackedVector2Array:
	var keys := PackedVector2Array()
	for key: Array in json_keys:
		keys.append(Vector2(key[0], key[1]))
	return keys


## The value at t (0..1 through a particle's life, or a system's duration). `pick` (0..1)
## chooses between the two curves or constants; keep it per particle so it chooses the same
## way all along.
func sample(t: float, pick: float) -> float:
	match mode:
		Mode.CURVE:
			return keyed(curve, t) * scalar
		Mode.TWO_CURVES:
			return lerpf(keyed(min_curve, t), keyed(curve, t), pick) * scalar
		Mode.TWO_CONSTANTS:
			return lerpf(min_scalar, scalar, pick)
	return scalar


## (time, value) keys at t, linearly between them; `fallback` when there are none.
static func keyed(keys: PackedVector2Array, t: float, fallback := 0.0) -> float:
	return Keyframes.linear(keys, t, fallback)
