class_name Clash
extends Node2D
## A Limbus-style clash between a sinner and a desktop icon (scenes/clash/clash.tscn), from
## the leap in to the icon hopping home. Each round both sides flip their coins one by one
## (power = base + heads × coin power) and the lower total breaks a coin, until one side has
## none left. The winner then hits once per coin it kept. The sinner's coins land heads
## (50 + Sanity)% of the time; the result moves its Sanity by the identity's rules, and the
## icon's hits cost it HP.
##
## Looks and timing follow the game (matches/PowerGuard.gif, matches/clash_count.png): badges
## flip in, numbers pop on every heads, a fiery impact with a red ring, the lost coin cracking
## in its slot, each round's count ("N합") between the badges, yellow damage numbers with the
## attack type. The badges are
## the game's (SkillAndCoinUI), each a ClashBadge. Lives on the overlay, so it draws in
## overlay coordinates. Steps: prepare(), then fits()/footprint() to choose an icon, start().

signal finished

## Debug: how the coins fall.
enum Outcome { BY_CHANCE, SINNER_WINS, SINNER_LOSES }

const BADGE_SCENE := preload("res://scenes/ui/clash_badge.tscn")
const ICON_HEADS_CHANCE := 0.5  ## desktop icons have no Sanity
const MAX_ROUNDS := 12  ## ties break no coin; stop a long streak of them
const SKIP_TO_END := 10.0  ## seconds: longer than any of its tweens
const LOG_ICON_NUMBERS := 1000  ## the log names icons by a short number, not by their file names

const LEAP_SPEED := 1800.0  ## px/s
const LEAP_SECONDS := Vector2(0.25, 0.7)  ## the leap in takes at least this long, at most that
const POWER_SHOWS_AFTER := 0.12  ## the power pops in once the badge has flipped in
const BADGES_SETTLE := 0.45  ## after the badges come up, before the first round

const WIND_UP_SECONDS := 0.3
const COIN_FLIP_SECONDS := 0.26  ## between one coin flip and the next
const BEFORE_STRIKE := 0.15
const RECOIL := 26.0  ## px the sinner rocks back as the coins clash
const RECOIL_SECONDS := Vector2(0.06, 0.14)  ## rocking back, and forward again
const IMPACT_TOWARD_LOSER := 0.3  ## the blast lands this much closer to the loser
const ROUND_AFTERMATH := 0.75  ## after an impact, before the next round's flips

const ICON_HIT_SECONDS := 0.35  ## between the icon's hits
const AFTER_ATTACKS := 0.3
const HOME_DELAY := 2.5  ## before a knocked-back icon starts hopping home
const WINNER_HOP := Vector2(250, -350)  ## the sinner hops off a win (x away from the icon)
const LOSER_THROW := Vector2(700, -600)  ## ... and is thrown off a loss
const WHOLE_CLIP_FIRST_HIT := 0.3  ## a skill clip with no strikes to find hits here
const WHOLE_CLIP_HIT_GAP := 0.1  ## at least this long between hits spread over a clip

const HEADS_STAR_OFFSET := Vector2(-20, -24)  ## from a badge's centre, by its power
## A round's count sits between the badges, this much of the way towards the round's winner
## (measured in matches/clash_count.png).
const COUNT_TOWARD_WINNER := 0.125
const ICON_DAMAGE_OFFSET := Vector2(10, -34)  ## the icon's damage, from its centre
const SINNER_DAMAGE_OFFSET := Vector2(20, -160)  ## the sinner's, from its feet (x away from the icon)
## Where the sinner's weapon meets the icon, from its feet (x towards the icon).
const SINNER_FRONT := Vector2(55, -95)

var sinner: Sinner
var icon: DesktopIcon
var area := Rect2()  ## the part of the overlay it takes up (see ClashLayout.footprint())
var verbose := false  ## print each step
var forced_skill := ""  ## debug: use this skill slot instead of a random one
var forced_outcome := Outcome.BY_CHANCE

var _desktop: Desktop
var _skill: SkillData
var _stand_off := ClashLayout.STAND_OFF  ## how far from the icon the skill wants the sinner (SkillReach)
var _you: ClashFighter  ## the sinner
var _foe: ClashFighter  ## the icon
var _layout: ClashLayout
var _side := 1  ## +1: the sinner is right of the icon
var _flipped_coin := -1  ## during the sinner's attack: the last coin flipped so far
var _aborted := false
var _tween: Tween
var _time := 0.0

@onready var _badges: Node2D = $Badges
@onready var _effects: ClashEffects = $Effects
@onready var _knockback: IconKnockback = $IconKnockback


