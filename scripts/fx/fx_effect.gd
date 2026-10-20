class_name FxEffect
extends Node2D
## One of the game's skill effects (a Unity prefab of particle systems and lines), played in
## 2D from its FxEffectDef: each part plays as its own node (FxParticleSystem, FxLine) and
## draws through the game's own shader, translated (FxMaterialDef). Systems that others'
## particles set off (sub-emitters) are linked to them here.
## Set scale.x (-1 facing left), anchor_to(), stand_on(), then FxStage.play(). Frees itself.

var _life := 1.0  ## seconds the game keeps it on
var _time := 0.0
var _rng := RandomNumberGenerator.new()
var _anchor := Callable()  ## -> Vector2: the point it goes from, in its parent's coordinates
var _offset := Vector2.ZERO  ## from that point, on the screen
var _follows := false
var _follows_height := false
var _floor_y := INF  ## the battle floor, y in its parent's coordinates; INF: none
var _below_floor_hidden: Array[FxSystemNode] = []  ## parts the floor hides (FxSystemDef.hidden_below_floor())
var _screen_part: Node2D  ## its screen-reading parts, on FxStage's screen layer


## Places it at `anchor_at` (Callable -> Vector2, the definition's anchor point now) plus its
## offset, mirrored by scale.x; if the definition follows, it keeps to that point as it moves.
func anchor_to(anchor_at: Callable, definition: FxEffectDef) -> void:
	_anchor = anchor_at
	_offset = definition.offset * Vector2(scale.x, -1)
	_follows = definition.follows
	_follows_height = definition.follows_height
	position = anchor_at.call() + _offset


## The floor y (parent coordinates) below which depth-tested parts are hidden.
func stand_on(floor_y: float) -> void:
	_floor_y = floor_y


## life: seconds on. source, target: where lines run. screen_layer: for screen-reading parts.
func play(definition: FxEffectDef, life: float, source: Vector2, target: Vector2, screen_layer: Node2D = null) -> void:
	_life = life
	var by_path: Dictionary[String, Node2D] = {}
	for system in definition.systems:
		if _plays(system):
			var node := system.instantiate(_rng, source, target)
			by_path[system.path] = node
			_holder_for(system, screen_layer).add_child(node)
			if system.hidden_below_floor():
				_below_floor_hidden.append(node as FxSystemNode)
	for system in definition.systems:
		if system is FxParticleSystemDef and by_path.has(system.path):
			_link_sub_emitters(system as FxParticleSystemDef, by_path)
	_hide_below_floor()


## Sets a value of its parts' materials over the game's own (one the game's code drives).
func set_material_value(property: String, value: float) -> void:
	for system in _parts():
		system.material_values[property] = value


func _process(delta: float) -> void:
	_time += delta
	if _time >= _life:
		queue_free()
		return
	if _follows and _anchor.is_valid():
		var now: Vector2 = _anchor.call() + _offset
		position = Vector2(now.x, now.y if _follows_height else position.y)
		_hide_below_floor()
	if _screen_part:
		_screen_part.transform = transform
	for system in _parts():
		system.advance(_time, delta)


func _exit_tree() -> void:
	if _screen_part:
		_screen_part.queue_free()


func _holder_for(system: FxSystemDef, screen_layer: Node2D) -> Node2D:
	if screen_layer == null or not system.reads_screen():
		return self
	if _screen_part == null:
		_screen_part = Node2D.new()
		_screen_part.transform = transform
		screen_layer.add_child(_screen_part)
	return _screen_part


func _parts() -> Array[FxSystemNode]:
	var parts: Array[FxSystemNode] = []
	parts.assign(get_children())
	if _screen_part:
		parts.append_array(_screen_part.get_children())
	return parts


func _hide_below_floor() -> void:
	if is_inf(_floor_y):
		return
	var floor_here := (_floor_y - position.y) / scale.y
	for system in _below_floor_hidden:
		system.hide_below(floor_here)


## A part plays if it draws or sets others off (an invisible emitter can drive visible ones).
static func _plays(system: FxSystemDef) -> bool:
	return system.draws() or (system is FxParticleSystemDef and not (system as FxParticleSystemDef).sub_emitters.is_empty())


static func _link_sub_emitters(system: FxParticleSystemDef, by_path: Dictionary[String, Node2D]) -> void:
	var node: FxParticleSystem = by_path[system.path]
	for link in system.sub_emitters:
		var target := by_path.get(link.system_path) as FxParticleSystem
		if target:
			node.set_off(link, target)
