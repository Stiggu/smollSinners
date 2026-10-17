class_name FxBurst
extends RefCounted
## One of a particle system's emission bursts: `count` particles at `time`, repeated
## `cycles` times (0: forever) every `interval` seconds, each with this `probability`.

const MIN_INTERVAL := 0.001

var time := 0.0
var count: FxCurve
var cycles := 1
var interval := 0.0
var probability := 1.0


static func from_json(data: Dictionary) -> FxBurst:
	var burst := FxBurst.new()
	burst.time = data.time
	burst.count = FxCurve.from_json(data.count)
	burst.cycles = int(data.cycles)
	burst.interval = maxf(data.interval, MIN_INTERVAL)
	burst.probability = data.probability
	return burst


func repeats_forever() -> bool:
	return cycles <= 0


## When its n-th cycle (from 0) goes off.
func cycle_time(n: int) -> float:
	return time + n * interval
