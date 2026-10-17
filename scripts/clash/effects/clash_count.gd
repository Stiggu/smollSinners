class_name ClashCount
extends Node2D
## The count shown after every clash round, "N합" (합: bouts) in brush strokes on an ink
## splat: the game's ParryingTypo. scenes/clash/effects/clash_count.tscn lays it out as the
## prefab does and plays its Reveal, then frees it. Pieces from tools/export_ui.py.

## The splats the game picks from (which one it shows when isn't in its data: random here).
const SPLATS: Array[Texture2D] = [
	preload("res://assets/limbus/ui/clash_count/splat_3.png"),
	preload("res://assets/limbus/ui/clash_count/splat_7.png"),
	preload("res://assets/limbus/ui/clash_count/splat_11.png"),
	preload("res://assets/limbus/ui/clash_count/splat_13.png"),
	preload("res://assets/limbus/ui/clash_count/splat_14.png"),
]

@onready var _ink: Sprite2D = $Pivot/Ink
@onready var _count: Label = $Pivot/ScalePivot/Count


func show_round(round_number: int) -> void:
	_ink.texture = SPLATS.pick_random()
	_count.text = str(round_number)
