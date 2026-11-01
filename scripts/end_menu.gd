extends Control
class_name EndMenu

## Путь к сцене главного меню
const MAIN_MENU_SCENE: String = "res://scenes/MainMenu.tscn"

@onready var _main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	# Экран должен работать, даже если дерево на паузе (если его показывают оверлеем).
	process_mode = Node.PROCESS_MODE_ALWAYS

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_main_menu_button.pressed.connect(_on_main_menu_pressed)
	_main_menu_button.grab_focus()


## Выйти в главное меню
func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)