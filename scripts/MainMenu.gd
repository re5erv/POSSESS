extends Control
class_name MainMenu

# Путь к сцене игрового процесса
const GAME_SCENE: String = "res://scenes/level.tscn"

<<<<<<< Updated upstream
# Ссылки на узлы интерфейса
@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var buttons: VBoxContainer = $"Block 2/Buttons"
=======
# Настройки музыки
@export_group("Audio")
@export var music_stream: AudioStream            # Аудиофайл музыки (перетащите в инспекторе)
@export var music_bus: StringName = &"Music"      # Аудио-шина (по умолчанию Music или Master)
@export var music_fade_duration: float = 1.0     # Длительность плавного затухания/появления в сек.
@export_range(-80.0, 6.0, 0.5) var music_volume_db: float = 0.0 # Целевая громкость

# Настройки параллакса за курсором мыши
@export_group("Parallax")
@export var buttons_parallax_strength: float = 25.0 # Смещение кнопок (Block 2)
@export var logo_parallax_strength: float = 12.0    # Смещение логотипа (Block 1)
@export var follow_speed: float = 5.0              # Скорость сглаживания движения

# Ссылки на узлы интерфейса
@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var buttons: Control = $"Block 2/Buttons"
@onready var moving_buttons: Control = $"Block 2"
@onready var moving_logo: Control = $"Block 1"

var _music_player: AudioStreamPlayer
var _initial_buttons_pos: Vector2 = Vector2.ZERO
var _initial_logo_pos: Vector2 = Vector2.ZERO
>>>>>>> Stashed changes


func _ready() -> void:
	# Возвращаем видимый курсор мыши для управления интерфейсом
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
<<<<<<< Updated upstream
	var first_button := buttons.get_child(0) as Button
	if first_button != null:
		first_button.grab_focus()
=======
	
	if moving_buttons != null:
		_initial_buttons_pos = moving_buttons.position
	if moving_logo != null:
		_initial_logo_pos = moving_logo.position
	
	if buttons != null and buttons.get_child_count() > 0:
		var first_button := buttons.get_child(0) as Button
		if first_button != null:
			first_button.grab_focus()

	_setup_and_play_music()


func _process(delta: float) -> void:
	_update_mouse_follow(delta)


## Создание плеера и запуск музыки с плавным появлением
func _setup_and_play_music() -> void:
	# Если узел AudioStreamPlayer уже есть в сцене под именем MusicPlayer, используем его,
	# иначе создаем автоматически через код
	_music_player = get_node_or_null("MusicPlayer") as AudioStreamPlayer
	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "MusicPlayer"
		add_child(_music_player)

	_music_player.bus = music_bus

	if music_stream != null:
		_music_player.stream = music_stream
		_music_player.volume_db = -80.0
		_music_player.play()
		
		# Плавное нарастание громкости
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", music_volume_db, music_fade_duration)


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
>>>>>>> Stashed changes


## Нажатие кнопки «Новая игра»
func _on_new_game_pressed() -> void:
	_start_game()


## Нажатие кнопки «Продолжить»
func _on_continue_pressed() -> void:
	# TODO: Добавить логику загрузки последнего сохранения
	_start_game()


## Запуск игрового процесса с плавным затуханием музыки
func _start_game() -> void:
	if _music_player != null and _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, 0.5)
		tween.tween_callback(Callable(self, "_change_scene").bind(GAME_SCENE))
	else:
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
