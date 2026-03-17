extends Control


@export var menu: CanvasLayer 
@export var settings: Control
@export var new_game_confirm: Control
@export var exit_game_confirm: Control

@export var new_game_button: Button
@export var continue_button: Button
@export var settings_button: Button
@export var exit_game_button: Button


func _on_new_game_button_pressed() -> void:
	menu.update(new_game_confirm)


func _on_settings_button_pressed() -> void:
	menu.update(settings)


func _on_exit_game_button_pressed() -> void:
	menu.update(exit_game_confirm)
