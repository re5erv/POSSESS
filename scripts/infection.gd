extends Node2D

@export var grow_time = 1.0 
@export var heal_amount = 10
@export var eat_radius = 80.0 
@export var dissolve_speed = 1.5 

var target_scale = Vector2.ONE 
var is_grown = false
var current_time = 0.0

@onready var sprite = $Sprite2D

func _ready():
	target_scale = scale 
	scale = Vector2(0.1, 0.1) 

func _process(delta):
	if not is_grown:
		current_time += delta
		var progress = current_time / grow_time 
		scale = Vector2(0.1, 0.1).lerp(target_scale, progress)
		if progress >= 1.0:
			scale = target_scale 
			is_grown = true
			
	eat_corpses()

func eat_corpses():
	for body in get_tree().get_nodes_in_group("corpse"):
		if body.get_meta("is_dissolving", false): continue
		if global_position.distance_to(body.global_position) < eat_radius:
			body.set_meta("is_dissolving", true)
			dissolve_corpse(body)

func dissolve_corpse(body):
	var tween = create_tween()
	tween.tween_property(body, "modulate:a", 0.0, dissolve_speed)
	await tween.finished
	
	# --- ИЩЕМ ТЕКУЩЕГО ИГРОКА ---
	var player = null
	
	# 1. Ищем слизня (Прыгуна)
	for p in get_tree().get_nodes_in_group("enemies"):
		if not p.has_method("heal"): continue
		# Если это слизень (у него нет is_possessed или он false, но он живой)
		if "is_possessed" in p and not p.is_possessed:
			player = p
			break
			
	# 2. Если слизня нет, ищем человека, в которого вселились
	if not player:
		for p in get_tree().get_nodes_in_group("enemies"):
			if "is_possessed" in p and p.is_possessed and not p.dead:
				player = p
				break
				
	# 3. Лечим
	if player:
		if player.has_method("heal"):
			player.heal(heal_amount)
			print("+", heal_amount, " ХП (Игроку: ", player.name, ")")
		else:
			print("У игрока нет метода heal!")
	else:
		print("Игрок не найден!")
		
	body.queue_free()
