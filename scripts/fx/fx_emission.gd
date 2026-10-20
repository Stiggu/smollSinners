class_name FxEmission
extends RefCounted
## When a particle system emits (Unity's Emission module, timed by its main module): its bursts
## and its steady rate, over its duration or looping. A system has one of its own; each time
## another system's particle sets it off (a sub-emitter) it runs another, from that particle.

var origin := Vector3.ZERO  ## where its particles start from, in the system's space
var tint := Color.WHITE  ## multiplies its particles' colour (a parent's, when inherited)
var follows: FxParticle  ## the particle it's moving with, if any
var from_parent := Transform3D.IDENTITY  ## from that particle's system's space into this one's
var time := 0.0  ## seconds it has been emitting
var _definition: FxParticleSystemDef
var _rate_owed := 0.0  ## particles the rate owes, carried between frames
var _bursts_fired: Array[int] = []  ## cycles fired so far this run through, per burst
var _loop := 0  ## a looping system's run through its duration: each starts its bursts over


func _init(definition: FxParticleSystemDef) -> void:
	_definition = definition
	for burst in definition.bursts:
		_bursts_fired.append(0)


## How far through the system's duration it is, 0..1 (round again each loop).
func cycle() -> float:
	var duration := _definition.duration
	return fmod(time, duration) / duration if _definition.looping else minf(time / duration, 1.0)


func is_over() -> bool:
	return not _definition.looping and time > _definition.duration


## How many particles are due after `delta` more seconds.
func advance(delta: float, rng: RandomNumberGenerator) -> int:
	time += delta
	var due := _due_from_bursts(rng)
	if _definition.rate != null and not is_over():
		_rate_owed += _definition.rate.sample(cycle(), rng.randf()) * delta
		var whole := floori(_rate_owed)
		_rate_owed -= whole
		due += whole
	return due


func _due_from_bursts(rng: RandomNumberGenerator) -> int:
	if not _definition.looping:
		return _fire_bursts(time, rng)
	var loop := floori(time / _definition.duration)
	var due := 0
	if loop != _loop:  # finish the last run through, then go again
		due += _fire_bursts(_definition.duration, rng)
		_loop = loop
		_bursts_fired.fill(0)
	return due + _fire_bursts(time - loop * _definition.duration, rng)


## Particles due from bursts up to `until` seconds into this run through.
func _fire_bursts(until: float, rng: RandomNumberGenerator) -> int:
	var due := 0
	for i in _definition.bursts.size():
		var burst := _definition.bursts[i]
		while burst.repeats_forever() or _bursts_fired[i] < burst.cycles:
			var at := burst.cycle_time(_bursts_fired[i])
			if until < at or at > _definition.duration:
				break
			_bursts_fired[i] += 1
			if rng.randf() <= burst.probability:
				due += roundi(burst.count.sample(cycle(), rng.randf()))
	return due
