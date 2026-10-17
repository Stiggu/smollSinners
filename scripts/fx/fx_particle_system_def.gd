class_name FxParticleSystemDef
extends FxSystemDef
## A Unity particle system from fx.json: its main module (duration, looping, start lifetime,
## speed, size, rotation and colour, gravity, the most particles alive), its emission (rate
## and bursts), its shape, the over-lifetime modules it uses (each null when off), its
## flipbook, custom data, trails and sub-emitters, and how it's drawn (billboards, stretched
## billboards or meshes, and the vertex streams its shader reads). See FxParticleSystem.

enum Render { BILLBOARD, STRETCHED, HORIZONTAL, MESH }

const MIN_DURATION := 0.001
const DEFAULT_MAX_PARTICLES := 1000
const RENDER_MODES := {"billboard": Render.BILLBOARD, "vertical": Render.BILLBOARD, "stretched": Render.STRETCHED,
		"horizontal": Render.HORIZONTAL, "mesh": Render.MESH}

var duration := 1.0
var looping := false
var delay: FxCurve
var start_lifetime: FxCurve
var start_speed: FxCurve
var start_size: FxCurve
var start_size_y: FxCurve  ## null: as start_size
var start_size_z: FxCurve  ## null: as start_size
var start_rotation: FxCurve  ## about z, radians
var start_rotation_x: FxCurve  ## null: none
var start_rotation_y: FxCurve  ## null: none
var start_color: FxColorCurve
var gravity: FxCurve  ## multiplies Unity's gravity
var max_particles := DEFAULT_MAX_PARTICLES

var rate: FxCurve  ## particles a second; null: no steady emission
var bursts: Array[FxBurst] = []
var shape: FxShape  ## null: from the origin, straight ahead

var size_over_life: FxCurve
var size_over_life_y: FxCurve  ## null: as size_over_life
var color_over_life: FxColorCurve
## Velocity over lifetime: each axis, out from the centre, and orbiting about z (radians/s).
var velocity_x: FxCurve
var velocity_y: FxCurve
var velocity_z: FxCurve
var velocity_radial: FxCurve
var velocity_orbit_z: FxCurve
var velocity_limit: FxVelocityLimit  ## null: no speed limit or drag
var noise_strength: FxCurve
var noise_frequency := 0.0
var spin: FxCurve  ## about z, radians/s; null: the spin module is off
var spin_x: FxCurve
var spin_y: FxCurve
var flipbook: FxFlipbook
var custom_data: FxCustomData  ## null: the shader gets zeros
var trail: FxTrailDef  ## null: no trails
var sub_emitters: Array[FxSubEmitterDef] = []
var is_sub_emitter := false  ## it plays only when another system's particles set it off

var render := Render.BILLBOARD
var mesh_name := ""  ## under FxAssets, for Render.MESH
var length_scale := 1.0  ## stretched billboards: length as a share of the size...
var velocity_scale := 0.0  ## ... plus this much a unit/s of speed
var streams: FxVertexStreams


func instantiate(rng: RandomNumberGenerator, _source: Vector2, _target: Vector2) -> Node2D:
	var system := FxParticleSystem.new()
	system.setup(self, rng)
	return system


func has_velocity() -> bool:
	return velocity_x != null


func has_noise() -> bool:
	return noise_strength != null


func has_spin() -> bool:
	return spin != null


func _read(data: Dictionary) -> void:
	duration = maxf(data.duration, MIN_DURATION)
	looping = data.looping
	delay = FxCurve.from_json(data.get("delay", {}))
	start_lifetime = FxCurve.from_json(data.lifetime)
	start_speed = FxCurve.from_json(data.speed)
	start_size = FxCurve.from_json(data.size)
	start_size_y = FxCurve.optional(data, "size_y")
	start_size_z = FxCurve.optional(data, "size_z")
	start_rotation = FxCurve.from_json(data.rotation)
	start_rotation_x = FxCurve.optional(data, "rotation_x")
	start_rotation_y = FxCurve.optional(data, "rotation_y")
	start_color = FxColorCurve.from_json(data.color)
	gravity = FxCurve.from_json(data.gravity)
	max_particles = int(data.get("max", DEFAULT_MAX_PARTICLES))
	rate = FxCurve.optional(data, "rate")
	for burst: Dictionary in data.get("bursts", []):
		bursts.append(FxBurst.from_json(burst))
	if not data.get("shape", {}).is_empty():
		shape = FxShape.from_json(data.shape)
	size_over_life = FxCurve.optional(data, "size_over_life")
	size_over_life_y = FxCurve.optional(data, "size_over_life_y")
	color_over_life = FxColorCurve.optional(data, "color_over_life")
	_read_velocity(data.get("velocity", {}))
	if data.has("limit_velocity"):
		velocity_limit = FxVelocityLimit.from_json(data.limit_velocity)
	if data.has("noise"):
		noise_strength = FxCurve.from_json(data.noise.strength)
		noise_frequency = data.noise.frequency
	spin = FxCurve.optional(data, "spin")
	spin_x = FxCurve.optional(data, "spin_x")
	spin_y = FxCurve.optional(data, "spin_y")
	if data.has("flipbook"):
		flipbook = FxFlipbook.from_json(data.flipbook, data.get("flipbook_frames", []))
	if data.has("custom_data"):
		custom_data = FxCustomData.from_json(data.custom_data)
	if data.has("trail") and data.has("trail_material"):
		trail = FxTrailDef.from_json(data.trail, data.trail_material)
	for link: Dictionary in data.get("sub_emitters", []):
		sub_emitters.append(FxSubEmitterDef.from_json(link))
	is_sub_emitter = data.get("sub_emitter", false)
	render = RENDER_MODES.get(data.get("render", "billboard"), Render.BILLBOARD)
	var mesh: Variant = data.get("mesh")  # null: a mesh renderer with no mesh draws quads
	mesh_name = mesh if mesh is String else ""
	length_scale = data.get("length_scale", 1.0)
	velocity_scale = data.get("velocity_scale", 0.0)
	streams = FxVertexStreams.from_ids(data.get("streams", FxVertexStreams.DEFAULT), render == Render.MESH)


func _read_velocity(velocity: Dictionary) -> void:
	if velocity.is_empty():
		return
	velocity_x = FxCurve.from_json(velocity.x)
	velocity_y = FxCurve.from_json(velocity.y)
	velocity_z = FxCurve.from_json(velocity.z)
	velocity_radial = FxCurve.from_json(velocity.radial)
	velocity_orbit_z = FxCurve.from_json(velocity.orbital_z)
