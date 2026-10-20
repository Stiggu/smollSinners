class_name FxStage
extends Node2D
## Skill effects drawn in HDR with the game's bloom; parts that read the screen play on
## ScreenEffects above. Idle while no effect plays. Covers the overlay, or `size` px from its
## position (a small stage of its own for one thing that always glows).

## px; zero: the whole overlay, following it as it resizes.
@export var size := Vector2i.ZERO
## Drawn this many times finer than shown, so thin lines on a small stage don't break up.
@export_range(1, 4) var oversample := 1

@onready var _bloom: FxBloom = $Bloom
@onready var _composite: Sprite2D = $Composite
@onready var _screen_effects: Node2D = $ScreenEffects


func _ready() -> void:
	_bloom.levels += _levels_for_oversample()
	_bloom.build(_stage_size() * oversample)
	_bloom.effects.scale = Vector2.ONE * oversample
	_composite.scale = Vector2.ONE / oversample
	_composite.texture = _bloom.picture
	(_composite.material as ShaderMaterial).set_shader_parameter("bloom", _bloom.glow)
	_bloom.effects.child_entered_tree.connect(_on_effect_started)
	_bloom.effects.child_exiting_tree.connect(_on_effect_ending)
	if size == Vector2i.ZERO:
		get_viewport().size_changed.connect(_on_overlay_resized)
	_show(false)


func play(effect: FxEffect, definition: FxEffectDef, life: float, source: Vector2, target: Vector2) -> void:
	_bloom.effects.add_child(effect)
	effect.play(definition, life, source, target, _screen_effects)


## Something else drawn in HDR under the bloom, placed in the stage's coordinates; it frees itself.
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
	_bloom.resize(_stage_size() * oversample)


func _stage_size() -> Vector2i:
	return size if size != Vector2i.ZERO else Vector2i(get_viewport_rect().size)


## One more blur level each time the stage is drawn twice as fine, so its glow spreads as far.
func _levels_for_oversample() -> int:
	return roundi(log(float(oversample)) / log(2.0))
