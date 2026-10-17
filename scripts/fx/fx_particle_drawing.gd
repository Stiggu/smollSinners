class_name FxParticleDrawing
extends RefCounted
## Turns a particle system's live particles into one triangle array a frame for the game's
## shader: each particle a billboard (facing the camera), a stretched billboard (drawn out
## behind it along its motion) or its mesh, in its colour, with the vertex streams the shader
## reads (FxVertexStreams, handed over by FxVertexData). All in one array, so each vertex's
## VERTEX_ID finds its streams.

## A billboard lying flat, as the battle camera's slight downward tilt shows it.
const HORIZONTAL_SQUASH := 0.2
const MIN_STRETCH := 0.0001  ## px of motion a frame under which a stretched billboard just faces the camera

var _def: FxParticleSystemDef
var _billboard_px := 1.0  ## px a unit of billboard size
var _vertex_data := FxVertexData.new()
var _state := FxParticleState.new()
var _rng: RandomNumberGenerator


func _init(definition: FxParticleSystemDef, billboard_px: float, rng: RandomNumberGenerator) -> void:
	_def = definition
	_billboard_px = billboard_px
	_rng = rng


func draw(canvas_item: RID, particles: Array[FxParticle], material: ShaderMaterial) -> void:
	var mesh := FxAssets.mesh(_def.mesh_name) if _def.render == FxParticleSystemDef.Render.MESH else FxAssets.quad()
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var data := PackedFloat32Array()
	for particle in particles:
		_follow(particle)
		var row := _def.streams.particle_row(_state)
		var frame := int(_state.frame)
		var turn := FxUnity.rotation(particle.rotation)
		var first := points.size()
		for i in mesh.vertices.size():
			points.append(_corner(particle, mesh.vertices[i], turn))
			colors.append(particle.shown_color)
			_def.streams.add_vertex(data, row, _uv(mesh.uv(i), frame), _normal(mesh, i, turn))
		for index in mesh.indices:
			indices.append(first + index)
	if indices.is_empty():
		return
	_vertex_data.upload(data, _def.streams, material)
	RenderingServer.canvas_item_add_triangle_array(canvas_item, indices, points, colors)


## The particle as its shader sees it this frame, in the effect's units.
func _follow(particle: FxParticle) -> void:
	_state.particle = particle
	_state.center = _def.transform * particle.position / FxUnity.PX_PER_UNIT
	_state.size = particle.shown_size
	_state.velocity = _def.transform.basis * particle.moving / FxUnity.PX_PER_UNIT
	_state.frame = _def.flipbook.frame_at(particle.life_fraction(), particle.flipbook_pick) if _def.flipbook else 0
	_state.varying_random = Vector4(_rng.randf(), _rng.randf(), _rng.randf(), _rng.randf())


## Where a vertex of the particle's quad or mesh lands on the screen.
func _corner(particle: FxParticle, vertex: Vector3, turn: Basis) -> Vector2:
	var center := FxUnity.to_screen(_def.transform, particle.position)
	match _def.render:
		FxParticleSystemDef.Render.MESH:
			return FxUnity.to_screen(_def.transform, turn * (vertex * particle.shown_size) + particle.position)
		FxParticleSystemDef.Render.STRETCHED:
			var motion := FxUnity.to_screen(_def.transform, particle.position + particle.moving) - center
			if motion.length() > MIN_STRETCH:
				return center + _stretched(particle, vertex, motion.normalized())
		FxParticleSystemDef.Render.HORIZONTAL:
			return center + _billboard(particle, vertex) * Vector2(1.0, HORIZONTAL_SQUASH)
	return center + _billboard(particle, vertex)


## A billboard faces the camera: it turns only about the view axis, and its size goes through
## the system's scale but not its rotation.
func _billboard(particle: FxParticle, vertex: Vector3) -> Vector2:
	var corner := Vector2(vertex.x * particle.shown_size.x, vertex.y * particle.shown_size.y).rotated(particle.rotation.z)
	return Vector2(corner.x, -corner.y) * _billboard_px


## A stretched billboard runs back from the particle along its motion (u along it, the head
## at u = 1): as long as its size times the length scale, plus its speed times the speed scale.
func _stretched(particle: FxParticle, vertex: Vector3, heading: Vector2) -> Vector2:
	var speed := particle.moving.length()
	var length := (particle.shown_size.x * _def.length_scale + speed * _def.velocity_scale) * _billboard_px
	var width := particle.shown_size.y * _billboard_px
	return heading * (vertex.x - 0.5) * length + heading.orthogonal() * vertex.y * width


func _uv(uv: Vector2, frame: int) -> Vector2:
	return _def.flipbook.uv_in_frame(uv, frame) if _def.flipbook else uv


## A mesh vertex's normal in the effect's space (a billboard's faces the camera: the shader's own).
func _normal(mesh: FxAssets.MeshData, vertex: int, turn: Basis) -> Vector3:
	if _def.streams.normal_slot < 0:
		return Vector3.ZERO
	return (_def.transform.basis * (turn * mesh.normal(vertex))).normalized()
