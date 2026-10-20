class_name StaggerGlass
extends Node2D
## The stagger's glass, the game's own effects (tools/export_stagger_fx.py), on its own Stage.

const EFFECTS := "res://assets/limbus/ui/unit_bar/stagger_fx.json"
const SHATTER := "FX_PC_BaseFX_Break1"  ## the first tier's: the pet's units never reach Stagger+
const SHARDS := "FX_PC_BaseFX_Break_Loop1"
const SHATTER_SECONDS := 1.75  ## its systems run 1 s, and their particles live up to 0.75 s

static var _effects: FxEffectSet

var _shards: FxEffect

@onready var _stage: FxStage = $Stage


func _ready() -> void:
	if _effects == null:
		_effects = FxEffectSet.load_from(EFFECTS)


## The glass shatters at `at` (a node beside this one: the STAGGER burst).
func shatter(at: Node2D) -> void:
	_play(SHATTER, at, SHATTER_SECONDS)


## Shards hang round `plate` (a node beside this one) until stop_shards().
func start_shards(plate: Node2D) -> void:
	if _shards == null:
		_shards = _play(SHARDS, plate, INF)


func stop_shards() -> void:
	if _shards:
		_shards.queue_free()
		_shards = null


func _play(effect_name: String, on: Node2D, seconds: float) -> FxEffect:
	var definition: FxEffectDef = _effects.effects[effect_name]
	var on_stage := func() -> Vector2: return on.position - position - _stage.position
	var effect := FxEffect.new()
	effect.anchor_to(on_stage, definition)
	_stage.play(effect, definition, seconds, on_stage.call(), on_stage.call())
	return effect
