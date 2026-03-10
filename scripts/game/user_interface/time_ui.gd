extends Control

@export var game: Node3D

@export var month_count: Label
@export var end_month_button: Button


func _ready() -> void:
	game.turn_ended.connect(update_date)


func update_date(count) -> void:
	month_count.text = str(count)


func _on_end_month_button_pressed() -> void:
	game.end_month()


func _input(_event):
	if Input.is_action_just_pressed("end_month"):
		game.end_month()
