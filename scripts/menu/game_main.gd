extends Control


@export var menu: CanvasLayer
@export var settings: Control
@export var back_to_main_menu_confirm: Control

@export var continue_button: Button
@export var settings_button: Button
@export var back_to_main_menu_button: Button


func _on_continue_button_pressed() -> void:
	SFXManager.play_sound("menu_nav_button")
	get_tree().paused = false
	menu.visible = false


func _on_settings_button_pressed() -> void:
	SFXManager.play_sound("menu_nav_button")
	menu.update(settings)


func _on_back_to_main_menu_button_pressed() -> void:
	SFXManager.play_sound("menu_nav_button")
	menu.update(back_to_main_menu_confirm)


func _input(event) -> void:
	if event is InputEventMouseMotion:
		return
	if !GameManager.is_input_allowed:
		return
	if Input.is_action_just_pressed("abort_key"):
		if self.visible:
			SFXManager.play_sound("menu_nav_button")
			menu.visible = false
			get_tree().paused = false
			get_viewport().set_input_as_handled()
