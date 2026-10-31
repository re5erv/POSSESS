extends CharacterBody2D

@export var move_speed = 150.0
@export var jump_scale = 1.5 
@export var jump_duration = 0.8 
@export var jump_distance = 200.0 # Как далеко прыгает (в пикселях)

@onready var sprite = $AnimatedSprite2D

var is_jumping = false
var jump_timer = 0.0
var jump_target = null 
var jump_direction = Vector2.ZERO

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
	
	# ПОВОРОТ ЗА МЫШЬЮ
	var mouse_angle = global_position.direction_to(get_global_mouse_position()).angle()
	rotation = mouse_angle + PI/2.0 
	
	# ЛОГИКА ПРЫЖКА (Парение)
	if is_jumping:
		jump_timer += _delta
		var progress = jump_timer / jump_duration
		
		# Плавное изменение масштаба (горб)
		var flight_curve = sin(progress * PI)
		var current_scale = 1.0 + (jump_scale - 1.0) * flight_curve
		scale = Vector2(current_scale, current_scale)
		
		# Движение вперед во время прыжка
		global_position += jump_direction * (jump_distance / jump_duration) * _delta
		
		# ПРОВЕРКА НА ВСЕЛЕНИЕ В ПОЛЕТЕ
		if jump_target and is_instance_valid(jump_target):
			# Если мы подлетели достаточно близко к цели
			if global_position.distance_to(jump_target.global_position) < 30.0:
				possess_target(jump_target)
				return
		
		# Если время вышло — заканчиваем прыжок
		if progress >= 1.0:
			is_jumping = false
			scale = Vector2.ONE
			
			# Если приземлились, но никого не нашли
			if sprite:
				sprite.play("Larp")

func _physics_process(_delta):
	if dead or is_jumping: return # Во время прыжка физика отключается
	
	# ДВИЖЕНИЕ
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_dir.length() > 0.1:
		velocity = input_dir * move_speed
		move_and_slide()
		
		if sprite and sprite.animation != "Walk":
			sprite.play("Walk")
	else:
		velocity = Vector2.ZERO
		if sprite and sprite.animation != "Larp":
			sprite.play("Larp")
			
	# НАЖАТИЕ НА ПРЫЖОК (ПКМ)
	if InputMap.has_action("jump") and Input.is_action_just_pressed("jump") and not is_jumping:
		start_jump()

func start_jump():
	is_jumping = true
	jump_timer = 0.0
	jump_target = null 
	
	# Направление прыжка — туда, куда смотрит мышь
	var mouse_pos = get_global_mouse_position()
	jump_direction = (mouse_pos - global_position).normalized()
	
	# Ищем ближайшего Human в секторе прыжка
	var humans = get_tree().get_nodes_in_group("human")
	var min_dist = jump_distance + 50.0 # Ищем чуть дальше, чем длина прыжка
	
	for human in humans:
		if human.dead or human.is_possessed: 
			continue
			
		var dist = global_position.distance_to(human.global_position)
		if dist < min_dist:
			# Проверяем, находится ли он в направлении прыжка (примерно)
			var dir_to_human = (human.global_position - global_position).normalized()
			var dot = jump_direction.dot(dir_to_human)
			
			# Если угол меньше 45 градусов (dot > 0.7)
			if dot > 0.7:
				min_dist = dist
				jump_target = human
	
	if sprite:
		sprite.play("Jump")

func possess_target(target):
	# Вызываем у человека функцию вселения
	target.possess()
	
	# Удаляем прыгуна (слизь) с карты
	queue_free()
