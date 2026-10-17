class_name ImpactBurst
extends TimedEffect
## The blast where coins clash or a hit lands (scenes/clash/effects/impact_burst.tscn): a
## hot flash, long fiery rays, a swoosh from the attacker's side, then a red ring.
## Stages are given as shares of the lifetime.

const RING_SEGMENTS := 40
const SWOOSH_SEGMENTS := 16

## Which way the swoosh comes from: -1 left, 1 right, 0 none.
@export var swoosh_from := 0
## Scales every size here (hits are smaller than clashes).
@export var size := 1.0

@export_group("Flash")
@export var flash_ends := 0.45
@export var flash_radius := Vector2(22, 48)  ## at its start and at its end
@export var flash_layers := 4  ## nested discs, from the orange glow out to the white-hot core
@export var flash_layer_shrink := 0.22  ## each disc this much smaller than the one outside it
@export var flash_outer_alpha := 0.35
@export var flash_alpha_per_layer := 0.15  ## inner discs are more opaque
@export var glow_color := Color("ff6a1e")
@export var core_color := Color("fff6c8")

@export_group("Rays")
@export var ray_count := 12
@export var ray_reach := Vector2(90, 180)  ## px, shortest and longest
@export var ray_grow_ends := 1.0 / 3.0  ## the rays' heads reach full length by here
## Their tails set off here, as fast as the heads, and keep going out past where the heads
## stopped: late on, each ray is a streak flying outward.
@export var ray_tail_starts := 0.2
@export var ray_width := 2.0
@export var ray_alpha := 0.9

@export_group("Swoosh")
@export var swoosh_ends := 0.5
@export var swoosh_offset := 18.0  ## px towards the side it comes from
@export var swoosh_radius := 34.0
@export var swoosh_half_arc := 1.0  ## radians either side
@export var swoosh_color := Color("ffb347")
@export var swoosh_width := 5.0

@export_group("Ring")
@export var ring_starts := 0.15
@export var ring_radius := Vector2(30, 46)  ## at its start and at its end
@export var ring_color := Color("e8322a", 0.9)
@export var ring_width := 3.0

## The rays' directions and lengths, fixed for this burst so they don't flicker.
var _rays: Array[Vector2] = []


func _ready() -> void:
	for i in ray_count:
		_rays.append(Vector2.from_angle(randf() * TAU) * randf_range(ray_reach.x, ray_reach.y))


func _draw() -> void:
	if progress < flash_ends:
		_draw_flash(stage(0.0, flash_ends))
	_draw_rays()
	if swoosh_from != 0 and progress < swoosh_ends:
		_draw_swoosh(stage(0.0, swoosh_ends))
	if progress > ring_starts:
		_draw_ring(stage(ring_starts, 1.0))


## Nested discs, white-hot inside an orange glow, swelling as they fade.
func _draw_flash(t: float) -> void:
	var radius := lerpf(flash_radius.x, flash_radius.y, t) * size
	for layer in flash_layers:
		var inwards := float(layer) / (flash_layers - 1)
		var color := glow_color.lerp(core_color, inwards)
		color.a = (flash_outer_alpha + layer * flash_alpha_per_layer) * (1.0 - t)
		draw_circle(Vector2.ZERO, radius * (1.0 - layer * flash_layer_shrink), color)


## Rays shooting out, their tails following them out as they fade.
func _draw_rays() -> void:
	var head := stage(0.0, ray_grow_ends)
	var tail := maxf((progress - ray_tail_starts) / ray_grow_ends, 0.0)
	var color := Color(glow_color, ray_alpha * (1.0 - progress))
	for ray in _rays:
		draw_line(ray * tail * size, ray * head * size, color, ray_width)


## An arc sweeping in from the attacker's side.
func _draw_swoosh(t: float) -> void:
	var facing_angle := PI if swoosh_from > 0 else 0.0
	draw_arc(Vector2(swoosh_from * swoosh_offset, 0), swoosh_radius * size, facing_angle - swoosh_half_arc,
			facing_angle + swoosh_half_arc, SWOOSH_SEGMENTS, Color(swoosh_color, 1.0 - t), swoosh_width)


func _draw_ring(t: float) -> void:
	var color := Color(ring_color, ring_color.a * (1.0 - t))
	draw_arc(Vector2.ZERO, lerpf(ring_radius.x, ring_radius.y, t) * size, 0.0, TAU, RING_SEGMENTS, color, ring_width)
