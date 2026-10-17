class_name SpChange
extends Node2D
## A Sanity change on the orb (scenes/ui/sp_change.tscn): a ring bursting out of the orb, an
## arrow rising (or sinking) through it, and by how much. Plays once and frees itself.

@onready var _ring: RingLine = $Ring
@onready var _arrow: Node2D = $Arrow
@onready var _arrow_sprite: Sprite2D = $Arrow/Sprite
@onready var _number: Label = $Number


## delta: how much Sanity changed; colour: up or down, as the orb shows it.
func show_change(delta: int, colour: Color) -> void:
	_arrow.scale.y = -1.0 if delta > 0 else 1.0  # the arrow image points down; going up, flip its path too
	_arrow_sprite.self_modulate = colour
	_ring.color = Color(colour, _ring.color.a)
	_number.text = "%+d" % delta
	_number.label_settings = _number.label_settings.duplicate()
	_number.label_settings.font_color = colour
