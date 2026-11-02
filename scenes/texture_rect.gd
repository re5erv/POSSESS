extends TextureRect

@export var circle_radius: float = 5.0  # Радиус движения по кругу (в пикселях)
@export var circle_speed: float = 3.0   # Скорость движения по кругу

var _base_position: Vector2 = Vector2.ZERO
var _time: float = 0.0

func _ready() -> void:
	# Запоминаем изначальную позицию, чтобы крутиться вокруг неё
	_base_position = position

func _process(delta: float) -> void:
	_time += delta
	# Крутимся по кругу
	position = _base_position + Vector2(cos(_time * circle_speed), sin(_time * circle_speed)) * circle_radius
