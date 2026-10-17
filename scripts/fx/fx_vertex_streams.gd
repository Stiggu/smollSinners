class_name FxVertexStreams
extends RefCounted
## What the game's particle renderer sends its shader with each vertex besides position,
## normal and colour: Unity's vertex streams (uv, custom data, random numbers...), in the
## order the renderer lists them, packed four floats to a TEXCOORD the way Unity packs them
## (a stream may run on into the next TEXCOORD). One row of floats a vertex: the TEXCOORDs,
## then the normal for mesh particles. The translated shader reads them back by VERTEX_ID
## (see FxVertexData and tools/fx_shaders.py).

## Unity's ParticleSystemVertexStream.
enum Stream {
	POSITION = 0, NORMAL = 1, TANGENT = 2, COLOR = 3, UV = 4, UV2 = 5, UV3 = 6, UV4 = 7,
	ANIM_BLEND = 8, ANIM_FRAME = 9, CENTER = 10, VERTEX_ID = 11,
	SIZE_X = 12, SIZE_XY = 13, SIZE_XYZ = 14, ROTATION = 15, ROTATION_3D = 16,
	ROTATION_SPEED = 17, ROTATION_SPEED_3D = 18, VELOCITY = 19, SPEED = 20,
	AGE_PERCENT = 21, INV_START_LIFETIME = 22,
	STABLE_RANDOM_X = 23, STABLE_RANDOM_XY = 24, STABLE_RANDOM_XYZ = 25, STABLE_RANDOM_XYZW = 26,
	VARYING_RANDOM_X = 27, VARYING_RANDOM_XY = 28, VARYING_RANDOM_XYZ = 29, VARYING_RANDOM_XYZW = 30,
	CUSTOM1_X = 31, CUSTOM1_XY = 32, CUSTOM1_XYZ = 33, CUSTOM1_XYZW = 34,
	CUSTOM2_X = 35, CUSTOM2_XY = 36, CUSTOM2_XYZ = 37, CUSTOM2_XYZW = 38,
}

const FLOATS_PER_SLOT := 4
## What a renderer sends when it names no streams of its own: position, normal, colour, uv.
const DEFAULT := [Stream.POSITION, Stream.NORMAL, Stream.COLOR, Stream.UV]
## Streams with a vertex attribute of their own rather than a share of the TEXCOORDs.
const OWN_ATTRIBUTE := [Stream.POSITION, Stream.NORMAL, Stream.TANGENT, Stream.COLOR]
## How many floats each stream takes; those not listed take one. Noise and mesh-index
## streams (39 and up) are sent as zeros.
const WIDTHS := {
	Stream.UV: 2, Stream.UV2: 2, Stream.UV3: 2, Stream.UV4: 2, Stream.CENTER: 3,
	Stream.SIZE_XY: 2, Stream.SIZE_XYZ: 3, Stream.ROTATION_3D: 3, Stream.ROTATION_SPEED_3D: 3,
	Stream.VELOCITY: 3, Stream.STABLE_RANDOM_XY: 2, Stream.STABLE_RANDOM_XYZ: 3,
	Stream.STABLE_RANDOM_XYZW: 4, Stream.VARYING_RANDOM_XY: 2, Stream.VARYING_RANDOM_XYZ: 3,
	Stream.VARYING_RANDOM_XYZW: 4, Stream.CUSTOM1_XY: 2, Stream.CUSTOM1_XYZ: 3,
	Stream.CUSTOM1_XYZW: 4, Stream.CUSTOM2_XY: 2, Stream.CUSTOM2_XYZ: 3, Stream.CUSTOM2_XYZW: 4,
	39: 1, 40: 2, 41: 3, 42: 1, 43: 2, 44: 3,
}
## The uv streams: every vertex has its own (the rest are the particle's).
const UV_STREAMS := [Stream.UV, Stream.UV2, Stream.UV3, Stream.UV4]

var texcoord_slots := 0  ## TEXCOORDs the streams fill
var normal_slot := -1  ## where a mesh particle's normal goes; -1: none (the shader's facing the camera)
var _streams: Array[int] = []  ## those packed into the TEXCOORDs, in order
var _starts := PackedInt32Array()  ## the float each starts at
var _uv_starts := PackedInt32Array()  ## where the uv streams' floats go


