class_name ClashEffects
extends Node2D
## The clash's flashes, sparks and numbers. Each is a scene under scenes/clash/effects/ that
## plays once and frees itself; this places them.

const IMPACT := preload("res://scenes/clash/effects/impact_burst.tscn")
const HIT := preload("res://scenes/clash/effects/hit_spark.tscn")
const HEADS_STAR := preload("res://scenes/clash/effects/heads_star.tscn")
const CLASH_COUNT := preload("res://scenes/clash/effects/clash_count.tscn")
const DAMAGE_NUMBER := preload("res://scenes/clash/effects/damage_number.tscn")
const ICON_FLASH := preload("res://scenes/clash/effects/icon_flash.tscn")

const ICON_FLASH_MARGIN := 4.0  ## px the white flash spills past the icon
## Damage numbers land anywhere this far (px, either way) around the spot above the unit hit.
const DAMAGE_SPREAD := Vector2(60, 40)
## Of this many random spots, a number takes the one furthest from the last few numbers.
const DAMAGE_SPOT_TRIES := 8
const DAMAGE_SPOTS_REMEMBERED := 4

var glow_stage: FxStage  ## where damage numbers glow; unset: drawn here, without bloom

var _recent_damage_spots: Array[Vector2] = []


## The blast where the coins clash, its swoosh coming from swoosh_from (-1 left, 1 right,
## 0 none).
func impact(at: Vector2, swoosh_from := 0) -> void:
	var burst: ImpactBurst = _spawn(IMPACT, at)
	burst.swoosh_from = swoosh_from


## A smaller blast where a hit lands.
func hit(at: Vector2) -> void:
	_spawn(HIT, at)


## The sparkle by a badge when a coin lands heads.
func heads_star(at: Vector2) -> void:
	_spawn(HEADS_STAR, at)


## Which clash round this was, "N합" in brush strokes on ink.
func clash_count(at: Vector2, round_number: int) -> void:
	var count: ClashCount = _spawn(CLASH_COUNT, at)
	count.show_round(round_number)


## A hit's damage from the attacker's skill, somewhere around `at` (see DamageNumber.show_hit()).
func damage(at: Vector2, amount: int, attacker: ClashFighter, staggered := false) -> void:
	var spot := _damage_spot(at)
	var number: DamageNumber
	if glow_stage:
		number = DAMAGE_NUMBER.instantiate()
		number.position = to_global(spot)
		glow_stage.add_glowing(number)
	else:
		number = _spawn(DAMAGE_NUMBER, spot)
	number.show_hit(amount, attacker, staggered)


## The icon flashing white as it's hit.
func icon_flash(icon_rect: Rect2) -> void:
	var flash: Control = ICON_FLASH.instantiate()
	var area := icon_rect.grow(ICON_FLASH_MARGIN)
	flash.position = area.position
	flash.size = area.size
	add_child(flash)


## A random spot around `around`, kept clear of the last few numbers where it can be.
func _damage_spot(around: Vector2) -> Vector2:
	var best := around
	var best_gap := -1.0
	for _try in DAMAGE_SPOT_TRIES:
		var spot := around + DAMAGE_SPREAD * Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		var gap := INF
		for recent in _recent_damage_spots:
			gap = minf(gap, spot.distance_to(recent))
		if gap > best_gap:
			best = spot
			best_gap = gap
	_recent_damage_spots.append(best)
	if _recent_damage_spots.size() > DAMAGE_SPOTS_REMEMBERED:
		_recent_damage_spots.pop_front()
	return best


func _spawn(scene: PackedScene, at: Vector2) -> Node2D:
	var effect: Node2D = scene.instantiate()
	effect.position = at
	add_child(effect)
	return effect
