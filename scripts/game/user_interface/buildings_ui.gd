extends Control

@export var game: Node3D

@export var house_button: Button
@export var field_button: Button
@export var pasture_button: Button
@export var delete_button: Button

var prev_button: Button
var last_action_frame = -1

# Храним исходные Y-позиции кнопок
var default_y_positions = {}
# На сколько пикселей кнопка уходит вниз, когда скрыта
var hide_offset = 100.0

func _ready() -> void:
	game.player_action_started.connect(on_player_action_started)
	game.player_action_ended.connect(on_player_action_ended)
	
	for btn in [house_button, field_button, pasture_button, delete_button]:
		default_y_positions[btn] = btn.position.y
		# Изначально прячем все кнопки вниз без анимации
		btn.position.y += hide_offset
		btn.disabled = true

func on_player_action_started() -> void:
	var delay = 0.0
	for btn in [house_button, field_button, pasture_button, delete_button]:
		btn.disabled = false
		# Плавное появление каждой кнопки с небольшой задержкой (каскад)
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "position:y", default_y_positions[btn], 0.4).set_delay(delay)
		delay += 0.05

func on_player_action_ended() -> void:
	clear_building_action() # Сначала сбрасываем выбранную (чтобы она ушла на базу)
	
	for btn in [house_button, field_button, pasture_button, delete_button]:
		btn.disabled = true
		# Прячем все кнопки вниз
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(btn, "position:y", default_y_positions[btn] + hide_offset, 0.3)

func handle_building(action_index: int, button: Button) -> void:
	if GameManager.is_build_allowed == false:
		return

	if last_action_frame == Engine.get_frames_drawn():
		return
	last_action_frame = Engine.get_frames_drawn()

	if prev_button == button:
		clear_building_action()
		return

	if prev_button:
		animate_button_selection(prev_button, false)

	GameManager.building_action = action_index
	prev_button = button
	animate_button_selection(button, true)

func clear_building_action() -> void:
	GameManager.building_action = -999
	if prev_button:
		animate_button_selection(prev_button, false)
		prev_button = null

# Анимация выбора (выдвижение на 16 пикселей)
func animate_button_selection(button: Button, up: bool) -> void:
	var target_y = default_y_positions[button]
	if up:
		target_y -= 16
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "position:y", target_y, 0.2)

# --- Инпут без изменений ---
func _on_house_button_pressed() -> void:
	handle_building(1, house_button)
func _on_field_button_pressed() -> void:
	handle_building(2, field_button)
func _on_pasture_button_pressed() -> void:
	handle_building(3, pasture_button)
func _on_delete_button_pressed() -> void:
	handle_building(0, delete_button)

func _input(event):
	if event.is_echo(): return
	
	if Input.is_action_just_pressed("set_build_to_house"):
		handle_building(1, house_button)
	elif Input.is_action_just_pressed("set_build_to_field"):
		handle_building(2, field_button)
	elif Input.is_action_just_pressed("set_build_to_pasture"):
		handle_building(3, pasture_button)
	elif Input.is_action_just_pressed("set_build_to_tile"):
		handle_building(0, delete_button)
	elif Input.is_action_just_pressed("clear_building_action"):
		clear_building_action()