class_name TimelinePlayer
extends Node
## Plays a Timeline on the sinner's SinnerBody (in scenes/sinner/sinner.tscn): the pose and
## the slash as the timeline keys them, and its particle effects as they come up (fx_cued).
## The last pose stays up for `hold` seconds after the end; then it's `finished`.

## The timeline switches on one of the game's effects now.
signal fx_cued(cue: FxCue)
## Done, including the hold.
signal finished

@export var body: SinnerBody
@export var hold := 0.4  ## seconds the last pose stays up after the end

var identity: IdentityData  ## whose sprites the timelines name

var _timeline: Timeline
var _time := 0.0
var _next_cue := 0


func play(timeline: Timeline) -> void:
	_timeline = timeline
	_time = 0.0
	_next_cue = 0
	_advance(0.0)


func stop() -> void:
	_timeline = null
	body.hide_slash()


func is_playing() -> bool:
	return _timeline != null


func _process(delta: float) -> void:
	if _timeline:
		_advance(delta)


func _advance(delta: float) -> void:
	_time += delta
	if _timeline.body_poses.has_started(_time):
		body.show_pose(identity.pose(_timeline.body_poses.value_at(_time)))
	_update_slash()
	_cue_effects()
	if _time >= _timeline.length + hold:
		stop()
		finished.emit()


func _update_slash() -> void:
	var sprite := identity.pose(_timeline.slash_sprites.value_at(_time))
	if sprite == null or not _timeline.slash_shown.value_at(_time, false):
		body.hide_slash()
		return
	body.show_slash(sprite, _timeline.slash_positions.value_at(_time, Vector2.ZERO))


func _cue_effects() -> void:
	var cues := _timeline.fx_cues
	while _next_cue < cues.size() and cues[_next_cue].time <= _time:
		fx_cued.emit(cues[_next_cue])
		_next_cue += 1
