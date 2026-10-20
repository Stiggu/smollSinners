class_name Wallpaper
extends RefCounted
## One monitor's wallpaper as Windows draws it, rebuilt off-thread so icons can be patched over.

## Windows' own copy of the picture it shows, for a file Godot can't read (a .heic, say).
const TRANSCODED := "Microsoft/Windows/Themes/TranscodedWallpaper"
const NOT_BUILDING := -1

var _key: Dictionary = {}  ## what the current build is of: the layout and the monitor
var _monitor := Rect2i()  ## the built monitor, Godot screen coordinates
var _drawn: Image  ## its wallpaper as drawn
var _built: Array = [null]  ## the worker thread's result: [Image]
var _task := NOT_BUILDING


## Rebuild in the background if the wallpaper or the monitor around `area` changed.
func refresh(area: Rect2i) -> void:
	_collect()
	if _task != NOT_BUILDING:
		return
	var layout: Dictionary = WinGlue.GetWallpaper()
	var monitor := _monitor_around(layout, area)
	if monitor.is_empty():
		return
	var key := {"layout": layout, "monitor": monitor}
	if key == _key:
		return
	_key = key
	_built = [null]
	var span := Rect2i(monitor.rect)
	for other: Dictionary in layout.monitors:
		span = span.merge(other.rect)
	_task = WorkerThreadPool.add_task(_build.bind(_built, monitor.rect, monitor.file, layout.position, layout.background, span))


## The wallpaper under `area` (screen coords), or null if unbuilt or off the monitor.
func patch(area: Rect2i) -> Image:
	_collect()
	if _drawn == null or not _monitor.encloses(area):
		return null
	return _drawn.get_region(Rect2i(area.position - _monitor.position, area.size))


## Picks up a finished build.
func _collect() -> void:
	if _task == NOT_BUILDING or not WorkerThreadPool.is_task_completed(_task):
		return
	WorkerThreadPool.wait_for_task_completion(_task)
	_task = NOT_BUILDING
	_drawn = _built[0]
	_monitor = _key.monitor.rect


static func _monitor_around(layout: Dictionary, area: Rect2i) -> Dictionary:
	for monitor: Dictionary in layout.get("monitors", []):
		if Rect2i(monitor.rect).has_point(area.get_center()):
			return monitor
	return {}


## Draws the monitor's wallpaper into result[0] (on a worker thread).
static func _build(result: Array, monitor: Rect2i, file: String, position: String, background: Color, span: Rect2i) -> void:
	var drawn := Image.create_empty(monitor.size.x, monitor.size.y, false, Image.FORMAT_RGB8)
	drawn.fill(background)
	var picture := _load_picture(file)
	if picture:
		picture.convert(Image.FORMAT_RGB8)
		if position == "tile":
			_tile(drawn, picture)
		elif position == "span":  # one picture filling all the monitors together
			var placed := _placed(picture.get_size(), span.size, "fill")
			_paint(drawn, picture, Rect2i(placed.position + span.position - monitor.position, placed.size))
		else:
			_paint(drawn, picture, _placed(picture.get_size(), monitor.size, position))
	result[0] = drawn


## Where a picture lands on an area: top-left (negative when cropped) and size.
static func _placed(picture: Vector2i, area_size: Vector2i, position: String) -> Rect2i:
	var scale := 1.0
	match position:
		"stretch":
			return Rect2i(Vector2i.ZERO, area_size)
		"fill":
			scale = maxf(float(area_size.x) / picture.x, float(area_size.y) / picture.y)
		"fit":
			scale = minf(float(area_size.x) / picture.x, float(area_size.y) / picture.y)
	var size := Vector2i((Vector2(picture) * scale).round())
	return Rect2i((area_size - size) / 2, size)


## Paint `picture` scaled to `where` on `drawn`, cropped to it.
static func _paint(drawn: Image, picture: Image, where: Rect2i) -> void:
	var scaled := picture
	if picture.get_size() != where.size:
		scaled = picture.duplicate()
		scaled.resize(where.size.x, where.size.y, Image.INTERPOLATE_LANCZOS)
	var on_drawn := where.intersection(Rect2i(Vector2i.ZERO, drawn.get_size()))
	drawn.blit_rect(scaled, Rect2i(on_drawn.position - where.position, on_drawn.size), on_drawn.position)


static func _tile(drawn: Image, picture: Image) -> void:
	for y in range(0, drawn.get_height(), picture.get_height()):
		for x in range(0, drawn.get_width(), picture.get_width()):
			_paint(drawn, picture, Rect2i(Vector2i(x, y), picture.get_size()))


## The wallpaper's picture, or null for a plain colour or a file nothing can read.
static func _load_picture(file: String) -> Image:
	if file.is_empty():
		return null
	for path in [file.replace("\\", "/"), OS.get_environment("APPDATA").path_join(TRANSCODED)]:
		if FileAccess.file_exists(path):
			var picture := _decode(FileAccess.get_file_as_bytes(path))
			if picture:
				return picture
	return null


## A JPEG, PNG, WebP or BMP picture, told apart by its first bytes; null for anything else.
static func _decode(bytes: PackedByteArray) -> Image:
	var picture := Image.new()
	var error := ERR_FILE_UNRECOGNIZED
	if _starts_with(bytes, [0xFF, 0xD8, 0xFF]):
		error = picture.load_jpg_from_buffer(bytes)
	elif _starts_with(bytes, [0x89, 0x50, 0x4E, 0x47]):
		error = picture.load_png_from_buffer(bytes)
	elif _starts_with(bytes, "RIFF".to_ascii_buffer()) and bytes.slice(8, 12).get_string_from_ascii() == "WEBP":
		error = picture.load_webp_from_buffer(bytes)
	elif _starts_with(bytes, "BM".to_ascii_buffer()):
		error = picture.load_bmp_from_buffer(bytes)
	return picture if error == OK else null


static func _starts_with(bytes: PackedByteArray, magic: Variant) -> bool:
	var prefix := PackedByteArray(magic)
	return bytes.size() >= prefix.size() and bytes.slice(0, prefix.size()) == prefix
