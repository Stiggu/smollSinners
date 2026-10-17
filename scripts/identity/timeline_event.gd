class_name TimelineEvent
extends RefCounted
## Something a coin's timeline makes happen at a moment (see Timeline.events()).

enum Kind { MOVE, TURN, HIT }

var time := 0.0
var kind := Kind.TURN
var move: TimelineMove  ## MOVE: where to
var damage_ratio := 0.0  ## HIT: this hit's share of the coin's power
var is_final_hit := false  ## HIT: the skill's very last hit


static func moving(marker: TimelineMove) -> TimelineEvent:
	var event := TimelineEvent.new()
	event.kind = Kind.MOVE
	event.time = marker.time
	event.move = marker
	return event


static func turning(at: float) -> TimelineEvent:
	var event := TimelineEvent.new()
	event.kind = Kind.TURN
	event.time = at
	return event


static func hitting(at: float, ratio: float) -> TimelineEvent:
	var event := TimelineEvent.new()
	event.kind = Kind.HIT
	event.time = at
	event.damage_ratio = ratio
	return event


## For sort_custom(): earlier events first.
static func comes_before(a: TimelineEvent, b: TimelineEvent) -> bool:
	return a.time < b.time
