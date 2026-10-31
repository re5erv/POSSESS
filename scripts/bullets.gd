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
var enemy_bullet = false  

func _ready():
	global_position = pos
	rotation = dir
	start_pos = global_position
	current_dir = dir
	
	hit_area.body_entered.connect(_on_hit_area_body_entered)
	hit_area.area_entered.connect(_on_hit_area_area_entered)
	
	collision_layer = 0
	collision_mask = 0

func _physics_process(delta):
	var distance_traveled = global_position.distance_to(start_pos)
	
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

func _on_hit_area_body_entered(body):
	if not can_hit:
		return
	
	can_hit = false
	
	if body.is_in_group("player"):
		if body.has_method("play_collision_sound"):
			body.play_collision_sound()
		if body.has_method("take_damage"):
			body.take_damage(10)
		if body.has_method("play_hit_sound"):
			body.play_hit_sound()
	
	elif body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(10, enemy_bullet)
		if body.has_method("play_hit_sound"):
			body.play_hit_sound()
			
	elif body.is_in_group("Psycho"):
		if body.has_method("take_damage"):
			body.take_damage(20, enemy_bullet)
		if body.has_method("play_hit_sound"):
			body.play_hit_sound()
			
	elif body.is_in_group("vincible"):
		if body.has_method("take_damage"):
			body.take_damage(100, enemy_bullet)
		if body.has_method("play_hit_sound"):
			body.play_hit_sound()

	elif body.is_in_group("friendlies"):
		if body.has_method("take_damage"):
			body.take_damage(10, enemy_bullet)
		if body.has_method("play_hit_sound"):
			body.play_hit_sound()
	
	else:
		var players = get_tree().get_nodes_in_group("player")
		for player in players:
			if player.has_method("play_collision_sound"):
				player.play_collision_sound()
	
	queue_free()

func _on_hit_area_area_entered(area):
	if not can_hit:
		return
	
	can_hit = false
	
	var parent = area.get_parent()
	
	if parent and parent.is_in_group("vincible"):
		if not enemy_bullet:
			if parent.has_method("die"):
				parent.die()
		if parent.has_method("take_damage"):
			parent.take_damage(10, enemy_bullet)
		if parent.has_method("play_hit_sound"):
			parent.play_hit_sound()
	
	elif parent and parent.is_in_group("enemies"):
		if parent.has_method("take_damage"):
			parent.take_damage(10)
		if parent.has_method("play_hit_sound"):
			parent.play_hit_sound()
	
	else:
		var players = get_tree().get_nodes_in_group("player")
		for player in players:
			if player.has_method("play_collision_sound"):
				player.play_collision_sound()
	
	queue_free()
