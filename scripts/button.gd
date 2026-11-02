extends Button

@export var hover_scale_x: float = 1.1 # Насколько растянуть вправо
@export var tween_speed: float = 0.1 

var _tween: Tween

func _ready() -> void:
	# Ставим точку вращения (pivot) в левый край кнопки
	pivot_offset = Vector2(0, size.y / 2)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Растягиваем кнопку по X (визуально выезжает вправо)
	_tween.tween_property(self, "scale", Vector2(hover_scale_x, 1.0), tween_speed)

func _on_mouse_exited() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Возвращаем обратно
	_tween.tween_property(self, "scale", Vector2(1.0, 1.0), tween_speed)
