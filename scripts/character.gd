extends CharacterBody2D

@export var move_speed = 120
@export var is_possessed: bool = false

# --- Переменные ИИ ---
@export var attack_range = 250
@export var view_range = 600
@export var reaction_delay = 0.3
var ai_target = null
var ai_is_reloading = false
var ai_reaction_timer = 0.0
var is_shooting = false
var current_target = null

# --- Ссылки на узлы ---
@onready var stats = $Stats
@onready var Torso_sprite = $Torso
@onready var Legs_sprite = $Torso/Legs
@onready var camera = get_node_or_null("Camera2D")
@onready var shoot_pos = $ShootPos
@onready var ray_cast = $RayCast2D
@onready var data_gun = get_node_or_null("DataGun")
@onready var scream_sound = get_node_or_null("ScreamSound")
@onready var possess_sound = get_node_or_null("PossessSound")

@onready var liner_scene = preload("res://objects/Liner.tscn")
@onready var specimen_scene = preload("res://objects/specimen.tscn")
var bullet_path = preload("res://objects/Bullet.tscn")

var time_played = 0.0
var dead = false
var shoot_timer = 0.0
var fire_rate = 0.08
var is_reloading = false
var is_empty_sound_playing = false
var hunger_timer = 0.0
var hunger_interval = 10.0

var current_weapon_type: String = "Uzi"
var current_ammo_in_mag: int = 32
var max_ammo_in_mag: int = 32

var is_pistol: bool = false

func _ready():
	if is_possessed:
		add_to_group("enemies")
	else:
		add_to_group("human")
		
	Torso_sprite.play("LarpUzi")
	Legs_sprite.play("Larp")
	
	ray_cast.enabled = true
	ray_cast.collide_with_areas = true
	ray_cast.collide_with_bodies = true
	
	stats.max_health = 100
	stats.health = 100
	stats.hunger = 100
	
	if data_gun:
		current_weapon_type = data_gun.gun_name
		max_ammo_in_mag = data_gun.in_mag_max
		current_ammo_in_mag = max_ammo_in_mag
		
		if current_weapon_type == "Pistol":
			fire_rate = 0.5 
			is_pistol = true
		else:
			fire_rate = 0.08 

func possess():
	if is_possessed or dead: return
	is_possessed = true
	
	remove_from_group("human")
	add_to_group("enemies")
	
	if scream_sound: scream_sound.play()
	if possess_sound: possess_sound.play()
	
	Torso_sprite.stop()
	Torso_sprite.play("LarpUzi") 
	
	var cam = get_tree().get_first_node_in_group("main_camera")
	if cam:
		cam.reparent(self)
		cam.position = Vector2.ZERO
		if cam.has_method("snap_to_parent"):
			cam.snap_to_parent()
	print("Вселились в ", name)

# --- ФУНКЦИЯ СПРЫГИВАНИЯ ---
# --- ФУНКЦИЯ СПРЫГИВАНИЯ ---
func unpossess():
	if dead: return
	
	# 1. Спавним слизня на месте курсора
	var new_slime = specimen_scene.instantiate()
	var mouse_world_pos = get_global_mouse_position()
	new_slime.global_position = mouse_world_pos
	get_parent().add_child(new_slime)
	
	# 2. Перекидываем камеру на слизня
	var cam = get_tree().get_first_node_in_group("main_camera")
	if cam:
		cam.reparent(new_slime)
		cam.position = Vector2.ZERO
		if cam.has_method("snap_to_parent"):
			cam.snap_to_parent()
	
	# 3. УБИВАЕМ ЧЕЛОВЕКА (обычная смерть)
	die() 
	print("Спрыгнули с ", name)



func _process(_delta):
	if dead: return
	time_played += _delta
	
	if is_possessed:
		var mouse_angle = global_position.direction_to(get_global_mouse_position()).angle()
		rotation = mouse_angle + PI/2.0

func _physics_process(_delta):
	if dead: return
	
	if is_possessed:
		player_logic(_delta)
	else:
		enemy_ai_logic(_delta)

