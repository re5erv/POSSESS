extends Node2D

@export var grow_time = 1.0 # За сколько секунд он достигает нужного размера
@export var heal_amount = 15 # Сколько ХП лечит один труп

var target_scale = Vector2.ONE 
var is_grown = false
var current_time = 0.0

@onready var sprite = $Sprite2D
@onready var area = $Area2D

func _ready():
	add_to_group("infection")
	area.body_entered.connect(_on_body_entered)
	
	# Берем масштаб из редактора
	target_scale = scale 
	# Начинаем с маленького размера
	scale = Vector2(0.1, 0.1) 

func _process(delta):
	# Логика роста (вращение убрано)
	if not is_grown:
		current_time += delta
		var progress = current_time / grow_time 
		
		scale = Vector2(0.1, 0.1).lerp(target_scale, progress)
		
		if progress >= 1.0:
			scale = target_scale 
			is_grown = true

func _on_body_entered(body):
	if body.is_in_group("corpse") or (body.is_in_group("human") and "dead" in body and body.dead):
		var players = get_tree().get_nodes_in_group("enemies")
		for p in players:
			if p.has_method("heal"):
				p.heal(heal_amount)
				
		print("Труп поглощен!")
		body.queue_free()
