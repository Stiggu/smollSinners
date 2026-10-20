class_name FallenIcon
extends Node2D
## A defeated icon crumbling to Dust, with a wallpaper Cover hiding the real one underneath.

const DUST_REACH := 300.0  ## px the dust can drift (it's drawn while any of it is on screen)
const CRUMBLE := &"crumble"

@export var grain_size := 2  ## px square
@export var sweep_seconds := 0.9  ## for the crumbling to sweep across the icon
@export var grain_jitter := 0.25  ## seconds of random extra delay per grain

@onready var _cover: Sprite2D = $Cover
@onready var _dust: MultiMeshInstance2D = $Dust
@onready var _animation: AnimationPlayer = $AnimationPlayer


## Crumble what the screen `shown` against its `wallpaper`; blow_from: -1 left, +1 right.
func crumble(shown: Image, wallpaper: Image, blow_from: int) -> void:
	var picture := IconPatch.icon_pixels(shown, wallpaper)
	var icon_pixels := BitMap.new()
	icon_pixels.create_from_image_alpha(picture)
	var offset := IconPatch.colour_offset(shown, wallpaper, picture)
	_cover.texture = ImageTexture.create_from_image(IconPatch.cover(wallpaper, picture, offset))
	_dust.texture = ImageTexture.create_from_image(picture)
	_dust.multimesh = _grains(icon_pixels, blow_from)
	var dust_material := _dust.material as ShaderMaterial
	dust_material.set_shader_parameter("picture_size", Vector2(picture.get_size()))
	var wind: Vector2 = dust_material.get_shader_parameter("wind")
	dust_material.set_shader_parameter("wind", Vector2(-blow_from * absf(wind.x), wind.y))
	_animation.play(CRUMBLE)


## Gather back from wherever the crumbling got to, then free itself (await it).
func reform() -> void:
	var from := _animation.current_animation_position if _animation.is_playing() else _animation.get_animation(CRUMBLE).length
	_animation.play_backwards(CRUMBLE)
	_animation.seek(from, true)
	await _animation.animation_finished
	queue_free()


## Off while a window covers this part of the desktop: the cover would show over it.
func show_cover(shown: bool) -> void:
	_cover.visible = shown


## One grain per grain_size square of icon pixels, timed to sweep from the blow's side.
func _grains(icon_pixels: BitMap, blow_from: int) -> MultiMesh:
	var size := icon_pixels.get_size()
	var homes: Array[Vector2] = []
	for y in range(0, size.y, grain_size):
		for x in range(0, size.x, grain_size):
			var square := Rect2i(x, y, grain_size, grain_size).intersection(Rect2i(Vector2i.ZERO, size))
			if _any_set(icon_pixels, square):
				homes.append(Vector2(square.get_center()))
	var quad := QuadMesh.new()
	quad.size = Vector2(grain_size, grain_size)
	var grains := MultiMesh.new()
	grains.transform_format = MultiMesh.TRANSFORM_2D
	grains.use_custom_data = true
	grains.mesh = quad
	grains.instance_count = homes.size()
	for i in homes.size():
		var across := homes[i].x / size.x
		var from_blow := across if blow_from < 0 else 1.0 - across
		grains.set_instance_transform_2d(i, Transform2D.IDENTITY)
		grains.set_instance_custom_data(i, Color(from_blow * sweep_seconds + randf() * grain_jitter, homes[i].x, homes[i].y))
	grains.custom_aabb = AABB(Vector3(-DUST_REACH, -DUST_REACH, 0.0), Vector3(size.x + DUST_REACH * 2.0, size.y + DUST_REACH * 2.0, 0.0))
	return grains


static func _any_set(bits: BitMap, square: Rect2i) -> bool:
	for y in range(square.position.y, square.end.y):
		for x in range(square.position.x, square.end.x):
			if bits.get_bit(x, y):
				return true
	return false