## ids: Unity's stream numbers as the renderer lists them. with_normal: give each vertex a
## normal (mesh particles).
static func from_ids(ids: Array, with_normal := false) -> FxVertexStreams:
	var streams := FxVertexStreams.new()
	var floats := 0
	for id in ids:
		if int(id) in OWN_ATTRIBUTE:
			continue
		streams._streams.append(int(id))
		streams._starts.append(floats)
		if int(id) in UV_STREAMS:
			streams._uv_starts.append(floats)
		floats += WIDTHS.get(int(id), 1)
	streams.texcoord_slots = ceili(float(floats) / FLOATS_PER_SLOT)
	if with_normal:
		streams.normal_slot = streams.texcoord_slots
	return streams


## TEXCOORDs plus the normal, if any.
func slots() -> int:
	return texcoord_slots + (1 if normal_slot >= 0 else 0)


func floats_per_vertex() -> int:
	return slots() * FLOATS_PER_SLOT


## One vertex's row with everything that's the particle's (its uvs and normal still zero).
func particle_row(state: FxParticleState) -> PackedFloat32Array:
	var row := PackedFloat32Array()
	row.resize(floats_per_vertex())
	for i in _streams.size():
		_write(row, _starts[i], _streams[i], state)
	return row


## Adds a vertex: the particle's row with this vertex's uv (Unity's: v up) and normal.
func add_vertex(data: PackedFloat32Array, particle_row: PackedFloat32Array, uv: Vector2, normal := Vector3.ZERO) -> void:
	var at := data.size()
	data.append_array(particle_row)
	for start in _uv_starts:
		data[at + start] = uv.x
		data[at + start + 1] = uv.y
	if normal_slot >= 0:
		var n := at + normal_slot * FLOATS_PER_SLOT
		data[n] = normal.x
		data[n + 1] = normal.y
		data[n + 2] = normal.z


func _write(row: PackedFloat32Array, at: int, stream: int, state: FxParticleState) -> void:
	match stream:
		Stream.ANIM_FRAME:
			row[at] = state.frame
		Stream.CENTER:
			_put(row, at, [state.center.x, state.center.y, state.center.z])
		Stream.SIZE_X, Stream.SIZE_XY, Stream.SIZE_XYZ:
			_put(row, at, [state.size.x, state.size.y, state.size.z], WIDTHS.get(stream, 1))
		Stream.ROTATION:
			row[at] = state.particle.rotation.z
		Stream.ROTATION_3D:
			_put(row, at, [state.particle.rotation.x, state.particle.rotation.y, state.particle.rotation.z])
		Stream.VELOCITY:
			_put(row, at, [state.velocity.x, state.velocity.y, state.velocity.z])
		Stream.SPEED:
			row[at] = state.velocity.length()
		Stream.AGE_PERCENT:
			row[at] = state.particle.life_fraction()
		Stream.INV_START_LIFETIME:
			row[at] = 1.0 / state.particle.lifetime
		Stream.STABLE_RANDOM_X, Stream.STABLE_RANDOM_XY, Stream.STABLE_RANDOM_XYZ, Stream.STABLE_RANDOM_XYZW:
			_put_vector4(row, at, state.particle.stable_random, WIDTHS.get(stream, 1))
		Stream.VARYING_RANDOM_X, Stream.VARYING_RANDOM_XY, Stream.VARYING_RANDOM_XYZ, Stream.VARYING_RANDOM_XYZW:
			_put_vector4(row, at, state.varying_random, WIDTHS.get(stream, 1))
		Stream.CUSTOM1_X, Stream.CUSTOM1_XY, Stream.CUSTOM1_XYZ, Stream.CUSTOM1_XYZW:
			_put_vector4(row, at, state.particle.custom1, WIDTHS.get(stream, 1))
		Stream.CUSTOM2_X, Stream.CUSTOM2_XY, Stream.CUSTOM2_XYZ, Stream.CUSTOM2_XYZW:
			_put_vector4(row, at, state.particle.custom2, WIDTHS.get(stream, 1))


static func _put(row: PackedFloat32Array, at: int, values: Array, count := -1) -> void:
	for i in (values.size() if count < 0 else count):
		row[at + i] = values[i]


static func _put_vector4(row: PackedFloat32Array, at: int, value: Vector4, count: int) -> void:
	_put(row, at, [value.x, value.y, value.z, value.w], count)
