extends CharacterBody2D

# --- Общие настройки ---
@export var move_speed = 120
@export var strafe_speed = 100
@export var is_possessed: bool = false # ВСЕЛИЛСЯ ЛИ ИГРОК В НЕГО?

# --- Переменные ИИ (Бывший NPC) ---
@export var attack_range = 250
@export var view_range = 600
@export var reaction_delay = 0.3
var ai_player = null
var ai_ammo = 32
var ai_max_ammo = 32
var ai_is_reloading = false
var ai_reaction_timer = 0.0
var is_shooting = false

# --- Ссылки на узлы ---
@onready var stats = $Stats
@onready var Torso_sprite = $Torso
@onready var Legs_sprite = $Torso/Legs
@onready var camera = get_node_or_null("Camera2D")
@onready var holster = $Holster
@onready var shoot_pos = $ShootPos
@onready var ray_cast = $RayCast2D

@onready var liner_scene = preload("res://objects/Liner.tscn")
var bullet_path = preload("res://objects/Bullet.tscn")

# --- Переменные игрока (Из playerRC) ---
var time_played = 0.0
var innocent: bool = true
var satisfied: bool = true
var military: bool = false
var zoom_level = 5
var min_zoom = 3
var max_zoom = 8
var zoom_step = 0.5
var dead = false
var shoot_timer = 0.0
var fire_rate = 0.08
var is_reloading = false
var can_axe_attack = true
var current_datagun = null  
var is_empty_sound_playing = false
var is_holster_animating = false
var carried_item: String = ""
var is_carrying_item: bool = false
var item_speed_multiplier: float = 1.0
var hunger_timer = 0.0
var hunger_interval = 10.0

func _ready():
	# Добавляем в правильные группы в зависимости от того, кто это
	if is_possessed:
		add_to_group("player")
	else:
		add_to_group("enemies")
		
	Torso_sprite.play("LarpUzi")
	Legs_sprite.play("Larp")
	
	ray_cast.enabled = true
	ray_cast.collide_with_areas = true
	ray_cast.collide_with_bodies = true
	
	stats.max_health = 100
	stats.health = 100
	stats.current_weapon = ""
	stats.hunger = 100
	
	if is_possessed:
		camera = get_viewport().get_camera_2d()
		if camera:
			camera.zoom = Vector2(zoom_level, zoom_level)

# --- ФУНКЦИЯ ВСЕЛЕНИЯ ---
func possess():
	if is_possessed or dead: return
		
	is_possessed = true
	remove_from_group("enemies")
	add_to_group("player")
	
	var cam = get_tree().get_first_node_in_group("main_camera")
	if cam:
		cam.reparent(self)
		cam.position = Vector2.ZERO
		if cam.has_method("snap_to_parent"):
			cam.snap_to_parent()
		cam.zoom = Vector2(cam.zoom_level, cam.zoom_level) 
	
	print("Вселились в ", name)

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
# ЛОГИКА ИГРОКА (Почти полная копия playerRC)
# ==========================================
func player_logic(_delta):
	var move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var forward = Vector2.UP.rotated(rotation)
	var final_dir = forward * -move_input.y + forward.rotated(PI/2.0) * move_input.x
	
	var is_strafing = abs(move_input.x) > 0.1 and abs(move_input.y) < 0.1
	var current_speed = move_speed
	if is_carrying_item:
		current_speed = move_speed * item_speed_multiplier
	
	var current_speed_final = strafe_speed if is_strafing else current_speed
	velocity = final_dir * current_speed_final
	move_and_slide()
	
	update_animations(move_input)
	
	if InputMap.has_action("holster") and Input.is_action_just_pressed("holster"):
		toggle_holster()
	if InputMap.has_action("exit") and Input.is_action_just_pressed("exit"):
		pause_menu()
	if InputMap.has_action("interact") and Input.is_action_just_pressed("interact"):
		interact()
		
	if InputMap.has_action("reload") and Input.is_action_just_pressed("reload") and stats.current_weapon != "" and not is_reloading and current_datagun and current_datagun.ammo_in_mag < current_datagun.in_mag_max and stats.ammo_in_pocket > 0:
		reload()
		
	if InputMap.has_action("shoot") and Input.is_action_pressed("shoot") and stats.current_weapon != "" and not is_reloading and not is_carrying_item:
		if stats.current_weapon == "Axe":
			axe_attack()
		else:
			if current_datagun and current_datagun.ammo_in_mag > 0:
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
					
	if satisfied:
		hunger_timer += _delta
		if hunger_timer >= hunger_interval:
			hunger_timer = 0.0
			stats.hunger -= 1
			if stats.hunger <= 0:
				stats.hunger = 0
				die()

