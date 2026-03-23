extends Control


const year_offset = 1207
const month_offset = 2

@export var game: Node3D

signal start_new_month

@export var end_month_button: Button

@export var year_count: Label
@export var month_count: Label


func _ready() -> void:
	game.player_action_started.connect(on_player_action_started)
	game.player_action_ended.connect(on_player_action_ended)

func on_player_action_started() -> void:
	end_month_button.disabled = false
	
	var month = (game.month_count + month_offset) % 12 + 1
	if month < 10:
		month_count.text = "0" + str(month) + ".xx"
	else:
		month_count.text = str(month) + ".xx"

	var year = year_offset + (game.month_count + month_offset) / 12
	year_count.text = str(year)

func on_player_action_ended() -> void:
	end_month_button.disabled = true


func _on_end_month_button_pressed() -> void:
	start_new_month.emit()
	end_month_button.disabled = true


func _input(_event):
	if Input.is_action_just_pressed("end_month"):
		start_new_month.emit()
		end_month_button.disabled = true
