class_name EffectAnchors
extends RefCounted
## The points a sinner's effects go from while it plays a timeline (FxEffectDef.Anchor): its
## own feet and centre point, and its foe's. The foe (a desktop icon, or shadow-boxing's
## imaginary one) is known by its centre; having no body, its feet are taken to be the game's
## usual centre height below that. With no foe, effects meant for it play on the sinner.

## px from a foe's feet up to its centre: the game's usual CharacterCenterPoint (1.1 units).
const FOE_CENTER_HEIGHT := 66.0

var _sinner: Sinner
var _foe_center := Callable()  ## -> Vector2 in the sinner's parent's coordinates; invalid: no foe


func _init(sinner: Sinner, foe_center: Callable) -> void:
	_sinner = sinner
	_foe_center = foe_center


## Where `anchor` is now, in the sinner's parent's coordinates.
func point(anchor: FxEffectDef.Anchor) -> Vector2:
	match anchor:
		FxEffectDef.Anchor.CASTER_CENTER:
			return _caster_center()
		FxEffectDef.Anchor.TARGET_FEET:
			return foe_center() + Vector2(0, FOE_CENTER_HEIGHT) if has_foe() else _sinner.position
		FxEffectDef.Anchor.TARGET_CENTER:
			return foe_center()
	return _sinner.position


func has_foe() -> bool:
	return _foe_center.is_valid()


## The foe's centre (what a line effect runs to); the sinner's own without a foe.
func foe_center() -> Vector2:
	return _foe_center.call() if has_foe() else _caster_center()


func _caster_center() -> Vector2:
	return _sinner.position + _sinner.identity.body_center() * Vector2(_sinner.facing, -1)