# ==========================================
# ЛОГИКА ИИ (Из NPC)
# ==========================================
func enemy_ai_logic(delta):
	if not ai_player:
		ai_player = get_tree().get_first_node_in_group("player")
	
	if not ai_player: return
	
	var player_distance = global_position.distance_to(ai_player.global_position)
	var can_see_player = false
	
	if player_distance < view_range:
		ray_cast.target_position = to_local(ai_player.global_position)
		ray_cast.force_raycast_update()
		if ray_cast.is_colliding():
			if ray_cast.get_collider().is_in_group("player"):
				can_see_player = true
		else:
			can_see_player = true
	
	if can_see_player:
		rotation = global_position.direction_to(ai_player.global_position).angle() + PI/2.0
		
		if ai_is_reloading:
			velocity = Vector2.ZERO
			move_and_slide()
			return
			
		if player_distance < attack_range:
			ai_reaction_timer += delta
			if ai_reaction_timer >= reaction_delay:
				if not is_shooting:
					is_shooting = true
					Torso_sprite.play("ShootUzi")
				
				shoot_timer += delta
				if shoot_timer >= fire_rate and ai_ammo > 0:
					shoot_timer = 0.0
					enemy_shoot()
				elif ai_ammo <= 0:
					enemy_reload()
		else:
			velocity = global_position.direction_to(ai_player.global_position) * move_speed
			move_and_slide()
			Legs_sprite.play("Walk")
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		if not is_shooting:
			Torso_sprite.play("LarpUzi")
			Legs_sprite.play("Larp")

# ==========================================
# ФУНКЦИИ СТРЕЛЬБЫ И ПЕРЕЗАРЯДКИ (Игрок)
# ==========================================
func shoot_nigg():
	if current_datagun: current_datagun.ammo_in_mag -= 1
	else:
		Torso_sprite.play("EmptyUzi")
		return
	
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
	
	await get_tree().create_timer(0.1).timeout
	if not Input.is_action_pressed("shoot"):
		Torso_sprite.play("Uzi")

func reload():
	if is_reloading or is_carrying_item: return
	if stats.ammo_in_pocket <= 0: return
	if not current_datagun: return
	if current_datagun.ammo_in_mag >= current_datagun.in_mag_max: return
	
	is_reloading = true
	Torso_sprite.play("ReloadUzi")
	await Torso_sprite.animation_finished
	
	var needed = current_datagun.in_mag_max - current_datagun.ammo_in_mag
	var taken = min(needed, stats.ammo_in_pocket)
	current_datagun.ammo_in_mag += taken
	stats.ammo_in_pocket -= taken
	
	is_reloading = false
	Torso_sprite.play("LarpUzi" if stats.current_weapon != "" else "Larp")

func axe_attack():
	if not can_axe_attack or is_carrying_item: return
	can_axe_attack = false
	Torso_sprite.play("ShootAxe")
	
	var hit_something = false
	var trees = get_tree().get_nodes_in_group("trees")
	for tree in trees:
		if global_position.distance_to(tree.global_position) < 25:
			tree.take_damage(1)
			hit_something = true
	
	await get_tree().create_timer(0.5).timeout
	Torso_sprite.play("LarpAxe")
	await get_tree().create_timer(0.5).timeout
	can_axe_attack = true

# ==========================================
# ФУНКЦИИ СТРЕЛЬБЫ (ИИ)
# ==========================================
func enemy_shoot():
	ai_ammo -= 1
	var bullet = bullet_path.instantiate()
	bullet.dir = rotation
	bullet.pos = shoot_pos.global_position
	bullet.enemy_bullet = true 
	get_parent().add_child(bullet)

