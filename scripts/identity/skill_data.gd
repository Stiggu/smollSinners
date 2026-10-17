class_name SkillData
extends RefCounted
## One of an identity's skills (S1, S2, S3...), as tools/export_godot.py exports it.

var slot := ""  ## "S1", "S2", ...
var name := ""  ## shown on the clash badge's ribbon
var affinity := "NONE"  ## its sin, e.g. "SCARLET"
var attack := "blunt"  ## "slash", "pierce" or "blunt"
var base_power := 0
var coin_powers: Array[int] = []  ## per coin; negative for coins that subtract
var weight := 1.0  ## copies in the identity's deck: how often it comes up
var motion := ""  ## the clip that animates it as a whole
var coin_timelines: Array[Timeline] = []  ## the game's own per-coin timelines; may be empty


static func from_json(skill_slot: String, data: Dictionary) -> SkillData:
	var skill := SkillData.new()
	skill.slot = skill_slot
	skill.name = data.get("name", "")
	skill.affinity = data.get("affinity", "NONE")
	skill.attack = data.get("attack", "blunt")
	skill.base_power = int(data.base)  # JSON numbers arrive as floats
	for power: float in data.coins:
		skill.coin_powers.append(int(power))
	skill.weight = data.weight
	skill.motion = data.get("motion", skill_slot)
	for timeline: Dictionary in data.get("timelines", []):
		skill.coin_timelines.append(Timeline.from_json(timeline))
	return skill


func coin_count() -> int:
	return coin_powers.size()


## Whether the game choreographs it coin by coin (see SkillPerformance).
func has_coin_timelines() -> bool:
	return not coin_timelines.is_empty()
