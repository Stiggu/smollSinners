class_name TimedEffect
extends Node2D
## An effect drawn in code that plays once over `lifetime` seconds and then frees itself.
## Subclasses draw it in _draw() from `progress`: 0 at the start, 1 at the end.

@export var lifetime := 0.5

var progress := 0.0
var _age := 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	progress = _age / lifetime
	queue_redraw()


## How far through a stage of the effect it is (0..1), given the share of the lifetime where
## that stage starts and where it ends.
func stage(starts: float, ends: float) -> float:
	return clampf(inverse_lerp(starts, ends, progress), 0.0, 1.0)
