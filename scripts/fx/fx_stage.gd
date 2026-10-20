class_name FxStage
extends Node2D
## Skill effects drawn in HDR with the game's bloom; parts that read the screen play on
## ScreenEffects above. Idle while no effect plays.

@onready var _bloom: FxBloom = $Bloom
@onready var _composite: Sprite2D = $Composite
@onready var _screen_effects: Node2D = $ScreenEffects


func _ready() -> void:
	_bloom.build(_overlay_size())
	_composite.texture = _bloom.picture
	(_composite.material as ShaderMaterial).set_shader_parameter("bloom", _bloom.glow)
	_bloom.effects.child_entered_tree.connect(_on_effect_started)
	_bloom.effects.child_exiting_tree.connect(_on_effect_ending)
	get_viewport().size_changed.connect(_on_overlay_resized)
	_show(false)


func play(effect: FxEffect, definition: FxEffectDef, life: float, source: Vector2, target: Vector2) -> void:
	_bloom.effects.add_child(effect)
	effect.play(definition, life, source, target, _screen_effects)


## Something else drawn in HDR under the bloom, placed in overlay coordinates; it frees itself.
func add_glowing(node: Node2D) -> void:
	_bloom.effects.add_child(node)


func _on_effect_started(_effect: Node) -> void:
	_show(true)


func _on_effect_ending(_effect: Node) -> void:
	if _bloom.effects.get_child_count() <= 1:  # it's still counted as it leaves
		_show(false)


func _show(playing: bool) -> void:
	_bloom.run(playing)
	_composite.visible = playing


func _on_overlay_resized() -> void:
	_bloom.resize(_overlay_size())


func _overlay_size() -> Vector2i:
	return Vector2i(get_viewport_rect().size)
