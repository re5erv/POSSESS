extends Control

@export var line_length: float = 12.0
@export var min_line_length: float = 4.0
@export var line_thickness: float = 2.0
@export var min_gap: float = 4.0
@export var max_gap: float = 12.0
@export var color: Color = Color.WHITE
@export var breathing_speed: float = 4.0

var time_passed: float = 0.0

func _ready() -> void:
	# Работаем даже на паузе
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	mouse_filter = Control.MOUSE_FILTER_IGNORE 
	anchor_right = 1.0
	anchor_bottom = 1.0
	size = get_viewport().get_visible_rect().size
	
	show()

func _process(delta: float) -> void:
	time_passed += delta
	
	# СИСТЕМНУЮ МЫШЬ ПРЯЧЕМ ВСЕГДА
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Прицел всегда следует за мышкой
	global_position = get_viewport().get_mouse_position()
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = Vector2.ZERO
	var wave = (sin(time_passed * breathing_speed) + 1.0) / 2.0 
	
	var current_gap: float = lerpf(min_gap, max_gap, wave)
	var current_length: float = remap(current_gap, min_gap, max_gap, min_line_length, line_length)

	draw_line(center + Vector2(0, -current_gap), center + Vector2(0, -current_gap - current_length), color, line_thickness)
	draw_line(center + Vector2(0, current_gap), center + Vector2(0, current_gap + current_length), color, line_thickness)
	draw_line(center + Vector2(-current_gap, 0), center + Vector2(-current_gap - current_length, 0), color, line_thickness)
	draw_line(center + Vector2(current_gap, 0), center + Vector2(current_gap + current_length, 0), color, line_thickness)
