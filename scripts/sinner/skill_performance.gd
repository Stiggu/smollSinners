class_name SkillPerformance
extends RefCounted
## A skill performed coin by coin, the way the game does it (start it with
## Sinner.perform_skill()): each coin plays its own timeline (see CoinStep.plan()) with that
## timeline's moves, turns and hits, and the next coin starts when the game allows it. The
## sinner advances it every frame; any change of the sinner's state cancels it.

## A hit landed. coin: the coin's index; damage_ratio: this hit's share of the coin's power,
## 0 for a coin whose timelines have no hits (reported once, as its last timeline ends);
## is_final: the skill's very last hit.
signal hit_landed(coin: int, damage_ratio: float, is_final: bool)
## Over: completed, or cancelled part way. Emitted at the end of the frame, so it can be awaited.
signal ended(completed: bool)

var _sinner: Sinner
var _steps: Array[CoinStep]
var _foe_at: Callable  ## -> Vector2: where the foe is now (overlay coordinates)
var _ground_y: float  ## where the skill started; moves that land come back down to it
var _last_step_with_hits := -1  ## its last hit is the skill's final one
var _step := -1
var _step_time := 0.0
var _events: Array[TimelineEvent] = []
var _next_event := 0
var _step_events_done := false  ## all of the current step's events have happened
var _coin_reported := -1  ## the last coin a hit was reported for
var _move_tween: Tween
var _over := false


func _init(sinner: Sinner, steps: Array[CoinStep], foe_at: Callable) -> void:
	_sinner = sinner
	_steps = steps
	_foe_at = foe_at
	_ground_y = sinner.position.y
	for i in steps.size():
		if steps[i].timeline.has_hits():
			_last_step_with_hits = i


## Face the foe and begin the first coin.
func start() -> void:
	_sinner.face(_foe_at.call())
	if _steps.is_empty():
		_end(true)
		return
	_begin_step(0)


func advance(delta: float) -> void:
	if _over:
		return
	_step_time += delta
	_dispatch_due_events()
	if _over or _step_time < _step_end():
		return
	if _step == _steps.size() - 1:
		_end(true)
	else:
		_begin_step(_step + 1)


## Stop part way (the sinner was picked up, called off, ...), and stop any move in progress.
func cancel() -> void:
	if _move_tween:
		_move_tween.kill()
	if not _over:
		_end(false)


func _begin_step(index: int) -> void:
	_step = index
	_step_time = 0.0
	_events = _steps[index].timeline.events(index == _last_step_with_hits)
	_next_event = 0
	_step_events_done = false
	_sinner.play_timeline(_steps[index].timeline, _foe_at, _ground_y)
	_dispatch_due_events()


## When the current step gives way to the next coin; the last one plays to its end.
func _step_end() -> float:
	var timeline := _steps[_step].timeline
	return timeline.length if _step == _steps.size() - 1 else timeline.next_coin_at


func _dispatch_due_events() -> void:
	while _next_event < _events.size() and _events[_next_event].time <= _step_time:
		_dispatch(_events[_next_event])
		_next_event += 1
		if _over:
			return
	if _next_event == _events.size() and not _step_events_done:
		_step_events_done = true
		_report_coin_without_hits()


func _dispatch(event: TimelineEvent) -> void:
	match event.kind:
		TimelineEvent.Kind.MOVE:
			_move(event.move)
		TimelineEvent.Kind.TURN:
			_sinner.face(_foe_at.call())
		TimelineEvent.Kind.HIT:
			_coin_reported = _steps[_step].coin
			hit_landed.emit(_coin_reported, event.damage_ratio, event.is_final_hit)


## A coin whose timelines have no hits still counts, once, as its last timeline's events end.
func _report_coin_without_hits() -> void:
	var coin := _steps[_step].coin
	var is_last_step := _step == _steps.size() - 1
	var coin_ends_here := is_last_step or _steps[_step + 1].coin != coin
	if _coin_reported < coin and coin_ends_here:
		_coin_reported = coin
		hit_landed.emit(coin, 0.0, is_last_step and _last_step_with_hits < 0)


func _move(move: TimelineMove) -> void:
	var foe: Vector2 = _foe_at.call()
	if move.faces_foe_first:
		_sinner.face(foe)
	var to := _sinner.keep_on_overlay(move.destination(_sinner.position, _sinner.facing, foe, _ground_y))
	if _move_tween:
		_move_tween.kill()
	_move_tween = _sinner.create_tween().set_trans(move.transition).set_ease(move.easing)
	_move_tween.tween_property(_sinner, "position", to.round(), move.duration)


func _end(completed: bool) -> void:
	_over = true
	ended.emit.call_deferred(completed)
