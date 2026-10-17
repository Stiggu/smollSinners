class_name PoseSprite
extends RefCounted
## One of an identity's sprites: a body pose or a slash, with its anchor (the pixel that
## sits on the sinner's feet).

## Only pixels at least this opaque count as the top of the head.
const CROWN_MIN_ALPHA := 0.5
## Columns checked per row when looking for the top of the head: every other one is plenty.
const CROWN_SCAN_STEP := 2

var texture: Texture2D
var anchor: Vector2
var _crown := Vector2.INF  ## measured on first use
var _reach := INF  ## measured on first use


func _init(p_texture: Texture2D, p_anchor: Array) -> void:
	texture = p_texture
	anchor = Vector2(p_anchor[0], p_anchor[1])


## How far its visible pixels reach sideways from the anchor, on whichever side reaches
## further (the sprite is mirrored when facing left).
func reach() -> float:
	if _reach == INF:
		_reach = _find_reach()
	return _reach


## The topmost visible point of the sprite, from its anchor (unflipped). Line effects start
## there: the game places them by scripts it doesn't ship, and the one met so far (R Corp's
## mind lightning) leaps from the Reindeer's antlers.
func crown() -> Vector2:
	if _crown == Vector2.INF:
		_crown = _find_crown()
	return _crown


func _find_crown() -> Vector2:
	var image := texture.get_image()
	image.decompress()
	for y in image.get_height():
		for x in range(0, image.get_width(), CROWN_SCAN_STEP):
			if image.get_pixel(x, y).a > CROWN_MIN_ALPHA:
				return Vector2(x, y) - anchor
	return Vector2(0, -anchor.y)


func _find_reach() -> float:
	var image := texture.get_image()
	image.decompress()
	var drawn := image.get_used_rect()
	return maxf(anchor.x - drawn.position.x, drawn.end.x - anchor.x)
