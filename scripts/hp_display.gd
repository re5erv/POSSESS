extends Node2D
class_name HpDisplay

## Цифры HP слева с покачиванием и подтёками.
## Цифра рисуется в SubViewport, а показывается через TextureRect
## с шейдером подтёков (res://SpriteFrames/drip.gdshader).

@export var circle_radius: float = 6.0  # Радиус движения по кругу
@export var circle_speed: float = 3.0   # Скорость движения по кругу

@onready var _viewport: SubViewport = $NumberViewport
@onready var _label: Label = $NumberViewport/HpNumber
@onready var _drips: TextureRect = $HpDrips

var _base_position: Vector2 = Vector2.ZERO
var _time: float = 0.0
var _last_hp: int = -9999
var _stats: Node = null


func _ready() -> void:
	_base_position = position
	# Показываем отрендеренную цифру через TextureRect с шейдером подтёков.
	_drips.texture = _viewport.get_texture()


func _process(delta: float) -> void:
	_time += delta
	_sway()
	_update_hp()


func _sway() -> void:
	# Небольшое плавное движение по кругу.
	position = _base_position + Vector2(cos(_time * circle_speed), sin(_time * circle_speed)) * circle_radius
	rotation = 0.0
	scale = Vector2.ONE


func _update_hp() -> void:
	_stats = _find_player_stats()
	visible = _stats != null
	if _stats == null:
		return
	var hp: int = int(_stats.health)
	if hp != _last_hp:
		_last_hp = hp
		_label.text = str(hp)


## HP берем у того, на ком сейчас висит камера (вселенный человек).
func _find_player_stats() -> Node:
	var cam: Node = get_tree().get_first_node_in_group("main_camera")
	if cam == null:
		return null
	var player: Node = cam.get_parent()
	if player == null:
		return null
	return player.get_node_or_null("Stats")