# ==========================================
# ЛОГИКА ИГРОКА
# ==========================================
func player_logic(_delta):
	# --- СПРЫГНУТЬ (Пробел или ПКМ) ---
	if InputMap.has_action("jump") and Input.is_action_just_pressed("jump"):
		unpossess()
		return # Выходим, чтобы не двигаться дальше
		
	var move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var forward = Vector2.UP.rotated(rotation)
	var final_dir = forward * -move_input.y + forward.rotated(PI/2.0) * move_input.x
	
	velocity = final_dir * move_speed
	move_and_slide()
	
	update_animations(move_input)
	
	if InputMap.has_action("exit") and Input.is_action_just_pressed("exit"):
		pause_menu()
		
	if InputMap.has_action("reload") and Input.is_action_just_pressed("reload") and not is_reloading and current_ammo_in_mag < max_ammo_in_mag:
		reload()
		
	if InputMap.has_action("shoot") and not is_reloading:
		if is_pistol:
			if Input.is_action_just_pressed("shoot"):
				if current_ammo_in_mag > 0:
					shoot_nigg()
				else:
					if not is_empty_sound_playing:
						is_empty_sound_playing = true
						Torso_sprite.play("EmptyUzi")
						await get_tree().create_timer(0.3).timeout
						is_empty_sound_playing = false
						reload()
		else:
			if Input.is_action_pressed("shoot"):
				if current_ammo_in_mag > 0:
					shoot_timer += _delta
					if shoot_timer >= fire_rate:
						shoot_timer = 0.0
						shoot_nigg()
				else:
					if not is_empty_sound_playing:
						is_empty_sound_playing = true
						Torso_sprite.play("EmptyUzi")
						await get_tree().create_timer(0.3).timeout
						is_empty_sound_playing = false
						reload()
				
	if stats.hunger > 0:
		hunger_timer += _delta
		if hunger_timer >= hunger_interval:
			hunger_timer = 0.0
			stats.hunger -= 1
			if stats.hunger <= 0:
				stats.hunger = 0
				die()

# ==========================================
# СТРЕЛЬБА
# ==========================================
func shoot_nigg():
	if current_ammo_in_mag <= 0: return
	current_ammo_in_mag -= 1
	
	var liner = liner_scene.instantiate()
	var spawn_offset = Vector2(randf_range(8, 16), randf_range(-10, -20)).rotated(rotation)
	liner.global_position = global_position + spawn_offset
	liner.rotation = randf_range(-PI, PI)
	get_parent().add_child(liner)
	
	var bullet = bullet_path.instantiate()
	bullet.dir = rotation
	bullet.pos = shoot_pos.global_position
	get_parent().add_child(bullet)
	
	Torso_sprite.play("ShootUzi")
	$Shoot.play()
	
	if is_pistol:
		await get_tree().create_timer(0.15).timeout
		Torso_sprite.play("LarpUzi")
	else:
		await get_tree().create_timer(0.1).timeout
		if not Input.is_action_pressed("shoot"):
			Torso_sprite.play("LarpUzi")

func reload():
	if is_reloading: return
	is_reloading = true
	Torso_sprite.play("ReloadUzi")
	await Torso_sprite.animation_finished
	current_ammo_in_mag = max_ammo_in_mag
	is_reloading = false
	Torso_sprite.play("LarpUzi")

# ==========================================
# УМНЫЙ ИИ
# ==========================================
func enemy_ai_logic(delta):
	var enemies = get_tree().get_nodes_in_group("enemies")
	var visible_target = null
	var visible_target_dist = attack_range
	
	for enemy in enemies:
		if enemy == self: continue
		if "dead" in enemy and enemy.dead: continue
			
		var dist = global_position.distance_to(enemy.global_position)
		var enemy_visible = false
		
		if dist < view_range:
			ray_cast.target_position = to_local(enemy.global_position)
			ray_cast.force_raycast_update()
			if ray_cast.is_colliding():
				var collider = ray_cast.get_collider()
				if collider == enemy or collider.is_in_group("enemies"):
					enemy_visible = true
			else:
				enemy_visible = true
		
		if enemy_visible and dist < visible_target_dist:
			visible_target_dist = dist
			visible_target = enemy
	
	if not visible_target:
		current_target = null
		if Torso_sprite.animation != "ShootUzi" and Torso_sprite.animation != "ReloadUzi":
			Torso_sprite.play("LarpUzi")
		Legs_sprite.play("Larp")
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if visible_target != current_target:
		current_target = visible_target
	
	var target_dir = global_position.direction_to(visible_target.global_position)
	rotation = target_dir.angle() + PI/2.0
	
	if ai_is_reloading:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if visible_target_dist < attack_range:
		ai_reaction_timer += delta
		if ai_reaction_timer >= reaction_delay:
			shoot_timer += delta
			
			if shoot_timer >= fire_rate:
				shoot_timer = 0.0
				enemy_shoot()
			elif current_ammo_in_mag <= 0:
				enemy_reload()
			else:
				if not is_shooting:
					Torso_sprite.play("LarpUzi")
	else:
		ai_reaction_timer = 0.0
		if Torso_sprite.animation != "ShootUzi":
			Torso_sprite.play("LarpUzi")
		velocity = Vector2.ZERO
		move_and_slide()

