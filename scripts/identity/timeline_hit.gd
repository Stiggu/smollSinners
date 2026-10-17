class_name TimelineHit
extends RefCounted
## A hit marker on a coin's timeline (the game's GiveDamage): `count` hits (a multi-hit)
## spread over `span` seconds, sharing `damage_ratio` of the coin's power between them.

const SPACING_WITHOUT_SPAN := 0.06  ## seconds between the hits of a multi-hit that has no span

var time := 0.0
var damage_ratio := 1.0
var count := 1
var span := 0.0


static func from_json(data: Dictionary) -> TimelineHit:
	var hit := TimelineHit.new()
	hit.time = data.t
	hit.damage_ratio = data.ratio
	hit.count = maxi(int(data.count), 1)
	hit.span = data.span
	return hit


## When each of its hits lands.
func hit_times() -> Array[float]:
	var spacing := span / count if span > 0.0 else SPACING_WITHOUT_SPAN
	var times: Array[float] = []
	for i in count:
		times.append(time + i * spacing)
	return times


## The share of the coin's power each of its hits deals.
func ratio_per_hit() -> float:
	return damage_ratio / count
