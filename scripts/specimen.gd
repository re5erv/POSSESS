extends CharacterBody2D

@export var move_speed = 150.0
@export var jump_scale_multiplier = 1.3 
@export var jump_duration = 0.6 
@export var jump_distance = 100.0 

@export var base_scale = 1.0 
@export var table_scale_multiplier = 1.3 

@onready var sprite = $AnimatedSprite2D

var original_collision_mask = 0
var is_jumping = false
var is_on_table = false
var jump_timer = 0.0
var jump_target = null 
var jump_direction = Vector2.ZERO

var is_possessed = false
var dead = false

func _ready():
	add_to_group("enemies")
	if sprite: sprite.play("Larp")
	
	original_collision_mask = collision_mask
	scale = Vector2(base_scale, base_scale)

func heal(amount):
	if has_node("Stats"):
		var stats = get_node("Stats")
		stats.health = min(stats.health + amount, stats.max_health)
		print("Слизень вылечен на ", amount)
		
func _process(_delta):
	if dead: return
	
	var mouse_angle = global_position.direction_to(get_global_mouse_position()).angle()
	rotation = mouse_angle + PI/2.0 
	
	if is_jumping:
		jump_timer += _delta
		var progress = jump_timer / jump_duration
		
		var flight_curve = sin(progress * PI)
		var current_scale = base_scale + (base_scale * jump_scale_multiplier - base_scale) * flight_curve
		scale = Vector2(current_scale, current_scale)
		
		velocity = jump_direction * (jump_distance / jump_duration)
		move_and_slide()
		
		if jump_target and is_instance_valid(jump_target):
			if global_position.distance_to(jump_target.global_position) < 30.0:
				possess_target(jump_target)
				return
		
		if progress >= 1.0:
			end_jump()

func _physics_process(_delta):
	if dead or is_jumping: return
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_dir.length() > 0.1:
		velocity = input_dir * move_speed
		move_and_slide() 
		if sprite and sprite.animation != "Walk": sprite.play("Walk")
	else:
		velocity = Vector2.ZERO
		if sprite and sprite.animation != "Larp": sprite.play("Larp")
			
	if InputMap.has_action("jump") and Input.is_action_just_pressed("jump") and not is_jumping:
		start_jump()
		
	if not is_jumping:
		if is_on_table:
			scale = Vector2(base_scale * table_scale_multiplier, base_scale * table_scale_multiplier)
			collision_mask = original_collision_mask 
		else:
			scale = Vector2(base_scale, base_scale)
			collision_mask = original_collision_mask

func start_jump():
	is_jumping = true
	jump_timer = 0.0
	jump_target = null 
	
	var mouse_pos = get_global_mouse_position()
	jump_direction = (mouse_pos - global_position).normalized()
	
	collision_mask = 1 
	
	var humans = get_tree().get_nodes_in_group("human")
	var min_dist = jump_distance + 50.0 
	
	for human in humans:
		if human.dead or human.is_possessed: continue
		var dist = global_position.distance_to(human.global_position)
		if dist < min_dist:
			var dir_to_human = (human.global_position - global_position).normalized()
			if jump_direction.dot(dir_to_human) > 0.7:
				min_dist = dist
				jump_target = human
	
	if sprite: sprite.play("Jump")

func end_jump():
	is_jumping = false
	velocity = Vector2.ZERO
	
	if is_on_table:
		collision_mask = original_collision_mask
		scale = Vector2(base_scale * table_scale_multiplier, base_scale * table_scale_multiplier)
	else:
		collision_mask = original_collision_mask
		scale = Vector2(base_scale, base_scale)
		
	if sprite: sprite.play("Larp")

func possess_target(target):
	target.possess()
	queue_free()

func _on_table_area_entered(_table):
	is_on_table = true
	if not is_jumping:
		scale = Vector2(base_scale * table_scale_multiplier, base_scale * table_scale_multiplier)
		
func _on_table_area_exited(_table):
	is_on_table = false
	if not is_jumping:
		scale = Vector2(base_scale, base_scale)
