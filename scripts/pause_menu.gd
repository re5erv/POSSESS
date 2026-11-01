extends CanvasLayer

@onready var play_button = $Control/VBoxContainer/Play
@onready var menu_button = $Control/VBoxContainer/Menu

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	
	play_button.pressed.connect(_on_play_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_play_pressed():
	get_tree().paused = false
	queue_free()

func _on_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