func enemy_shoot():
	if current_ammo_in_mag <= 0: return
	current_ammo_in_mag -= 1
	
	Torso_sprite.play("ShootUzi")
	$Shoot.play()
	is_shooting = true
	
	var liner = liner_scene.instantiate()
	var spawn_offset = Vector2(randf_range(8, 16), randf_range(-10, -20)).rotated(rotation)
	liner.global_position = global_position + spawn_offset
	liner.rotation = randf_range(-PI, PI)
	get_parent().add_child(liner)
	
	var bullet = bullet_path.instantiate()
	bullet.visible = true
	bullet.pos = shoot_pos.global_position
	bullet.dir = rotation
	bullet.enemy_bullet = true  
	get_parent().add_child(bullet)
	
	await get_tree().create_timer(0.1).timeout
	if not is_reloading:
		Torso_sprite.play("LarpUzi")
	is_shooting = false

func enemy_reload():
	if ai_is_reloading: return
	ai_is_reloading = true
	if is_shooting:
		is_shooting = false
		Torso_sprite.play("LarpUzi")
	Torso_sprite.play("ReloadUzi")
	await Torso_sprite.animation_finished
	current_ammo_in_mag = max_ammo_in_mag
	ai_is_reloading = false
	Torso_sprite.play("LarpUzi")

# ==========================================
# СМЕРТЬ И АНИМАЦИИ
# ==========================================
func take_damage(dmg, from_enemy = false):
	if dead: return
	stats.health -= dmg
	update_hp_color()
	if stats.health <= 0: die(from_enemy)

# ==========================================
# СМЕРТЬ
# ==========================================
func die(from_enemy = false):
	if dead: return
	dead = true
	
	# ВСЕГДА анимация Dead
	Torso_sprite.play("Dead")
	Legs_sprite.play("Larp")
	Torso_sprite.modulate = Color(1, 1, 1)
	Legs_sprite.modulate = Color(1, 1, 1)
	velocity = Vector2.ZERO
	
	# ПОНИЖАЕМ Z-ИНДЕКС (чтобы труп был под ногами)
	z_index = 1
	
	# Отключаем коллизию, чтобы труп не мешал
	var collision = get_node_or_null("CollisionShape2D")
	if collision: collision.queue_free()
	
	# Если убили не враги (игрок), начисляем киллы
	if not is_possessed and not from_enemy:
		var humans = get_tree().get_nodes_in_group("enemies")
		for p in humans:
			if p.has_method("on_enemy_killed"):
				p.on_enemy_killed()

func update_hp_color():
	var health_percent = float(stats.health) / float(stats.max_health)
	var red_intensity = 0.1 + (1.0 - health_percent) * 0.5
	Torso_sprite.modulate = Color(1.0, 1.0 - red_intensity * 0.5, 1.0 - red_intensity * 0.5)
	Legs_sprite.modulate = Color(1.0, 1.0 - red_intensity * 0.5, 1.0 - red_intensity * 0.5)

func update_animations(move_input):
	if dead: return
	
	if is_shooting or Torso_sprite.animation == "ReloadUzi":
		return
		
	var is_moving = move_input.length() > 0.1
	var is_left = move_input.x < -0.1
	var is_right = move_input.x > 0.1
	var is_forward = move_input.y < -0.1
	var is_backward = move_input.y > 0.1
	
	var torso_anim = "LarpUzi"
	var legs_anim = "Larp"
	
	if is_moving:
		if is_left or is_right: torso_anim = "LarpUzi"
		else: torso_anim = "Uzi"
		
		if is_forward or is_backward: legs_anim = "Walk"
		elif is_left: legs_anim = "CrabLeft"
		elif is_right: legs_anim = "CrabRight"
		else: legs_anim = "Walk"
	else:
		torso_anim = "LarpUzi"
		legs_anim = "Larp"
	
	var protected_anims = ["ShootUzi", "ReloadUzi", "EmptyUzi", "Dead", "PossessDead"]
	if Torso_sprite.animation != torso_anim and not Torso_sprite.animation in protected_anims:
		Torso_sprite.play(torso_anim)
	if Legs_sprite.animation != legs_anim and Torso_sprite.animation != "Dead" and Torso_sprite.animation != "PossessDead":
		Legs_sprite.play(legs_anim)

func pause_menu():
	get_tree().paused = true
	var pause_ui = preload("res://ui/PauseMenu.tscn").instantiate()
	add_child(pause_ui)
