extends RigidBody2D

@onready var sprite = get_node_or_null("AnimatedSprite2D")
@onready var collision = get_node_or_null("CollisionShape2D")

var is_broken = false
var is_on_table = false

func _ready():
	add_to_group("flask")
	if sprite and sprite.sprite_frames.has_animation("Intact"):
		sprite.play("Intact")

func break_flask():
	if is_broken: return
	is_broken = true
	
	# --- ИСПРАВЛЕНИЕ ОШИБКИ ---
	# Используем set_deferred, чтобы Godot не ругался "while flushing queries"
	set_deferred("freeze", true)
	
	# Обнуляем скорость, чтобы она не летела дальше
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
	if sprite and sprite.sprite_frames.has_animation("crash"):
		sprite.play("crash")
		$Crash.play()
		
	scale = Vector2(0.7, 0.7)
	
	# Коллизию тоже лучше удалять через call_deferred
	if collision:
		collision.queue_free()
