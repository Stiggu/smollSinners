class_name Overlay
extends Node2D
## A transparent, always-on-top layer covering one monitor's desktop above the taskbar, where
## the sinners live (scenes/main.tscn). Clicks pass through to the desktop except on a
## sinner's visible pixels and on the Settings panel. Which monitor it covers is picked from
## the tray and remembered, and so is who's out: any of the twelve sinners, one of each,
## brought out from Settings. While the desktop is out of sight, nothing shows and next to
## nothing runs.
##
## This script only wires the parts together:
##  - Desktop: the icons. Team: the sinners. Clashes: their fights. FxStage: particle effects.
##  - IconStatuses: the icons' HP; IconBars show it, IconGraveyard turns defeated ones to dust.
##  - SettingsPanel and Tray: the controls. DesktopSleep: sleeping while the desktop is covered.

## Window titles and the tray's tooltip. The project keeps config/name "smollSinner": it
## names the user:// folder, which holds the settings and the moved icons' way home.
const APP_NAME := "Smoll Sinners"
## px the overlay stops short of the work area's bottom: Godot takes a borderless window that
## exactly covers it for maximized, and Windows one covering a whole screen for exclusive fullscreen.
const WORK_AREA_SHORTFALL := 1

var options: LaunchOptions

var _screen := 0  ## the monitor the overlay covers
var _carried: Sinner  ## being carried out of Settings on a dragged card

@onready var desktop: Desktop = $Desktop
@onready var team: Team = $Team
@onready var clashes: ClashDirector = $Clashes
@onready var icon_statuses: IconStatuses = $IconStatuses
@onready var settings_panel: SettingsPanel = $SettingsPanel
@onready var _icon_boxes: IconBoxes = $IconBoxes
@onready var _sleep: DesktopSleep = $DesktopSleep
@onready var _tray: Tray = $Tray


func _ready() -> void:
	get_window().title = APP_NAME
	options = LaunchOptions.from_command_line()
	_apply_options()
	_cover_screen(options.screen if options.screen != LaunchOptions.NOT_GIVEN else AppSettings.screen())
	var lineup := AppSettings.team()
	if options.identity:
		lineup = [options.identity]
	team.bring_out(Team.valid_lineup(lineup))
	_set_icon_dust(AppSettings.icons_turn_to_dust())
	WinGlue.process_mode = Node.PROCESS_MODE_ALWAYS  # keeps the overlay click-through while asleep
	DebugLaunch.apply(options, self)


func _process(_delta: float) -> void:
	WinGlue.SetClickThrough(not _wants_pointer())
	if options.clash_test and not clashes.is_any_running() and team.members[0].state == Sinner.State.IDLE:
		_start_clash(team.members[0])


## The pointer is over something of ours: a sinner (or one being carried), or the Settings panel.
func _wants_pointer() -> bool:
	var pointer := Vector2(DisplayServer.mouse_get_position() - get_window().position)
	var over_sinner := team.members.any(func(sinner: Sinner) -> bool: return sinner.is_dragging() or sinner.hit_test(pointer))
	var over_settings := settings_panel.visible and (settings_panel.is_busy() or settings_panel.get_rect().has_point(pointer))
	return over_sinner or over_settings


func _apply_options() -> void:
	desktop.fake_icons = options.fake_icons
	clashes.verbose = options.clash_test
	clashes.forced_skill = options.clash_skill
	clashes.forced_outcome = options.clash_outcome
	clashes.icon_filter = options.clash_icon
	IconStats.forced_max_hp = options.icon_hp
	_show_icon_boxes(options.icon_boxes)


## Fit the overlay to a monitor's work area (the screen above the taskbar), a little short of it.
func _cover_screen(screen: int) -> void:
	_screen = screen
	var area := DisplayServer.screen_get_usable_rect(screen)
	# Exactly covering it, Godot calls the window maximized and clips it to that size for good.
	area.size.y -= WORK_AREA_SHORTFALL
	get_window().position = area.position
	get_window().size = area.size
	_tray.show_monitor(screen)


## Cover another monitor: the sinners drop in there (stopping any clash), and it's remembered.
func _move_to_screen(screen: int) -> void:
	if screen == _screen or screen >= DisplayServer.get_screen_count():
		return
	_cover_screen(screen)
	settings_panel.fit_in(Vector2(get_window().size))
	team.drop_all_in()
	AppSettings.save_screen(screen)


func open_settings() -> void:
	if _sleep.is_asleep:  # asked for from the tray: show it whatever covers the desktop
		_sleep.wake()
	settings_panel.set_team(team.identity_paths())
	settings_panel.open(Vector2(get_window().size))


func _show_icon_boxes(shown: bool) -> void:
	_icon_boxes.visible = shown
	_tray.show_icon_boxes(shown)


## Whether defeated icons turn to dust for a while, or get back up at once.
func _set_icon_dust(on: bool) -> void:
	icon_statuses.turn_to_dust = on
	_tray.show_icon_dust(on)


## Off the desktop. A clash it was in has been stopped (picking it up does that) but may still
## be putting its icon back; the sinner goes once that's done.
func _send_home(sinner: Sinner) -> void:
	team.dismiss(sinner)
	await clashes.wait_until_free(sinner)
	sinner.queue_free()


func _start_clash(sinner: Sinner) -> bool:
	return not _sleep.is_asleep and clashes.start(sinner, _keep_clear())


## Where clashes mustn't go: under the Settings panel.
func _keep_clear() -> Array[Rect2]:
	var areas: Array[Rect2] = []
	if settings_panel.visible:
		areas.append(settings_panel.get_rect())
	return areas


#region Signals (connected in scenes/main.tscn)

func _on_team_changed() -> void:
	AppSettings.save_team(team.identity_paths())
	settings_panel.set_team(team.identity_paths())


func _on_clash_wanted(sinner: Sinner) -> void:
	if sinner in team.members and not _sleep.is_asleep:
		clashes.request(sinner, _keep_clear())


## Let go of over the Settings panel: sent home, unless it's the last one out.
func _on_sinner_dropped(sinner: Sinner) -> void:
	if not settings_panel.visible or team.members.size() < 2:
		return
	if settings_panel.get_rect().has_point(get_global_mouse_position()):
		_send_home(sinner)


func _on_identity_chosen(identity_path: String) -> void:
	if IdentityLibrary.is_playable(identity_path):
		team.wear(identity_path)


## A card dragged out of Settings: its sinner comes along under the pointer.
func _on_card_drag_started(identity_path: String) -> void:
	if IdentityLibrary.is_playable(identity_path):
		_carried = team.wear(identity_path)
		_carried.pick_up_by_middle()
		_carried.pop_in()


func _on_card_drag_ended() -> void:
	if is_instance_valid(_carried):
		_carried.drop()
	_carried = null


func _on_settings_visibility_changed() -> void:
	_sleep.stay_awake = settings_panel.visible


func _on_icon_dust_toggled(on: bool) -> void:
	_set_icon_dust(on)
	AppSettings.save_icons_turn_to_dust(on)


## Right away, ignoring the cooldown: everyone free, each against an icon of their own, as
## long as there are icons with room.
func _on_force_clash_requested() -> void:
	var everyone := team.members.duplicate()
	everyone.shuffle()
	for sinner: Sinner in everyone:
		_start_clash(sinner)


func _on_fell_asleep() -> void:
	clashes.call_off_all()
	visible = false
	WinGlue.SetClickThrough(true)
	desktop.paused = true


func _on_woke_up() -> void:
	desktop.paused = false
	visible = true


func _on_quit_requested() -> void:
	get_tree().quit()

#endregion
