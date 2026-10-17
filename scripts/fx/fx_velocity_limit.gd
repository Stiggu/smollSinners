class_name FxVelocityLimit
extends RefCounted
## A particle system's speed limit and drag (Unity's Limit Velocity over Lifetime module):
## a particle going faster than the limit loses `dampen` of the excess (a share per frame at
## Unity's reference rate), and drag slows every particle, more for bigger or faster ones
## when the module says so.

const DAMPEN_FRAME_RATE := 30.0  ## dampen is the share of the excess lost per frame at this rate

var limit: FxCurve  ## Unity units/s, over the particle's life
var limit_axes: Array[FxCurve] = []  ## x, y, z limits, when limited on each axis
var dampen := 0.0
var drag: FxCurve
var drag_by_size := false
var drag_by_speed := false


static func from_json(data: Dictionary) -> FxVelocityLimit:
	var module := FxVelocityLimit.new()
	module.limit = FxCurve.from_json(data.limit)
	if data.get("separate_axes", false):
		for axis: Dictionary in data.limit_xyz:
			module.limit_axes.append(FxCurve.from_json(axis))
	module.dampen = data.get("dampen", 0.0)
	module.drag = FxCurve.from_json(data.get("drag", {}))
	module.drag_by_size = data.get("drag_by_size", false)
	module.drag_by_speed = data.get("drag_by_speed", false)
	return module


## The particle's own velocity after `delta` seconds of drag and the speed limit.
func applied(velocity: Vector3, particle: FxParticle, delta: float) -> Vector3:
	var life := particle.life_fraction()
	var resistance := drag.sample(life, particle.velocity_pick)
	if drag_by_size:
		resistance *= maxf(particle.shown_size.x, maxf(particle.shown_size.y, particle.shown_size.z))
	if drag_by_speed:
		resistance *= velocity.length()
	velocity *= maxf(0.0, 1.0 - resistance * delta)
	var kept := pow(1.0 - dampen, delta * DAMPEN_FRAME_RATE)  # of the excess over the limit
	if limit_axes.is_empty():
		var top := limit.sample(life, particle.velocity_pick)
		var speed := velocity.length()
		if speed > top:
			velocity *= (top + (speed - top) * kept) / speed
		return velocity
	for axis in 3:
		var top := limit_axes[axis].sample(life, particle.velocity_pick)
		var along := absf(velocity[axis])
		if along > top:
			velocity[axis] = signf(velocity[axis]) * (top + (along - top) * kept)
	return velocity
