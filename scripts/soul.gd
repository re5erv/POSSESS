extends Camera2D

@export var follow_speed = 10.0 # Плавность (10 - мягко, 100 - жестко)
@export var offset_y = 0.0 # Смещение вниз (если камера смотрит слишком высоко, поставь тут 20 или 30)

# Настройки зума
var zoom_level = 5.0
var min_zoom = 3.0
var max_zoom = 8.0
var zoom_step = 0.5

func _ready():
	add_to_group("main_camera")
	zoom = Vector2(zoom_level, zoom_level)
	# На старте камера центрируется на том, к кому привязана
	snap_to_parent()

func _process(delta):
	var parent = get_parent()
	
	if parent and parent.is_in_group("player"):
		# Плавно летим к позиции родителя + смещение
		var target_pos = parent.global_position + Vector2(0, offset_y)
		global_position = global_position.lerp(target_pos, follow_speed * delta)

# Функция для мгновенного центрирования (вызываем при вселении)
func snap_to_parent():
	var parent = get_parent()
	if parent:
		global_position = parent.global_position + Vector2(0, offset_y)

# Обработка колесика мыши
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_level = clamp(zoom_level + zoom_step, min_zoom, max_zoom)
			zoom = Vector2(zoom_level, zoom_level)
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_level = clamp(zoom_level - zoom_step, min_zoom, max_zoom)
			zoom = Vector2(zoom_level, zoom_level)
