extends Node
## Checks desktop icon access without the pet. From the project folder:
##   <godot> --headless --path . res://scenes/debug/icon_test.tscn
##       lists every icon with its screen rect and whether a window covers it
##   <godot> --headless --path . res://scenes/debug/icon_test.tscn -- --move "Recycle Bin"
##       also moves that icon 300px right, then puts it back


func _ready() -> void:
	await _wait_for_icons()
	print("layout: ", WinGlue.GetDesktopLayout())
	for icon: Dictionary in WinGlue.GetDesktopIcons():
		print("%-32s rect=%s visible=%s" % [icon.name, icon.rect, icon.visible])

	var args := OS.get_cmdline_user_args()
	var move_at := args.find("--move")
	if move_at >= 0 and move_at + 1 < args.size():
		await _move_test(args[move_at + 1])
	get_tree().quit()


func _wait_for_icons() -> void:
	for i in 50:
		if not WinGlue.GetDesktopIcons().is_empty():
			return
		await get_tree().create_timer(0.1).timeout
	print("no icons after 5s, error: ", WinGlue.GetDesktopIconsError())


func _move_test(icon_name: String) -> void:
	var icon := _find(icon_name)
	if icon.is_empty():
		print("no icon named ", icon_name)
		return
	var start: Rect2i = icon.rect
	WinGlue.MoveDesktopIcon(icon.id, start.position + Vector2i(300, 0))
	await get_tree().create_timer(2.5).timeout  # icons refresh about once a second
	print("after move:    ", _find(icon_name).rect, "  error: ", WinGlue.GetDesktopIconsError())
	WinGlue.RestoreDesktopIcons()
	await get_tree().create_timer(2.5).timeout
	print("after restore: ", _find(icon_name).rect, "  (started at ", start, ")")


func _find(icon_name: String) -> Dictionary:
	for icon: Dictionary in WinGlue.GetDesktopIcons():
		if icon.name == icon_name:
			return icon
	return {}
