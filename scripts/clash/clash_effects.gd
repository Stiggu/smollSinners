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
## Back-to-back damage numbers scatter this much, so they don't sit on top of each other.
const DAMAGE_SCATTER := Rect2(-14, -10, 28, 16)

var glow_stage: FxStage  ## where damage numbers glow; unset: drawn here, without bloom


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


## A hit's damage from the attacker's skill, scattered a little (see DamageNumber.show_hit()).
func damage(at: Vector2, amount: int, attacker: ClashFighter, staggered := false) -> void:
	var spot := at + DAMAGE_SCATTER.position + DAMAGE_SCATTER.size * Vector2(randf(), randf())
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


func _spawn(scene: PackedScene, at: Vector2) -> Node2D:
	var effect: Node2D = scene.instantiate()
	effect.position = at
	add_child(effect)
	return effect
