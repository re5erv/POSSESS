extends Control

@export var circle_radius: float = 3.0    # Радиус кручения (в пикселях)
@export var circle_speed: float = 3.0     # Скорость кручения
@export var down_offset: float = 250.0    # Смещение вниз (на 250 пикселей)

var _base_position: Vector2 = Vector2.ZERO
var _time: float = 0.0

func _ready() -> void:
	# Запоминаем изначальную позицию
	_base_position = position

func _process(delta: float) -> void:
	_time += delta
	# Сдвигаем вниз на down_offset и крутим по кругу вокруг этой точки
	var target_pos = _base_position + Vector2(0, down_offset) + Vector2(cos(_time * circle_speed), sin(_time * circle_speed)) * circle_radius
	position = target_pos
