class_name DebugLaunch
extends RefCounted
## The debug switches that act once the overlay is up (see LaunchOptions).

const CAPTURE := preload("res://scripts/debug/capture.gd")
const SHOT_DELAY := 1.0  ## seconds for the Settings panel to settle before its picture


static func apply(options: LaunchOptions, overlay: Overlay) -> void:
	var first := overlay.team.members[0]
	if options.start_sp != 0:
		first.status.add_sp(options.start_sp)
		first.status.fighting()  # as if mid-battle, so it doesn't settle back to 0 at once
	if options.start_damage != 0:
		first.status.take_hit(options.start_damage, "blunt")
	if options.capture_dir:
		_start_capture(options, overlay)
	if options.settings_shot:
		_take_settings_shot(options, overlay)


static func _start_capture(options: LaunchOptions, overlay: Overlay) -> void:
	var capture: Node = CAPTURE.new()
	capture.dir = options.capture_dir
	if options.capture_every > 0.0:
		capture.every = options.capture_every
	overlay.add_child(capture)


## Open Settings (on one sinner's identities if asked) and save a picture of it.
static func _take_settings_shot(options: LaunchOptions, overlay: Overlay) -> void:
	overlay.open_settings()
	if options.settings_sinner:
		overlay.settings_panel.show_sinner(options.settings_sinner)
	await overlay.get_tree().create_timer(SHOT_DELAY).timeout
	var picture := overlay.get_viewport().get_texture().get_image()
	picture.get_region(Rect2i(overlay.settings_panel.get_rect())).save_png(options.settings_shot)
