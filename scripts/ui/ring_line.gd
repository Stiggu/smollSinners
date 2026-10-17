@tool
class_name RingLine
extends Node2D
## A circle outline about the node's position, for effects to animate.

@export var radius := 10.0:
	set(value):
		radius = value
		queue_redraw()
@export var width := 2.0:
	set(value):
		width = value
		queue_redraw()
@export var color := Color.WHITE:
	set(value):
		color = value
		queue_redraw()
@export var segments := 40
@export var antialiased := false


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, segments, color, width, antialiased)
