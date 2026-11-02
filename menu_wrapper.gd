extends Node

@export var hover_offset: float = 20.0
@export var tween_speed: float = 0.1

@onready var click_sound = $ClickSound
@onready var tick_sound = $TickSound # <--- ДОБАВИЛИ ССЫЛКУ НА ЗВУК НАВЕДЕНИЯ

func _ready():
	# Подключаемся к смене сцены, чтобы обновлять кнопки
	get_tree().node_added.connect(_on_node_added)
	
	# Ищем кнопки в стартовой сцене
	await get_tree().process_frame
	_setup_buttons_in_tree()

func _on_node_added(node: Node):
	# Если добавилась сцена (например, меню паузы), ищем кнопки в ней
	if node is Control or node is CanvasLayer:
		await get_tree().process_frame
		_setup_buttons_in_tree()

func _setup_buttons_in_tree():
	var all_buttons = get_tree().root.find_children("*", "Button", true, false)
	for btn in all_buttons:
		_setup_button(btn)

func _setup_button(btn: Button):
	if btn.has_meta("menu_setup_done"): return
	btn.set_meta("menu_setup_done", true)
	
	btn.set_meta("orig_offset_right", btn.offset_right)
	
	btn.mouse_entered.connect(_on_hover.bind(btn))
	btn.mouse_exited.connect(_on_unhover.bind(btn))
	btn.pressed.connect(_on_click)

func _on_hover(btn: Button):
	if not is_instance_valid(btn): return
	
	# --- ЗВУК НАВЕДЕНИЯ ---
	if tick_sound:
		tick_sound.play()
	# -----------------------
	
	if btn.has_meta("tween") and btn.get_meta("tween").is_valid():
		btn.get_meta("tween").kill()
	
	var tween = create_tween()
	btn.set_meta("tween", tween)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	var target_offset = btn.get_meta("orig_offset_right") + hover_offset
	tween.tween_property(btn, "offset_right", target_offset, tween_speed)

func _on_unhover(btn: Button):
	if not is_instance_valid(btn): return
	if btn.has_meta("tween") and btn.get_meta("tween").is_valid():
		btn.get_meta("tween").kill()
	
	var tween = create_tween()
	btn.set_meta("tween", tween)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	var target_offset = btn.get_meta("orig_offset_right")
	tween.tween_property(btn, "offset_right", target_offset, tween_speed)

func _on_click():
	if click_sound:
		click_sound.play()
