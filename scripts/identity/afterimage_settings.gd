class_name AfterimageSettings
extends RefCounted
## The faint copy an identity leaves where each attack starts (identity.json "afterimages",
## from the game's CharacterAppearanceTrail).

var keep_seconds := 1.5  ## each copy fades out over this long
var has_own_color := false  ## false: the game's default trail colour
var color := Color.WHITE  ## HDR; only with has_own_color


## The settings in identity.json, or null for an identity that leaves none.
static func from_json(data: Variant) -> AfterimageSettings:
	if not data is Dictionary:
		return null
	var settings := AfterimageSettings.new()
	settings.keep_seconds = data.keep_seconds
	if data.color is Array:
		var rgb: Array = data.color
		settings.has_own_color = true
		settings.color = Color(rgb[0], rgb[1], rgb[2])
	return settings
