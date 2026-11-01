extends CanvasModulate

@export var pulse_speed = 5.0 # Скорость мигания (чем больше, тем быстрее)
@export var max_red = Color(1.0, 0.0, 0.0) # Чистый ярко-красный
@export var flash_color = Color(1.0, 0.2, 0.2) # Цвет вспышки (светло-красный)

var time_passed = 0.0

func _process(delta):
	time_passed += delta
	
	# Пульсация от 0.0 до 1.0
	var pulse = (sin(time_passed * pulse_speed) + 1.0) / 2.0
	
	# Плавно переключаемся между ярко-красным и вспышкой
	color = max_red.lerp(flash_color, pulse)
