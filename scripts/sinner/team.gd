class_name Team
extends Node2D
## The sinners out on the desktop, as its children: one of each sinner at most, as in the
## game's formation, each wearing one identity. Identities go by path, "<sinner>/<folder>"
## (see IdentityLibrary).

## Someone came out, went home or changed identity.
signal changed
## A member's idle AI wants to fight a desktop icon.
signal clash_wanted(sinner: Sinner)
## A member was let go of after being carried.
signal member_dropped(sinner: Sinner)

const SINNER_SCENE := preload("res://scenes/sinner/sinner.tscn")
## A sinner brought out from Settings drops in somewhere in this span of the overlay's width.
const SPAWN_SPAN := Vector2(0.15, 0.85)

## Where the members' particle effects play: over the clashes, with the game's bloom.
@export var fx_stage: FxStage

var members: Array[Sinner] = []


## The playable identities in `paths`, one per sinner (the first one wins); the default
## identity if that leaves none.
static func valid_lineup(paths: Array[String]) -> Array[String]:
	var lineup: Array[String] = []
	var sinners_in := {}
	for path in paths:
		var sinner_key := IdentityLibrary.sinner_of(path)
		if IdentityLibrary.is_playable(path) and not sinners_in.has(sinner_key):
			lineup.append(path)
			sinners_in[sinner_key] = true
	if lineup.is_empty():
		lineup.append(IdentityLibrary.DEFAULT_IDENTITY)
	return lineup


## Bring out a whole lineup, spread evenly across the overlay.
func bring_out(lineup: Array[String]) -> void:
	for i in lineup.size():
		_spawn(lineup[i], _spread(i, lineup.size()))


## Put an identity on the desktop: its sinner changes into it if they're out, else comes out.
func wear(identity_path: String) -> Sinner:
	var sinner := member_for(IdentityLibrary.sinner_of(identity_path))
	if sinner == null:
		sinner = _spawn(identity_path, randf_range(SPAWN_SPAN.x, SPAWN_SPAN.y))
	elif sinner.identity.path != identity_path:
		sinner.wear(IdentityLibrary.load_identity(identity_path))  # also stops a running clash
	changed.emit()
	return sinner


## Off the team and out of sight. The caller frees it once nothing needs it any more (a clash
## it was in may still be putting its icon back).
func dismiss(sinner: Sinner) -> void:
	members.erase(sinner)
	sinner.hide()
	changed.emit()


## Everyone drops back in from above, spread evenly across the overlay.
func drop_all_in() -> void:
	for i in members.size():
		members[i].drop_in(_spread(i, members.size()))


## The member wearing one of this sinner's identities (key e.g. "yisang"), if any.
func member_for(sinner_key: String) -> Sinner:
	for sinner in members:
		if IdentityLibrary.sinner_of(sinner.identity.path) == sinner_key:
			return sinner
	return null


## The identities out, as paths.
func identity_paths() -> Array[String]:
	var paths: Array[String] = []
	for sinner in members:
		paths.append(sinner.identity.path)
	return paths


func _spawn(identity_path: String, x_fraction: float) -> Sinner:
	var sinner: Sinner = SINNER_SCENE.instantiate()
	sinner.fx_stage = fx_stage
	add_child(sinner)
	sinner.wear(IdentityLibrary.load_identity(identity_path))
	sinner.drop_in(x_fraction)
	sinner.clash_wanted.connect(clash_wanted.emit.bind(sinner))
	sinner.dropped.connect(member_dropped.emit.bind(sinner))
	members.append(sinner)
	return sinner


## The i-th of n evenly spaced places across the overlay, as a fraction of its width.
static func _spread(i: int, n: int) -> float:
	return (i + 1.0) / (n + 1.0)
