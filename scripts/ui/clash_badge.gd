class_name ClashBadge
extends Node2D
## One side's skill badge in a clash, as the game builds it (SkillAndCoinUI), as a scene:
## scenes/ui/clash_badge.tscn, laid out for a ribbon running right (place() with outward -1
## mirrors it). Back to front: the name Ribbon and the Name on it, the +N Tab, the Face (the
## sin's Glow, the skill Art, the sin's Frame; it flips in like a card), the AttackGlow and
## the Attack type, the Power (popping on every heads), the +N TabText, and the Coins above
## the ribbon (Coin1 is the first coin's place, Coin2 the step to the next; tossed coins spin
## edge-on until they land, lost ones go). With more tails than heads it greys out, all but
## the glows and the name: the art and attack icon through the game's ColorGrayscale shader,
## the rest in the greys measured off the game. The node is the badge's centre. Pieces from
## tools/export_ui.py.

const CLASH_UI := "res://assets/limbus/ui/clash"
const NO_SIN := "NONE"
## Sin affinity colours for the frame, tab and ribbon; NO_SIN is for a skill without one.
const SIN_COLOURS := {
	"CRIMSON": Color("c8322b"), "SCARLET": Color("e2702a"), "AMBER": Color("e9b53c"),
	"SHAMROCK": Color("7fb83a"), "AZURE": Color("2f86e0"), "INDIGO": Color("3d4fb0"),
	"VIOLET": Color("8f45d6"), NO_SIN: Color("9a7652"),
}
const COIN_FACES := {
	ClashFighter.Face.UNFLIPPED: preload("res://assets/limbus/ui/coin_idle.png"),
	ClashFighter.Face.SPINNING: preload("res://assets/limbus/ui/coin_idle.png"),
	ClashFighter.Face.HEADS: preload("res://assets/limbus/ui/coin_heads.png"),
	ClashFighter.Face.TAILS: preload("res://assets/limbus/ui/coin_tails.png"),
	ClashFighter.Face.CRACKED_FRONT: preload("res://assets/limbus/ui/coin_cracked_front.png"),
	ClashFighter.Face.CRACKED_BACK: preload("res://assets/limbus/ui/coin_cracked_back.png"),
}
const GRAYSCALE_FADE := &"grayscale_fade"  ## the ColorGrayscale shader's 0 (colour) to 1 (grey)
## Attack icon brightness per resist level, as the damage popup's; a resisted (Ineff.) attack is grey.
const ATTACK_ICON_LEVELS := {
	UnitStatus.ResistLevel.ENDURED: 0, UnitStatus.ResistLevel.NORMAL: 1,
	UnitStatus.ResistLevel.WEAK: 2, UnitStatus.ResistLevel.FATAL: 3,
}

## px of ribbon past the end of the name.
@export var end_pad := 18.0
@export_group("Flipping in")
@export var flip_in_seconds := 0.12
@export var flip_in_ease := 0.4  ## an ease() curve: under 1 starts fast
@export var flip_in_min_width := 0.02  ## the face never gets thinner than this (scale)
@export_group("Pops")
@export var power_pop_seconds := 0.2
@export var power_pop := 0.7  ## extra scale the power pops in with
@export var coin_pop_seconds := 0.12
@export var coin_pop := 0.45
@export_group("Spinning coins")  ## measured off matches/PowerGuard.gif (edge-on every ~80 ms)
@export var coin_spins_per_second := 3.0
@export var coin_edge_width := 0.1  ## an edge-on coin still shows this much of its width (scale)
@export_group("Sin colours")
@export var tab_darken := 0.15  ## the tab is a little darker than the ribbon
@export var name_outline_darken := 0.75  ## the name's outline is a dark shade of the ribbon
@export var frame_lighten := 0.15
@export_group("Greyed out")  ## measured off the game: matches/clash_count.png, its left badge
@export var greyed_ribbon := Color(0.31, 0.3, 0.29)
@export var greyed_tab := Color(0.29, 0.29, 0.29)
@export var greyed_frame := Color(0.28, 0.28, 0.27)  ## the frame's light lines
@export var greyed_power := Color(1, 0.99, 0.98)
@export var greyed_tab_text := Color(0.74, 0.67, 0.57)

## +1: the ribbon runs right, as laid out in the scene; -1: mirrored, running left.
var outward := 1

