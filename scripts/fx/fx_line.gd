class_name FxLine
extends FxSystemNode
## A line effect running from the caster to the target (a Unity LineRenderer), drawn through
## the game's shader with Unity's line uv: u along the line from the caster, v across. Its
## points zigzag like lightning, bent anew every REZIGZAG_SECONDS: the game sets them from a
## script that isn't in its files. How it's revealed and fades is the shader's, by the
## material values its Animator keys.

const REZIGZAG_SECONDS := 0.04  ## a new zigzag this often
const ZIGZAG := 0.7  ## how far each bend strays, as a share of the line's width
const LEAD := Vector2(1, 0)  ## which way a line with no length would face

var _def: FxLineDef
var _rng: RandomNumberGenerator
var _source := Vector2.ZERO  ## global: on the caster
var _target := Vector2.ZERO  ## global
var _bends := PackedFloat32Array()  ## each point's offset across the line
var _bent_at := -INF
var _time := 0.0
var _streams := FxVertexStreams.from_ids(FxVertexStreams.DEFAULT)
var _vertex_data := FxVertexData.new()
var _shader_material: ShaderMaterial


func setup(definition: FxLineDef, rng: RandomNumberGenerator, source: Vector2, target: Vector2) -> void:
	_def = definition
	_rng = rng
	_source = source
	_target = target
	if definition.draws():
		_shader_material = definition.material.make_material()
		material = _shader_material


func advance(effect_time: float, _delta: float) -> void:
	_time = effect_time
	if _shader_material:
		_def.material.animate(_shader_material, effect_time, material_values)
		queue_redraw()


func _draw() -> void:
	if not _shader_material:
		return
	var spine := _zigzag(to_local(_source), to_local(_target))
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var data := PackedFloat32Array()
	var row := _streams.particle_row(FxParticleState.new())
	for i in spine.size():
		var along := float(i) / (spine.size() - 1)
		var across := _direction(spine, i).orthogonal() * _def.width_at(along) * FxUnity.PX_PER_UNIT / 2.0
		var color := _def.color_at(along)
		points.append(spine[i] + across)
		points.append(spine[i] - across)
		colors.append(color)
		colors.append(color)
		_streams.add_vertex(data, row, Vector2(along, 1.0))
		_streams.add_vertex(data, row, Vector2(along, 0.0))
		if i > 0:
			var at := (i - 1) * 2
			indices.append_array(PackedInt32Array([at, at + 1, at + 2, at + 1, at + 3, at + 2]))
	_vertex_data.upload(data, _streams, _shader_material)
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), indices, points, colors)


## The line's points from a to b, each but the ends bent off the straight by its zigzag,
## which changes every REZIGZAG_SECONDS.
func _zigzag(a: Vector2, b: Vector2) -> PackedVector2Array:
	if _bends.size() != _def.points or _time - _bent_at >= REZIGZAG_SECONDS:
		_bend_again()
	var normal := (b - a).orthogonal().normalized()
	var spine := PackedVector2Array()
	for i in _def.points:
		spine.append(a.lerp(b, float(i) / (_def.points - 1)) + normal * _bends[i])
	return spine


func _bend_again() -> void:
	_bent_at = _time
	var stray := _def.width * FxUnity.PX_PER_UNIT * ZIGZAG
	_bends.resize(_def.points)
	for i in _def.points:
		var is_end := i == 0 or i == _def.points - 1
		_bends[i] = 0.0 if is_end else _rng.randf_range(-1.0, 1.0) * stray


static func _direction(spine: PackedVector2Array, i: int) -> Vector2:
	var span := spine[mini(i + 1, spine.size() - 1)] - spine[maxi(i - 1, 0)]
	return span.normalized() if span.length_squared() > 0.0 else LEAD
