class_name OrbGlass
extends Node2D
## The Sanity orb's glass, over its frame, as the game draws it (MPGauge): particle effects
## through the game's own shaders (tools/export_orb.py), in HDR on a small FxStage of its own
## so they bloom as in the game:
##  - the sphere: grey at 0 SP, blending to blue up to +45 and red down to -45
##  - while SP is up, every 1.1 s a blue ring swells out as it dissolves, over a burst of glow;
##    while it's down, a red ring every 0.6 s
##  - when SP changes: an SpChange (scenes/ui/sp_change.tscn) pops out of it
## The node is the orb's centre; its Stage is centred on it in scenes/ui/unit_bar.tscn.

const EFFECTS := "res://assets/limbus/ui/unit_bar/orb_fx.json"
const SPHERE := "FX_UI_Battle_MindPowerSphere"
const PULSE_UP := "FX_UI_Battle_MindPowerSphereFX_Up"
const PULSE_DOWN := "FX_UI_Battle_MindPowerSphereFX_Down"
## The sphere's values the game's code sets: how far it's turned blue (up) or red (down), 0..1.
const UP_VALUE := "_MindPower_UP"
const DOWN_VALUE := "_MindPower_Down"
## Their value at full Sanity (either way): the glass in an in-game screenshot at +45 (that code
## isn't in the game's data); the pulse's glow makes up the rest of its blue.
const VALUE_AT_FULL := 0.2
const SP_CHANGE := preload("res://scenes/ui/sp_change.tscn")
const LIGHT_FROM := 0.6  ## of max Sanity: where the number starts to light up with the glass

@export_group("Sanity change")
@export var up_color := Color(0.25, 0.55, 1.0)
@export var down_color := Color(1.0, 0.2, 0.18)
@export var change_lighten := 0.25  ## the change shows in the up or down colour, lightened

## Sanity to show (set by UnitBar).
var sp := 0:
	set(value):
		sp = value
		if is_node_ready():
			_show_sp()

static var _effects: FxEffectSet

var _sphere: FxEffect
var _pulse: FxEffect
var _pulse_name := ""

@onready var _stage: FxStage = $Stage


func _ready() -> void:
	if _effects == null:
		_effects = FxEffectSet.load_from(EFFECTS)
	_sphere = _play(SPHERE)
	_show_sp()


## A Sanity change to show: a ring, an arrow and by how much.
func show_change(delta: int) -> void:
	var change: SpChange = SP_CHANGE.instantiate()
	add_child(change)
	change.show_change(delta, (up_color if delta > 0 else down_color).lightened(change_lighten))


## 0..1: how far the number lights up with the glass (near +45). UnitBar lights it by this.
func bloom() -> float:
	return smoothstep(LIGHT_FROM, 1.0, float(sp) / UnitStatus.MAX_SP)


func _show_sp() -> void:
	_sphere.set_material_value(UP_VALUE, VALUE_AT_FULL * maxf(sp, 0.0) / UnitStatus.MAX_SP)
	_sphere.set_material_value(DOWN_VALUE, VALUE_AT_FULL * maxf(-sp, 0.0) / UnitStatus.MAX_SP)
	var pulse := PULSE_UP if sp > 0 else PULSE_DOWN if sp < 0 else ""
	if pulse == _pulse_name:
		return
	if _pulse:
		_pulse.queue_free()
	_pulse_name = pulse
	_pulse = _play(pulse) if pulse else null


## One of the orb's effects, playing on the stage until it's freed.
func _play(effect_name: String) -> FxEffect:
	var definition: FxEffectDef = _effects.effects[effect_name]
	var centre := Vector2(_stage.size) / 2.0
	var effect := FxEffect.new()
	effect.anchor_to(func() -> Vector2: return centre, definition)
	_stage.play(effect, definition, INF, centre, centre)
	return effect
