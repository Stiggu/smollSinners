class_name Sinner
extends Node2D
## One desktop sinner wearing one identity (scenes/sinner/sinner.tscn). It stands on the
## taskbar, dashes around, shadow-boxes with its skills, picks fights with desktop icons, and
## can be picked up and thrown. The node's position is the sinner's feet. It has HP and
## Sanity like in battle (`status`), shown on the game's bar under its feet; staggered,
## panicked or dead, it does nothing until that passes. Add it to the tree, then wear() an
## identity.

## The idle AI wants to fight a desktop icon; the overlay picks one and starts a Clash.
signal clash_wanted
## The player took over (picked it up, called it back, or dressed it differently); a
## running Clash stops.
signal interrupted
## Let go of after being carried (by the mouse, or on a card dragged out of Settings).
signal dropped

enum State { IDLE, DASH, SKILL, DRAGGED, FALLING, CLASH }
enum IdleAction { DASH, SHADOW_BOX, PICK_FIGHT, REST }

## How likely an idle sinner is to do each thing next.
const IDLE_ACTION_ODDS := {
	IdleAction.DASH: 0.45, IdleAction.SHADOW_BOX: 0.2, IdleAction.PICK_FIGHT: 0.15, IdleAction.REST: 0.2,
}
const IDLE_SECONDS := Vector2(2.0, 6.0)  ## it stands about at least this long, at most that
const DASH_DISTANCE := Vector2(150.0, 450.0)  ## px, least and most, either way
const DASH_SPEED := 260.0  ## px/s
const GRAVITY := 2400.0  ## px/s²
const MAX_THROW_SPEED := 2500.0  ## px/s
const WALL_BOUNCE := 0.5  ## a thrown sinner keeps this share of its sideways speed off a wall
## The throw follows the pointer's last few frames, not one jittery frame: each frame's
## movement counts this much.
const THROW_SMOOTHING := 0.5
const MIN_FRAME_SECONDS := 0.001
## px it keeps between itself (its widest side: standing sprite or unit bar) and the
## overlay's sides as it wanders, see FloorSpan
const EDGE_GAP := 8.0
## Left partly off the overlay (by a clash, a skill or a throw), it stands this many seconds
## before walking back into view.
const BACK_INTO_VIEW_DELAY := 0.3
const FLOOR_INSET := 24.0  ## the floor is this far above the taskbar: the unit bar lies around the feet
const STANDING_TOLERANCE := 0.5  ## px above the floor that still counts as standing
const DROP_IN_Y := -200.0  ## where it drops in from, above the overlay
## shadow-boxing, the imaginary foe stands at least this far in front (more for a skill whose
## opening effects reach further, see SkillReach)
const SHADOW_FOE_DISTANCE := 150.0
const POP_IN_FROM_SCALE := 0.25
const POP_IN_SECONDS := 0.3

## z_index while carried: over the Settings panel (z 10), so it can be dropped on it.
@export var carried_z_index := 20

var identity: IdentityData
var state := State.IDLE
var facing := 1  ## 1 = right, the way the game's sprites face
var status: UnitStatus  ## HP and Sanity; a new one with each identity
var fx_layer: Node  ## where its particle effects go (overlay coordinates); its parent if unset

var _state_time := 0.0
var _idle_seconds := 0.0
var _dash_target_x := 0.0
var _velocity := Vector2.ZERO
var _grab_offset := Vector2.ZERO  ## its feet from the pointer while carried
var _edge_clearance := 0.0  ## px from its feet to its widest side, plus EDGE_GAP
var _performance: SkillPerformance
var _effect_anchors: EffectAnchors  ## where the playing timeline's effects go

@onready var _body: SinnerBody = $Body
@onready var _player: TimelinePlayer = $TimelinePlayer
@onready var _bar: UnitBar = $UnitBar


func _ready() -> void:
	_effect_anchors = EffectAnchors.new(self, Callable())
	_player.fx_cued.connect(_spawn_fx)
	_player.finished.connect(_on_timeline_finished)


