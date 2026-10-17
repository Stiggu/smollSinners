class_name UnitBar
extends Node2D
## The bar the game draws under every unit in battle (UnitBottomStateUI), as a scene:
## scenes/ui/unit_bar.tscn, where the pieces can be moved, restyled and re-timed. The node is
## the unit's feet; add it after the unit's sprite (Floor has z_index -1, so it lies behind).
##  - Floor: the dark heptagon with the Limbus Company emblem, and the HP gauge (HPGauge)
##  - HPNumber, and the Sanity Orb: its frame, its glass (OrbGlass) and its Number
##  - States: the PANIC and STAGGER plates while they last, at Slot1 (and Slot2 for the
##    second), on their brushed plates when it's both at once; each pops in ("appear") and
##    glows ("pulse"). The Burst flashes up as the unit staggers (BattleUIBreakTypo_Reveal).
##  - BadgeAnchor: where the unit's clash badge goes
## Nodes in the "preview" group (a sample sinner and badge) are only there for the editor.
## Pieces from tools/export_unit_bar.py.

const HP_SLIDE_SHARE := 0.8  ## the HP gauge slides this share of max HP a second...
const HP_SLIDE_MIN := 40.0  ## ... but at least this many HP a second
const BLOOM_TEXT := Color(0.93, 0.92, 0.9)  ## the Sanity number as the orb blooms

## Whose HP and Sanity to show.
var status: UnitStatus:
	set = _set_status

var _shown_hp := 0.0  ## eases towards the real HP
var _sp_text_colour: Color  ## the Sanity number's own colour, before the bloom lightens it
var _pending_sp_changes: Array[int] = []  ## Sanity changes not shown on the orb yet

@onready var badge_anchor: Marker2D = $BadgeAnchor
@onready var _plate: Sprite2D = $Floor/Plate
@onready var _gauge: HPGauge = $Floor/HPGauge
@onready var _hp_number: Label = $HPNumber
@onready var _orb: Node2D = $Orb
@onready var _orb_frame: Sprite2D = $Orb/Frame
@onready var _glass: OrbGlass = $Orb/Glass
@onready var _sp_number: Label = $Orb/Number
@onready var _panic: Node2D = $States/Panic
@onready var _panic_name: Label = $States/Panic/IconAndName/Name
@onready var _panic_plate: CanvasItem = $States/Panic/Plate
@onready var _stagger: Node2D = $States/Stagger
@onready var _stagger_plate: CanvasItem = $States/Stagger/Plate
@onready var _stagger_bar: CanvasItem = $States/Stagger/Bar
@onready var _burst: AnimationPlayer = $States/Burst/AnimationPlayer
@onready var _slots: Array[Marker2D] = [$States/Slot1, $States/Slot2]


func _ready() -> void:
	for node in get_children():
		if node.is_in_group("preview"):
			remove_child(node)
			node.queue_free()
	# its colour changes at runtime: give this bar its own copy
	_sp_number.label_settings = _sp_number.label_settings.duplicate()
	_sp_text_colour = _sp_number.label_settings.font_color
	for node: Node2D in [_panic, _stagger, $States/Burst]:
		node.visible = false


## How far the bar reaches either side of the feet: its floor plate, or the Sanity orb on the
## right if that sticks out further (the HP number sits over the plate's left half).
func reach() -> float:
	var orb_reach := absf(_orb.position.x) + _orb_frame.texture.get_width() / 2.0
	return maxf(_plate.texture.get_width() / 2.0, orb_reach)


func _process(delta: float) -> void:
	visible = status != null
	if status == null:
		return
	_show_hp(delta)
	_show_sanity()
	_show_condition()


func _set_status(value: UnitStatus) -> void:
	if status and status.sp_changed.is_connected(_on_sp_changed):
		status.sp_changed.disconnect(_on_sp_changed)
	status = value
	_shown_hp = status.hp if status else 0.0
	if status:
		status.sp_changed.connect(_on_sp_changed)


func _on_sp_changed(delta: int, shown: bool) -> void:
	if shown:
		_pending_sp_changes.append(delta)


## The gauge and number slide down (and up) rather than jumping.
func _show_hp(delta: float) -> void:
	var slide_speed := maxf(status.max_hp * HP_SLIDE_SHARE, HP_SLIDE_MIN)
	_shown_hp = move_toward(_shown_hp, status.hp, slide_speed * delta)
	_gauge.fill = clampf(_shown_hp / status.max_hp, 0.0, 1.0)
	var thresholds: Array[float] = []
	for hp in status.thresholds:
		thresholds.append(float(hp) / status.max_hp)
	if thresholds != _gauge.thresholds:
		_gauge.thresholds = thresholds
	if status.broken != _gauge.broken:
		_gauge.broken = status.broken.duplicate()
	_hp_number.text = str(ceili(_shown_hp))


func _show_sanity() -> void:
	_glass.sp = status.sp
	for change in _pending_sp_changes:
		_glass.show_change(change)
	_pending_sp_changes.clear()
	_sp_number.text = str(status.sp)
	_sp_number.label_settings.font_color = _sp_text_colour.lerp(BLOOM_TEXT, _glass.bloom())


## PANIC and STAGGER plates while they last (panic first), and the burst as it staggers.
func _show_condition() -> void:
	_panic_name.text = status.panic_name
	_toggle_plate(_panic, status.is_panicked())
	if status.is_staggered() and not _stagger.visible:
		_burst.play("reveal")
	_toggle_plate(_stagger, status.is_staggered())
	_arrange_plates()


func _toggle_plate(plate: Node2D, on: bool) -> void:
	if plate.visible == on:
		return
	plate.visible = on
	if on:
		var player: AnimationPlayer = plate.get_node("AnimationPlayer")
		player.play("appear")
		player.queue("pulse")


## Into the slots in order; the brushed plates only when it's both at once, the stagger bar
## only when it's alone.
func _arrange_plates() -> void:
	var both := _panic.visible and _stagger.visible
	var slot := 0
	for plate: Node2D in [_panic, _stagger]:
		if plate.visible:
			plate.position = _slots[slot].position
			slot += 1
	_panic_plate.visible = both
	_stagger_plate.visible = both
	_stagger_bar.visible = not both
