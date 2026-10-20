class_name IconGraveyard
extends Node2D
## Turns defeated icons to dust over a wallpaper patch (the real icon never moves), then back.

const FALLEN_SCENE := preload("res://scenes/desktop/fallen_icon.tscn")
const DOWN_SECONDS := 45.0  ## a defeated icon lies as dust this long before it gathers back
const CHECK_SECONDS := 0.5  ## between checks that the fallen icons are still there and uncovered
const FULLY_UNCOVERED := 0.999

@export var desktop: Desktop
@export var icon_statuses: IconStatuses
@export var clashes: ClashDirector  ## who struck the blow, for which way the dust blows

var _fallen: Dictionary[String, FallenIcon] = {}
var _cells: Dictionary[String, Rect2i] = {}  ## where each fallen icon was cut from, screen pixels
var _down_for: Dictionary[String, float] = {}  ## seconds each fallen icon has left as dust
var _until_check := 0.0


func _ready() -> void:
	icon_statuses.icon_died.connect(_on_icon_died)
	icon_statuses.icon_got_up.connect(_on_icon_got_up)


func _process(delta: float) -> void:
	for icon_id in _down_for.keys():
		_down_for[icon_id] -= delta
		if _down_for[icon_id] <= 0.0:
			_rise(icon_id)
	_until_check -= delta
	if _until_check <= 0.0:
		_until_check = CHECK_SECONDS
		for icon_id in _fallen.keys():
			_check(icon_id)


func _on_icon_died(icon_id: String) -> void:
	if not icon_statuses.turn_to_dust:
		return  # it gets back up at once
	var icon := desktop.icon_by_id(icon_id)
	if icon == null:
		return
	var cell := desktop.cell_of(icon.rect)
	var wallpaper := desktop.wallpaper.patch(cell)
	if wallpaper == null:
		_get_back_up(icon_id, "the wallpaper isn't ready")
		return
	var shown: Image = WinGlue.CaptureScreen(cell)
	if not IconPatch.wallpaper_matches(shown, wallpaper):
		_get_back_up(icon_id, "the rebuilt wallpaper doesn't match the screen there")
		return
	var fallen: FallenIcon = FALLEN_SCENE.instantiate()
	fallen.position = desktop.to_overlay(cell).position
	add_child(fallen)
	fallen.crumble(shown, wallpaper, _blow_from(icon_id, cell))
	_fallen[icon_id] = fallen
	_cells[icon_id] = cell
	_down_for[icon_id] = DOWN_SECONDS


## Up some other way (turn_to_dust switched off): the dust still gathers back.
func _on_icon_got_up(icon_id: String) -> void:
	if _fallen.has(icon_id):
		_forget(icon_id).reform()


## Gather back, and get up once whole.
func _rise(icon_id: String) -> void:
	await _forget(icon_id).reform()
	var status := icon_statuses.status_by_id(icon_id)
	if status and status.is_dead():
		status.get_up()


## Hide the cover under windows; give up if the icon was moved or deleted.
func _check(icon_id: String) -> void:
	var icon := desktop.icon_by_id(icon_id)
	if icon == null or desktop.cell_of(icon.rect) != _cells[icon_id]:
		_forget(icon_id).queue_free()
		_get_back_up(icon_id, "")
		return
	_fallen[icon_id].show_cover(desktop.uncovered_fraction(_cells[icon_id]) >= FULLY_UNCOVERED)


## Up at full HP on the next frame (not in the middle of the hit that defeated it).
func _get_back_up(icon_id: String, why_not_dust: String) -> void:
	if why_not_dust:
		push_warning("A defeated icon can't turn to dust (%s): it gets back up." % why_not_dust)
	var status := icon_statuses.status_by_id(icon_id)
	if status:
		status.get_up.call_deferred()


func _forget(icon_id: String) -> FallenIcon:
	var fallen := _fallen[icon_id]
	_fallen.erase(icon_id)
	_cells.erase(icon_id)
	_down_for.erase(icon_id)
	return fallen


## -1 if the sinner fighting the icon stands left of it, +1 right of it (or with no clash).
func _blow_from(icon_id: String, cell: Rect2i) -> int:
	var clash := clashes.clash_on(icon_id)
	if clash == null:
		return 1
	return -1 if clash.sinner.position.x < desktop.to_overlay(cell).get_center().x else 1
