extends Sprite2D

@onready var datagun = $DataGunNode

func _ready():
	add_to_group("weapon_pickup")
	
	if not datagun.edited:
		datagun.gun_name = "Uzi"
		datagun.ammo_in_mag = 0
		datagun.in_mag_max = 32

func get_weapon_name():
	return datagun.gun_name
