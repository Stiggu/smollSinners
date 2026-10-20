class_name DamageNumber
extends Node2D
## A hit's damage as the game pops it up (BattleUnitDamageTypoUISlot): the attack icon in the
## attacker's sin colours, lit by how well the unit hit takes it, the game's word for that under
## it and the number beside it; on a staggered unit the number burns yellow over a burst.
## scenes/clash/effects/damage_number.tscn lays it out and floats it away, then frees it. Its
## number is HDR, so it glows under FxStage's bloom as it does in the game.

const ICONS := "res://assets/limbus/ui/damage_number"
## The game's words for how a unit takes a hit (EN_ResistText).
const WORDS := {
	UnitStatus.ResistLevel.RESISTED: "Ineff.",
	UnitStatus.ResistLevel.ENDURED: "Endure",
	UnitStatus.ResistLevel.NORMAL: "Normal",
	UnitStatus.ResistLevel.FATAL: "Fatal",
}
## Their colours (the game's ResistValueColors).
const WORD_COLOURS := {
	UnitStatus.ResistLevel.RESISTED: Color(0.5, 0.5, 0.5),
	UnitStatus.ResistLevel.ENDURED: Color(0.8, 0.8, 0.8),
	UnitStatus.ResistLevel.NORMAL: Color(0.894, 0.765, 0.576),
	UnitStatus.ResistLevel.FATAL: Color(1.0, 0.25, 0.25),
}
const STAGGERED_WORD_COLOUR := Color(0.94, 0.78, 0.31)  ## gold, as a screenshot of a staggered hit shows
## The attack icon's brightness per resistance, as screenshots show it; "Ineff." gets the grey one.
const ICON_LEVELS := {
	UnitStatus.ResistLevel.ENDURED: 0,
	UnitStatus.ResistLevel.NORMAL: 1,
	UnitStatus.ResistLevel.FATAL: 3,
}

@export var normal_number: LabelSettings
@export var staggered_number: LabelSettings

static var _icons: Dictionary[String, Texture2D] = {}

@onready var _burst: Sprite2D = $Rise/Pop/Staggered
@onready var _icon: Sprite2D = $Rise/Pop/Icon
@onready var _word: Label = $Rise/Pop/Word
@onready var _number: Label = $Rise/Pop/Number


## attacker: whose skill hit (its sin, its attack type and how well the unit hit takes it);
## staggered: the unit hit was staggered, so it took Fatal damage whatever the attack.
func show_hit(amount: int, attacker: ClashFighter, staggered: bool) -> void:
	var level := UnitStatus.ResistLevel.FATAL if staggered else attacker.attack_level
	_icon.texture = _icon_for(attacker.sin, attacker.attack, level)
	_word.text = WORDS[level]
	_word.self_modulate = STAGGERED_WORD_COLOUR if staggered else WORD_COLOURS[level]
	_number.label_settings = staggered_number if staggered else normal_number
	_number.text = str(amount)
	_number.reset_size()
	_burst.visible = staggered


static func _icon_for(sin: String, attack: String, level: UnitStatus.ResistLevel) -> Texture2D:
	var piece := "GREY_%s" % attack if not ICON_LEVELS.has(level) else "%s_%s_%d" % [sin, attack, ICON_LEVELS[level]]
	if not _icons.has(piece):
		_icons[piece] = load("%s/icon_%s.png" % [ICONS, piece])
	return _icons[piece]
