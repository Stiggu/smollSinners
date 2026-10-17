class_name FxShape
extends RefCounted
## Where a Unity particle system's particles start and which way they head (its Shape
## module), in the system's space.

## Unity's ParticleSystemShapeType, the ones these effects can use.
enum Type {
	SPHERE = 0, SPHERE_SHELL = 1, HEMISPHERE = 2, HEMISPHERE_SHELL = 3,
	CONE = 4, BOX = 5, CONE_SHELL = 7, CONE_VOLUME = 8, CONE_VOLUME_SHELL = 9,
	CIRCLE = 10, CIRCLE_EDGE = 11, SINGLE_SIDED_EDGE = 12, BOX_SHELL = 15, BOX_EDGE = 16,
}


## Where one particle starts and which way it heads.
class Spawn:
	var position := Vector3.ZERO
	var direction := Vector3.BACK  ## Unity's forward, +z

	func _init(at := Vector3.ZERO, heading := Vector3.BACK) -> void:
		position = at
		direction = heading


var type := Type.SPHERE
var radius := 1.0
## How far out particles start at least, as a share of the radius: 0 anywhere inside, 1
## only on the edge (Unity's radius thickness, the other way round).
var edge_start := 0.0
var cone_angle := 0.0  ## radians
var arc := TAU  ## radians of a circle used
var box_size := Vector3.ONE
var offset := Vector3.ZERO
var rotation := Basis.IDENTITY
var random_direction := 0.0  ## 0..1: how far each heading is blended towards a random one


static func from_json(data: Dictionary) -> FxShape:
	var shape := FxShape.new()
	shape.type = int(data.type) as Type
	shape.radius = data.radius
	shape.edge_start = 1.0 - float(data.thickness)
	shape.cone_angle = deg_to_rad(data.angle)
	shape.arc = deg_to_rad(data.arc)
	shape.box_size = FxUnity.vector3(data.scale)
	shape.offset = FxUnity.vector3(data.position)
	var degrees := FxUnity.vector3(data.rotation)
	shape.rotation = FxUnity.rotation(Vector3(deg_to_rad(degrees.x), deg_to_rad(degrees.y), deg_to_rad(degrees.z)))
	shape.random_direction = data.random_direction
	return shape


## A system without a shape module emits from its origin, straight ahead.
static func default_spawn() -> Spawn:
	return Spawn.new()


func spawn(rng: RandomNumberGenerator) -> Spawn:
	var at := _spawn_in_shape(rng)
	at.position = rotation * at.position
	at.direction = rotation * at.direction
	if random_direction > 0.0:
		var random := Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized()
		at.direction = at.direction.lerp(random, random_direction).normalized()
	at.position += offset
	return at


func _spawn_in_shape(rng: RandomNumberGenerator) -> Spawn:
	match type:
		Type.SPHERE, Type.SPHERE_SHELL, Type.HEMISPHERE, Type.HEMISPHERE_SHELL:
			return _in_sphere(rng)
		Type.CONE, Type.CONE_SHELL, Type.CONE_VOLUME, Type.CONE_VOLUME_SHELL:
			return _in_cone(rng)
		Type.BOX, Type.BOX_SHELL, Type.BOX_EDGE:
			return _in_box(rng)
		Type.CIRCLE, Type.CIRCLE_EDGE:
			return _in_circle(rng)
		Type.SINGLE_SIDED_EDGE:
			return Spawn.new(Vector3((rng.randf() * 2.0 - 1.0) * radius, 0, 0), Vector3.UP)
	return Spawn.new()


## Anywhere in the ball (evenly by volume), heading out from its centre; a hemisphere only forward.
func _in_sphere(rng: RandomNumberGenerator) -> Spawn:
	var heading := Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized()
	if type == Type.HEMISPHERE or type == Type.HEMISPHERE_SHELL:
		heading.z = absf(heading.z)
	var distance := radius * lerpf(edge_start, 1.0, pow(rng.randf(), 1.0 / 3.0))
	return Spawn.new(heading * distance, heading)


## From a disc at the base, opening out along z by the cone's angle the further out it starts.
func _in_cone(rng: RandomNumberGenerator) -> Spawn:
	var angle := rng.randf() * TAU
	var out := sqrt(rng.randf())  # evenly over the disc
	var around := Vector3(cos(angle), sin(angle), 0)
	var spread := sin(cone_angle) * out
	var heading := Vector3(around.x * spread, around.y * spread, cos(cone_angle)).normalized()
	return Spawn.new(around * radius * lerpf(edge_start, 1.0, out), heading)


func _in_box(rng: RandomNumberGenerator) -> Spawn:
	var unit := Vector3(rng.randf(), rng.randf(), rng.randf()) - Vector3.ONE * 0.5
	return Spawn.new(unit * box_size)


## Around the circle's arc in xy, heading outward; on its edge only for CIRCLE_EDGE.
func _in_circle(rng: RandomNumberGenerator) -> Spawn:
	var angle := rng.randf() * arc
	var out := 1.0 if type == Type.CIRCLE_EDGE else lerpf(edge_start, 1.0, sqrt(rng.randf()))
	var heading := Vector3(cos(angle), sin(angle), 0)
	return Spawn.new(heading * radius * out, heading)