static var _textures: Dictionary[String, Texture2D] = {}

var _sin := NO_SIN
var _colour := Color.WHITE  ## the sin's
var _coins: Array[Sprite2D] = []
var _coin_first: Vector2  ## the first coin's place, ribbon running right
var _coin_step: Vector2  ## ... and the step to the next
var _home: Dictionary[CanvasItem, Vector2] = {}  ## each piece's place as laid out in the scene
var _home_ribbon_length := 0.0
var _home_tab_flip := false
var _power_colour: Color
var _tab_text_colour: Color

@onready var _ribbon: NinePatchRect = $Ribbon
@onready var _name: Label = $Name
@onready var _tab: Sprite2D = $Tab
@onready var _face: Node2D = $Face
@onready var _glow: Sprite2D = $Face/Glow
@onready var _art_sprite: Sprite2D = $Face/Art
@onready var _frame: Sprite2D = $Face/Frame
@onready var _attack_glow: Sprite2D = $AttackGlow
@onready var _attack: Sprite2D = $Attack
## the art's and the attack icon's (one per badge: the scene makes it local)
@onready var _grayscale: ShaderMaterial = _art_sprite.material
@onready var _power: Label = $Power
@onready var _tab_text: Label = $TabText


static func has_sin_colour(sin: String) -> bool:
	return SIN_COLOURS.has(sin)


func _ready() -> void:
	for node: CanvasItem in [_ribbon, _name, _tab, _attack, _power, _tab_text]:
		_home[node] = node.position
	_home_ribbon_length = _ribbon.size.x
	_home_tab_flip = _tab.flip_h
	var first: Sprite2D = $Coins/Coin1
	var second: Sprite2D = $Coins/Coin2
	_coin_first = first.position
	_coin_step = second.position - first.position
	$Coins.remove_child(second)
	second.queue_free()
	_coins = [first]
	# their colours change at runtime: give this badge its own copies
	for label: Label in [_name, _power, _tab_text]:
		label.label_settings = label.label_settings.duplicate()
	_power_colour = _power.label_settings.font_color
	_tab_text_colour = _tab_text.label_settings.font_color


## What it shows: the fighter's skill name, sin, art, attack type (and how well the target
## takes it), first coin's power and coins.
func show_fighter(fighter: ClashFighter) -> void:
	_sin = fighter.sin
	_colour = SIN_COLOURS[_sin]
	_name.text = fighter.skill_name
	_tab_text.text = "%+d" % fighter.first_coin_power()
	_glow.texture = _texture("glow_" + _sin)
	_frame.texture = _texture("frame_" + _sin)
	_art_sprite.texture = fighter.art
	_art_sprite.visible = fighter.art != null
	_attack.texture = _attack_icon(fighter)
	_set_coin_count(fighter.coin_powers.size())
	place(position, outward)


## The attack type in the sin's colours, lit by how well the target takes it.
func _attack_icon(fighter: ClashFighter) -> Texture2D:
	if not ATTACK_ICON_LEVELS.has(fighter.attack_level):
		return _texture("attack_GREY_" + fighter.attack)
	return _texture("attack_%s_%s_%d" % [_sin, fighter.attack, ATTACK_ICON_LEVELS[fighter.attack_level]])


## Centre it at `center` with its ribbon running `toward` (+1 right, -1 left).
func place(center: Vector2, toward: int) -> void:
	position = center
	outward = toward
	_ribbon.size.x = ribbon_end()
	_ribbon.scale.x = outward
	_ribbon.position.x = _home[_ribbon].x * outward
	_place_name()
	_tab.position.x = _home[_tab].x * outward
	_tab.flip_h = _home_tab_flip if outward > 0 else not _home_tab_flip
	_attack.position.x = _home[_attack].x * outward
	_attack_glow.position.x = _attack.position.x
	for label: Label in [_power, _tab_text]:  # centred: mirror their centres
		label.position.x = outward * (_home[label].x + label.size.x / 2.0) - label.size.x / 2.0
	_place_coins()


## How far the ribbon reaches from the badge's centre: as laid out, or further for a long name.
func ribbon_end() -> float:
	return ribbon_end_for(_name.text)


## ... and how far it would reach with this name on it.
func ribbon_end_for(skill_name: String) -> float:
	return maxf(_home_ribbon_length, _home[_name].x + _name_width(skill_name) + end_pad)


