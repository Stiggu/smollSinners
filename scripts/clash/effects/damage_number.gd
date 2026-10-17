class_name DamageNumber
extends Node2D
## A hit's damage, yellow, with its attack type's icon beside it
## (scenes/clash/effects/damage_number.tscn, which pops it up and floats it away).

@export var slash_icon: Texture2D
@export var pierce_icon: Texture2D
@export var blunt_icon: Texture2D

@onready var _number: Label = $Rise/Pop/Number
@onready var _attack_icon: TextureRect = $Rise/Pop/Number/AttackIcon


## amount: the damage; attack: "slash", "pierce" or "blunt".
func show_damage(amount: int, attack: String) -> void:
	_number.text = str(amount)
	_number.reset_size()
	_number.position = (-_number.size / 2.0).round()  # centred on the node
	_attack_icon.texture = _icon_for(attack)


func _icon_for(attack: String) -> Texture2D:
	match attack:
		"slash":
			return slash_icon
		"pierce":
			return pierce_icon
	return blunt_icon
