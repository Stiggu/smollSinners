class_name IconBars
extends Node2D
## The game's enemy unit bar (gear emblem, no Sanity orb) under each desktop icon in a clash.

const BAR_SCENE := preload("res://scenes/ui/icon_bar.tscn")
const STAGGER_GREY := preload("res://scripts/battle/stagger_grey.gdshader")

@export var desktop: Desktop
@export var icon_statuses: IconStatuses
@export var clashes: ClashDirector
## px from the bottom of the icon's picture down to the bar's centre (where a unit's feet are).
@export var feet_below_icon := 22.0

var _bars: Dictionary[String, UnitBar] = {}
var _name_covers: Dictionary[String, IconCover] = {}  ## Explorer's name hidden under the bar
var _grey_covers: Dictionary[String, IconCover] = {}  ## a staggered icon's picture, greyed
## Icons' names and pictures as first read (IconCover.Look; null: couldn't be read this time).
var _names: Dictionary = {}
var _pictures: Dictionary = {}
var _grey := ShaderMaterial.new()

@onready var _cover_layer: Node2D = $Covers
@onready var _bar_layer: Node2D = $Bars


func _ready() -> void:
	_grey.shader = STAGGER_GREY


func _process(_delta: float) -> void:
	var shown: Dictionary[String, bool] = {}
	for icon in desktop.icons:
		var clash := clashes.clash_on(icon.id)
		if clash == null or clash.icon_status.is_dead() or not icon.visible:
			continue
		shown[icon.id] = true
		var rect := clash.icon_rect_now()
		_bar_for(icon.id, clash.icon_status).position = Vector2(rect.get_center().x, rect.end.y + feet_below_icon)
		var picture := desktop.to_screen(rect)
		_cover(_name_covers, _names, icon.id, desktop.name_area_of(picture))
		if clash.icon_status.is_staggered():
			_cover(_grey_covers, _pictures, icon.id, picture.grow(IconPatch.EDGE), _grey)
		else:
			_uncover(_grey_covers, _pictures, icon.id)
	for icon_id in _bars.keys():
		if not shown.has(icon_id):
			_drop(icon_id)


func _bar_for(icon_id: String, status: UnitStatus) -> UnitBar:
	if not _bars.has(icon_id):
		var bar: UnitBar = BAR_SCENE.instantiate()
		_bar_layer.add_child(bar)
		_bars[icon_id] = bar
	if _bars[icon_id].status != status:
		_bars[icon_id].status = status
	return _bars[icon_id]


## Cover part of an icon in `area`, read off the screen the first time; redrawn through `material` if set.
func _cover(covers: Dictionary[String, IconCover], looks: Dictionary, icon_id: String, area: Rect2i, material: Material = null) -> void:
	if not looks.has(icon_id):
		looks[icon_id] = IconCover.read(area, desktop)
	if looks[icon_id] == null:
		return
	if not covers.has(icon_id):
		covers[icon_id] = IconCover.new(desktop, looks[icon_id], material)
		_cover_layer.add_child(covers[icon_id])
	covers[icon_id].cover(area)


## Take a cover away; a part that couldn't be read is tried again next time.
func _uncover(covers: Dictionary[String, IconCover], looks: Dictionary, icon_id: String) -> void:
	if covers.has(icon_id):
		covers[icon_id].queue_free()
		covers.erase(icon_id)
	if looks.get(icon_id) == null:
		looks.erase(icon_id)


func _drop(icon_id: String) -> void:
	_bars[icon_id].queue_free()
	_bars.erase(icon_id)
	_uncover(_name_covers, _names, icon_id)
	_uncover(_grey_covers, _pictures, icon_id)
