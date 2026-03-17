extends Control


@export var menu: Node3D 
@export var main: Control

@export var no: Button
@export var yes: Button


func _ready() -> void:
	self.visible = false


func _on_no_pressed() -> void:
	menu.update(main)


func _on_yes_pressed() -> void:
	SceneManager.change_scene("res://scenes/active_scenes/game.tscn")


func _input(_event) -> void:
	if Input.is_action_just_pressed("abort_key"):
		menu.update(main)
