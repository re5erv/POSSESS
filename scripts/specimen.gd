extends CharacterBody2D

@export var move_speed = 150.0
@onready var sprite = $AnimatedSprite2D

func _ready():
	if sprite:
		sprite.play("Larp")

func _process(_delta):
	# ПОВОРОТ ЗА МЫШЬЮ (как у человека)
	# Находим угол между слизью и глобальной позицией мыши
	var mouse_angle = global_position.direction_to(get_global_mouse_position()).angle()
	
	# Поворачиваем ВСЁ тело (CharacterBody2D), чтобы коллизия тоже крутилась
	rotation = mouse_angle + PI/2.0 

func _physics_process(_delta):
	# 1. ДВИЖЕНИЕ
	# Input.get_vector двигает по осям X и Y экрана
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_dir.length() > 0.1:
		velocity = input_dir * move_speed
		move_and_slide()
		
		# Включаем ходьбу
		if sprite and sprite.animation != "Walk":
			sprite.play("Walk")
	else:
		velocity = Vector2.ZERO
		
		# Включаем покой
		if sprite and sprite.animation != "Larp":
			sprite.play("Larp")
