class_name HeadsStar
extends TimedEffect
## The four-point sparkle by a badge when a coin lands heads
## (scenes/clash/effects/heads_star.tscn): it swells and shrinks away, fading a little.

const POINTS := 4

@export var radius := 9.0  ## px to its tips at its biggest
@export var waist := 0.25  ## the dips between the tips, as a share of the radius
@export var color := Color("ffd27a")
@export var end_alpha := 0.5  ## its alpha by the end
@export var core_color := Color("fff4d6")  ## a bright dot in the middle, fading out
@export var min_drawn_radius := 0.5  ## smaller than this it's a point, which can't be filled


func _draw() -> void:
	var size := sin(progress * PI) * radius
	if size < min_drawn_radius:
		return
	var outline := PackedVector2Array()
	for corner in POINTS * 2:
		var reach := size if corner % 2 == 0 else size * waist
		outline.append(Vector2.from_angle(corner * PI / POINTS - PI / 2.0) * reach)
	draw_colored_polygon(outline, Color(color, lerpf(1.0, end_alpha, progress)))
	draw_circle(Vector2.ZERO, size * waist, Color(core_color, 1.0 - progress))