func enemy_reload():
	ai_is_reloading = true
	Torso_sprite.play("ReloadUzi")
	await Torso_sprite.animation_finished
	ai_ammo = ai_max_ammo
	ai_is_reloading = false
	Torso_sprite.play("LarpUzi")

# ==========================================
# СМЕРТЬ И УРОН
# ==========================================
func take_damage(dmg, from_enemy = false):
	if dead: return
	stats.health -= dmg
	update_hp_color()
	if stats.health <= 0: die(from_enemy)

func die(from_enemy = false):
	if dead: return
	dead = true
	Torso_sprite.play("Dead")
	Legs_sprite.play("Larp")
	Torso_sprite.modulate = Color(1, 1, 1)
	Legs_sprite.modulate = Color(1, 1, 1)
	velocity = Vector2.ZERO
	
	var collision = get_node_or_null("CollisionShape2D")
	if collision: collision.queue_free()
	
	if not is_possessed and not from_enemy:
		var players = get_tree().get_nodes_in_group("player")
		for p in players:
			p.stats.total_kills += 1
			if p.military:
				p.stats.moneys += 30
				p.stats.total_moneys += 30

func update_hp_color():
	var health_percent = float(stats.health) / float(stats.max_health)
	var red_intensity = 0.1 + (1.0 - health_percent) * 0.5
	Torso_sprite.modulate = Color(1.0, 1.0 - red_intensity * 0.5, 1.0 - red_intensity * 0.5)
	Legs_sprite.modulate = Color(1.0, 1.0 - red_intensity * 0.5, 1.0 - red_intensity * 0.5)

# ==========================================
# ИНТЕРАКТ И ПРЕДМЕТЫ (Из playerRC)
# ==========================================
func interact():
	if dead: return
	var nearby_item = get_nearest_item()
	if nearby_item:
		pickup_item(nearby_item)
		return
	var nearby_weapon = get_nearest_weapon()
	if nearby_weapon:
		pickup_weapon(nearby_weapon)
	else:
		if stats.current_weapon != "": drop_weapon()
		elif is_carrying_item: drop_item()