## Show the fighter's state at clash time `now`: its coins, its power, greyed out or not.
func show_state(fighter: ClashFighter, now: float) -> void:
	var greyed := fighter.is_greyed_out()
	var ribbon := greyed_ribbon if greyed else _colour
	_ribbon.self_modulate = ribbon
	_name.label_settings.outline_color = ribbon.darkened(name_outline_darken)
	_tab.self_modulate = greyed_tab if greyed else _colour.darkened(tab_darken)
	_tab_text.label_settings.font_color = greyed_tab_text if greyed else _tab_text_colour
	_face.scale.x = _flip_in_width(now - fighter.appeared_at)
	_glow.self_modulate = _colour
	_attack_glow.self_modulate = _colour
	_grayscale.set_shader_parameter(GRAYSCALE_FADE, 1.0 if greyed else 0.0)
	if greyed:
		_frame.self_modulate = greyed_frame
	elif _sin == NO_SIN:
		_frame.self_modulate = Color.WHITE  # the icons' frame is drawn in its own colours
	else:
		_frame.self_modulate = _colour.lightened(frame_lighten)
	_show_power(fighter, greyed, now)
	for i in mini(fighter.faces.size(), _coins.size()):
		_show_coin(_coins[i], fighter.faces[i], now - fighter.flipped_at[i], now - fighter.spun_at)


## One coin: gone, spinning edge-on, or showing its face (popping as it lands).
func _show_coin(coin: Sprite2D, face: ClashFighter.Face, landed_age: float, spin_age: float) -> void:
	coin.visible = face != ClashFighter.Face.GONE
	if not coin.visible:
		return
	coin.texture = COIN_FACES[face]
	var pop := _pop_scale(landed_age, coin_pop_seconds, coin_pop)
	var width := _spin_width(spin_age) if face == ClashFighter.Face.SPINNING else 1.0
	coin.scale = Vector2(pop * width, pop)


## A spinning coin's width: it turns about its upright axis, from face-on to edge-on and back.
func _spin_width(age: float) -> float:
	return maxf(absf(cos(TAU * coin_spins_per_second * age)), coin_edge_width)


## The power appears once it has a value, popping (and flashing its own colour) each time it changes.
func _show_power(fighter: ClashFighter, greyed: bool, now: float) -> void:
	_power.visible = now >= fighter.power_changed_at
	if not _power.visible:
		return
	var pop := _pop_scale(now - fighter.power_changed_at, power_pop_seconds, power_pop)
	_power.text = str(fighter.power)
	_power.scale = Vector2.ONE * pop
	var flash := (pop - 1.0) / power_pop
	_power.label_settings.font_color = greyed_power if greyed else Color.WHITE.lerp(_power_colour, flash)


## The face's width as it flips in like a card.
func _flip_in_width(age: float) -> float:
	return maxf(ease(clampf(age / flip_in_seconds, 0.0, 1.0), flip_in_ease), flip_in_min_width)


func _place_name() -> void:
	var width := _name_width(_name.text)
	_name.size.x = width
	if outward > 0:
		_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_name.position.x = _home[_name].x
	else:
		_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_name.position.x = -_home[_name].x - width


func _set_coin_count(count: int) -> void:
	while _coins.size() < count:
		var coin: Sprite2D = _coins[0].duplicate()
		$Coins.add_child(coin)
		_coins.append(coin)
	for i in _coins.size():
		_coins[i].visible = i < count
	_place_coins()


func _place_coins() -> void:
	for i in _coins.size():
		var at := _coin_first + _coin_step * i
		_coins[i].position = Vector2(at.x * outward, at.y)


func _name_width(text: String) -> float:
	var settings := _name.label_settings
	return settings.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, settings.font_size).x


## A little pop `age` seconds after something changed: 1 + amount at first, settling to 1
## over `seconds`.
static func _pop_scale(age: float, seconds: float, amount: float) -> float:
	var t := age / seconds
	return 1.0 if t >= 1.0 or t < 0.0 else 1.0 + amount * (1.0 - t)


static func _texture(piece: String) -> Texture2D:
	if not _textures.has(piece):
		_textures[piece] = load("%s/%s.png" % [CLASH_UI, piece])
	return _textures[piece]
