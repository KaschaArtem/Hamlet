extends CanvasLayer


@export var main: Control
@export var settings: Control
@export var new_game_confirm: Control
@export var exit_game_confirm: Control


func update(next: Control) -> void:
	main.visible = false
	settings.visible = false
	new_game_confirm.visible = false
	exit_game_confirm.visible = false
	next.visible = true
