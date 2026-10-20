class_name AfterimageTrail
extends Node
## The faint copy of its pose a sinner leaves where each attack starts (the game's
## CharacterAppearanceTrail): the attack's first frame stays put as the sinner moves on to
## the next one, and fades out.

const TINT := &"tint"  ## afterimage.gdshader's colour

@export var body: SinnerBody
## The game's trail material, ported (scripts/sinner/afterimage.gdshader).
@export var copy_material: ShaderMaterial
@export var behind_z := -1  ## copies draw under the sinners

var _settings: AfterimageSettings
var _material: ShaderMaterial
var _layer: Node  ## where the next copy goes; null: none wanted


func _ready() -> void:
	body.pose_changing.connect(_on_pose_changing)


## Leave copies the way this identity does (null: none).
func follow(settings: AfterimageSettings) -> void:
	_settings = settings
	_material = copy_material.duplicate()
	if settings and settings.has_own_color:
		_material.set_shader_parameter(TINT, settings.color)


## An attack starts: once the pose shown now gives way to the next, leave a copy of it on
## `layer` (a node at the overlay's origin).
func copy_when_pose_changes(layer: Node) -> void:
	_layer = layer if _settings else null


## The sinner stopped attacking: no copy pending.
func cancel() -> void:
	_layer = null


func _on_pose_changing() -> void:
	if _layer == null:
		return
	var copy := body.still_copy()
	if copy:
		copy.material = _material
		copy.z_index = behind_z
		_layer.add_child(copy)
		var fade := copy.create_tween()
		fade.tween_property(copy, "self_modulate:a", 0.0, _settings.keep_seconds)
		fade.tween_callback(copy.queue_free)
	_layer = null
