class_name FxFlipbook
extends RefCounted
## A particle system's flipbook (Unity's Texture Sheet Animation), played over each particle's
## life: frames on a grid over the whole texture, or sprite frames (each a rect of the texture
## Unity binds as the material's main texture). Rects are in Unity's uv (v up).

var tiles := Vector2i.ONE  ## columns, rows (grid mode)
var sprite_rects: Array[Rect2] = []  ## sprite mode: one a frame
var frame: FxCurve  ## 0..1 through the frames, over the particle's life
var cycles := 1.0  ## times through the frames per life
var start_frame: FxCurve


## sprite_rects: fx.json's "flipbook_frames" ([[u0, v0, u1, v1], ...]) in sprite mode.
static func from_json(data: Dictionary, sprite_rects: Array) -> FxFlipbook:
	var flipbook := FxFlipbook.new()
	flipbook.tiles = Vector2i(int(data.tiles[0]), int(data.tiles[1]))
	flipbook.frame = FxCurve.from_json(data.frame)
	flipbook.cycles = maxf(data.cycles, 1.0)
	flipbook.start_frame = FxCurve.from_json(data.start)
	if data.get("mode", "grid") == "sprites":
		for rect: Array in sprite_rects:
			flipbook.sprite_rects.append(Rect2(rect[0], rect[1], rect[2] - rect[0], rect[3] - rect[1]))
	return flipbook


func frame_count() -> int:
	return sprite_rects.size() if is_sprites() else tiles.x * tiles.y


func is_sprites() -> bool:
	return not sprite_rects.is_empty()


## The frame showing `life_fraction` of the way through a particle's life.
func frame_at(life_fraction: float, pick: float) -> int:
	var frames := frame_count()
	var progress := fmod(frame.sample(life_fraction, pick) * cycles, 1.0)
	return clampi(int(progress * frames + start_frame.sample(0.0, pick)), 0, frames - 1)


## A mesh uv (0..1 over the whole texture) moved into a frame.
func uv_in_frame(uv: Vector2, index: int) -> Vector2:
	if is_sprites():
		var rect := sprite_rects[index]
		return rect.position + uv * rect.size
	# grid frames run left to right, top row first; Unity's v runs up
	var cell := Vector2(index % tiles.x, tiles.y - 1 - floori(float(index) / tiles.x))
	return (cell + uv) / Vector2(tiles)
