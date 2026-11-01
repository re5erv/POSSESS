extends Node2D

@onready var sprite = $Sprite
# Ссылка на папку с людьми (если дверь лежит внутри неё, укажи путь к родителю)
@export var room_manager_path: NodePath 
# Путь к сцене финала (по умолчанию res://scenes/EndMenu.tscn)
@export var end_scene_path: String = "res://scenes/EndMenu.tscn"
# Задержка перед переходом, чтобы анимация двери успела проиграться (в секундах)
@export var transition_delay: float = 1.0

func _ready():
	if room_manager_path:
		var manager = get_node(room_manager_path)
		manager.all_humans_dead.connect(_on_all_humans_dead)
	else:
		# Если дверь лежит прямо в папке с людьми
		var parent = get_parent()
		if parent and parent.has_signal("all_humans_dead"):
			parent.all_humans_dead.connect(_on_all_humans_dead)

func _on_all_humans_dead():
	if sprite.animation != "open":
		sprite.play("open")
		
		# Отключаем коллизию, чтобы можно было пройти
		var col = get_node_or_null("CollisionShape2D")
		if col:
			col.set_deferred("disabled", true)
		
		# Ждем, пока проиграется анимация, и переходим
		await get_tree().create_timer(transition_delay).timeout
		get_tree().change_scene_to_file(end_scene_path)
