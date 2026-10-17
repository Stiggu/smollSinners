class_name FxParticleSystem
extends FxSystemNode
## One particle system of a playing FxEffect. It emits by its own bursts and rate (FxEmission)
## or, as a sub-emitter, from each particle of the system that sets it off; moves and changes
## its particles by its over-lifetime modules; sets off its own sub-emitters as its particles
## are born and die; and draws them through the game's shader (FxParticleDrawing), trails
## behind (FxTrails). In 3D, then flat on the screen (the game's effects sit under a
## transform scaled flat in z, so its camera sees them flat too).

const UNITY_GRAVITY := 9.81  ## Unity units/s²
const GRAVITY_PICK := 0.5  ## gravity curves take the middle of their two
const MIN_LIFETIME := 0.01
const MIN_RADIUS := 0.0001  ## nearer the centre than this, outward has no direction
## The noise module here is a cheap sway rather than Unity's curl noise: each particle
## wobbles on its own pair of sine waves, faster the higher the module's frequency.
const NOISE_SPEED := 6.0
const NOISE_WAVES := Vector2(1.7, 1.3)  ## x and y sway at these relative rates
const NOISE_STRENGTH := 3.0
const NOISE_PHASES := 100.0  ## particles start their sway anywhere in this many radians


## A system this one's particles set off, and how.
class SubEmitter:
	var link: FxSubEmitterDef
	var system: FxParticleSystem


var _def: FxParticleSystemDef
var _rng: RandomNumberGenerator
var _particles: Array[FxParticle] = []
var _own: FxEmission  ## null for a sub-emitter, which only plays when set off
var _delay := 0.0
var _runs: Array[FxEmission] = []  ## started by other systems' particles
var _sub_emitters: Array[SubEmitter] = []
var _drawing: FxParticleDrawing
var _trails: FxTrails
var _shader_material: ShaderMaterial


func setup(definition: FxParticleSystemDef, rng: RandomNumberGenerator) -> void:
	_def = definition
	_rng = rng
	if not definition.is_sub_emitter:
		_own = FxEmission.new(definition)
		_delay = definition.delay.sample(0.0, rng.randf())
	var billboard_px := _billboard_scale(definition.transform)
	_drawing = FxParticleDrawing.new(definition, billboard_px, rng)
	if definition.draws():
		_shader_material = definition.material.make_material()
		material = _shader_material
	if definition.trail and definition.trail.material:
		_trails = FxTrails.new()
		_trails.setup(definition.trail, definition.transform, billboard_px)
		add_child(_trails)


## Has this system's particles set `system` off by `link`.
func set_off(link: FxSubEmitterDef, system: FxParticleSystem) -> void:
	var sub_emitter := SubEmitter.new()
	sub_emitter.link = link
	sub_emitter.system = system
	_sub_emitters.append(sub_emitter)


## Starts a run of this system from `parent`, a particle of the system that sets it off.
func start_from(parent: FxParticle, link: FxSubEmitterDef) -> void:
	var run := FxEmission.new(_def)
	run.from_parent = link.to_child
	run.origin = link.to_child * parent.position
	if link.trigger == FxSubEmitterDef.Trigger.BIRTH:
		run.follows = parent
	if link.inherits_color():
		run.tint = parent.shown_color
	_runs.append(run)


func advance(effect_time: float, delta: float) -> void:
	if _own and effect_time >= _delay:
		_emit(_own.advance(delta, _rng), _own)
	for run in _runs:
		if run.follows:
			run.origin = run.from_parent * run.follows.position
		_emit(run.advance(delta, _rng), run)
	_runs = _runs.filter(func(run: FxEmission) -> bool:
		return not run.is_over() and (run.follows == null or run.follows.is_alive()))
	for particle in _particles:
		particle.age += delta
		if particle.is_alive():
			_move(particle, delta)
			_update_look(particle)
			_record_trail(particle)
		else:
			_set_off(FxSubEmitterDef.Trigger.DEATH, particle)
	_particles = _particles.filter(func(particle: FxParticle) -> bool: return particle.is_alive())
	if _shader_material:
		_def.material.animate(_shader_material, effect_time)
		queue_redraw()
	if _trails:
		_trails.show_trails(_particles, effect_time)


func _draw() -> void:
	if _shader_material:
		_drawing.draw(get_canvas_item(), _particles, _shader_material)


#region Emission

func _emit(count: int, emission: FxEmission) -> void:
	var cycle := emission.cycle()
	for i in count:
		if _particles.size() >= _def.max_particles:
			return
		var particle := FxParticle.new()
		var spawn := _def.shape.spawn(_rng) if _def.shape else FxShape.default_spawn()
		particle.position = emission.origin + spawn.position
		particle.velocity = spawn.direction * _sample(_def.start_speed, cycle)
		particle.lifetime = maxf(_sample(_def.start_lifetime, cycle), MIN_LIFETIME)
		var size := _sample(_def.start_size, cycle)
		particle.size = Vector3(size, _sample_or(_def.start_size_y, cycle, size), _sample_or(_def.start_size_z, cycle, size))
		particle.rotation = Vector3(_sample_or(_def.start_rotation_x, cycle, 0.0), _sample_or(_def.start_rotation_y, cycle, 0.0),
				_sample(_def.start_rotation, cycle))
		particle.color = _def.start_color.sample(cycle, _rng.randf()) * emission.tint
		_pick_randoms(particle)
		particle.has_trail = _def.trail != null and _rng.randf() < _def.trail.ratio
		_update_look(particle)
		_particles.append(particle)
		_set_off(FxSubEmitterDef.Trigger.BIRTH, particle)


