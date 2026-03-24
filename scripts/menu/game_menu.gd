extends CanvasLayer


@export var main: Control
@export var settings: Control
@export var back_to_main_menu_confirm: Control


func update(next: Control) -> void:
	main.visible = false
	settings.visible = false
	back_to_main_menu_confirm.visible = false
	next.visible = true
