class_name FxSystemDef
extends RefCounted
## One part of an effect from fx.json: a particle system or a line. Each kind knows how to
## make the node that plays it (instantiate()).

var name := ""
var path := ""  ## where it sits in the effect, which sub-emitters name it by
var hidden := false  ## its renderer is off in the prefab: it plays but draws nothing
var material: FxMaterialDef  ## null: it has none (it draws nothing)
var transform := Transform3D.IDENTITY  ## from the system's space to the effect's, in px


## The right kind of definition for a system's data.
static func from_json(data: Dictionary) -> FxSystemDef:
	var definition: FxSystemDef = FxLineDef.new() if data.kind == "line" else FxParticleSystemDef.new()
	definition.name = data.get("name", "")
	definition.path = data.get("path", "")
	definition.hidden = data.get("hidden", false)
	if data.has("material"):
		definition.material = FxMaterialDef.from_json(data.material, data.get("anim", {}))
	definition.transform = FxUnity.transform(data.matrix)
	definition._read(data)
	return definition


## Whether it shows anything.
func draws() -> bool:
	return not hidden and material != null


## The game's floor hides it below the feet (its shader tests depth).
func hidden_below_floor() -> bool:
	return draws() and material.depth_tested


## A distortion or screen filter: plays on FxStage's screen layer.
func reads_screen() -> bool:
	return draws() and material.reads_screen


## The node that plays it. source, target: global points a line runs between.
func instantiate(_rng: RandomNumberGenerator, _source: Vector2, _target: Vector2) -> Node2D:
	return null


## Reads the fields of its kind.
func _read(_data: Dictionary) -> void:
	pass