## Wear an identity. Can be called again to change: the sinner keeps its place, and a
## running clash stops.
func wear(new_identity: IdentityData) -> void:
	var changing := identity != null
	identity = new_identity
	_player.identity = identity
	status = UnitStatus.new(identity.battle_stats)
	status.condition_changed.connect(_on_condition_changed)
	_bar.status = status
	_edge_clearance = _widest_reach() + EDGE_GAP
	_player.stop()
	_velocity = Vector2.ZERO
	_enter(State.FALLING if _is_airborne() else State.IDLE)
	if changing:
		interrupted.emit()


func _process(delta: float) -> void:
	_state_time += delta
	status.tick(delta)
	if state == State.CLASH:
		status.fighting()
	match state:
		State.IDLE:
			_idle()
		State.DASH:
			_dash(delta)
		State.DRAGGED:
			_follow_pointer(delta)
		State.FALLING:
			_fall(delta)
	if _performance:
		_performance.advance(delta)
	var swing := _velocity if state == State.DRAGGED else Vector2.ZERO
	_body.animate(delta, facing, state == State.DASH, swing)


## A press on its visible pixels picks it up, unless the Settings panel took it first.
func _unhandled_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press and press.button_index == MOUSE_BUTTON_LEFT and press.pressed and hit_test(press.position):
		pick_up(position - press.position)
		get_viewport().set_input_as_handled()


## Letting go always drops it, wherever the pointer is (over the Settings panel too).
func _input(event: InputEvent) -> void:
	var release := event as InputEventMouseButton
	if release and release.button_index == MOUSE_BUTTON_LEFT and not release.pressed and is_dragging():
		drop()


#region Player control

## Carry it with the pointer, its feet `grab_offset` from the pointer.
func pick_up(grab_offset: Vector2) -> void:
	_grab_offset = grab_offset
	_velocity = Vector2.ZERO
	_player.stop()
	_enter(State.DRAGGED)
	interrupted.emit()


## Carry it by the middle of its body, wherever the pointer is.
func pick_up_by_middle() -> void:
	var grab_offset := (position - crown()) / 2.0
	position = _pointer() + grab_offset
	pick_up(grab_offset)


## Let go: thrown with the pointer's last movement.
func drop() -> void:
	if not is_dragging():
		return
	_velocity = _velocity.limit_length(MAX_THROW_SPEED)
	_enter(State.FALLING)
	dropped.emit()


## Stop whatever it's doing (a clash it's in ends: the icon goes home) and come down to the floor.
func call_off() -> void:
	_player.stop()
	_velocity = Vector2.ZERO
	_enter(State.FALLING)
	interrupted.emit()


## Drop back in from above, at a fraction of the overlay's width.
func drop_in(x_fraction: float) -> void:
	position = Vector2(get_viewport_rect().size.x * x_fraction, DROP_IN_Y)
	call_off()


## Grow in from small with a little overshoot, so a sinner turning up under the pointer
## catches the eye. Ends at exactly scale 1, so the art stays crisp.
func pop_in() -> void:
	scale = Vector2.ONE * POP_IN_FROM_SCALE
	create_tween().tween_property(self, "scale", Vector2.ONE, POP_IN_SECONDS) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

#endregion


#region Where things are

## True if the point (overlay coordinates) is on one of its visible pixels.
func hit_test(point: Vector2) -> bool:
	return visible and _body.is_opaque_at(point)


func is_dragging() -> bool:
	return state == State.DRAGGED


## Where its clash badge goes, from the feet (the unit bar scene's BadgeAnchor).
func badge_offset() -> Vector2:
	return _bar.badge_anchor.position


## Where the feet rest: a little above the bottom of the overlay (the top of the taskbar).
func floor_y() -> float:
	return get_viewport_rect().size.y - FLOOR_INSET


## The top of its head now (overlay coordinates): line effects start there.
func crown() -> Vector2:
	return position + _body.crown_offset() * Vector2(facing, 1)


