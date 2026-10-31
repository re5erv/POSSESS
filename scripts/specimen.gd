extends CharacterBody2D

@export var move_speed = 150.0
@export var jump_scale = 1.5 
@export var jump_duration = 0.8 

@onready var sprite = $AnimatedSprite2D

var is_jumping = false
var jump_timer = 0.0
var jump_target = null 

# Эти переменные нужны, чтобы люди (в группе "human") могли корректно его обрабатывать
var is_possessed = false
var dead = false

func _ready():
	# Добавляем в группу врагов, чтобы люди видели его и стреляли
	add_to_group("enemies")
	
	if sprite:
		sprite.play("Larp")

func _process(_delta):
	if dead: return
	
	# 1. ПОВОРОТ ЗА МЫШЬЮ
	var mouse_angle = global_position.direction_to(get_global_mouse_position()).angle()
	rotation = mouse_angle + PI/2.0 
	
	# 2. ЛОГИКА ПРЫЖКА (Парение)
	if is_jumping:
		jump_timer += _delta
		var progress = jump_timer / jump_duration
		
		var flight_curve = sin(progress * PI)
		var current_scale = 1.0 + (jump_scale - 1.0) * flight_curve
		scale = Vector2(current_scale, current_scale)
		
		if progress >= 1.0:
			is_jumping = false
			scale = Vector2.ONE
			
			# ПРИЗЕМЛЕНИЕ: проверяем, на кого прыгнули
			if jump_target and is_instance_valid(jump_target):
				possess_target(jump_target)
			else:
				if sprite:
					sprite.play("Larp")

func _physics_process(_delta):
	if dead: return
	
	# 1. ДВИЖЕНИЕ
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_dir.length() > 0.1:
		velocity = input_dir * move_speed
		move_and_slide()
		
		if sprite and sprite.animation != "Walk" and sprite.animation != "Jump":
			sprite.play("Walk")
	else:
		velocity = Vector2.ZERO
		if sprite and sprite.animation != "Larp" and sprite.animation != "Jump":
			sprite.play("Larp")
			
	# 2. НАЖАТИЕ НА ПРЫЖОК
	if InputMap.has_action("jump") and Input.is_action_just_pressed("jump") and not is_jumping:
		start_jump()

func start_jump():
	is_jumping = true
	jump_timer = 0.0
	jump_target = null 
	
	# Ищем ближайшего Human в радиусе (например, 60 пикселей)
	var nearest_human = null
	var min_dist = 60.0 
	
	for human in get_tree().get_nodes_in_group("human"):
		# Проверяем, что он не мертв и в него еще не вселились
		if human.dead or human.is_possessed: 
			continue
			
		var dist = global_position.distance_to(human.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest_human = human
	
	jump_target = nearest_human
	
	if sprite:
		sprite.play("Jump")

func possess_target(target):
	# Вызываем у человека функцию вселения
	target.possess()
	
	# Удаляем прыгуна (слизь) с карты
	queue_free()

# --- Функция для получения урона (если люди попадут) ---
#func take_damage(dmg):
	#if dead: return
	# У слизи нет здоровья, поэтому просто игнорируем или удаляем
	#print("Слизень получил урон, но выжил (или умри, если нужно)")
	# Если хочешь, чтобы слизень умирал:
	# dead = true
	# queue_free()
