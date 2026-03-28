extends Node


@export var menu: CanvasLayer 
@export var main: Control

@export var no: Button
@export var yes: Button


func _ready() -> void:
	self.visible = false


func _on_no_pressed() -> void:
	SFXManager.play_sound("menu_nav_button")
	menu.update(main)


func _on_yes_pressed() -> void:
	SFXManager.play_sound("menu_nav_button")
	SceneManager.load_scene("res://scenes/active_scenes/main_menu.tscn")


func _input(_event) -> void:
	if !GameManager.is_input_allowed:
		return
	if Input.is_action_just_pressed("abort_key"):
		if self.visible:
			SFXManager.play_sound("menu_nav_button")
			menu.update(main)
			get_viewport().set_input_as_handled()
