extends Control
class_name MainMenu

# Путь к сцене игрового процесса
const GAME_SCENE: String = "res://scenes/main.tscn"

# Ссылки на узлы интерфейса
@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var buttons: VBoxContainer = $"Block 2/Buttons"


func _ready() -> void:
	# Возвращаем видимый курсор мыши для управления интерфейсом
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var first_button := buttons.get_child(0) as Button
	if first_button != null:
		first_button.grab_focus()


## Нажатие кнопки «Новая игра»
func _on_new_game_pressed() -> void:
	_start_game()


## Нажатие кнопки «Продолжить»
func _on_continue_pressed() -> void:
	# TODO: Добавить логику загрузки последнего сохранения
	_start_game()


## Запуск игрового процесса
func _start_game() -> void:
	_change_scene(GAME_SCENE)


## Открытие меню настроек
func _on_settings_pressed() -> void:
	if settings_menu != null:
		settings_menu.open()


## Выход из игры
func _on_exit_pressed() -> void:
	get_tree().quit()


## Переход на другую сцену по переданному пути
func _change_scene(path: String) -> void:
	if path.is_empty():
		push_warning("MainMenu: Не указан путь к сцене игры (GAME_SCENE пустой).")
		return
	
	get_tree().change_scene_to_file(path)
