class_name FxCue
extends RefCounted
## A timeline switching on one of the game's particle effects (its EffectActivate clip).

var time := 0.0
var duration := 0.0  ## seconds the game keeps it on
var effect_name := ""  ## its name in the identity's fx.json


## data: [time, seconds on, effect name], as tools/export_godot.py writes it.
static func from_json(data: Array) -> FxCue:
	var cue := FxCue.new()
	cue.time = data[0]
	cue.duration = data[1]
	cue.effect_name = data[2]
	return cue


## For sort_custom(): earlier cues first.
static func comes_before(a: FxCue, b: FxCue) -> bool:
	return a.time < b.time
