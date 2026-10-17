class_name IconKnockback
extends Node
## Moves a clash's real desktop icon: knocked back one grid cell per hop through free cells,
## and later hopped home, the last hop landing exactly where it started. If the clash is
## freed while the icon is away (the app quitting), it's put straight back.

const KNOCK_HOP_SECONDS := 0.07  ## per grid cell while knocked back
const HOME_HOP_SECONDS := 0.28  ## per grid cell on the way home

var _desktop: Desktop
var _icon: DesktopIcon
var _home: Vector2i  ## the icon image's top-left before the clash, screen pixels
var _now_at: Vector2i  ## where it was last sent
var _cell: Vector2i  ## the desktop grid's cell: the step an icon moves by


func track(desktop: Desktop, icon: DesktopIcon) -> void:
	_desktop = desktop
	_icon = icon
	_home = icon.rect.position
	_now_at = _home
	_cell = desktop.grid_spacing()


## The icon's centre where it is now, in overlay coordinates.
func icon_center() -> Vector2:
	return _desktop.to_overlay(Rect2i(_now_at, _icon.rect.size)).get_center()


func is_away() -> bool:
	return _now_at != _home


## Knock the icon `cells` grid cells away, hop by hop: away from the sinner (standing on
## sinner_side, +1 right) if there's room, otherwise down, otherwise up (icons often sit in
## full columns against the screen edge). Returns false, and doesn't move it, when it's
## boxed in.
func knock_back(cells: int, sinner_side: int) -> bool:
	var path := _free_path(cells, [Vector2i(-sinner_side, 0), Vector2i.DOWN, Vector2i.UP])
	if path.is_empty():
		return false
	_hop_along(path)
	return true


## Hop back one grid cell at a time.
func go_home() -> void:
	while is_away():
		var to_home := _home - _now_at
		if absi(to_home.x) <= _cell.x and absi(to_home.y) <= _cell.y:
			_now_at = _home
		else:
			_now_at += to_home.clamp(-_cell, _cell)
		_desktop.move_icon(_icon, _now_at)
		await get_tree().create_timer(HOME_HOP_SECONDS).timeout


## Quitting mid-clash: put the icon straight back where it was.
func _exit_tree() -> void:
	if _icon and is_away():
		_desktop.move_icon(_icon, _home)


func _hop_along(path: Array[Vector2i]) -> void:
	for cell in path:
		_now_at = cell
		_desktop.move_icon(_icon, _now_at)
		await get_tree().create_timer(KNOCK_HOP_SECONDS).timeout


## The free cells the icon would hop through, in the first direction that has any.
func _free_path(cells: int, directions: Array[Vector2i]) -> Array[Vector2i]:
	var screen := _desktop.overlay_area()
	var taken := _cells_taken_by_other_icons()
	for direction in directions:
		var path: Array[Vector2i] = []
		var at := _now_at
		for i in cells:
			at += direction * _cell
			if not screen.encloses(Rect2i(at, _icon.rect.size)) or _is_taken(at, taken):
				break
			path.append(at)
		if not path.is_empty():
			return path
	return []


func _cells_taken_by_other_icons() -> Array[Vector2i]:
	var taken: Array[Vector2i] = []
	for other in _desktop.icons:
		if other.id != _icon.id:
			taken.append(other.rect.position)
	return taken


## Whether an icon sits within half a cell of `at`.
func _is_taken(at: Vector2i, taken: Array[Vector2i]) -> bool:
	for other in taken:
		if absi(other.x - at.x) * 2 < _cell.x and absi(other.y - at.y) * 2 < _cell.y:
			return true
	return false