func _pick_randoms(particle: FxParticle) -> void:
	particle.velocity_pick = _rng.randf()
	particle.orbit_pick = _rng.randf()
	particle.size_pick = _rng.randf()
	particle.color_pick = _rng.randf()
	particle.noise_pick = _rng.randf()
	particle.flipbook_pick = _rng.randf()
	particle.spin_pick = _rng.randf()
	particle.custom_pick = _rng.randf()
	particle.noise_phase = _rng.randf() * NOISE_PHASES
	particle.stable_random = Vector4(_rng.randf(), _rng.randf(), _rng.randf(), _rng.randf())


## Sets off the sub-emitters waiting on `trigger` from `particle`.
func _set_off(trigger: FxSubEmitterDef.Trigger, particle: FxParticle) -> void:
	for sub_emitter in _sub_emitters:
		if sub_emitter.link.trigger == trigger and _rng.randf() <= sub_emitter.link.probability:
			sub_emitter.system.start_from(particle, sub_emitter.link)


## A start value: a fresh random pick for each particle.
func _sample(curve: FxCurve, cycle: float) -> float:
	return curve.sample(cycle, _rng.randf())


func _sample_or(curve: FxCurve, cycle: float, fallback: float) -> float:
	return _sample(curve, cycle) if curve else fallback

#endregion


#region Over its life

func _move(particle: FxParticle, delta: float) -> void:
	var life := particle.life_fraction()
	particle.velocity += Vector3.DOWN * UNITY_GRAVITY * _def.gravity.sample(life, GRAVITY_PICK) * delta
	if _def.velocity_limit:
		particle.velocity = _def.velocity_limit.applied(particle.velocity, particle, delta)
	var velocity := particle.velocity
	if _def.has_velocity():
		velocity += _velocity_over_life(particle, life, delta)
	if _def.has_noise():
		velocity += _noise_sway(particle, life)
	particle.position += velocity * delta
	particle.moving = velocity
	if _def.has_spin():
		var spin := Vector3(_sample_at(_def.spin_x, life, particle.spin_pick), _sample_at(_def.spin_y, life, particle.spin_pick),
				_def.spin.sample(life, particle.spin_pick))
		particle.rotation += spin * delta


## Velocity over lifetime: along each axis, out from the centre; orbiting about z turns the
## particle's position directly.
func _velocity_over_life(particle: FxParticle, life: float, delta: float) -> Vector3:
	var pick := particle.velocity_pick
	var extra := Vector3(_def.velocity_x.sample(life, pick), _def.velocity_y.sample(life, pick), _def.velocity_z.sample(life, pick))
	var outward := _def.velocity_radial.sample(life, particle.orbit_pick)
	if outward != 0.0 and particle.position.length() > MIN_RADIUS:
		extra += particle.position.normalized() * outward
	var orbit := _def.velocity_orbit_z.sample(life, particle.orbit_pick) * delta
	if orbit != 0.0:
		particle.position = particle.position.rotated(Vector3.BACK, orbit)
	return extra


func _noise_sway(particle: FxParticle, life: float) -> Vector3:
	var strength := _def.noise_strength.sample(life, particle.noise_pick)
	var phase := particle.noise_phase + particle.age * _def.noise_frequency * NOISE_SPEED
	return Vector3(sin(phase * NOISE_WAVES.x), cos(phase * NOISE_WAVES.y), 0.0) * strength * NOISE_STRENGTH


## Its colour, size and custom data for where it is in its life.
func _update_look(particle: FxParticle) -> void:
	var life := particle.life_fraction()
	var color := particle.color
	if _def.color_over_life:
		color *= _def.color_over_life.sample(life, particle.color_pick)
	particle.shown_color = color.clamp()
	particle.shown_size = particle.size
	if _def.size_over_life:
		var factor := _def.size_over_life.sample(life, particle.size_pick)
		var factor_y := _sample_at(_def.size_over_life_y, life, particle.size_pick, factor)
		particle.shown_size = particle.size * Vector3(factor, factor_y, factor)
	if _def.custom_data:
		_def.custom_data.update(particle)


## Drops the trail points that have run out and adds one when the particle has moved far enough.
func _record_trail(particle: FxParticle) -> void:
	if not particle.has_trail:
		return
	var point_life := _def.trail.point_life(particle)
	while not particle.trail_ages.is_empty() and particle.age - particle.trail_ages[0] > point_life:
		particle.trail_points.remove_at(0)
		particle.trail_ages.remove_at(0)
	var points := particle.trail_points
	if points.is_empty() or points[-1].distance_to(particle.position) >= _def.trail.min_vertex_distance:
		particle.trail_points.append(particle.position)
		particle.trail_ages.append(particle.age)


static func _sample_at(curve: FxCurve, life: float, pick: float, fallback := 0.0) -> float:
	return curve.sample(life, pick) if curve else fallback

#endregion


## px per unit for billboards: the system transform's largest on-screen axis.
static func _billboard_scale(system_transform: Transform3D) -> float:
	var axes := system_transform.basis
	return maxf(Vector2(axes.x.x, axes.x.y).length(), maxf(Vector2(axes.y.x, axes.y.y).length(), Vector2(axes.z.x, axes.z.y).length()))
