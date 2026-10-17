class_name FxEffect
extends Node2D
## One of the game's skill effects (a Unity prefab of particle systems and lines), played in
## 2D from its FxEffectDef: each part plays as its own node (FxParticleSystem, FxLine) and
## draws through the game's own shader, translated (FxMaterialDef). Systems that others'
## particles set off (sub-emitters) are linked to them here.
## Add it to the overlay, set scale.x (-1 for a caster facing left), anchor_to() the point the
## game puts it at, then play(). It frees itself when the game would switch it off.

var _life := 1.0  ## seconds the game keeps it on
var _time := 0.0
var _rng := RandomNumberGenerator.new()
var _anchor := Callable()  ## -> Vector2: the point it goes from, in its parent's coordinates
var _offset := Vector2.ZERO  ## from that point, on the screen
var _follows := false
var _follows_height := false


## Places it at `anchor_at` (Callable -> Vector2, the definition's anchor point now) plus its
## offset, mirrored by scale.x; if the definition follows, it keeps to that point as it moves.
func anchor_to(anchor_at: Callable, definition: FxEffectDef) -> void:
	_anchor = anchor_at
	_offset = definition.offset * Vector2(scale.x, -1)
	_follows = definition.follows
	_follows_height = definition.follows_height
	position = anchor_at.call() + _offset


## life: seconds it stays on (its clip's length in the timeline). source, target: global
## points a line runs between (the caster's head and the foe).
func play(definition: FxEffectDef, life: float, source: Vector2, target: Vector2) -> void:
	_life = life
	var by_path: Dictionary[String, Node2D] = {}
	for system in definition.systems:
		if _plays(system):
			var node := system.instantiate(_rng, source, target)
			by_path[system.path] = node
			add_child(node)
	for system in definition.systems:
		if system is FxParticleSystemDef and by_path.has(system.path):
			_link_sub_emitters(system as FxParticleSystemDef, by_path)


func _process(delta: float) -> void:
	_time += delta
	if _time >= _life:
		queue_free()
		return
	if _follows and _anchor.is_valid():
		var now: Vector2 = _anchor.call() + _offset
		position = Vector2(now.x, now.y if _follows_height else position.y)
	for system: FxSystemNode in get_children():
		system.advance(_time, delta)


## A part plays if it draws or sets others off (an invisible emitter can drive visible ones).
static func _plays(system: FxSystemDef) -> bool:
	return system.draws() or (system is FxParticleSystemDef and not (system as FxParticleSystemDef).sub_emitters.is_empty())


static func _link_sub_emitters(system: FxParticleSystemDef, by_path: Dictionary[String, Node2D]) -> void:
	var node: FxParticleSystem = by_path[system.path]
	for link in system.sub_emitters:
		var target := by_path.get(link.system_path) as FxParticleSystem
		if target:
			node.set_off(link, target)
