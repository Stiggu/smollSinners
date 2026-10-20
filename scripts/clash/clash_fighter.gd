class_name ClashFighter
extends RefCounted
## One side of a clash: its skill, its coins and its badge. Coins land heads or tails one by
## one, and each heads adds that coin's power: power = base + the powers of the coins that
## came up heads.

## How a coin shows: tossed coins spin until they land; a coin lost in a clash round shows
## cracked (its back if it had landed tails) until the next round, then it's gone.
enum Face { UNFLIPPED, SPINNING, HEADS, TAILS, CRACKED_FRONT, CRACKED_BACK, GONE }

const LONG_AGO := -10.0  ## a clash time well before anything: nothing is still popping
const NO_SIN := "NONE"  ## a skill whose sin affinity has no colours
## The seven sin affinities: a desktop icon's skill takes one at random each clash.
const SINS: Array[String] = ["CRIMSON", "SCARLET", "AMBER", "SHAMROCK", "AZURE", "INDIGO", "VIOLET"]

var skill_name := ""  ## on the badge's ribbon
var sin := NO_SIN  ## the skill's sin affinity, e.g. "SCARLET"
var art: Texture2D  ## the skill's art inside the badge, or null
var attack := "blunt"  ## "slash", "pierce" or "blunt"
## How well the other side takes this fighter's attack: the badge's attack icon shows it.
var attack_level := UnitStatus.ResistLevel.NORMAL
var base_power := 0
var coin_powers: Array[int] = []  ## per coin; negative for coins that subtract
var coins_left := 0  ## losing a clash round breaks the last one
## Per coin, lost ones too: coins break from the end, so those from coins_left on are lost.
var faces: Array[Face] = []
var flipped_at: Array[float] = []  ## per coin: when it last flipped or cracked (it pops)
var spun_at := LONG_AGO  ## when the coins were tossed (they spin until each lands)
var power := 0  ## shown on the badge
var power_changed_at := LONG_AGO  ## (it pops)
var appeared_at := LONG_AGO  ## when its badge flipped in
var shown := false  ## its badge is up
var badge: ClashBadge


static func for_skill(skill: SkillData, skill_art: Texture2D) -> ClashFighter:
	var fighter := ClashFighter.new()
	fighter.skill_name = skill.name
	fighter.sin = skill.affinity if ClashBadge.has_sin_colour(skill.affinity) else NO_SIN
	fighter.art = skill_art
	fighter.attack = skill.attack
	fighter.base_power = skill.base_power
	fighter._set_coins(skill.coin_powers)
	return fighter


## A desktop icon's side: its made-up skill (see IconStats), named after the icon, in a random sin and attack type.
static func for_icon(icon: DesktopIcon) -> ClashFighter:
	var fighter := ClashFighter.new()
	fighter.skill_name = icon.short_name()
	fighter.sin = SINS.pick_random()
	fighter.attack = IconStats.ATTACKS.pick_random()
	var stats := IconStats.of(fighter.skill_name)
	fighter.base_power = stats.base_power
	fighter._set_coins(stats.coin_powers)
	return fighter


## The coins left back to unflipped, the lost ones gone, and the power back to base (which
## pops in again).
func reset(now: float) -> void:
	faces.resize(coin_powers.size())
	flipped_at.resize(coin_powers.size())
	for i in faces.size():
		faces[i] = Face.UNFLIPPED if i < coins_left else Face.GONE
		flipped_at[i] = LONG_AGO
	power = base_power
	power_changed_at = now


## Toss the coins left: they spin until flip() lands each.
func toss(now: float) -> void:
	spun_at = now
	for i in coins_left:
		faces[i] = Face.SPINNING


## Flip coin i; heads adds its power. Returns whether it came up heads.
func flip(i: int, now: float, heads_chance: float) -> bool:
	var heads := randf() < heads_chance
	faces[i] = Face.HEADS if heads else Face.TAILS
	flipped_at[i] = now
	if heads:
		power = maxi(power + coin_powers[i], 0)
		power_changed_at = now
	return heads


## More tails than heads so far: the game greys the badge out.
func is_greyed_out() -> bool:
	return faces.count(Face.TAILS) > faces.count(Face.HEADS)


## The last coin left breaks at clash time `now`: cracked in its slot until the next reset().
func break_last_coin(now: float) -> void:
	coins_left -= 1
	faces[coins_left] = Face.CRACKED_BACK if faces[coins_left] == Face.TAILS else Face.CRACKED_FRONT
	flipped_at[coins_left] = now


## Its first coin's power, shown on the badge's +N tab.
func first_coin_power() -> int:
	return coin_powers[0] if not coin_powers.is_empty() else 0


func _set_coins(powers: Array[int]) -> void:
	coin_powers = powers
	coins_left = powers.size()
	reset(LONG_AGO)
