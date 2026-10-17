@tool
class_name HPGauge
extends Node2D
## The HP gauge lying round the lower half of the unit bar's floor heptagon (the game's
## HPGauge, a shader filling FX_Tex_UI_Battle_HP): what's left sits at the right end, with a
## white-hot edge where it burns down, and a tick across it at each stagger threshold (grey
## once broken). The node is the gauge's centre; place it in scenes/ui/unit_bar.tscn.
## Pieces, and the gauge's shape on the floor, from tools/export_unit_bar.py.

const DIR := "res://assets/limbus/ui/unit_bar"
const HOT_EDGE_WIDTH := 2.0  ## px of white-hot texture at the burning edge

## How full, 0..1 of max HP (set by UnitBar; in the editor, a preview).
@export_range(0.0, 1.0) var fill := 1.0:
	set(value):
		fill = value
		queue_redraw()
## Stagger thresholds as fractions of max HP (set by UnitBar; in the editor, a preview).
@export var thresholds: Array[float] = [0.65, 0.35, 0.15]:
	set(value):
		thresholds = value
		queue_redraw()
## Which thresholds broke this battle, by index.
var broken: Array[bool] = []:
	set(value):
		broken = value
		queue_redraw()

## Where along the gauge texture its burning edge sits when full, and when empty.
static var _edge_when_full := 0.0
static var _edge_when_empty := 0.0
## The gauge's centre line, left to right, on the floor before it's squashed into perspective.
static var _spine := PackedVector2Array()
static var _floor_squash := 1.0  ## the floor's height over its width, as the camera sees it
static var _tick_size := Vector2.ZERO
static var _gauge: Texture2D
static var _hot_gauge: Texture2D
static var _tick: Texture2D
static var _broken_tick: Texture2D


func _draw() -> void:
	_load()
	var corner := (-_gauge.get_size() / 2.0).round()
	if fill > 0.0:
		_draw_remaining(corner)
	for i in thresholds.size():
		_draw_tick(1.0 - thresholds[i], i < broken.size() and broken[i])


## What's left, from its burning edge to the right end; full, it keeps the left end's glow too.
func _draw_remaining(corner: Vector2) -> void:
	var height := _gauge.get_height()
	var edge := lerpf(_edge_when_empty, _edge_when_full, fill)
	var left := 0.0 if fill >= 1.0 else edge
	var width := _gauge.get_width() - left
	draw_texture_rect_region(_gauge, Rect2(corner + Vector2(left, 0), Vector2(width, height)), Rect2(left, 0, width, height))
	if fill < 1.0:
		var hot := Rect2(edge - HOT_EDGE_WIDTH / 2.0, 0.0, HOT_EDGE_WIDTH, height)
		draw_texture_rect_region(_hot_gauge, Rect2(corner + hot.position, hot.size), hot)


## A threshold's tick lying across the gauge, `along` of the way from its left end.
func _draw_tick(along: float, is_broken: bool) -> void:
	var at := along * (_spine.size() - 1)
	var i := clampi(int(at), 0, _spine.size() - 2)
	var forward := (_spine[i + 1] - _spine[i]).normalized()
	var across := forward.orthogonal()
	var texture := _broken_tick if is_broken else _tick
	# its width runs along the gauge and its length across it, both squashed onto the floor
	var x_axis := _onto_floor(forward) * _tick_size.x / texture.get_width()
	var y_axis := _onto_floor(across) * _tick_size.y / texture.get_height()
	var center := _onto_floor(_spine[i].lerp(_spine[i + 1], at - i))
	var origin := center - (x_axis * texture.get_width() + y_axis * texture.get_height()) / 2.0
	draw_set_transform_matrix(Transform2D(x_axis, y_axis, origin))
	draw_texture(texture, Vector2.ZERO)
	draw_set_transform_matrix(Transform2D.IDENTITY)


static func _onto_floor(point: Vector2) -> Vector2:
	return Vector2(point.x, point.y * _floor_squash)


static func _load() -> void:
	if _gauge:
		return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "/unit_bar.json"))
	_edge_when_full = data.hp.span[0]
	_edge_when_empty = data.hp.span[1]
	for point: Array in data.hp.spine:
		_spine.append(Vector2(point[0], point[1]))
	_floor_squash = data.flat
	_tick_size = Vector2(data.tick[0], data.tick[1])
	_gauge = load(DIR + "/hp.png")
	_hot_gauge = load(DIR + "/hp_hot.png")
	_tick = load(DIR + "/tick.png")
	_broken_tick = load(DIR + "/tick_used.png")
