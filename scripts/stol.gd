extends StaticBody2D

@onready var detect_area = $DetectArea

func _ready():
	add_to_group("table")
	if detect_area:
		detect_area.body_entered.connect(_on_body_entered)
		detect_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("flask"):
		body.is_on_table = true

func _on_body_exited(body):
	if body.is_in_group("flask"):
		# ПРОВЕРКА: ломаем только если колба реально движется (её толкнули)
		# Если она просто заспавнилась и вышла из зоны, её скорость будет 0.
		if body.linear_velocity.length() > 10.0:
			body.break_flask()
