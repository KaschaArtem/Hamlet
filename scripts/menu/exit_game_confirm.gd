extends Control


@export var menu: CanvasLayer 
@export var main: Control

@export var no: Button
@export var yes: Button


func _ready() -> void:
	self.visible = false


func _on_no_pressed() -> void:
	menu.update(main)


func _on_yes_pressed() -> void:
	get_tree().quit()


func _input(_event) -> void:
	if Input.is_action_just_pressed("abort_key"):
		menu.update(main)