func get_nearest_weapon():
	var nearest = null
	var nearest_dist = 30.0
	for w in get_tree().get_nodes_in_group("weapon_pickup"):
		var dist = global_position.distance_to(w.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = w
	return nearest

func get_nearest_item():
	var nearest = null
	var nearest_dist = 30.0
	for item in get_tree().get_nodes_in_group("item_pickup"):
		var dist = global_position.distance_to(item.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = item
	return nearest

func pickup_item(item):
	if dead or stats.current_weapon != "": return
	if is_carrying_item: drop_item()
	carried_item = item.item_name
	is_carrying_item = true
	item_speed_multiplier = item.speed_multiplier
	item.queue_free()

func drop_item():
	if not is_carrying_item: return
	var drop_pos = global_position + Vector2(20, 0).rotated(rotation)
	var pickup = load("res://scenes/objects/TimberPick.tscn").instantiate()
	pickup.global_position = drop_pos
	pickup.rotation = rotation
	get_parent().add_child(pickup)
	carried_item = ""
	is_carrying_item = false
	item_speed_multiplier = 1.0

func pickup_weapon(pickup):
	if dead or is_carrying_item: return
	if stats.current_weapon != "": drop_weapon()
	
	var pickup_datagun = pickup.get_node_or_null("DataGunNode")
	if pickup_datagun:
		pickup.remove_child(pickup_datagun)
		add_child(pickup_datagun)
		current_datagun = pickup_datagun
		stats.current_weapon = pickup_datagun.gun_name
		current_datagun.edited = true
	else:
		stats.current_weapon = pickup.weapon_name
		current_datagun = null
	is_reloading = false
	can_axe_attack = true
	pickup.queue_free()

func drop_weapon():
	if stats.current_weapon == "": return
	if is_reloading: is_reloading = false
	
	Torso_sprite.play("Larp")
	var drop_pos = global_position + Vector2(20, 0)
	var pickup_path = "res://objects/" + stats.current_weapon + "Pick.tscn"
	var pickup = load(pickup_path).instantiate()
	pickup.global_position = drop_pos
	
	var pickup_datagun = pickup.get_node_or_null("DataGunNode")
	if pickup_datagun and current_datagun:
		pickup_datagun.gun_name = current_datagun.gun_name
		pickup_datagun.ammo_in_mag = current_datagun.ammo_in_mag
		pickup_datagun.in_mag_max = current_datagun.in_mag_max
		pickup_datagun.edited = true
		current_datagun.queue_free()
		current_datagun = null
	
	get_parent().add_child(pickup)
	stats.current_weapon = ""
	can_axe_attack = true

# ==========================================
# КОБУРА, АНИМАЦИИ И ПАУЗА
# ==========================================
func toggle_holster():
	if is_holster_animating or is_carrying_item: return
	is_holster_animating = true
	
	if stats.current_weapon != "" and holster.holsted_weapon == "":
		var weapon_name = stats.current_weapon
		if weapon_name == "Uzi":
			Torso_sprite.play("HolstUzi")
			await Torso_sprite.animation_finished
		elif weapon_name == "Axe":
			Torso_sprite.play("HolstAxe")
			await Torso_sprite.animation_finished
		
		if current_datagun:
			remove_child(current_datagun)
			holster.add_child(current_datagun)
		holster.set_holsted(weapon_name)
		stats.current_weapon = ""
		current_datagun = null
		Torso_sprite.play("Larp")
		is_holster_animating = false
		return
	
	if stats.current_weapon == "" and holster.holsted_weapon != "":
		var weapon_name = holster.holsted_weapon
		stats.current_weapon = weapon_name
		holster.set_holsted("")
		
		if weapon_name == "Uzi":
			Torso_sprite.play("UnHolstUzi")
			await Torso_sprite.animation_finished
		elif weapon_name == "Axe":
			Torso_sprite.play("UnHolstAxe")
			await Torso_sprite.animation_finished
		
		var holster_datagun = holster.get_node_or_null("DataGunNode")
		if holster_datagun:
			holster.remove_child(holster_datagun)
			add_child(holster_datagun)
			current_datagun = holster_datagun
		is_holster_animating = false
		return
		
	is_holster_animating = false

func update_animations(move_input):
	if dead: return
	var is_moving = move_input.length() > 0.1
	var is_left = move_input.x < -0.1
	var is_right = move_input.x > 0.1
	var is_forward = move_input.y < -0.1
	var is_backward = move_input.y > 0.1
	
	var torso_anim = "Larp"
	var legs_anim = "Larp"
	
	if is_moving:
		if is_carrying_item: torso_anim = "TimberUn"
		elif stats.current_weapon != "":
			if stats.current_weapon == "Axe": torso_anim = "Axe"
			else:
				if is_left or is_right: torso_anim = "LarpUzi"
				else: torso_anim = "Uzi"
		else:
			if is_left or is_right: torso_anim = "Larp"
			else: torso_anim = "Walk"
		
		if is_forward or is_backward: legs_anim = "Walk"
		elif is_left: legs_anim = "CrabLeft"
		elif is_right: legs_anim = "CrabRight"
		else: legs_anim = "Walk"
	else:
		if is_carrying_item: torso_anim = "TimberUn"
		elif stats.current_weapon == "Axe": torso_anim = "LarpAxe"
		else: torso_anim = "LarpUzi" if stats.current_weapon != "" else "Larp"
		legs_anim = "Larp"
	
	var protected_anims = ["ShootUzi", "ReloadUzi", "ShootAxe", "EmptyUzi", "HolstUzi", "UnHolstUzi", "HolstAxe", "UnHolstAxe", "Dead"]
	if Torso_sprite.animation != torso_anim and not Torso_sprite.animation in protected_anims:
		Torso_sprite.play(torso_anim)
	if Legs_sprite.animation != legs_anim and Torso_sprite.animation != "Dead":
		Legs_sprite.play(legs_anim)

func pause_menu():
	get_tree().paused = true
	var pause_ui = preload("res://ui/PauseMenu.tscn").instantiate()
	add_child(pause_ui)
