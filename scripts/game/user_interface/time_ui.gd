extends Control


@export var game: Node3D

signal start_new_month

@export var month_count: Label
@export var end_month_button: Button


func _ready() -> void:
	game.player_action_started.connect(on_player_action_started)
	game.player_action_ended.connect(on_player_action_ended)

func on_player_action_started() -> void:
	end_month_button.disabled = false
	month_count.text = str(game.month_count)
func on_player_action_ended() -> void:
	end_month_button.disabled = true


func _on_end_month_button_pressed() -> void:
	start_new_month.emit()
	end_month_button.disabled = true


func _input(_event):
	if Input.is_action_just_pressed("end_month"):
		start_new_month.emit()
		end_month_button.disabled = true
