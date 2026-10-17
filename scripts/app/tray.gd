class_name Tray
extends StatusIndicator
## The app's icon in the Windows tray and its menu (scenes/app/tray.tscn). The menu's items
## are laid out in the scene, with MenuItem's ids; the Monitor submenu lists the monitors
## there are. It keeps working while the app sleeps.

signal settings_requested
signal force_clash_requested
signal bring_back_requested
signal monitor_chosen(screen: int)
signal icon_boxes_toggled(shown: bool)
signal quit_requested

## The menu items' ids, as set in the scene.
enum MenuItem { SETTINGS = 0, FORCE_CLASH = 1, BRING_BACK = 2, ICON_BOXES = 3, QUIT = 4, MONITOR = 5 }

const SCREEN_LABEL := "Monitor %d (%d×%d, %s)"

@onready var _menu: PopupMenu = $Menu
@onready var _monitors: PopupMenu = $Menu/Monitors


func _ready() -> void:
	_menu.set_item_submenu_node(_menu.get_item_index(MenuItem.MONITOR), _monitors)
	for screen in DisplayServer.get_screen_count():
		_monitors.add_radio_check_item(_screen_label(screen), screen)


## Tick the monitor the overlay covers.
func show_monitor(screen: int) -> void:
	for i in _monitors.item_count:
		_monitors.set_item_checked(i, _monitors.get_item_id(i) == screen)


func show_icon_boxes(shown: bool) -> void:
	_menu.set_item_checked(_menu.get_item_index(MenuItem.ICON_BOXES), shown)


func _on_menu_id_pressed(id: int) -> void:
	match id:
		MenuItem.SETTINGS:
			settings_requested.emit()
		MenuItem.FORCE_CLASH:
			force_clash_requested.emit()
		MenuItem.BRING_BACK:
			bring_back_requested.emit()
		MenuItem.ICON_BOXES:
			var shown := not _menu.is_item_checked(_menu.get_item_index(MenuItem.ICON_BOXES))
			show_icon_boxes(shown)
			icon_boxes_toggled.emit(shown)
		MenuItem.QUIT:
			quit_requested.emit()


func _on_monitor_id_pressed(screen: int) -> void:
	monitor_chosen.emit(screen)


## e.g. "Monitor 2 (1920×1080, left)": its size, and where it is from the main one.
static func _screen_label(screen: int) -> String:
	var size := DisplayServer.screen_get_size(screen)
	return SCREEN_LABEL % [screen + 1, size.x, size.y, _where(screen)]


static func _where(screen: int) -> String:
	var main := DisplayServer.get_primary_screen()
	if screen == main:
		return "main"
	var center := DisplayServer.screen_get_position(screen) + DisplayServer.screen_get_size(screen) / 2
	var main_area := Rect2i(DisplayServer.screen_get_position(main), DisplayServer.screen_get_size(main))
	if center.x < main_area.position.x:
		return "left"
	if center.x >= main_area.end.x:
		return "right"
	return "above" if center.y < main_area.position.y else "below"