## A point brought onto the overlay: half off-screen at worst (e.g. past an icon by the
## edge), and never below the floor.
func keep_on_overlay(point: Vector2) -> Vector2:
	return Vector2(clampf(point.x, 0.0, get_viewport_rect().size.x), minf(point.y, floor_y()))


func face(point: Vector2) -> void:
	facing = 1 if point.x > position.x else -1

#endregion


#region Clash control: a Clash drives the sinner between begin_clash() and end_clash()

## Stop wandering and falling until end_clash().
func begin_clash() -> void:
	_player.stop()
	_velocity = Vector2.ZERO
	_enter(State.CLASH)


## Show a single-pose clip ("Move", "Guard", "Damaged"...: see IdentityData), stopping
## whatever was playing.
func show_clip_pose(clip_name: String) -> void:
	show_pose(identity.clip_pose(clip_name))


## Show one sprite by name (null hides the body), e.g. a skill's wind-up frame, stopping
## whatever was playing.
func show_pose(pose_name: Variant) -> void:
	_player.stop()
	_body.show_pose(identity.pose(pose_name))


## Play a timeline on top of the current state, with the effects it switches on aimed at the
## foe if one is given (foe_at: Callable -> Vector2, the foe's centre). Returns its length in seconds.
func play_timeline(timeline: Timeline, foe_at := Callable()) -> float:
	_effect_anchors = EffectAnchors.new(self, foe_at)
	_player.play(timeline)
	return timeline.length


## Play a skill's whole clip. Returns its length in seconds.
func play_skill_clip(slot: String) -> float:
	return play_timeline(identity.skill_clip(slot))


## Perform `coins` of a skill's coins the way the game choreographs them (the skill needs
## coin timelines): see SkillPerformance. foe_at: Callable -> Vector2, where the foe is now
## (overlay coordinates). Listen to the result's hit_landed and await its ended.
func perform_skill(slot: String, coins: int, foe_at: Callable) -> SkillPerformance:
	var skill := identity.skills[slot]
	if _performance:
		_performance.cancel()
	_performance = SkillPerformance.new(self, CoinStep.plan(skill.coin_timelines, skill.coin_count(), coins), foe_at)
	_performance.start()
	return _performance


## Leave the clash moving at this velocity; gravity brings it back down.
func end_clash(launch := Vector2.ZERO) -> void:
	_player.stop()
	_velocity = launch
	_enter(State.FALLING)

#endregion


func _enter(new_state: State) -> void:
	state = new_state
	z_index = carried_z_index if state == State.DRAGGED else 0
	_state_time = 0.0
	if _performance:
		_performance.cancel()
		_performance = null
	match state:
		State.IDLE:
			_idle_seconds = randf_range(IDLE_SECONDS.x, IDLE_SECONDS.y)
			_show_clip(_resting_clip())
		State.DASH:
			_show_clip(IdentityData.CLIP_MOVE)
		State.DRAGGED, State.FALLING:
			_show_clip(IdentityData.CLIP_HURT)


func _idle() -> void:
	if not status.can_act():
		return
	var span := _floor_span()
	if span.cuts_off(position.x):
		if _state_time >= BACK_INTO_VIEW_DELAY:
			_dash_to(span.clamp_x(position.x))
		return
	if _state_time < _idle_seconds:
		return
	match RandomPick.weighted(IDLE_ACTION_ODDS):
		IdleAction.DASH:
			_start_dash()
		IdleAction.SHADOW_BOX:
			_enter(State.SKILL)
			_shadow_box(identity.random_skill_slot())
		IdleAction.PICK_FIGHT:
			_enter(State.IDLE)
			clash_wanted.emit()  # the overlay may start a Clash, which takes over
		IdleAction.REST:
			_enter(State.IDLE)


## A dash of random length, more likely towards the middle the further it is from it.
func _start_dash() -> void:
	var span := _floor_span()
	var distance := randf_range(DASH_DISTANCE.x, DASH_DISTANCE.y) * span.dash_direction(position.x)
	_dash_to(span.clamp_x(position.x + distance))


