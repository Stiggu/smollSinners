class_name Keyframes
extends RefCounted
## Curves given as (time, value) keys.


## The value at t, linear between keys, holding the first and last beyond them; `fallback`
## when there are no keys.
static func linear(keys: PackedVector2Array, t: float, fallback := 0.0) -> float:
	if keys.is_empty():
		return fallback
	if t <= keys[0].x:
		return keys[0].y
	for i in keys.size() - 1:
		var from := keys[i]
		var to := keys[i + 1]
		if t < to.x:
			var span := to.x - from.x
			return lerpf(from.y, to.y, (t - from.x) / span if span > 0.0 else 1.0)
	return keys[-1].y
