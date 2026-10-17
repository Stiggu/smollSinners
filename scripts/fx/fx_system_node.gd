class_name FxSystemNode
extends Node2D
## A playing part of an FxEffect (a particle system or a line), drawn on its own so the
## shader can give it its own heat. The effect advances it every frame.


## The effect has been playing `effect_time` seconds, `delta` of them since last frame.
func advance(_effect_time: float, _delta: float) -> void:
	pass
