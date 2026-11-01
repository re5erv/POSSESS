extends Node

signal all_humans_dead

@export var check_interval: float = 0.5
var _check_timer: float = 0.0
var _is_already_triggered: bool = false

func _ready() -> void:
	print("[ROOM] _ready вызван на ", name, " | детей: ", get_child_count())

func _process(delta: float) -> void:
	if _is_already_triggered:
		return
		
	_check_timer += delta
	if _check_timer >= check_interval:
		_check_timer = 0.0
		_check_humans()

func _check_humans() -> void:
	var alive_humans_found: bool = false

	for child in get_children():
		var is_human_type = child.is_in_group("human") or ("stats" in child)
		if not is_human_type:
			continue

		# ⛔ Если в этого персонажа вселился игрок — игнорируем его
		if "is_possessed" in child and child.is_possessed:
			continue

		var is_dead = false
		if "dead" in child and child.dead:
			is_dead = true
		elif "stats" in child and child.stats.health <= 0:
			is_dead = true

		if not is_dead:
			alive_humans_found = true
			break

	if not alive_humans_found:
		_is_already_triggered = true
		print("[ROOM] Все люди мертвы (или нет живых). Открываю дверь.")
		all_humans_dead.emit()

func _trigger() -> void:
	_is_already_triggered = true
	print("[ROOM] !!! ТРИГГЕР СРАБОТАЛ — испускаю all_humans_dead")
	all_humans_dead.emit()
