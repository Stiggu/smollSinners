class_name SettingsPanel
extends Control
## Pick who's on the desktop; opened from the tray menu (scenes/ui/settings_panel.tscn). It's
## drawn on the overlay, over the sinners, like one of the game's own screens: the team
## formation, the twelve sinners as identity cards. Clicking one lists that sinner's
## identities; dragging any card off the panel carries that sinner onto the desktop. Grab any
## empty part of it to move it.

## An identity card was clicked: its path, e.g. "yisang/10101_Base".
signal identity_chosen(path: String)
## A card is being dragged out: the overlay hands that identity to the pointer.
signal card_drag_started(path: String)
## ... and let go of; the pointer is wherever it was dropped.
signal card_drag_ended

const CARD_SCENE := preload("res://scenes/ui/identity_card.tscn")
const ROSTER_TITLE := "SINNERS"
const HINT := "Drag a card off here to bring that sinner out; drop a sinner back on here to send them home."
const CARRY_HINT := "Let go on the desktop to bring %s out, or back on here to put them away."
const UNSUPPORTED_HINT := "Not supported yet: this identity is animated with a cutout rig."
const NOTHING_EXPORTED := "No identities exported yet: run tools/export_godot.py"
const ON_DESKTOP := "On the desktop: "

@export var rows_shown := 2  ## rows of cards it opens tall enough for: all twelve sinners
## How much of the screen's height it takes. It's laid out in the game's canvas units (a card is
## 300x450) and scaled to the screen like the game's own UI, so it looks the same on any monitor.
@export_range(0.3, 1.0) var screen_share := 0.8
@export var screen_margin := 24.0  ## screen px kept clear between the panel and the overlay's edges
@export var scroll_bar_gap := 16.0  ## between the cards and the scroll bar
@export var carried_alpha := 0.3  ## while a card's sinner is being carried: out of the way
@export var fade_seconds := 0.15

## The identities on the desktop, as paths, in the order they came out; their cards are
## numbered in that order and tagged SELECTED.
var team: Array[String] = []

var _roster: Roster
var _placed := false
var _area := Vector2.ZERO  ## the overlay's size, which the panel stays inside
var _grab := Vector2.INF  ## while it's being moved: the pointer from its top-left; INF otherwise
var _dragged_card: IdentityCard  ## the card out being dragged, if any
var _fade: Tween
var _card_size := Vector2.ZERO

@onready var _layout: Control = $Body/Layout
@onready var _title: Label = $Body/Layout/Column/Top/Header/Title
@onready var _back: Button = $Body/Layout/Column/Top/Back
@onready var _scroll: ScrollContainer = $Body/Layout/Column/Cards/Scroll
@onready var _grid: GridContainer = $Body/Layout/Column/Cards/Scroll/Center/Grid
@onready var _status: Label = $Body/Layout/Column/Bottom/Lines/Status
@onready var _hint: Label = $Body/Layout/Column/Bottom/Lines/Hint


func _ready() -> void:
	var probe: Control = CARD_SCENE.instantiate()
	_card_size = probe.custom_minimum_size
	probe.free()
	# never narrower than a full row, whatever is listed
	_grid.custom_minimum_size.x = _span(_grid.columns, _card_size.x, _grid.get_theme_constant("h_separation"))
	_load_roster()


## Show the panel on the twelve sinners: centred on the overlay the first time, and wherever
## it was left after that (as long as it still fits). area: the overlay's size.
func open(area: Vector2) -> void:
	if not _placed or not Rect2(Vector2.ZERO, area).encloses(get_rect()):
		fit_in(area)
	_show_roster()
	show()


## Size it for rows_shown rows of cards and scale it to screen_share of the overlay's height
## (less if it would be too wide), and put it at the top, centred: the floor below stays in view.
func fit_in(area: Vector2) -> void:
	_placed = true
	_area = area
	size = _natural_size()
	var room := area - Vector2.ONE * 2.0 * screen_margin
	var largest_that_fits := minf(room.x / size.x, room.y / size.y)
	scale = Vector2.ONE * minf(screen_share * area.y / size.y, largest_that_fits)
	position = Vector2(roundf((area.x - get_rect().size.x) / 2.0), screen_margin)


## One sinner's identities, e.g. "ryoshu"; picking one puts it on the desktop.
func show_sinner(sinner_key: String) -> void:
	_show_identities(sinner_key)


## Who's on the desktop changed: number and tag their cards.
func set_team(paths: Array[String]) -> void:
	team = paths
	for card: IdentityCard in _grid.get_children():
		card.set_team_order(_team_order(card.identity_path))
	_update_status()


## Being moved, or a card on it is out being dragged: the overlay must keep the mouse.
func is_busy() -> bool:
	return _grab != Vector2.INF or _dragged_card != null


## Whatever no card or button takes moves the panel.
func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		_grab = button.position if button.pressed else Vector2.INF
		accept_event()
	var motion := event as InputEventMouseMotion
	if motion and _grab != Vector2.INF:
		var top_left := position + (motion.position - _grab) * scale  # local, so scaled to the overlay's px
		position = top_left.clamp(Vector2.ZERO, (_area - get_rect().size).max(Vector2.ZERO)).round()


