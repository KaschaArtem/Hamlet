extends Control


@export var game: Node3D


signal building_action_clear
signal building_action_set


@export var house_button: Button
@export var field_button: Button
@export var pasture_button: Button
@export var delete_button: Button
@export var r_to_cancel_label: Label

var prev_button: Button


func _ready() -> void:
	game.player_action_started.connect(on_player_action_started)
	game.player_action_ended.connect(on_player_action_ended)
	r_to_cancel_label.visible = false


func on_player_action_started() -> void:
	house_button.disabled = false
	field_button.disabled = false
	pasture_button.disabled = false
	delete_button.disabled = false
func on_player_action_ended() -> void:
	house_button.disabled = true
	field_button.disabled = true
	pasture_button.disabled = true
	delete_button.disabled = true
	clear_building_action()

func handle_building(action_index: int, button: Button) -> void:
	if GameManager.is_build_allowed == false:
		return
	GameManager.building_action = action_index
	building_action_set.emit()
	r_to_cancel_label.visible = true
	if prev_button:
		prev_button.remove_theme_color_override("font_color")
		button.add_theme_color_override("font_color", Color.YELLOW)
		prev_button = button
	else:
		button.add_theme_color_override("font_color", Color.YELLOW)
		prev_button = button
func clear_building_action() -> void:
	GameManager.building_action = -999
	building_action_clear.emit()
	r_to_cancel_label.visible = false
	if prev_button:
		prev_button.remove_theme_color_override("font_color")
		prev_button = null

func _on_house_button_pressed() -> void:
	handle_building(1, house_button)
func _on_field_button_pressed() -> void:
	handle_building(2, field_button)
func _on_pasture_button_pressed() -> void:
	handle_building(3, pasture_button)
func _on_delete_button_pressed() -> void:
	handle_building(0, delete_button)

func _input(_event):
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
