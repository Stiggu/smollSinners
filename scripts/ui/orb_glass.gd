@tool
class_name OrbGlass
extends Node2D
## The Sanity orb's glass, over its frame (the game's MPGauge and its effects):
##  - the sphere: veined glass, grey at 0 SP, bluer up to +45, redder down to -45
##    (FX_Mat_UI_Battle_MindPowerSphere); near +45 its HDR blue blooms past the frame
##  - while SP is up (or down), a pulse every pulse_period: a ring swelling out of the orb as
##    it fades, over a burst of glow (FX_UI_Battle_MindPowerSphereFX_Up / _Down: Ring1 and
##    Burn1, looping)
##  - when SP changes: an SpChange (scenes/ui/sp_change.tscn) pops out of it
## The node is the orb's centre; place it in scenes/ui/unit_bar.tscn. The colours here are
## how the game's HDR colours read on screen; tune them in the inspector.

const SPHERE: Texture2D = preload("res://assets/limbus/ui/unit_bar/sphere.png")
const SP_CHANGE := preload("res://scenes/ui/sp_change.tscn")
## Burn1's alpha over its life, as (life fraction, alpha) keys.
const BURN_FADE: Array[Vector2] = [Vector2(0.0, 1.0), Vector2(0.33, 0.28), Vector2(1.0, 0.0)]
const HALO_MIDPOINT := 0.55  ## this far out from its centre...
const HALO_MIDPOINT_ALPHA := 0.55  ## ... the soft halo is still this opaque
const RING_SEGMENTS := 48
const RIM_SEGMENTS := 40

## Sanity to show (set by UnitBar; in the editor, a preview).
@export_range(-45, 45) var sp := 45
@export var sphere_size := 30.0  ## px: the glass inside the frame
@export var frame_radius := 19.0  ## px: the frame's rim, which the bloom covers
@export var spin_speed := 0.5  ## radians a second: the glass turns slowly

@export_group("Glass colours")
@export var normal_color := Color(0.72, 0.73, 0.76)  ## at 0 SP
@export var up_color := Color(0.25, 0.55, 1.0)  ## at +45
@export var down_color := Color(1.0, 0.2, 0.18)  ## at -45
@export var change_lighten := 0.25  ## an SP change shows in the up or down colour, lightened

@export_group("Bloom near +45")
@export var bloom_from := 0.6  ## of max Sanity: where the sphere starts to bloom
@export var bloom_body := Color(0.48, 0.63, 0.85)
@export var bloom_rim := Color(0.6, 0.72, 0.91)
@export var bloom_glass := Color(0.6, 0.78, 1.0)
@export var halo_size := 2.8  ## across, in frame radii
@export var halo_alpha := 0.85
@export var body_alpha := 0.75  ## over the frame
@export var glass_wash_alpha := 0.35  ## one even blue over the glass
@export var rim_alpha := 0.9
@export var rim_width := 2.0

@export_group("Pulse while up or down")
@export var pulse_period := 1.1  ## Ring1 / Burn1: a loop with one burst at its start
@export var pulse_life := 1.0  ## each lives this long, growing to three times its size
@export var up_pulse_lighten := 0.45
@export var down_pulse_lighten := 0.3
## Diameters in px as they grow (game: ring 33 to 100 canvas units, glow 44 to 133, at 0.6 px each).
@export var ring_size := Vector2(20, 60)
@export var burn_size := Vector2(26, 80)
@export var ring_width := 2.0
@export var burn_alpha := Vector2(0.35, 0.7)  ## at the least and the most Sanity
@export var ring_alpha := Vector2(0.6, 1.0)

static var _halo: GradientTexture2D  ## a soft round glow

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## A Sanity change to show: a ring, an arrow and by how much.
func show_change(delta: int) -> void:
	var change: SpChange = SP_CHANGE.instantiate()
	add_child(change)
	change.show_change(delta, (up_color if delta > 0 else down_color).lightened(change_lighten))


## 0..1: how far the sphere has bloomed (near +45). UnitBar lights the number by it.
func bloom() -> float:
	return smoothstep(bloom_from, 1.0, float(sp) / UnitStatus.MAX_SP)


func _draw() -> void:
	var glow := bloom()
	if sp != 0:
		_draw_pulse()
	if glow > 0.0:
		_draw_centered(_halo_texture(), frame_radius * halo_size, Color(bloom_body, halo_alpha * glow))
		draw_circle(Vector2.ZERO, frame_radius, Color(bloom_body, body_alpha * glow))
	draw_set_transform(Vector2.ZERO, _time * spin_speed, Vector2.ONE * sphere_size / SPHERE.get_width())
	draw_texture(SPHERE, -SPHERE.get_size() / 2.0, _glass_color().lerp(bloom_glass, glow))
	draw_set_transform(Vector2.ZERO)
	if glow > 0.0:
		draw_circle(Vector2.ZERO, sphere_size / 2.0, Color(bloom_body, glass_wash_alpha * glow))
		draw_arc(Vector2.ZERO, frame_radius + 1.0, 0.0, TAU, RIM_SEGMENTS, Color(bloom_rim, rim_alpha * glow), rim_width, true)


## Grey at 0 SP, towards blue at +45 and red at -45.
func _glass_color() -> Color:
	return normal_color.lerp(up_color if sp >= 0 else down_color, _sanity_strength())


## The loop while Sanity is up or down: a glow bursting out and fading fast, and a ring
## swelling out as it dissolves; then again.
func _draw_pulse() -> void:
	var t := fmod(_time, pulse_period) / pulse_life
	if t >= 1.0:
		return
	var color := up_color.lightened(up_pulse_lighten) if sp > 0 else down_color.lightened(down_pulse_lighten)
	var strength := _sanity_strength()
	var burn := Color(color, Keyframes.linear(PackedVector2Array(BURN_FADE), t) * lerpf(burn_alpha.x, burn_alpha.y, strength))
	_draw_centered(_halo_texture(), lerpf(burn_size.x, burn_size.y, t), burn)
	var ring := Color(color, (1.0 - t) * lerpf(ring_alpha.x, ring_alpha.y, strength))
	draw_arc(Vector2.ZERO, lerpf(ring_size.x, ring_size.y, t) / 2.0, 0.0, TAU, RING_SEGMENTS, ring, ring_width, true)


## 0 at no Sanity, 1 at either end.
func _sanity_strength() -> float:
	return absf(sp) / UnitStatus.MAX_SP


func _draw_centered(texture: Texture2D, diameter: float, modulate_color: Color) -> void:
	draw_texture_rect(texture, Rect2(-Vector2.ONE * diameter / 2.0, Vector2.ONE * diameter), false, modulate_color)


static func _halo_texture() -> GradientTexture2D:
	if _halo == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color.WHITE)
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(HALO_MIDPOINT, Color(1, 1, 1, HALO_MIDPOINT_ALPHA))
		_halo = GradientTexture2D.new()
		_halo.fill = GradientTexture2D.FILL_RADIAL
		_halo.fill_from = Vector2(0.5, 0.5)
		_halo.fill_to = Vector2(1.0, 0.5)
		_halo.gradient = gradient
	return _halo
