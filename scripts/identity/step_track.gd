class_name StepTrack
extends RefCounted
## Values keyed in time that hold until the next key, the way the game's sprite swaps and
## on/off toggles play: no blending between keys.

var _times := PackedFloat32Array()
var _values: Array = []


## keys: [[time, value], ...] in time order, as tools/export_godot.py writes them.
static func from_pairs(keys: Array) -> StepTrack:
	var track := StepTrack.new()
	for key: Array in keys:
		track.add(key[0], key[1])
	return track


func add(time: float, value: Variant) -> void:
	_times.append(time)
	_values.append(value)


func is_empty() -> bool:
	return _values.is_empty()


func size() -> int:
	return _values.size()


func time_of(index: int) -> float:
	return _times[index]


func value_of(index: int) -> Variant:
	return _values[index]


## The index of the last key at or before `time`; -1 while `time` is before the first key.
func index_at(time: float) -> int:
	var found := -1
	for i in _times.size():
		if _times[i] > time:
			break
		found = i
	return found


## Whether the first key has been reached by `time`.
func has_started(time: float) -> bool:
	return index_at(time) >= 0


## The value of the last key at or before `time`, or `before_first` while there is none yet.
func value_at(time: float, before_first: Variant = null) -> Variant:
	var index := index_at(time)
	return _values[index] if index >= 0 else before_first
