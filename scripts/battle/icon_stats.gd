class_name IconStats
extends RefCounted
## A desktop icon's skill, HP, stagger thresholds and resistances, made up from its name.

## Each skill stat comes from its own slice of the name's hash.
enum SkillStat { BASE_POWER, COIN_COUNT, COIN_POWER }

const BASE_POWERS := [3, 4, 5, 6]
const COIN_COUNTS := [1, 2, 3]
const COIN_POWERS := [2, 3, 4, 5]
const ATTACKS := ["slash", "pierce", "blunt"]
const BITS_PER_SKILL_STAT := 4  ## the size of each SkillStat's slice of the hash

const HP_STEP := 5
const HP_STEPS := Vector2i(9, 15)  ## max HP is HP_STEP times this many, at least and at most
## Its stagger thresholds, as % of max HP: one of these sets.
const STAGGER_SETS: Array[Array] = [[50.0], [65.0, 30.0], [70.0, 40.0, 15.0]]
## Damage multipliers: one attack type hurts more (Weak, Fatal), one less (Endure, Ineff.).
const WEAK_TO: Array[float] = [1.5, 2.0]
const RESISTS: Array[float] = [0.75, 0.5]
const NORMAL := 1.0

## Debug: every icon's max HP, when above 0 (see LaunchOptions).
static var forced_max_hp := 0

var base_power := 0
var coin_powers: Array[int] = []
## For UnitStatus: "hp", "stagger" (% of max HP) and "resist" (multiplier per attack type).
var battle: Dictionary = {}


## The stats of the icon with this shown name.
static func of(icon_name: String) -> IconStats:
	var stats := IconStats.new()
	var name_hash := absi(icon_name.hash())
	stats.base_power = _skill_stat(name_hash, SkillStat.BASE_POWER, BASE_POWERS)
	var coin_power: int = _skill_stat(name_hash, SkillStat.COIN_POWER, COIN_POWERS)
	for i in _skill_stat(name_hash, SkillStat.COIN_COUNT, COIN_COUNTS):
		stats.coin_powers.append(coin_power)
	stats.battle = _battle_stats(name_hash)
	return stats


static func _skill_stat(name_hash: int, stat: SkillStat, options: Array) -> Variant:
	return options[(name_hash >> (stat * BITS_PER_SKILL_STAT)) % options.size()]


static func _battle_stats(name_hash: int) -> Dictionary:
	var dice := RandomNumberGenerator.new()
	dice.seed = name_hash
	var hp := HP_STEP * dice.randi_range(HP_STEPS.x, HP_STEPS.y)
	var stagger: Array = STAGGER_SETS[dice.randi() % STAGGER_SETS.size()]
	var attack_types := _shuffled(ATTACKS, dice)
	return {
		"hp": forced_max_hp if forced_max_hp > 0 else hp,
		"stagger": stagger,
		"resist": {
			attack_types[0]: WEAK_TO[dice.randi() % WEAK_TO.size()],
			attack_types[1]: RESISTS[dice.randi() % RESISTS.size()],
			attack_types[2]: NORMAL,
		},
	}


## A copy of `items` in an order the dice pick.
static func _shuffled(items: Array, dice: RandomNumberGenerator) -> Array:
	var left := items.duplicate()
	var order := []
	while not left.is_empty():
		order.append(left.pop_at(dice.randi() % left.size()))
	return order
