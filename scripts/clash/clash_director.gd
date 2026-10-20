class_name ClashDirector
extends Node2D
## Starts clashes between sinners and desktop icons, and keeps them (as its children, so they
## draw in overlay coordinates). The idle AI starts one clash at a time with a cooldown in
## between; a forced clash starts at once. A clash only goes where it fits as laid out and
## clear of the other clashes and of whatever the overlay asks to keep clear.

const CLASH_SCENE := preload("res://scenes/clash/clash.tscn")
const COOLDOWN_SECONDS := 30.0  ## after a clash, before the idle AI may start another
const PREFER_WOUNDED := 0.75  ## how likely a clash goes for a wounded icon when one has room
const ICON_SETTLE_SECONDS := 2.0  ## after a clash, before its icon can be fought again (icon positions lag moves ~1.5 s)

@export var desktop: Desktop
@export var fx_stage: FxStage  ## where the clashes' damage numbers glow
@export var icon_statuses: IconStatuses

## Debug switches (see LaunchOptions).
var verbose := false
var forced_skill := ""
var forced_outcome := Clash.Outcome.BY_CHANCE
var icon_filter := ""  ## only fight icons whose name contains this

var _clashes: Array[Clash] = []
var _settled_at: Dictionary[String, float] = {}  ## per icon: when its last clash's moves show in desktop.icons
var _ready_at := 0.0  ## seconds since start


## The idle AI wants a fight: one clash at a time, and not straight after the last.
func request(sinner: Sinner, keep_clear: Array[Rect2]) -> void:
	if _clashes.is_empty() and _now() >= _ready_at:
		start(sinner, keep_clear)


## Start a clash for this sinner right away, against a random visible icon on this screen
## that has room for it (Clash.fits()) and lies clear of the other clashes and `keep_clear`.
## False if there's no such icon, or the sinner is busy, staggered, panicked or dead.
func start(sinner: Sinner, keep_clear: Array[Rect2]) -> bool:
	if not sinner.status.can_act() or sinner.is_dragging() or clash_of(sinner):
		return false
	var candidates := _free_visible_icons()
	if candidates.is_empty():
		return false
	var clash: Clash = CLASH_SCENE.instantiate()
	clash.verbose = verbose
	clash.fx_stage = fx_stage
	clash.forced_skill = forced_skill
	clash.forced_outcome = forced_outcome
	add_child(clash)
	clash.prepare(sinner, desktop)
	var taken := keep_clear.duplicate()
	for other in _clashes:
		taken.append(other.area)
	candidates = candidates.filter(func(icon: DesktopIcon) -> bool:
		var footprint := clash.footprint(icon)
		return clash.fits(icon) and not taken.any(func(area: Rect2) -> bool: return area.intersects(footprint)))
	if candidates.is_empty():
		clash.queue_free()
		return false
	clash.finished.connect(_on_clash_finished.bind(clash))
	_clashes.append(clash)
	var target := _pick_target(candidates)
	clash.start(target, icon_statuses.status_of(target))
	return true


## Every running clash stops (their icons still go home).
func call_off_all() -> void:
	for clash in _clashes:
		clash.sinner.call_off()


## The clash this sinner is in, if any.
func clash_of(sinner: Sinner) -> Clash:
	for clash in _clashes:
		if clash.sinner == sinner:
			return clash
	return null


## Returns once the sinner is in no clash (one it was in may still be putting its icon back).
func wait_until_free(sinner: Sinner) -> void:
	var clash := clash_of(sinner)
	if clash:
		await clash.finished


func is_any_running() -> bool:
	return not _clashes.is_empty()


## The clash fighting this icon, if any.
func clash_on(icon_id: String) -> Clash:
	for clash in _clashes:
		if clash.icon and clash.icon.id == icon_id:
			return clash
	return null


## A clash's icon's rect now (overlay coords, knocked back or not); empty if no clash has it.
func icon_rect_now(icon_id: String) -> Rect2:
	var clash := clash_on(icon_id)
	return clash.icon_rect_now() if clash else Rect2()


## A wounded icon most of the time, if there's one; else any.
func _pick_target(candidates: Array[DesktopIcon]) -> DesktopIcon:
	var wounded := candidates.filter(_is_wounded)
	if not wounded.is_empty() and randf() < PREFER_WOUNDED:
		return wounded.pick_random()
	return candidates.pick_random()


## Visible, still-standing icons wholly on the overlay's screen that no clash is using.
func _free_visible_icons() -> Array[DesktopIcon]:
	var screen := desktop.overlay_area()
	var free: Array[DesktopIcon] = []
	for icon in desktop.icons:
		if icon.visible and screen.encloses(icon.rect) and _is_settled(icon) and not _in_use(icon) and not _is_defeated(icon) and _matches_filter(icon):
			free.append(icon)
	return free


func _is_settled(icon: DesktopIcon) -> bool:
	return _now() >= _settled_at.get(icon.id, 0.0)


func _is_wounded(icon: DesktopIcon) -> bool:
	var status := icon_statuses.status_by_id(icon.id)
	return status != null and status.hp < status.max_hp


func _is_defeated(icon: DesktopIcon) -> bool:
	var status := icon_statuses.status_by_id(icon.id)
	return status != null and status.is_dead()


func _in_use(icon: DesktopIcon) -> bool:
	return _clashes.any(func(clash: Clash) -> bool: return clash.icon.id == icon.id)


func _matches_filter(icon: DesktopIcon) -> bool:
	return icon_filter.is_empty() or icon.name.contains(icon_filter)


func _on_clash_finished(clash: Clash) -> void:
	_clashes.erase(clash)
	_settled_at[clash.icon.id] = _now() + ICON_SETTLE_SECONDS
	_ready_at = _now() + COOLDOWN_SECONDS


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
