extends Control
class_name MainMenu

# Пути к сценам
const GAME_SCENE: String = "res://scenes/level.tscn"
const END_SCENE: String = "res://scenes/EndMenu.tscn"
const GUIDE_SCENE: String = "res://scenes/GuideMenu.tscn" # Если есть гайд

# Настройки параллакса за курсором мыши
@export var buttons_parallax_strength: float = 25.0 
@export var logo_parallax_strength: float = 12.0    
@export var follow_speed: float = 5.0              

# Ссылки на узлы интерфейса
@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var buttons: Control = $"Block 2/Buttons"
@onready var moving_buttons: Control = $"Block 2"
@onready var moving_logo: Control = $"Block 1"

var _initial_buttons_pos: Vector2 = Vector2.ZERO
var _initial_logo_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Очистка корня от меню паузы и настроек, чтобы они не висели
	for child in get_tree().root.get_children():
		if child is PauseMenu or child is SettingsMenu:
			child.queue_free()
	
	if moving_buttons != null:
		_initial_buttons_pos = moving_buttons.position
	if moving_logo != null:
		_initial_logo_pos = moving_logo.position
	
	# Фокусировка на первой кнопке
	if buttons != null and buttons.get_child_count() > 0:
		var first_button := buttons.get_child(0) as Button
		if first_button != null:
			first_button.grab_focus()

func _process(delta: float) -> void:
	_update_mouse_follow(delta)

## Плавное смещение узлов в зависимости от положения мыши
func _update_mouse_follow(delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	var screen_center := viewport_size * 0.5
	
	var mouse_pos := get_viewport().get_mouse_position()
	var mouse_offset := (mouse_pos - screen_center) / screen_center
	mouse_offset.x = clampf(mouse_offset.x, -1.0, 1.0)
	mouse_offset.y = clampf(mouse_offset.y, -1.0, 1.0)
	
	if moving_buttons != null:
		var target_btn_pos := _initial_buttons_pos + (mouse_offset * buttons_parallax_strength)
		moving_buttons.position = moving_buttons.position.lerp(target_btn_pos, delta * follow_speed)
	
	if moving_logo != null:
		var target_logo_pos := _initial_logo_pos + (mouse_offset * logo_parallax_strength)
		moving_logo.position = moving_logo.position.lerp(target_logo_pos, delta * follow_speed)

# --- НОВЫЕ ФУНКЦИИ ДЛЯ КНОПОК ---

## Нажатие кнопки "Титры" (концовка)
func _on_titles_pressed() -> void:
	# Очищаем корень и переходим в меню концовки
	_clean_up_root()
	_change_scene(END_SCENE)

## Нажатие кнопки "Гайд" (Управление)


## Нажатие кнопки «Новая игра»
func _on_new_game_pressed() -> void:
	_start_game()

## Нажатие кнопки «Продолжить»
func _on_continue_pressed() -> void:
	_start_game()

## Запуск игрового процесса
func _start_game() -> void:
	_clean_up_root()
	get_tree().paused = false
	_change_scene(GAME_SCENE)

## Открытие меню настроек
func _on_settings_pressed() -> void:
	if settings_menu != null:
		settings_menu.open()

## Выход из игры
func _on_exit_pressed() -> void:
	get_tree().quit()

## Очистка корня (удаление меню паузы и прочего мусора)
func _clean_up_root() -> void:
	for child in get_tree().root.get_children():
		if child is PauseMenu or child is SettingsMenu:
			child.queue_free()

## Переход на другую сцену по переданному пути
func _change_scene(path: String) -> void:
	if path.is_empty():
		push_warning("MainMenu: Не указан путь к сцене.")
		return
	
	get_tree().change_scene_to_file(path)


func _on_guid_inputs_pressed() -> void:
	_clean_up_root()
	_change_scene(GUIDE_SCENE)
