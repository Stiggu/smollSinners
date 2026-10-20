class_name IdentityData
extends RefCounted
## One identity as tools/export_godot.py exports it, in its folder under IdentityLibrary.ROOT
## (e.g. yisang/10101_Base/): identity.json (names, skills, sprite anchors, animation clips,
## battle stats), poses/<pose>.png, skills/<slot>.png, and fx.json once
## tools/extract_effects.py has exported its particle effects.

## The game's names for the clips that hold a single pose.
const CLIP_IDLE := "Default"
const CLIP_MOVE := "Move"
const CLIP_GUARD := "Guard"
const CLIP_HURT := "Damaged"
const CLIP_DEAD := "Dead"

var path := ""  ## "<sinner>/<folder>", see IdentityLibrary
var id := ""  ## the game's id, e.g. "10101"
var title := ""  ## e.g. "LCB Sinner"
## HP, stagger thresholds, resistances and Sanity rules (identity.json "battle"): see UnitStatus.
var battle_stats: Dictionary = {}
var skills: Dictionary[String, SkillData] = {}  ## by slot: "S1", "S2", ...
## The game plays one of these for a clash round's strike; may be empty.
var parry_timelines: Array[Timeline] = []
var afterimages: AfterimageSettings  ## the copy it leaves as each attack starts; null: none

var _dir := ""
var _poses: Dictionary[String, PoseSprite] = {}
var _clips: Dictionary[String, Timeline] = {}
var _effects := FxEffectSet.new()


static func load_from(identity_dir: String, identity_path: String) -> IdentityData:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(identity_dir.path_join("identity.json")))
	var identity := IdentityData.new()
	identity.path = identity_path
	identity._dir = identity_dir
	identity.id = str(int(data.id))
	identity.title = data.title
	identity.battle_stats = data.get("battle", {})
	for pose_name: String in data.sprites:
		var texture: Texture2D = load("%s/poses/%s.png" % [identity_dir, pose_name])
		identity._poses[pose_name] = PoseSprite.new(texture, data.sprites[pose_name].anchor)
	for clip_name: String in data.clips:
		identity._clips[clip_name] = Timeline.from_json(data.clips[clip_name])
	for slot: String in data.skills:
		identity.skills[slot] = SkillData.from_json(slot, data.skills[slot])
	for parry: Dictionary in data.get("parry", []):
		identity.parry_timelines.append(Timeline.from_json(parry))
	identity.afterimages = AfterimageSettings.from_json(data.get("afterimages"))
	identity._effects = FxEffectSet.load_from(identity_dir.path_join("fx.json"))
	return identity


## A sprite by name; null for null (a key that hides the body) or a name it doesn't have.
func pose(pose_name: Variant) -> PoseSprite:
	return _poses.get(pose_name) if pose_name is String else null


## A clip by name, or the idle one if it has none by that name.
func clip(clip_name: String) -> Timeline:
	return _clips.get(clip_name, _clips[CLIP_IDLE])


## The pose a single-pose clip shows, e.g. "Default" -> "idle". Sprite names differ per
## identity, so states look poses up through the clips rather than by name.
func clip_pose(clip_name: String) -> Variant:
	return clip(clip_name).first_visible_pose()


## The clip a skill slot plays as a whole: the one its data names, else the slot's own.
func skill_clip(slot: String) -> Timeline:
	var skill: SkillData = skills.get(slot)
	if skill and _clips.has(skill.motion):
		return _clips[skill.motion]
	return clip(slot)


## A skill slot picked by weight (copies in the identity's deck: S1 comes up most).
func random_skill_slot() -> String:
	var weights := {}
	for slot in skills:
		weights[slot] = skills[slot].weight
	return RandomPick.weighted(weights)


## The skill's art for the clash badge, or null.
func skill_art(slot: String) -> Texture2D:
	var art_path := "%s/skills/%s.png" % [_dir, slot]
	return load(art_path) if ResourceLoader.exists(art_path) else null


## One of the game's particle effects by its path in the prefab, or null if it isn't exported.
func effect(effect_path: String) -> FxEffectDef:
	return _effects.effects.get(effect_path)


## The character's centre point (the game's CharacterCenterPoint): px from its feet, x
## forward, y up. Effects placed on the caster's centre go from here.
func body_center() -> Vector2:
	return _effects.body_center