## First step, once added to the overlay: picks the sinner's skill and makes its badge, so
## fits() and footprint() can measure a clash against each icon. The sinner itself isn't
## touched until start(); a clash that finds no icon is just freed.
func prepare(p_sinner: Sinner, desktop: Desktop) -> void:
	sinner = p_sinner
	_desktop = desktop
	var identity := sinner.identity
	var slot := forced_skill if identity.skills.has(forced_skill) else identity.random_skill_slot()
	_skill = identity.skills[slot]
	_stand_off = SkillReach.stand_off(identity, _skill, ClashLayout.STAND_OFF)
	_you = ClashFighter.for_skill(_skill, identity.skill_art(slot))
	_add_badge(_you)


## Whether a clash against this icon fits on the overlay just as laid out (see ClashLayout).
func fits(candidate: DesktopIcon) -> bool:
	return _layout_against(candidate).fits(get_viewport_rect().size, _you.badge.ribbon_end(),
			_you.badge.ribbon_end_for(candidate.short_name()))


## The part of the overlay a clash against this icon would take up.
func footprint(candidate: DesktopIcon) -> Rect2:
	return _layout_against(candidate).footprint(_you.badge.ribbon_end(),
			_you.badge.ribbon_end_for(candidate.short_name()))


## Fight this icon (one that fits()).
func start(target: DesktopIcon) -> void:
	icon = target
	area = footprint(target)
	_layout = _layout_against(target)
	_knockback.track(_desktop, target)
	sinner.interrupted.connect(_on_interrupted)
	_run()


func _process(delta: float) -> void:
	_time += delta
	for fighter: ClashFighter in [_you, _foe]:
		if fighter and fighter.badge:
			fighter.badge.visible = fighter.shown
			if fighter.shown:
				fighter.badge.show_state(fighter, _time)


func _run() -> void:
	sinner.begin_clash()
	_foe = ClashFighter.for_icon(icon)
	_foe.attack_level = sinner.status.resistance_level(_foe.attack)  # desktop icons resist nothing
	_add_badge(_foe)
	_log("%s (%s) vs icon #%d: %s %d%s against %d%s" % [sinner.identity.id, sinner.identity.title,
			icon.name.hash() % LOG_ICON_NUMBERS, _skill.slot, _you.base_power, _you.coin_powers, _foe.base_power, _foe.coin_powers])

	await _leap_in()
	var rounds := 0
	while not _aborted and _you.coins_left > 0 and _foe.coins_left > 0 and rounds < MAX_ROUNDS:
		rounds += 1
		await _clash_round(rounds)
	if not _aborted:
		await _finish(rounds)
	_you.shown = false
	_foe.shown = false
	if _knockback.is_away():
		await _wait(HOME_DELAY)
		await _knockback.go_home()
	_log("done%s" % [" (interrupted)" if _aborted else ""])
	finished.emit()
	queue_free()


## The winner attacks.
func _finish(rounds: int) -> void:
	var sinner_won := _you.coins_left >= _foe.coins_left
	sinner.status.clash_ended(sinner_won, rounds)
	if sinner_won:
		await _sinner_attacks()
	else:
		await _icon_attacks()


func _leap_in() -> void:
	_side = _layout.side
	sinner.face(_layout.feet)
	sinner.show_clip_pose(IdentityData.CLIP_MOVE)
	var seconds := clampf(sinner.position.distance_to(_layout.feet) / LEAP_SPEED, LEAP_SECONDS.x, LEAP_SECONDS.y)
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(sinner, "position", _layout.feet, seconds)
	await _tween.finished
	if _aborted:
		return
	sinner.facing = -_side
	sinner.show_clip_pose(IdentityData.CLIP_GUARD)
	_place_badges()
	await _wait(BADGES_SETTLE)


## Badges above each fighter, ribbons pointing away from each other; fits() made sure there's room.
func _place_badges() -> void:
	_you.badge.place(_layout.sinner_badge, _side)
	_foe.badge.place(_layout.icon_badge, -_side)
	for fighter: ClashFighter in [_you, _foe]:
		fighter.appeared_at = _time
		fighter.power_changed_at = _time + POWER_SHOWS_AFTER
		fighter.shown = true


