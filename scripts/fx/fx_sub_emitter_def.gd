class_name FxSubEmitterDef
extends RefCounted
## A particle system another one's particles set off (Unity's Sub Emitters module): when one
## of them is born it starts the other emitting from where it is, following it while it lives;
## when one dies the other bursts there once.

enum Trigger { BIRTH = 0, COLLISION = 1, DEATH = 2, TRIGGER = 3, MANUAL = 4 }
## What the set-off particles take from the one that set them off (Unity's flags).
const INHERIT_COLOR := 1

var system_path := ""  ## the system set off, by its path in the effect
var trigger := Trigger.BIRTH
var inherit := 0
var probability := 1.0
var to_child := Transform3D.IDENTITY  ## a point in the setting-off system's space into the other's


static func from_json(data: Dictionary) -> FxSubEmitterDef:
	var link := FxSubEmitterDef.new()
	link.system_path = data.system
	link.trigger = int(data.type) as Trigger
	link.inherit = int(data.get("inherit", 0))
	link.probability = data.get("probability", 1.0)
	if data.has("to_child"):
		link.to_child = FxUnity.transform(data.to_child)
	return link


func inherits_color() -> bool:
	return inherit & INHERIT_COLOR != 0
