extends Node
## Debug: saves what the overlay renders, cropped around the first sinner (and its clash), so
## changes can be checked without looking at the screen.
##   -- --capture-dir <folder> [--capture-every <seconds>]
## Frames are RGBA PNGs named by milliseconds since start, each with a .json saying where the
## sinner's feet are in the crop, which way it faces and what it's doing.

const START_AFTER := 0.5  ## seconds, so the first frame isn't the empty one
const AROUND_SINNER := Rect2(-220, -300, 440, 340)  ## from its feet
const AROUND_ICON := 260.0  ## px around a clash's icon

var dir := ""
var every := 0.25
var _next := START_AFTER
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	if _time < _next:
		return
	_next += every
	var overlay: Overlay = get_parent()
	if overlay.team.members.is_empty():
		return
	var sinner := overlay.team.members[0]
	var region := Rect2(sinner.position + AROUND_SINNER.position, AROUND_SINNER.size)
	var clash := overlay.clashes.clash_of(sinner)
	if clash and clash.icon:
		region = region.merge(overlay.desktop.to_overlay(clash.icon.rect).grow(AROUND_ICON))
	var image := get_viewport().get_texture().get_image()
	var crop := Rect2i(region.intersection(Rect2(Vector2.ZERO, image.get_size())))
	if not crop.has_area():
		return
	var path := "%s/%06d" % [dir, int(_time * 1000)]
	image.get_region(crop).save_png(path + ".png")
	var info := {"feet": [sinner.position.x - crop.position.x, sinner.position.y - crop.position.y],
			"facing": sinner.facing, "state": Sinner.State.keys()[sinner.state]}
	FileAccess.open(path + ".json", FileAccess.WRITE).store_string(JSON.stringify(info))
