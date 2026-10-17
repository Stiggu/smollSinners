class_name FloorSpan
extends RefCounted
## The stretch of the floor where a sinner stands whole on the overlay: its feet at least
## `clearance` px from either side, so neither its sprite nor its unit bar is cut off. It
## wanders inside it, leaning towards the middle, so a team spreads over the desktop rather
## than piling up by the edges (edges are fine, just not past them).

## How strongly dashes lean towards the middle: from the middle either way is as likely; from
## an end it heads inwards with odds 0.5 + this.
const MIDDLE_PULL := 0.4

var left := 0.0  ## the leftmost its feet can be
var right := 0.0  ## ... and the rightmost
var _overlay_width := 0.0


func _init(overlay_width: float, clearance: float) -> void:
	_overlay_width = overlay_width
	var inset := minf(clearance, overlay_width / 2.0)
	left = inset
	right = overlay_width - inset


## x brought inside the span.
func clamp_x(x: float) -> float:
	return clampf(x, left, right)


## True if feet at x leave part of the sinner off the overlay.
func cuts_off(x: float) -> bool:
	return not is_equal_approx(x, clamp_x(x))


## -1 or 1: which way to dash from x, leaning inwards the further x is from the middle.
func dash_direction(x: float) -> int:
	var middle := (left + right) / 2.0
	var off_middle := clampf((x - middle) / (middle - left), -1.0, 1.0)  # -1 at the left end, 1 at the right
	var inwards := 1 if off_middle < 0.0 else -1
	var inwards_odds := 0.5 + MIDDLE_PULL * absf(off_middle)
	return inwards if randf() < inwards_odds else -inwards


## The walls a sinner falling (or thrown) from `from_x` bounces off, as (left, right): the
## span's ends. One already past an end (a clash or a skill took it there) isn't pulled back,
## it just can't go further out, and never more than half off the overlay (feet on its edge).
func walls_from(from_x: float) -> Vector2:
	return Vector2(clampf(from_x, 0.0, left), clampf(from_x, right, _overlay_width))