func _clash_round(round_number: int) -> void:
	var skill_clip := sinner.identity.skill_clip(_skill.slot)
	sinner.show_pose(skill_clip.opening_pose())  # wind-up
	_you.reset(_time)
	_foe.reset(_time)
	await _wait(WIND_UP_SECONDS)
	if not await _flip_coins_together():
		return
	await _wait(BEFORE_STRIKE)
	if _aborted:
		return
	var recoil := _strike(skill_clip)
	_log("round: %d vs %d" % [_you.power, _foe.power])
	_break_the_weaker_coin(round_number)
	await recoil.finished
	if _aborted:
		return
	await _wait(ROUND_AFTERMATH)


## Coin by coin, both sides together; a heads pops the number with a little star. False if
## the clash was called off meanwhile.
func _flip_coins_together() -> bool:
	for i in maxi(_you.coins_left, _foe.coins_left):
		for fighter: ClashFighter in [_you, _foe]:
			if i < fighter.coins_left:
				_flip(fighter, i)
		await _wait(COIN_FLIP_SECONDS)
		if _aborted:
			return false
	return true


## The sinner strikes (the game's own clash strike if it has one) and rocks back. Returns the
## rocking tween.
func _strike(skill_clip: Timeline) -> Tween:
	if sinner.identity.parry_timelines.is_empty():
		sinner.show_pose(skill_clip.strike_pose())
	else:
		sinner.play_timeline(sinner.identity.parry_timelines.pick_random(), _icon_center)
	var feet := sinner.position
	_tween = create_tween()
	_tween.tween_property(sinner, "position", feet + Vector2(-_side * RECOIL, 0), RECOIL_SECONDS.x)
	_tween.tween_property(sinner, "position", feet, RECOIL_SECONDS.y)
	return _tween


## The lower power loses a coin, blasted on its side; a tie only blasts the middle. Either
## way the round's count pops up.
func _break_the_weaker_coin(round_number: int) -> void:
	var middle := (_sinner_front() + _icon_center()) / 2.0
	if _you.power == _foe.power:
		_effects.impact(middle)
		_effects.clash_count(_count_spot(null), round_number)
		return
	var icon_lost := _you.power > _foe.power
	var loser := _foe if icon_lost else _you
	var losing_side := _icon_center() if icon_lost else _sinner_front()
	_effects.impact(middle.lerp(losing_side, IMPACT_TOWARD_LOSER), -1 if icon_lost else 1)
	_effects.clash_count(_count_spot(_you if icon_lost else _foe), round_number)
	loser.break_last_coin(_time)
	if icon_lost:
		_effects.icon_flash(_icon_rect())
	else:
		sinner.show_clip_pose(IdentityData.CLIP_HURT)


## Where a round's count goes: between the badges, a little towards the round's winner (null
## for a tie).
func _count_spot(winner: ClashFighter) -> Vector2:
	var middle := (_you.badge.position + _foe.badge.position) / 2.0
	return middle if winner == null else middle.lerp(winner.badge.position, COUNT_TOWARD_WINNER)


## The winner flips each coin it kept as that coin's first hit lands; damage is the power so
## far. Each coin plays the game's timeline for it (see SkillPerformance): its slice of the
## animation, its moves (some skills dash through the target and strike back from the other
## side), its hits. The clash breaks coins from the end, so the ones kept are the first.
func _sinner_attacks() -> void:
	_foe.shown = false
	_you.reset(_time)
	if not _skill.has_coin_timelines():
		await _sinner_attacks_with_whole_clip()
		return
	_flipped_coin = -1
	var performance := sinner.perform_skill(_skill.slot, _you.coins_left, _icon_center)
	performance.hit_landed.connect(_on_coin_hit)
	var completed: bool = await performance.ended
	if not completed or _aborted:
		return
	await _wait(AFTER_ATTACKS)
	if not _aborted:
		_side = _sinner_side()
		sinner.end_clash(WINNER_HOP * Vector2(_side, 1))


func _on_coin_hit(coin: int, damage_ratio: float, is_final: bool) -> void:
	if _aborted:
		return
	if coin > _flipped_coin:  # the coin's first hit: flip it
		_flipped_coin = coin
		_flip(_you, coin)
	if damage_ratio > 0.0:
		_hit_icon(maxi(1, roundi(_you.power * damage_ratio)))
	if is_final:
		_side = _sinner_side()  # the knockback goes away from wherever the sinner ended up
		_knock_icon(_you.coins_left)


