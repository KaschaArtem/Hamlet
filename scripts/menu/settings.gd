extends Control


@export var menu: Node3D 

@export var main: Control


func _ready() -> void:
	self.visible = false


func _on_back_pressed() -> void:
	menu.update(main)


func _input(_event) -> void:
	if Input.is_action_just_pressed("abort_key"):
		menu.update(main)
