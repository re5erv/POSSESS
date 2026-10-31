extends Control

@onready var h_num = $VBoxContainer3/Hnumb
@onready var f_num = $VBoxContainer3/Fnumb
@onready var m_num = $VBoxContainer3/Mnumb
@onready var b_num = $VBoxContainer3/Bnumb
@onready var time_label = $Time/TimeL
@onready var wname = $ItemName/Name
@onready var wbullets = $ItemName/Bullets
@onready var wtitle = $ItemName/Title
@onready var wicon = $WeaponContainer/WeaponIcon

var player = null

func _ready():
	player = get_parent().get_parent()
	update_hud()

func _process(_delta):
	update_hud()

func update_hud():
	if not player:
		return
	
	var stats = $"../../Stats"
	
	h_num.text = ": " + str(stats.health)
	f_num.text = ": " + str(stats.hunger)
	m_num.text = ": " + str(stats.moneys)
	
	var time_seconds = int(player.time_played)
	var minutes = int(time_seconds / 60.0)  # ← деление с float
	var seconds = int(time_seconds % 60)
	time_label.text = "%02d:%02d" % [minutes, seconds]
	
	var weapon_name = ""
	var ammo_text = ": 0"
	var title_text = ""
	var bullets_text = ""
	var icon_path = ""
	
	if stats.current_weapon != "":
		weapon_name = stats.current_weapon
		
		if weapon_name == "Uzi":
			weapon_name = "KH-9 Cinder"
			title_text = "Fast and lightweight"
			icon_path = "res://textures/basetexs/KHCinderIC.png"
			if player.current_datagun:
				bullets_text = str(player.current_datagun.ammo_in_mag) + "/" + str(player.current_datagun.in_mag_max)
				ammo_text = ": " + str(player.current_datagun.ammo_in_mag + stats.ammo_in_pocket)
			else:
				bullets_text = "0/32"
				ammo_text = ": " + str(stats.ammo_in_pocket)
		
		elif weapon_name == "Axe":
			title_text = "Cut down trees"
			ammo_text = ": " + str(stats.ammo_in_pocket)
			icon_path = "res://textures/basetexs/AxeIC.png"
		
		# Добавь сюда другие оружия
	
	elif player.is_carrying_item:
		weapon_name = player.carried_item
		title_text = "Very heavy log"
		ammo_text = ": " + str(stats.ammo_in_pocket)
		icon_path = "res://textures/basetexs/TimberIC.png"
	
	else:
		weapon_name = ""
		ammo_text = ": " + str(stats.ammo_in_pocket)
		icon_path = ""
	
	wname.text = weapon_name
	b_num.text = ammo_text
	wtitle.text = title_text
	wbullets.text = bullets_text
	
	if icon_path != "":
		wicon.texture = load(icon_path)
		wicon.visible = true
	else:
		wicon.visible = false