func _dash_to(x: float) -> void:
	_dash_target_x = x
	facing = 1 if _dash_target_x > position.x else -1
	_enter(State.DASH)


func _dash(delta: float) -> void:
	position.x = move_toward(position.x, _dash_target_x, DASH_SPEED * delta)
	if is_equal_approx(position.x, _dash_target_x):
		_enter(State.IDLE)


## Play a skill against an imaginary foe in front (turning round if there's no room), so
## skills that dash through the foe and strike back still face the right way.
func _shadow_box(slot: String) -> void:
	var skill := identity.skills[slot]
	if not skill.has_coin_timelines():
		play_skill_clip(slot)
		return
	var distance := SkillReach.stand_off(identity, skill, SHADOW_FOE_DISTANCE)
	if _floor_span().cuts_off(position.x + facing * distance):
		facing = -facing
	# its centre, so its feet stand on the floor with the sinner's
	var foe := Vector2(position.x + facing * distance, position.y - EffectAnchors.FOE_CENTER_HEIGHT)
	perform_skill(slot, skill.coin_count(), func() -> Vector2: return foe)


func _follow_pointer(delta: float) -> void:
	var target := _pointer() + _grab_offset
	var frame_velocity := (target - position) / maxf(delta, MIN_FRAME_SECONDS)
	_velocity = _velocity.lerp(frame_velocity, THROW_SMOOTHING)
	position = target


## Down under gravity, bouncing off the overlay's sides (see FloorSpan.walls_from()).
func _fall(delta: float) -> void:
	_velocity.y += GRAVITY * delta
	var walls := _floor_span().walls_from(position.x)
	position += _velocity * delta
	if position.x < walls.x or position.x > walls.y:
		position.x = clampf(position.x, walls.x, walls.y)
		_velocity.x *= -WALL_BOUNCE
	if position.y >= floor_y():
		position.y = floor_y()
		_body.land(_velocity.y)
		_velocity = Vector2.ZERO
		_enter(State.IDLE)


## A shadow-boxed skill played to its end. Some leap: come back down first.
func _on_timeline_finished() -> void:
	if state == State.SKILL:
		_enter(State.FALLING if _is_airborne() else State.IDLE)


func _on_condition_changed() -> void:
	if state == State.IDLE:
		_show_clip(_resting_clip())


## Standing still: lying dead, reeling while staggered, or idle.
func _resting_clip() -> String:
	if status.is_dead():
		return IdentityData.CLIP_DEAD
	return IdentityData.CLIP_HURT if status.is_staggered() else IdentityData.CLIP_IDLE


func _show_clip(clip_name: String) -> void:
	_body.show_pose(identity.pose(identity.clip_pose(clip_name)))


## Switch on one of the game's effects where the game puts it (the caster's or the foe's feet
## or centre, see EffectAnchors), mirrored when facing left.
func _spawn_fx(cue: FxCue) -> void:
	var definition := identity.effect(cue.effect_name)
	if definition == null:
		return
	var effect := FxEffect.new()
	effect.scale.x = facing
	effect.anchor_to(_effect_anchors.point.bind(definition.anchor), definition)
	(fx_layer if fx_layer else get_parent()).add_child(effect)
	effect.play(definition, cue.duration, crown(), _effect_anchors.foe_center())


func _is_airborne() -> bool:
	return position.y < floor_y() - STANDING_TOLERANCE


## The pointer in overlay coordinates, wherever it is (the press may belong to another window).
func _pointer() -> Vector2:
	return Vector2(DisplayServer.mouse_get_position() - get_window().position)


## Where on the floor it stands whole on the overlay (worked out afresh: the overlay can move
## to another monitor).
func _floor_span() -> FloorSpan:
	return FloorSpan.new(get_viewport_rect().size.x, _edge_clearance)


## px from its feet to its furthest side: its standing sprite, or its unit bar if wider.
func _widest_reach() -> float:
	var standing := identity.pose(identity.clip_pose(IdentityData.CLIP_IDLE))
	return maxf(standing.reach() if standing else 0.0, _bar.reach())
