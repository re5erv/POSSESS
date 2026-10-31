extends CanvasLayer
class_name SettingsMenu

signal closed

const CONFIG_PATH: String = "user://settings.cfg"

@onready var _backdrop: ColorRect = %Backdrop
@onready var _window: PanelContainer = %Window

@onready var _master_slider: HSlider = %MasterSlider
@onready var _master_value: Label = %MasterValue
@onready var _music_slider: HSlider = %MusicSlider
@onready var _music_value: Label = %MusicValue
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _sfx_value: Label = %SfxValue

@onready var _close_button: Button = %CloseButton
@onready var _fullscreen_check: CheckButton = %FullscreenCheck

var _tween: Tween


func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")

	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_close_button.pressed.connect(close)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_backdrop.gui_input.connect(_on_backdrop_input)

	_load_settings()

	_refresh_label(_master_slider.value, _master_value)
	_refresh_label(_music_slider.value, _music_value)
	_refresh_label(_sfx_slider.value, _sfx_value)

	visible = false
	_window.modulate.a = 0.0


func open() -> void:
	visible = true
	_close_button.grab_focus()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_window.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_window, "modulate:a", 1.0, 0.15)


func close() -> void:
	_save_settings()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_window, "modulate:a", 0.0, 0.12)
	_tween.tween_callback(func() -> void: visible = false)
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()


func _on_fullscreen_toggled(pressed: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if pressed
		else DisplayServer.WINDOW_MODE_WINDOWED
	)


func _on_master_changed(value: float) -> void:
	_apply_bus("Master", value)
	_refresh_label(value, _master_value)


func _on_music_changed(value: float) -> void:
	_apply_bus("Music", value)
	_refresh_label(value, _music_value)


func _on_sfx_changed(value: float) -> void:
	_apply_bus("SFX", value)
	_refresh_label(value, _sfx_value)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var index: int = AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")


func _apply_bus(bus_name: String, value: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	if value <= 0.001:
		AudioServer.set_bus_mute(index, true)
	else:
		AudioServer.set_bus_mute(index, false)
		AudioServer.set_bus_volume_db(index, linear_to_db(value))


func _refresh_label(value: float, label: Label) -> void:
	label.text = "%d%%" % roundi(value * 100.0)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	_master_slider.value = config.get_value("audio", "master", 1.0)
	_music_slider.value = config.get_value("audio", "music", 1.0)
	_sfx_slider.value = config.get_value("audio", "sfx", 1.0)
	_fullscreen_check.set_pressed_no_signal(
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", _master_slider.value)
	config.set_value("audio", "music", _music_slider.value)
	config.set_value("audio", "sfx", _sfx_slider.value)
	config.save(CONFIG_PATH)
