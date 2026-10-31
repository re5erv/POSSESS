extends Node

@export var holsted_weapon: String = ""

@onready var uzi_sprite = $"../UziHolster"
@onready var axe_sprite = $"../AxeHolster"

func _ready():
	update_visibility()

func update_visibility():
	if uzi_sprite:
		uzi_sprite.visible = (holsted_weapon == "Uzi")
		print(uzi_sprite.visible)
	if axe_sprite:
		axe_sprite.visible = (holsted_weapon == "Axe")

func set_holsted(weapon_name: String):
	holsted_weapon = weapon_name
	update_visibility()
