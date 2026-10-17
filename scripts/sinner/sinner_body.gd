class_name SinnerBody
extends Node2D
## The sinner's sprites (in scenes/sinner/sinner.tscn): its Pose, and over it a skill's
## Slash. Turned the way the sinner faces, squashed as it lands, bobbing while it dashes and
## swinging while it's carried. At rest the sprites end up at scale 1 and rotation 0 exactly,
## or every pixel would be resampled and the art would go soft.

## Where the top of the head is taken to be, from the feet, when there's no pose to measure.
const FALLBACK_CROWN := Vector2(0, -130)

@export_group("Landing")
@export var squash_range := Vector2(0.05, 0.3)  ## the least and most a landing squashes it
@export var squash_full_speed := 4000.0  ## px/s: landing this fast squashes it the most
@export var squash_recovery := 1.5  ## squash shed per second
@export var widening_per_squash := 0.5  ## squashed down, it bulges out this much as wide
@export_group("Dashing")
@export var bob_height := 3.0  ## px
@export var bob_speed := 12.0  ## radians a second; it bounces twice per cycle
@export_group("Carried")
@export var tilt_per_speed := 0.0003  ## radians of tilt per px/s it's swung sideways
@export var max_tilt := 0.35  ## radians
@export var tilt_smoothing := 0.2  ## share of the way to the wanted tilt each frame
@export var tilt_snap := 0.002  ## radians: this close, it settles exactly

var _shown_pose: PoseSprite  ## the last pose shown (kept while the body is hidden)
var _squash := 0.0

@onready var _pose: Sprite2D = $Pose
@onready var _slash: Sprite2D = $Slash


## Show a pose; null hides the body (some skills clear it for a moment).
func show_pose(pose: PoseSprite) -> void:
	_pose.visible = pose != null
	if pose == null:
		return
	_shown_pose = pose
	_pose.texture = pose.texture
	_pose.offset = -pose.anchor


## Show a skill's slash sprite at `at` from the feet.
func show_slash(sprite: PoseSprite, at: Vector2) -> void:
	_slash.visible = true
	_slash.texture = sprite.texture
	_slash.offset = -sprite.anchor
	_slash.position = at


func hide_slash() -> void:
	_slash.visible = false


## Squash it for a landing at this fall speed (px/s).
func land(fall_speed: float) -> void:
	_squash = clampf(fall_speed / squash_full_speed, squash_range.x, squash_range.y)


## Squash, bob and tilt for this frame. carried_velocity: how fast it's being swung (zero
## when it isn't being carried).
func animate(delta: float, facing: int, dashing: bool, carried_velocity: Vector2) -> void:
	_squash = move_toward(_squash, 0.0, delta * squash_recovery)
	scale = Vector2(facing * (1.0 + _squash * widening_per_squash), 1.0 - _squash)
	position.y = _dash_bob() if dashing else 0.0
	var tilt := clampf(-carried_velocity.x * tilt_per_speed, -max_tilt, max_tilt)
	rotation = lerp_angle(rotation, tilt, tilt_smoothing)
	if absf(rotation - tilt) < tilt_snap:
		rotation = tilt


## True if the point (global, i.e. overlay coordinates) is on one of the pose's visible pixels.
func is_opaque_at(point: Vector2) -> bool:
	return _pose.visible and _pose.texture != null and _pose.is_pixel_opaque(_pose.to_local(point))


## The top of the head from the feet, unflipped (see PoseSprite.crown()).
func crown_offset() -> Vector2:
	return _shown_pose.crown() if _shown_pose else FALLBACK_CROWN


func _dash_bob() -> float:
	var seconds := Time.get_ticks_msec() / 1000.0
	return -absf(sin(seconds * bob_speed)) * bob_height
