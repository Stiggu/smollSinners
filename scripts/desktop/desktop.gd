class_name Desktop
extends Node
## The Windows desktop behind the overlay, through the WinGlue autoload: its icons (re-read
## every POLL_SECONDS while the game runs), the icon grid, moving icons, and how much of the
## desktop shows. With fake_icons on it reports made-up icons instead of the real ones, so
## clashes can be tried without moving anything on the user's desktop.

const POLL_SECONDS := 0.5
## The icon grid's spacing until Explorer has been read (Windows' default at 100% scale).
const FALLBACK_GRID := Vector2i(75, 99)
## Made-up icons for testing, as fractions of the overlay: far enough from the edges for a
## clash to fit around them.
const FAKE_ICON_SPOTS: Array[Vector2] = [Vector2(0.2, 0.4), Vector2(0.73, 0.4)]
const FAKE_ICON_SIZE := Vector2i(48, 48)
const FAKE_ID_PREFIX := "fake://"  ## no real icon has an id like this, so moves are ignored

## Desktop icons as last read.
var icons: Array[DesktopIcon] = []
var fake_icons := false
## While true the icons aren't re-read (nothing shows, so nobody needs them).
var paused := false:
	set(value):
		paused = value
		WinGlue.SetDesktopIconsPaused(value)

var _until_poll := 0.0


func _process(delta: float) -> void:
	_until_poll -= delta
	if _until_poll <= 0.0:
		_until_poll = POLL_SECONDS
		icons = _read_icons()


## The desktop grid's cell size: the step an icon moves by.
func grid_spacing() -> Vector2i:
	return WinGlue.GetDesktopLayout().get("spacing", FALLBACK_GRID)


## Move an icon so its image's top-left is at `top_left` (screen pixels). Asynchronous.
func move_icon(icon: DesktopIcon, top_left: Vector2i) -> void:
	WinGlue.MoveDesktopIcon(icon.id, top_left)


## How much of a screen area shows the desktop, 0 to 1: the part no other app's window covers.
func uncovered_fraction(area: Rect2i) -> float:
	return WinGlue.DesktopUncoveredFraction(area)


## A screen rect in the overlay's coordinates.
func to_overlay(screen_rect: Rect2i) -> Rect2:
	return Rect2(Vector2(screen_rect.position - get_window().position), Vector2(screen_rect.size))


## The screen area the overlay covers.
func overlay_area() -> Rect2i:
	return Rect2i(get_window().position, get_window().size)


func _read_icons() -> Array[DesktopIcon]:
	var found: Array[DesktopIcon] = []
	if fake_icons:
		found.assign(_made_up_icons())
		return found
	for data: Dictionary in WinGlue.GetDesktopIcons():
		found.append(DesktopIcon.from_win_glue(data))
	return found


func _made_up_icons() -> Array[DesktopIcon]:
	var made_up: Array[DesktopIcon] = []
	var area := overlay_area()
	for i in FAKE_ICON_SPOTS.size():
		var icon := DesktopIcon.new()
		icon.name = "Fake icon %d" % (i + 1)
		icon.id = FAKE_ID_PREFIX + icon.name
		icon.rect = Rect2i(area.position + Vector2i(Vector2(area.size) * FAKE_ICON_SPOTS[i]), FAKE_ICON_SIZE)
		made_up.append(icon)
	return made_up
