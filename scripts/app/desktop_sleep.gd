class_name DesktopSleep
extends Timer
## Puts the app to sleep while the desktop is out of sight (a maximized or fullscreen window
## over the overlay's monitor), so it shows nothing and costs next to nothing, and wakes it as
## soon as some of the desktop shows again. Checks every wait_time seconds, paused or not.

## Gone to sleep: the overlay calls off clashes and hides. The game is then paused, nothing
## is drawn and the main loop ticks ASLEEP_FPS times a second.
signal fell_asleep
## Awake again, with everything running.
signal woke_up

## The desktop is in sight while at least this share of the overlay's area is uncovered.
const SHOWING_FROM := 0.02
## Checks in a row that must find it covered, so a window dragged past doesn't blink everyone out.
const COVERED_CHECKS_TO_SLEEP := 2
const ASLEEP_FPS := 4  ## enough to notice the desktop is back within a check
const FALLBACK_FPS := 30  ## if the project doesn't set one
const FRAMES_TO_CLEAR := 2  ## empty frames shown before drawing stops, so nothing is left on screen

@export var desktop: Desktop

var is_asleep := false
var stay_awake := false  ## e.g. while the Settings panel is open
var _covered_checks := 0


func _ready() -> void:
	timeout.connect(_check)


func sleep() -> void:
	is_asleep = true
	fell_asleep.emit()
	Engine.max_fps = ASLEEP_FPS
	get_tree().paused = true
	for i in FRAMES_TO_CLEAR:
		await RenderingServer.frame_post_draw
	if is_asleep:
		RenderingServer.render_loop_enabled = false


func wake() -> void:
	is_asleep = false
	_covered_checks = 0
	RenderingServer.render_loop_enabled = true
	Engine.max_fps = ProjectSettings.get_setting("application/run/max_fps", FALLBACK_FPS)
	get_tree().paused = false
	woke_up.emit()


func _check() -> void:
	var covered := desktop.uncovered_fraction(desktop.overlay_area()) < SHOWING_FROM
	_covered_checks = _covered_checks + 1 if covered and not stay_awake else 0
	if _covered_checks >= COVERED_CHECKS_TO_SLEEP and not is_asleep:
		sleep()
	elif _covered_checks == 0 and is_asleep:
		wake()
