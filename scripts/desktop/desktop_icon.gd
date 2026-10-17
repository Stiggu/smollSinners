class_name DesktopIcon
extends RefCounted
## One icon on the Windows desktop, as WinGlue reads it from Explorer.

## Longer names are cut short on a clash badge's ribbon, or it would reach across half the screen.
const MAX_SHOWN_NAME := 16
## A file extension at most this long is dropped from the shown name ("notes.txt" -> "notes").
const MAX_EXTENSION := 4

var id := ""  ## unique per icon: its full parsing path
var name := ""
var rect := Rect2i()  ## the icon's image (not its label), in screen pixels
var visible := true  ## no window covers its centre


static func from_win_glue(data: Dictionary) -> DesktopIcon:
	var icon := DesktopIcon.new()
	icon.id = data.id
	icon.name = data.name
	icon.rect = data.rect
	icon.visible = data.visible
	return icon


## The name as a clash badge shows it.
func short_name() -> String:
	var stem := name.get_basename() if name.get_extension().length() <= MAX_EXTENSION else name
	return stem if stem.length() <= MAX_SHOWN_NAME else stem.left(MAX_SHOWN_NAME - 1) + "…"
