class_name TimelineMove
extends RefCounted
## A move marker on a coin's timeline: the game's TweenMove_ToTarget(_Wide) and
## TweenMove_Relative(V2), as tools/export_godot.py exports them (in pixels).

enum Goal {
	TO_FOE,  ## stop offset.x short of the foe, along the way the sinner faces; negative: past it
	BY_OFFSET,  ## move by offset from where the sinner is: x forward, y up
}

const MIN_DURATION := 0.01  ## seconds; a zero-length tween wouldn't play
## DOTween's eases, by the names tools/export_godot.py gives them: "quad_out" is QUAD + OUT.
const TRANSITIONS := {
	"linear": Tween.TRANS_LINEAR, "sine": Tween.TRANS_SINE, "quad": Tween.TRANS_QUAD,
	"cubic": Tween.TRANS_CUBIC, "quart": Tween.TRANS_QUART, "quint": Tween.TRANS_QUINT,
	"expo": Tween.TRANS_EXPO, "circ": Tween.TRANS_CIRC, "elastic": Tween.TRANS_ELASTIC,
	"back": Tween.TRANS_BACK, "bounce": Tween.TRANS_BOUNCE,
}
const EASES := {"in": Tween.EASE_IN, "out": Tween.EASE_OUT, "in_out": Tween.EASE_IN_OUT}

var time := 0.0
var goal := Goal.BY_OFFSET
var offset := Vector2.ZERO
var duration := MIN_DURATION
var transition := Tween.TRANS_LINEAR
var easing := Tween.EASE_OUT
var faces_foe_first := false  ## turn to face the foe before moving
var lands := false  ## BY_OFFSET: ends back on the ground the skill started from


static func from_json(data: Dictionary) -> TimelineMove:
	var move := TimelineMove.new()
	move.time = data.t
	move.goal = Goal.TO_FOE if data.to == "target" else Goal.BY_OFFSET
	move.offset = Vector2(data.x, data.y)
	move.duration = maxf(data.dur, MIN_DURATION)
	var curve := str(data.ease).split("_", true, 1)
	move.transition = TRANSITIONS.get(curve[0], Tween.TRANS_LINEAR)
	move.easing = EASES.get(curve[1] if curve.size() > 1 else "", Tween.EASE_OUT)
	move.faces_foe_first = data.turn
	move.lands = data.get("ground", false)
	return move


## Where a sinner standing at `from`, facing `facing`, ends up with its foe at `foe`.
## ground_y: the ground the skill started from.
func destination(from: Vector2, facing: int, foe: Vector2, ground_y: float) -> Vector2:
	var to := from
	if goal == Goal.TO_FOE:
		to.x = foe.x - facing * offset.x
	else:
		to += Vector2(facing * offset.x, -offset.y)
		if lands:
			to.y = ground_y
	return to
