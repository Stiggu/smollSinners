class_name IconPatch
extends RefCounted
## Cuts a desktop icon's pixels out of a screen capture, and covers them with the wallpaper.

const ICON_FROM := 24.0  ## a pixel is the icon's when a colour channel is this far (0-255) from the wallpaper's
const COVER_GROW := 2  ## px a cover reaches past the icon's pixels, over their soft edges and shadows
const EDGE := 2  ## px border, never the icon's, where the wallpaper must match the screen
const EDGE_TOLERANCE := 8.0  ## mean colour difference (0-255) allowed on that border
const CHANNEL_LEVELS := 255.0


## Whether `wallpaper` looks like what the screen showed (`shown`) along the area's edge.
static func wallpaper_matches(shown: Image, wallpaper: Image) -> bool:
	var size := shown.get_size()
	var inner := Rect2i(Vector2i(EDGE, EDGE), size - Vector2i(EDGE, EDGE) * 2)
	var total := 0.0
	var count := 0
	for y in size.y:
		for x in size.x:
			if not inner.has_point(Vector2i(x, y)):
				total += _difference(shown.get_pixel(x, y), wallpaper.get_pixel(x, y))
				count += 1
	return count > 0 and total / count <= EDGE_TOLERANCE


## What the screen showed, see-through wherever it's the wallpaper.
static func icon_pixels(shown: Image, wallpaper: Image) -> Image:
	var pixels := shown.duplicate() as Image
	pixels.convert(Image.FORMAT_RGBA8)
	for y in pixels.get_height():
		for x in pixels.get_width():
			if _difference(shown.get_pixel(x, y), wallpaper.get_pixel(x, y)) < ICON_FROM:
				pixels.set_pixel(x, y, Color.TRANSPARENT)
	return pixels


## How far the screen is from the wallpaper on average around the icon's pixels (alpha 0).
static func colour_offset(shown: Image, wallpaper: Image, pixels: Image) -> Color:
	var covered := _grown(pixels)
	var total := Color(0.0, 0.0, 0.0, 0.0)
	var count := 0
	for y in shown.get_height():
		for x in shown.get_width():
			if not covered.get_bit(x, y):
				total += shown.get_pixel(x, y) - wallpaper.get_pixel(x, y)
				count += 1
	return total / count if count > 0 else Color(0.0, 0.0, 0.0, 0.0)


## The wallpaper, shifted by `offset`, over the icon's pixels and COVER_GROW around them.
static func cover(wallpaper: Image, pixels: Image, offset: Color) -> Image:
	var covered := _grown(pixels)
	var image := Image.create_empty(wallpaper.get_width(), wallpaper.get_height(), false, Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			if covered.get_bit(x, y):
				image.set_pixel(x, y, wallpaper.get_pixel(x, y) + offset)
	return image


static func _grown(pixels: Image) -> BitMap:
	var grown := BitMap.new()
	grown.create_from_image_alpha(pixels)
	grown.grow_mask(COVER_GROW, Rect2i(Vector2i.ZERO, grown.get_size()))
	return grown


## How far apart two colours are: their most different channel, 0-255.
static func _difference(a: Color, b: Color) -> float:
	return maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b))) * CHANNEL_LEVELS
