class_name IdentityCard
extends Control
## One identity as a card from the game's team-formation screen
## (scenes/ui/identity_card.tscn): the portrait, the frame and rarity marks for its rank, the
## sinner's emblem, the level line and the name. While it's on the desktop it looks like a
## card picked on the game's sortie screen: darkened, under its place in the team and a
## SELECTED tag. Click it, or drag it out of the Settings panel. Art from
## tools/export_formation.py (assets/limbus/ui/formation).

## Clicked: let go of over the card without dragging it.
signal pressed
## Pulled further than drag_distance with the button down; drag_ended follows when it's let go.
signal drag_started
signal drag_ended

const FORMATION := "res://assets/limbus/ui/formation"
const LOWEST_RANK := 1
const HIGHEST_RANK := 3
## set_team_order(): the identity isn't on the desktop, so no number and no tag.
const NOT_IN_TEAM := 0

@export var drag_distance := 8.0  ## px the pointer moves, button down, before a click becomes a drag
@export var hover_scale := 1.04
@export var hover_seconds := 0.12
@export var dragged_alpha := 0.45  ## the card while it's out being dragged
## The card under the number and tag while it's on the desktop: the game darkens it to about
## half (measured off its sortie screen: frame, rarity marks and text).
@export var in_team_tint := Color(0.5, 0.5, 0.5)

var identity_path := ""  ## "<sinner>/<folder>"

static var _textures: Dictionary[String, Texture2D] = {}

var _enabled := true
var _press_at := Vector2.INF  ## where the button went down (window px); INF while it's up
var _dragging := false
var _scale_tween: Tween

@onready var _face: Control = $Face  ## everything the tag and number sit on
@onready var _glow: TextureRect = $Face/GlowSlot/Glow
@onready var _portrait: TextureRect = $Face/Portrait
@onready var _unavailable: ColorRect = $Face/Portrait/Unavailable
@onready var _frame: TextureRect = $Face/Frame
@onready var _grade: TextureRect = $Face/Grade
@onready var _ring: TextureRect = $Face/Ring
@onready var _emblem: TextureRect = $Face/EmblemSlot/Emblem
@onready var _level_line: Label = $Face/Text/LevelLine
@onready var _name: Label = $Face/Text/Name
@onready var _selected_tag: TextureRect = $SelectedTag
## The game's ParticipateOrder. Its box sits 101 canvas units over the tag's centre there, but
## Godot draws the digit higher in its box than TextMeshPro does, so in the scene it's placed
## where the game's digits come out (measured against the tag on the sortie screen).
@onready var _team_order: Label = $SelectedTag/TeamOrder


func show_identity(identity: Roster.IdentityEntry, sinner: Roster.SinnerEntry) -> void:
	identity_path = identity.path
	_enabled = identity.supported
	var rank := clampi(identity.rank, LOWEST_RANK, HIGHEST_RANK)
	_glow.texture = _piece("glow_%d" % rank)
	_frame.texture = _piece("frame_%d" % rank)
	_grade.texture = _piece("grade_%d" % rank)
	_ring.texture = _piece("ring_%d" % rank)
	_emblem.texture = _piece("emblem_" + sinner.key)
	_center_in_slot(_glow)
	_center_in_slot(_emblem)
	var portrait_path := IdentityLibrary.dir_of(identity.path).path_join("card.png")
	_portrait.texture = load(portrait_path) if ResourceLoader.exists(portrait_path) else null
	_unavailable.visible = not _enabled
	_level_line.text = sinner.name
	_name.text = identity.card_title
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _enabled else Control.CURSOR_ARROW
	set_team_order(NOT_IN_TEAM)


## Where this identity stands in the team on the desktop: 1 for the first one out, or
## NOT_IN_TEAM. A team member's card goes dark under that number and a SELECTED tag.
func set_team_order(order: int) -> void:
	var in_team := order != NOT_IN_TEAM
	_face.modulate = in_team_tint if in_team else Color.WHITE
	_selected_tag.visible = in_team
	_team_order.text = str(order)


## Finish a drag, if one is going: when the button comes up (the panel may hear it first).
func end_drag() -> void:
	_press_at = Vector2.INF
	if _dragging:
		_dragging = false
		modulate.a = 1.0
		drag_ended.emit()


func _ready() -> void:
	pivot_offset = size / 2.0
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))


func _gui_input(event: InputEvent) -> void:
	if not _enabled:
		return
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if button.pressed:
			_press_at = button.global_position
		elif _press_at != Vector2.INF:
			_on_release(button.position)
	var motion := event as InputEventMouseMotion
	if motion and _press_at != Vector2.INF and not _dragging and motion.global_position.distance_to(_press_at) > drag_distance:
		_dragging = true
		modulate.a = dragged_alpha
		drag_started.emit()


func _on_release(at: Vector2) -> void:
	_press_at = Vector2.INF
	if _dragging:
		end_drag()
	elif Rect2(Vector2.ZERO, size).has_point(at):
		pressed.emit()


func _on_hover(hovered: bool) -> void:
	if _scale_tween:
		_scale_tween.kill()
	_scale_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var target := hover_scale if hovered and _enabled else 1.0
	_scale_tween.tween_property(self, "scale", Vector2.ONE * target, hover_seconds)


## Sits a picture in the middle of its slot (its parent), on whole units (texels), like the
## exporter places it. The game's pieces are trimmed to different sizes, so the slot's centre
## is what lines up.
static func _center_in_slot(picture: TextureRect) -> void:
	picture.size = picture.texture.get_size()
	picture.position = ((picture.get_parent_control().size - picture.size) / 2.0).floor()


static func _piece(file: String) -> Texture2D:
	if not _textures.has(file):
		_textures[file] = load("%s/%s.png" % [FORMATION, file])
	return _textures[file]
