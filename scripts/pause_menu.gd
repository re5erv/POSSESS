extends CanvasLayer
class_name PauseMenu

## Путь к сцене главного меню
const MAIN_MENU_SCENE: String = "res://scenes/MainMenu.tscn"

@onready var _settings_menu: SettingsMenu = %SettingsMenu
@onready var _continue_button: Button = %ContinueButton
@onready var _settings_button: Button = %SettingsButton
@onready var _main_menu_button: Button = %MainMenuButton
@onready var _exit_button: Button = %ExitButton


func _ready() -> void:
	# Меню должно работать, даже когда дерево на паузе.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_continue_button.pressed.connect(_on_continue_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)
	_exit_button.pressed.connect(_on_exit_pressed)
	_settings_menu.closed.connect(_on_settings_closed)

	_continue_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	# Esc / exit закрывает паузу, если не открыто меню настроек.
	if _settings_menu.visible:
		return
	if _is_pause_event(event):
		get_viewport().set_input_as_handled()
		resume()


func _is_pause_event(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		return true
	return InputMap.has_action("exit") and event.is_action_pressed("exit")


## Продолжить игру
func _on_continue_pressed() -> void:
	resume()


## Открыть меню настроек
func _on_settings_pressed() -> void:
	_settings_menu.open()


## Вернуть фокус на «Продолжить» после закрытия настроек
func _on_settings_closed() -> void:
	_continue_button.grab_focus()


## Выйти в главное меню
func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


## Выйти из игры
func _on_exit_pressed() -> void:
	get_tree().quit()


## Снять паузу и убрать меню
func resume() -> void:
	get_tree().paused = false
	queue_free()
