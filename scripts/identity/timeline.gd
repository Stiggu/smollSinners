class_name Timeline
extends RefCounted
## One of the game's animation timelines for a sinner, as tools/export_godot.py exports it:
## a whole clip ("Default", "Move", "S1"...) or one coin's share of a skill. It swaps the
## body's pose and the slash effect's sprite; a coin's share also carries the markers of the
## game's Unity Timelines: moves, turns, hits and the particle effects it switches on.

## Strikes closer together than this (seconds) count as one when guessed from pose changes.
const MIN_STRIKE_GAP := 0.05

var length := 0.0
## When the next coin's timeline may start (the game's HitCheaker marker); its length if unmarked.
var next_coin_at := 0.0
var body_poses := StepTrack.new()  ## pose names; null hides the body for a moment
var slash_sprites := StepTrack.new()  ## the slash effect's sprite names; null: none
var slash_shown := StepTrack.new()  ## bools: whether the slash shows
var slash_positions := StepTrack.new()  ## Vector2: where the slash sits from the feet
var moves: Array[TimelineMove] = []
var hits: Array[TimelineHit] = []
var turns: Array[float] = []  ## when the sinner turns to face its foe
var fx_cues: Array[FxCue] = []  ## in time order


static func from_json(data: Dictionary) -> Timeline:
	var timeline := Timeline.new()
	timeline.length = data.length
	var next: Variant = data.get("next")
	timeline.next_coin_at = next if next != null else timeline.length
	timeline.body_poses = StepTrack.from_pairs(data.body)
	var slash: Dictionary = data.effect
	timeline.slash_sprites = StepTrack.from_pairs(slash.sprites)
	timeline.slash_shown = StepTrack.from_pairs(slash.on)
	for key: Array in slash.pos:  # [time, x, y]
		timeline.slash_positions.add(key[0], Vector2(key[1], key[2]))
	for move: Dictionary in data.get("moves", []):
		timeline.moves.append(TimelineMove.from_json(move))
	for hit: Dictionary in data.get("hits", []):
		timeline.hits.append(TimelineHit.from_json(hit))
	timeline.turns.assign(data.get("turns", []))
	for cue: Array in data.get("effects", []):
		timeline.fx_cues.append(FxCue.from_json(cue))
	timeline.fx_cues.sort_custom(FxCue.comes_before)
	return timeline


func has_hits() -> bool:
	return not hits.is_empty()


## When it first dashes at the foe (a move that stops short of it); INF if it never does.
func first_dash_time() -> float:
	var first := INF
	for move in moves:
		if move.goal == TimelineMove.Goal.TO_FOE:
			first = minf(first, move.time)
	return first


## The pose it opens with: a skill's wind-up.
func opening_pose() -> Variant:
	return body_poses.value_of(0) if not body_poses.is_empty() else null


## The pose after the opening one: a skill's strike (the opening one if it has only one).
func strike_pose() -> Variant:
	return body_poses.value_of(mini(1, body_poses.size() - 1)) if not body_poses.is_empty() else null


## The first pose that shows the body: what a single-pose clip like "Guard" stands in.
func first_visible_pose() -> Variant:
	for i in body_poses.size():
		if body_poses.value_of(i) != null:
			return body_poses.value_of(i)
	return null


## When its strikes land: when the slash effect flashes on, or failing that, when the pose
## changes after the wind-up.
func strike_times() -> Array[float]:
	var times: Array[float] = []
	for i in slash_shown.size():
		if slash_shown.value_of(i):
			times.append(slash_shown.time_of(i))
	if not times.is_empty():
		return times
	for i in range(1, body_poses.size()):
		var at := body_poses.time_of(i)
		if body_poses.value_of(i) != null and (times.is_empty() or at > times[-1] + MIN_STRIKE_GAP):
			times.append(at)
	return times


## Its moves, turns and hits, in time order. A multi-hit marker gives one event per hit.
## ends_with_final_hit: its last hit is the skill's last of all.
func events(ends_with_final_hit: bool) -> Array[TimelineEvent]:
	var hit_events: Array[TimelineEvent] = []
	for hit in hits:
		for at in hit.hit_times():
			hit_events.append(TimelineEvent.hitting(at, hit.ratio_per_hit()))
	hit_events.sort_custom(TimelineEvent.comes_before)
	if ends_with_final_hit and not hit_events.is_empty():
		hit_events[-1].is_final_hit = true

	var all: Array[TimelineEvent] = []
	for move in moves:
		all.append(TimelineEvent.moving(move))
	for at in turns:
		all.append(TimelineEvent.turning(at))
	all.append_array(hit_events)
	all.sort_custom(TimelineEvent.comes_before)
	return all