## Identities without the game's per-coin timelines: the skill's whole clip, the coins' hits
## spread over its strikes.
func _sinner_attacks_with_whole_clip() -> void:
	var length := sinner.play_skill_clip(_skill.slot)
	var hits := _spread_hits(sinner.identity.skill_clip(_skill.slot).strike_times(), _you.coins_left)
	var elapsed := 0.0
	for i in hits.size():
		await _wait(hits[i] - elapsed)
		elapsed = hits[i]
		if _aborted:
			return
		_flip(_you, i)
		_hit_icon(_you.power)
		if i == hits.size() - 1:
			_knock_icon(hits.size())
	await _wait(maxf(length - elapsed, 0.0) + AFTER_ATTACKS)
	if not _aborted:
		sinner.end_clash(WINNER_HOP * Vector2(_side, 1))


func _icon_attacks() -> void:
	_you.shown = false
	_foe.reset(_time)
	sinner.show_clip_pose(IdentityData.CLIP_GUARD)
	for i in _foe.coins_left:
		await _wait(ICON_HIT_SECONDS)
		if _aborted:
			return
		_flip(_foe, i)
		_effects.icon_flash(_icon_rect())
		_effects.hit(_sinner_front())
		var taken := sinner.status.take_hit(_foe.power, _foe.attack)  # after the identity's resistance
		_effects.damage(sinner.position + SINNER_DAMAGE_OFFSET * Vector2(_side, 1), taken, _foe.attack)
		sinner.show_clip_pose(IdentityData.CLIP_HURT)
		if sinner.status.is_dead():
			break
	await _wait(AFTER_ATTACKS)
	if not _aborted:
		sinner.end_clash(LOSER_THROW * Vector2(_side, 1))


## Flip one of a fighter's coins; a heads gets a star by its badge.
func _flip(fighter: ClashFighter, coin: int) -> void:
	if fighter.flip(coin, _time, _heads_chance(fighter)):
		_effects.heads_star(fighter.badge.position + HEADS_STAR_OFFSET)


func _hit_icon(damage: int) -> void:
	_effects.hit(_icon_center())
	_effects.icon_flash(_icon_rect())
	_effects.damage(_icon_center() + ICON_DAMAGE_OFFSET, damage, _you.attack)


func _knock_icon(cells: int) -> void:
	if _knockback.knock_back(cells, _side):
		_log("icon knocked back %d cells" % cells)
	else:
		_log("icon is boxed in, no knockback")
		_effects.impact(_icon_center())  # slammed against whatever is in the way


## The sinner's coins by its Sanity, an icon's by chance, or as a debug flag says.
func _heads_chance(fighter: ClashFighter) -> float:
	match forced_outcome:
		Outcome.SINNER_WINS:
			return 1.0 if fighter == _you else 0.0
		Outcome.SINNER_LOSES:
			return 0.0 if fighter == _you else 1.0
	return sinner.status.heads_chance() if fighter == _you else ICON_HEADS_CHANCE


func _on_interrupted() -> void:
	_aborted = true
	for fighter: ClashFighter in [_you, _foe]:
		if fighter:
			fighter.shown = false
	if _tween and _tween.is_valid():
		_tween.custom_step(SKIP_TO_END)  # finish it now, so the step awaiting it sees the abort


func _add_badge(fighter: ClashFighter) -> void:
	fighter.badge = BADGE_SCENE.instantiate()
	fighter.badge.visible = false
	_badges.add_child(fighter.badge)
	fighter.badge.show_fighter(fighter)


func _layout_against(candidate: DesktopIcon) -> ClashLayout:
	return ClashLayout.around(_desktop.to_overlay(candidate.rect), get_viewport_rect().size,
			sinner.floor_y(), sinner.badge_offset(), _stand_off)


func _icon_center() -> Vector2:
	return _knockback.icon_center()


func _icon_rect() -> Rect2:
	return Rect2(_icon_center() - Vector2(icon.rect.size) / 2.0, icon.rect.size)


## +1 when the sinner is right of the icon.
func _sinner_side() -> int:
	return 1 if sinner.position.x >= _icon_center().x else -1


func _sinner_front() -> Vector2:
	return sinner.position + SINNER_FRONT * Vector2(-_side, 1)


## Spread `coins` hits over a clip's strikes, the last coin on the last strike.
static func _spread_hits(strikes: Array[float], coins: int) -> Array[float]:
	if strikes.is_empty():
		strikes = [WHOLE_CLIP_FIRST_HIT]
	var times: Array[float] = []
	for i in coins:
		var strike := strikes.size() - 1 if coins == 1 else roundi(float(i) * (strikes.size() - 1) / (coins - 1))
		var at := strikes[strike]
		if not times.is_empty() and at <= times[-1]:
			at = times[-1] + WHOLE_CLIP_HIT_GAP
		times.append(at)
	return times


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _log(message: String) -> void:
	if verbose:
		print("[clash] ", message)
