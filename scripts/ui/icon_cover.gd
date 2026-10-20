class_name IconCover
extends Sprite2D
## Hides part of a desktop icon (its name, its picture) with the wallpaper; can redraw it on top through a material.

## Part of an icon as read off the screen once: its pixels, and how far the wallpaper was off there.
class Look:
	var pixels: Image
	var offset: Color

var _desktop: Desktop
var _look: Look
var _area := Rect2i()  ## where it covers now, screen pixels


## Read the icon in `area` (screen pixels); null if the wallpaper isn't ready or doesn't match there.
static func read(area: Rect2i, desktop: Desktop) -> Look:
	var wallpaper := desktop.wallpaper.patch(area)
	if wallpaper == null or not area.has_area():
		return null
	var shown: Image = WinGlue.CaptureScreen(area)
	if not IconPatch.wallpaper_matches(shown, wallpaper):
		return null
	var look := Look.new()
	look.pixels = IconPatch.icon_pixels(shown, wallpaper)
	look.offset = IconPatch.colour_offset(shown, wallpaper, look.pixels)
	return look


## redrawn_through: if set, the icon's own pixels are drawn again over the cover through it.
func _init(desktop: Desktop, look: Look, redrawn_through: Material = null) -> void:
	_desktop = desktop
	_look = look
	centered = false
	if redrawn_through:
		var redrawn := Sprite2D.new()
		redrawn.centered = false
		redrawn.texture = ImageTexture.create_from_image(look.pixels)
		redrawn.material = redrawn_through
		add_child(redrawn)


## Cover the icon's part in `area` (screen pixels), wherever the icon is now.
func cover(area: Rect2i) -> void:
	position = _desktop.to_overlay(area).position
	if area == _area:
		return
	_area = area
	var wallpaper := _desktop.wallpaper.patch(area)
	visible = wallpaper != null and area.size == _look.pixels.get_size()
	if visible:
		texture = ImageTexture.create_from_image(IconPatch.cover(wallpaper, _look.pixels, _look.offset))
