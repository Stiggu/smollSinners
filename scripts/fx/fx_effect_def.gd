class_name FxEffectDef
extends RefCounted
## One of the game's effects (a Unity prefab of particle systems and lines), as
## tools/extract_effects.py exports it into an identity's fx.json: where it goes and its parts.

## The point the game puts it at: the caster's or the target's feet or centre point.
enum Anchor { CASTER_FEET, CASTER_CENTER, TARGET_FEET, TARGET_CENTER }

const ANCHORS := {"caster_feet": Anchor.CASTER_FEET, "caster_center": Anchor.CASTER_CENTER,
		"target_feet": Anchor.TARGET_FEET, "target_center": Anchor.TARGET_CENTER}

var anchor := Anchor.CASTER_FEET
var offset := Vector2.ZERO  ## px from its anchor point (x forward, y up): where it sits in the prefab
var follows := false  ## it keeps to its anchor point as that moves...
var follows_height := false  ## ... up and down too
var systems: Array[FxSystemDef] = []  ## in drawing order


static func from_json(data: Dictionary) -> FxEffectDef:
	var effect := FxEffectDef.new()
	effect.anchor = ANCHORS.get(data.get("anchor", "caster_feet"), Anchor.CASTER_FEET)
	effect.offset = Vector2(data.pos[0], data.pos[1])
	effect.follows = data.get("follow", false)
	effect.follows_height = data.get("follow_y", false)
	for system: Dictionary in data.systems:
		effect.systems.append(FxSystemDef.from_json(system))
	return effect


func is_on_target() -> bool:
	return anchor == Anchor.TARGET_FEET or anchor == Anchor.TARGET_CENTER


## How far in front of its anchor point it plays, px: its offset plus where its drawn parts
## are centred along the way it faces (the middle of them, so one stray part doesn't count).
func forward_reach() -> float:
	var centres: Array[float] = []
	for system in systems:
		if system.draws():
			centres.append(system.transform.origin.x)
	if centres.is_empty():
		return offset.x
	centres.sort()
	return offset.x + centres[floori(centres.size() / 2.0)]
