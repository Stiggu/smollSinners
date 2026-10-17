class_name IconBoxes
extends Node2D
## Debug view: an outline round every desktop icon with its name, green while it's in sight
## and red while a window covers it. Toggled from the tray (Show icon boxes).

@export var desktop: Desktop
@export var outline_width := 2.0
@export var in_sight := Color.LIME
@export var covered := Color.RED
@export var name_size := 11
@export var name_width := 120.0
@export var name_raise := 3.0  ## px the name sits above the outline


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for icon in desktop.icons:
		var rect := desktop.to_overlay(icon.rect)
		var color := in_sight if icon.visible else covered
		draw_rect(rect, color, false, outline_width)
		draw_string(font, rect.position + Vector2(0, -name_raise), icon.name, HORIZONTAL_ALIGNMENT_LEFT, name_width, name_size, color)
