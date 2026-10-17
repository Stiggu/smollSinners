class_name FxTrails
extends Node2D
## The trails a particle system's particles leave (FxTrailDef), drawn behind them through the
## game's trail shader: a ribbon a particle, from where it is back along the points it passed,
## its width and colour by the trail's curves. Unity's trails carry only a uv (u along the
## trail from the particle, v across).

const LEAD := Vector2(1, 0)  ## which way a ribbon of one point would face

var _def: FxTrailDef
var _system_transform := Transform3D.IDENTITY
var _billboard_px := 1.0  ## px a unit of particle size
var _particles: Array[FxParticle] = []
var _streams := FxVertexStreams.from_ids(FxVertexStreams.DEFAULT)
var _vertex_data := FxVertexData.new()
var _material: ShaderMaterial


func setup(definition: FxTrailDef, system_transform: Transform3D, billboard_px: float) -> void:
	_def = definition
	_system_transform = system_transform
	_billboard_px = billboard_px
	show_behind_parent = true
	_material = definition.material.make_material()
	material = _material


## The particles to draw the trails of this frame, `time` seconds into the effect.
func show_trails(particles: Array[FxParticle], time: float) -> void:
	_particles = particles
	_def.material.animate(_material, time)
	queue_redraw()


func _draw() -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var data := PackedFloat32Array()
	var state := FxParticleState.new()
	for particle in _particles:
		if not particle.has_trail or particle.trail_points.is_empty():
			continue
		state.particle = particle
		var row := _streams.particle_row(state)
		var path := _screen_path(particle)
		var first := points.size()
		for i in path.size():
			var along := float(i) / (path.size() - 1)
			var half_width := _width(particle, along) / 2.0
			var across := _direction(path, i).orthogonal() * half_width
			var color := _color(particle, along)
			points.append(path[i] + across)
			points.append(path[i] - across)
			colors.append(color)
			colors.append(color)
			_streams.add_vertex(data, row, Vector2(along, 1.0))
			_streams.add_vertex(data, row, Vector2(along, 0.0))
			if i > 0:
				var at := first + (i - 1) * 2
				indices.append_array(PackedInt32Array([at, at + 1, at + 2, at + 1, at + 3, at + 2]))
	if indices.is_empty():
		return
	_vertex_data.upload(data, _streams, _material)
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), indices, points, colors)


## The particle, then the points it passed, newest first, on the screen.
func _screen_path(particle: FxParticle) -> PackedVector2Array:
	var path := PackedVector2Array([FxUnity.to_screen(_system_transform, particle.position)])
	for i in range(particle.trail_points.size() - 1, -1, -1):
		path.append(FxUnity.to_screen(_system_transform, particle.trail_points[i]))
	return path


func _width(particle: FxParticle, along: float) -> float:
	var width := _def.width_over_trail.sample(along, particle.custom_pick) * _billboard_px
	return width * particle.shown_size.x if _def.size_affects_width else width


func _color(particle: FxParticle, along: float) -> Color:
	var color := _def.color_over_trail.sample(along, particle.color_pick)
	color *= _def.color_over_lifetime.sample(particle.life_fraction(), particle.color_pick)
	return color * particle.shown_color if _def.inherit_particle_color else color


static func _direction(path: PackedVector2Array, i: int) -> Vector2:
	var span := path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]
	return span.normalized() if span.length_squared() > 0.0 else LEAD