func _process(_delta: float) -> void:
	# the card hears the button come up (Godot holds the mouse while it's down); in case it
	# doesn't, nothing stays stuck to the pointer
	if _dragged_card and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_dragged_card.end_drag()


func _load_roster() -> void:
	_roster = Roster.load_file()
	if _roster.is_empty():
		_status.text = NOTHING_EXPORTED


## The twelve sinners, each wearing the identity on the desktop or the one picked last.
func _show_roster() -> void:
	_title.text = ROSTER_TITLE
	_back.visible = false
	_clear_grid()
	for sinner in _roster.sinners:
		var identity := _shown_identity(sinner)
		if identity == null:
			continue
		var card := _add_card(sinner, identity)
		# deferred: switching views frees this card, which is still handling the click
		card.pressed.connect(_show_identities.bind(sinner.key), CONNECT_DEFERRED)
	_update_status()


func _show_identities(sinner_key: String) -> void:
	var sinner := _roster.find(sinner_key)
	_title.text = sinner.name.to_upper()
	_back.visible = true
	_clear_grid()
	for identity in sinner.identities:
		var card := _add_card(sinner, identity)
		card.pressed.connect(_choose.bind(sinner, identity))
	_scroll.scroll_vertical = 0
	_update_status()


func _add_card(sinner: Roster.SinnerEntry, identity: Roster.IdentityEntry) -> IdentityCard:
	var card: IdentityCard = CARD_SCENE.instantiate()
	_grid.add_child(card)
	card.show_identity(identity, sinner)
	card.set_team_order(_team_order(identity.path))
	card.drag_started.connect(_on_card_drag_started.bind(card, sinner, identity))
	card.drag_ended.connect(_on_card_drag_ended.bind(card))
	if not identity.supported:  # say why it can't be picked, where the hint goes
		card.mouse_entered.connect(_hint.set_text.bind(UNSUPPORTED_HINT))
		card.mouse_exited.connect(_hint.set_text.bind(HINT))
	return card


func _choose(sinner: Roster.SinnerEntry, identity: Roster.IdentityEntry) -> void:
	AppSettings.save_formation_pick(sinner.key, identity.folder)
	identity_chosen.emit(identity.path)


func _on_card_drag_started(card: IdentityCard, sinner: Roster.SinnerEntry, identity: Roster.IdentityEntry) -> void:
	_dragged_card = card
	AppSettings.save_formation_pick(sinner.key, identity.folder)
	_hint.text = CARRY_HINT % sinner.name
	_fade_to(carried_alpha)
	card_drag_started.emit(identity.path)


func _on_card_drag_ended(card: IdentityCard) -> void:
	if card == _dragged_card:
		_dragged_card = null
		_hint.text = HINT
		_fade_to(1.0)
		card_drag_ended.emit()


func _fade_to(alpha: float) -> void:
	if _fade:
		_fade.kill()
	_fade = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_fade.tween_property(self, "modulate:a", alpha, fade_seconds)


## The identity a sinner's card shows: the one on the desktop, else the one picked last,
## else the first one the pet can play (the LCB Sinner). Null if it can play none.
func _shown_identity(sinner: Roster.SinnerEntry) -> Roster.IdentityEntry:
	var picked_last := AppSettings.formation_pick(sinner.key)
	var picked: Roster.IdentityEntry
	var first_playable: Roster.IdentityEntry
	for identity in sinner.identities:
		if identity.path in team:
			return identity
		if identity.supported:
			if identity.folder == picked_last:
				picked = identity
			if first_playable == null:
				first_playable = identity
	return picked if picked else first_playable


## An identity's place in the team: 1 for the first one out, IdentityCard.NOT_IN_TEAM if
## it isn't out.
func _team_order(identity_path: String) -> int:
	var index := team.find(identity_path)
	return IdentityCard.NOT_IN_TEAM if index == -1 else index + 1


func _update_status() -> void:
	var out: Array[String] = []
	for sinner in _roster.sinners:
		for identity in sinner.identities:
			if identity.path in team:
				out.append("%s, %s" % [sinner.name, identity.title] if team.size() == 1 else sinner.name)
	if not out.is_empty():
		_status.text = ON_DESKTOP + ", ".join(out)


func _clear_grid() -> void:
	for card in _grid.get_children():
		_grid.remove_child(card)
		card.queue_free()
	_hint.text = HINT  # a card that was showing why it's unsupported is gone


## Tall enough for rows_shown rows of cards, with room for the scroll bar beside them.
func _natural_size() -> Vector2:
	var cards_height := _span(rows_shown, _card_size.y, _grid.get_theme_constant("v_separation"))
	var scroll_bar_room := _scroll.get_v_scroll_bar().get_combined_minimum_size().x + scroll_bar_gap
	return (_layout.get_combined_minimum_size() + Vector2(scroll_bar_room, cards_height)).ceil()


## How long `count` cards of `length` take up in a row or column, `gap` apart.
static func _span(count: int, length: float, gap: int) -> float:
	return count * length + (count - 1) * gap
