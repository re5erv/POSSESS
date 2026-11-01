extends CharacterBody2D

@onready var hit_area = $Area2D

var pos: Vector2
var dir: float
var speed = 500
var max_distance = 250
var start_pos: Vector2
var can_hit = true
var current_dir: float = 0
var wobble_timer: float = 0.0

var enemy_bullet = false # Флаг: true = пуля от бота, false = пуля от игрока

func _ready():
	global_position = pos
	rotation = dir
	start_pos = global_position
	current_dir = dir
	
	hit_area.body_entered.connect(_on_hit_area_body_entered)
	hit_area.area_entered.connect(_on_hit_area_area_entered)
	
	# Сама пуля не должна сталкиваться физически
	collision_layer = 0
	collision_mask = 0

func _physics_process(delta):
	var distance_traveled = global_position.distance_to(start_pos)
	
	# Легкое виляние (wobble) после 150 пикселей
	if distance_traveled < 150:
		current_dir = dir
	else:
		wobble_timer += delta
		if wobble_timer >= 0.05:
			wobble_timer = 0.0
			current_dir += randf_range(-0.05, 0.05)
		
		current_dir = clamp(current_dir, dir - 0.2, dir + 0.2)
	
	rotation = current_dir
	position += Vector2(0, -speed).rotated(rotation) * delta
	
	if distance_traveled > max_distance:
		queue_free()

# --- СТОЛКНОВЕНИЕ С ТЕЛОМ (CharacterBody2D) ---
func _on_hit_area_body_entered(body):
	if not can_hit:
		return
	
	# Если это ЗАРАЖЕННЫЙ (слизень или тот, в кого вселились)
	if body.is_in_group("enemies"):
		# Если стреляет бот (enemy_bullet = true), он бьет зараженного
		if body.has_method("take_damage"):
			body.take_damage(10, enemy_bullet)
		if body.has_method("play_hit_sound"):
			body.play_hit_sound()
		can_hit = false
		queue_free()
		return
		
	# Если это ОБЫЧНЫЙ ЧЕЛОВЕК (бот)
	elif body.is_in_group("human"):
		# Если стреляет игрок (enemy_bullet = false), он бьет обычного человека
		if not enemy_bullet:
			if body.has_method("take_damage"):
				body.take_damage(10)
			if body.has_method("play_hit_sound"):
				body.play_hit_sound()
			can_hit = false
			queue_free()
			return
		else:
			# Если пуля от бота попала в другого бота, она просто пролетает (или исчезает)
			# Если хочешь, чтобы она игнорировала ботов, убери queue_free() отсюда
			can_hit = false
			queue_free()
			return
			
	# Если попали в стену (или другой объект без группы)
	else:
		if body is StaticBody2D or body is TileMap:
			can_hit = false
			queue_free()

# --- СТОЛКНОВЕНИЕ С ЗОНОЙ (Area2D, например, колбы) ---
func _on_hit_area_area_entered(area):
	if not can_hit:
		return
		
	# Если попали в колбу
	if area.is_in_group("flask"):
		if area.has_method("break_flask"):
			area.break_flask()
		can_hit = false
		queue_free()
		return
		
	# Если попали в какую-то другую зону (например, триггер)
	var parent = area.get_parent()
	if parent:
		if parent.is_in_group("enemies") and parent.has_method("take_damage"):
			parent.take_damage(10, enemy_bullet)
			can_hit = false
			queue_free()
		elif parent.is_in_group("human") and not enemy_bullet and parent.has_method("take_damage"):
			parent.take_damage(10)
			can_hit = false
			queue_free()
