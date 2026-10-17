class_name ClashFighter
extends RefCounted
## One side of a clash: its skill, its coins and its badge. Coins land heads or tails one by
## one, and each heads adds that coin's power: power = base + the powers of the coins that
## came up heads.

## How a coin shows: a coin lost in a clash round stays in its slot cracked, its front up, or
## its back if it had landed tails.
enum Face { UNFLIPPED, HEADS, TAILS, CRACKED_FRONT, CRACKED_BACK }
## Each of an icon's stats comes from its own slice of its name's hash.
enum IconStat { BASE_POWER, COIN_COUNT, COIN_POWER, ATTACK }

const LONG_AGO := -10.0  ## a clash time well before anything: nothing is still popping

## Desktop icons get their stats from their name's hash, so an icon always fights the same
## way; about the range of a sinner's early skills.
const ICON_BASE_POWERS := [3, 4, 5, 6]
const ICON_COIN_COUNTS := [1, 2, 3]
const ICON_COIN_POWERS := [2, 3, 4, 5]
const ICON_ATTACKS := ["slash", "pierce", "blunt"]
const BITS_PER_ICON_STAT := 4  ## the size of each IconStat's slice of the hash
const ICON_SIN := "NONE"  ## desktop icons have no sin affinity

var skill_name := ""  ## on the badge's ribbon
var sin := ICON_SIN  ## the skill's sin affinity, e.g. "SCARLET"
var art: Texture2D  ## the skill's art inside the badge, or null
var attack := "blunt"  ## "slash", "pierce" or "blunt"
## How well the other side takes this fighter's attack: the badge's attack icon shows it.
var attack_level := UnitStatus.ResistLevel.NORMAL
var base_power := 0
var coin_powers: Array[int] = []  ## per coin; negative for coins that subtract
var coins_left := 0  ## losing a clash round breaks the last one
## Per coin, cracked ones too: coins break from the end, so those from coins_left on are cracked.
var faces: Array[Face] = []
var flipped_at: Array[float] = []  ## per coin: when it last flipped or cracked (it pops)
var power := 0  ## shown on the badge
var power_changed_at := LONG_AGO  ## (it pops)
var appeared_at := LONG_AGO  ## when its badge flipped in
var shown := false  ## its badge is up
var badge: ClashBadge


static func for_skill(skill: SkillData, skill_art: Texture2D) -> ClashFighter:
	var fighter := ClashFighter.new()
	fighter.skill_name = skill.name
	fighter.sin = skill.affinity if ClashBadge.has_sin_colour(skill.affinity) else ICON_SIN
	fighter.art = skill_art
	fighter.attack = skill.attack
	fighter.base_power = skill.base_power
	fighter._set_coins(skill.coin_powers)
	return fighter


static func for_icon(icon: DesktopIcon) -> ClashFighter:
	var fighter := ClashFighter.new()
	fighter.skill_name = icon.short_name()
	var name_hash := absi(fighter.skill_name.hash())
	fighter.base_power = _icon_stat(name_hash, IconStat.BASE_POWER, ICON_BASE_POWERS)
	var coin_count: int = _icon_stat(name_hash, IconStat.COIN_COUNT, ICON_COIN_COUNTS)
	var coin_power: int = _icon_stat(name_hash, IconStat.COIN_POWER, ICON_COIN_POWERS)
	fighter.attack = _icon_stat(name_hash, IconStat.ATTACK, ICON_ATTACKS)
	var powers: Array[int] = []
	for i in coin_count:
		powers.append(coin_power)
	fighter._set_coins(powers)
	return fighter


static func _icon_stat(name_hash: int, stat: IconStat, options: Array) -> Variant:
	return options[(name_hash >> (stat * BITS_PER_ICON_STAT)) % options.size()]


## The coins left back to unflipped and the power back to base (which pops in again).
func reset(now: float) -> void:
	faces.resize(coin_powers.size())
	flipped_at.resize(coin_powers.size())
	for i in coins_left:
		faces[i] = Face.UNFLIPPED
		flipped_at[i] = LONG_AGO
	power = base_power
	power_changed_at = now


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


## The last coin left breaks at clash time `now`; it stays in its slot, cracked.
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
