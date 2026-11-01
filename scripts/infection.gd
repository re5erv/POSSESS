extends Node2D

@export var grow_time = 1.0 
@export var heal_amount = 50
@export var eat_radius = 25.0 # <--- ИЗМЕНЕНО НА 25
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
	# Учитываем текущий масштаб инфекции
	var actual_radius = eat_radius * scale.x 
	
	for body in get_tree().get_nodes_in_group("corpse"):
		if body.get_meta("is_dissolving", false): continue
		
		# Проверяем расстояние с учетом радиуса
		if global_position.distance_to(body.global_position) < actual_radius:
			body.set_meta("is_dissolving", true)
			dissolve_corpse(body)

func dissolve_corpse(body):
	# Создаем твин для растворения
	var tween = create_tween()
	tween.tween_property(body, "modulate:a", 0.0, dissolve_speed)
	
	# Ждем окончания
	await tween.finished
	
	# --- ЛЕЧИМ ИГРОКА ---
	var player = null
	for p in get_tree().get_nodes_in_group("enemies"):
		if not p.has_method("heal"): continue
		if "is_possessed" in p and not p.is_possessed:
			player = p
			break
			
	if not player:
		for p in get_tree().get_nodes_in_group("enemies"):
			if "is_possessed" in p and p.is_possessed and not p.dead:
				player = p
				break
				
	if player and player.has_method("heal"):
		player.heal(heal_amount)
		print("+", heal_amount, " ХП (Игроку: ", player.name, ")")
		
	body.queue_free()
