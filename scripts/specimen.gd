extends CharacterBody2D

@export var move_speed = 150.0
@export var jump_scale = 1.5 # Насколько слизь увеличивается в прыжке
@export var jump_duration = 0.8 # Длительность прыжка (0.8 сек = плавное парение)

@onready var sprite = $AnimatedSprite2D

var is_jumping = false
var jump_timer = 0.0

func _ready():
	if sprite:
		sprite.play("Larp")

func _process(_delta):
	# 1. ПОВОРОТ ЗА МЫШЬЮ
	var mouse_angle = global_position.direction_to(get_global_mouse_position()).angle()
	rotation = mouse_angle + PI/2.0 
	
	# 2. ЛОГИКА ПРЫЖКА (Парение)
	if is_jumping:
		jump_timer += _delta
		var progress = jump_timer / jump_duration
		
		# Используем функцию smoothstep для более плавного парения (взлет и посадка)
		# Вместо простого синуса мы берем "горб" (от 0 до 1 и обратно к 0)
		var flight_curve = sin(progress * PI)
		
		# Применяем масштаб (плавно)
		var current_scale = 1.0 + (jump_scale - 1.0) * flight_curve
		scale = Vector2(current_scale, current_scale)
		
		# Если время вышло — заканчиваем прыжок
		if progress >= 1.0:
			is_jumping = false
			scale = Vector2.ONE # Возвращаем исходный размер
			# Возвращаем анимацию покоя
			if sprite:
				sprite.play("Larp")

func _physics_process(_delta):
	# 1. ДВИЖЕНИЕ
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_dir.length() > 0.1:
		velocity = input_dir * move_speed
		move_and_slide()
		
		# Если мы в прыжке, не перебиваем анимацию Jump анимацией Walk
		if sprite and sprite.animation != "Walk" and sprite.animation != "Jump":
			sprite.play("Walk")
	else:
		velocity = Vector2.ZERO
		# Если мы в прыжке, не перебиваем Jump анимацией Larp
		if sprite and sprite.animation != "Larp" and sprite.animation != "Jump":
			sprite.play("Larp")
			
	# 2. НАЖАТИЕ НА ПРЫЖОК
	if InputMap.has_action("jump") and Input.is_action_just_pressed("jump") and not is_jumping:
		start_jump()

func start_jump():
	is_jumping = true
	jump_timer = 0.0
	
	# Включаем анимацию прыжка
	if sprite:
		sprite.play("Jump")
	
	# Здесь в будущем можно добавить проверку, есть ли под нами враг, чтобы вселиться
