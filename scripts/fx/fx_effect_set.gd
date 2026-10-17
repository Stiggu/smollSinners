class_name FxEffectSet
extends RefCounted
## An identity's effects as tools/extract_effects.py exports them (its fx.json): each effect by
## its path in the prefab (as the timelines' cues name it), and the character's centre point,
## which effects placed on "the caster's centre" go from.

## The game's usual centre point (1.1 units above the feet), for an identity without fx.json.
const DEFAULT_BODY_CENTER := Vector2(0, 66)

var body_center := DEFAULT_BODY_CENTER  ## px from the feet, x forward, y up
var effects: Dictionary[String, FxEffectDef] = {}


## The set in an fx.json; an empty one if the file isn't there.
static func load_from(path: String) -> FxEffectSet:
	var effect_set := FxEffectSet.new()
	if not FileAccess.file_exists(path):
		return effect_set
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var center: Array = data.get("body_center", [DEFAULT_BODY_CENTER.x, DEFAULT_BODY_CENTER.y])
	effect_set.body_center = Vector2(center[0], center[1])
	var by_path: Dictionary = data.get("effects", {})
	for path_in_prefab: String in by_path:
		effect_set.effects[path_in_prefab] = FxEffectDef.from_json(by_path[path_in_prefab])
	return effect_set
