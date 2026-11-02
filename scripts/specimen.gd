extends CharacterBody2D

@export var move_speed = 150.0
@export var jump_scale_multiplier = 1.3 
@export var jump_duration = 0.6 
@export var jump_distance = 100.0 

@export var base_scale = 1.0 
@export var table_scale_multiplier = 1.3 

@onready var sprite = $AnimatedSprite2D
@onready var stats = get_node_or_null("Stats")

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
	
	if stats:
		stats.max_health = 100
		stats.health = 100
	else:
		print("ОШИБКА: У слизи нет узла Stats!")

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
	
	if InputMap.has_action("exit") and Input.is_action_just_pressed("exit"):
		pause_menu()
		return
	
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

# ==========================================
# УРОН И СМЕРТЬ
# ==========================================
func take_damage(dmg, _from_enemy = false):
	if dead: return
	if stats:
		stats.health -= dmg
		print("Слизень получил урон! ХП: ", stats.health)
		if stats.health <= 0:
			die()
	else:
		print("Слизень не может получить урон: нет Stats!")

func die():
	if dead: return
	dead = true
	
	set_physics_process(false)
	velocity = Vector2.ZERO
	
	if sprite:
		sprite.play("Dead")
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
	
	get_tree().paused = true
	
	var canvas = CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(canvas)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas.add_child(bg)
	
	var label = Label.new()
	label.text = "ЗАРАЖЕНИЕ УНИЧТОЖЕНО"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_color_override("font_color", Color.RED)
	label.add_theme_font_size_override("font_size", 64)
	
	var font = load("res://determination.otf")
	if font: label.add_theme_font_override("font", font)
		
	label.modulate.a = 0.0
	label.scale = Vector2(0.8, 0.8)
	label.pivot_offset = get_viewport_rect().size / 2
	label.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas.add_child(label)
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 2.0)
	tween.tween_property(label, "scale", Vector2(1.1, 1.1), 2.0)
	
	await get_tree().create_timer(3.0, true, false, true).timeout
	
	canvas.queue_free() 
	get_tree().paused = false
	get_tree().reload_current_scene()

func pause_menu():
	get_tree().paused = true
	var pause_scene = preload("res://ui/PauseMenu.tscn")
	var pause_ui = pause_scene.instantiate()
	get_tree().root.add_child(pause_ui)
	if pause_ui is CanvasLayer or pause_ui is Control: pause_ui.visible = true
	pause_ui.process_mode = Node.PROCESS_MODE_ALWAYS
