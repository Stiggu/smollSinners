class_name FxSystemNode
extends Node2D
## A playing part of an FxEffect (a particle system or a line), drawn on its own so the
## shader can give it its own heat. The effect advances it every frame.

const CLIP_REACH := 100000.0  ## px: far enough every way to take in any overlay

## Material values set from outside, over the material's own (see FxEffect.set_material_value()).
var material_values: Dictionary[String, float] = {}
var _floor_y := INF  ## px down from its origin below which it shows nothing; INF: no floor


## The effect has been playing `effect_time` seconds, `delta` of them since last frame.
func advance(_effect_time: float, _delta: float) -> void:
	pass


## Clips what it draws below `floor_y` px down from its origin.
func hide_below(floor_y: float) -> void:
	if floor_y == _floor_y:
		return
	_floor_y = floor_y
	queue_redraw()


func _notification(what: int) -> void:
	# a redraw resets the clip
	if what == NOTIFICATION_DRAW and not is_inf(_floor_y):
		var above_floor := Rect2(-CLIP_REACH, -CLIP_REACH, 2.0 * CLIP_REACH, CLIP_REACH + _floor_y)
		RenderingServer.canvas_item_set_custom_rect(get_canvas_item(), true, above_floor)
		RenderingServer.canvas_item_set_clip(get_canvas_item(), true)
