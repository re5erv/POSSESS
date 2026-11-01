extends RigidBody2D

@onready var sprite = get_node_or_null("AnimatedSprite2D")
@onready var collision = get_node_or_null("CollisionShape2D")

var is_broken = false
var is_on_table = false

func _ready():
	add_to_group("flask")
	if sprite and sprite.sprite_frames.has_animation("default"):
		sprite.play("default")
	
	# Ждем 0.5 секунды, чтобы физика 100% прогрузилась
	await get_tree().create_timer(0.5).timeout
	
	# Теперь проверяем, есть ли под нами стол
	check_table()

func _physics_process(_delta):
	if is_broken: return
	
	# Если мы уже стоим на столе, проверяем, не упали ли мы
	if is_on_table:
		var still_on_table = false
		for table in get_tree().get_nodes_in_group("table"):
			var area = table.get_node_or_null("DetectArea")
			if area and area.overlaps_body(self):
				still_on_table = true
				break
		
		if not still_on_table:
			break_flask()

func check_table():
	var found_table = false
	for table in get_tree().get_nodes_in_group("table"):
		var area = table.get_node_or_null("DetectArea")
		if area and area.overlaps_body(self):
			found_table = true
			break
			
	if found_table:
		is_on_table = true
	else:
		# Если мы не на столе (на полу), ломаемся
		break_flask()

func break_flask():
	if is_broken: return
	is_broken = true
	
	set_deferred("freeze", true)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
	if sprite and sprite.sprite_frames.has_animation("crash"):
		sprite.play("crash")
		$Crash.play()
		
	scale = Vector2(0.7, 0.7)
	
	if collision:
		collision.queue_free()
