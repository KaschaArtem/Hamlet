extends Control

@export var game: Node3D

@export_group("Scenes Objects")
@export var button_node: Control
@export var end_month_button: Button

@export var year_count: Label
@export var month_count: Label

signal start_new_month

const year_offset = 1207
const month_offset = 2

var default_x_position: float
var hide_offset = 200.0 
var hover_offset = 6.0  

# Переменная для хранения текущей анимации
var move_tween: Tween

func _ready() -> void:
	game.player_action_started.connect(on_player_action_started)
	game.player_action_ended.connect(on_player_action_ended)
	
	default_x_position = button_node.position.x
	button_node.position.x += hide_offset

func on_player_action_started() -> void:
	end_month_button.disabled = false
	
	# Останавливаем старую анимацию, если она была
	if move_tween: move_tween.kill()
	
	move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	move_tween.tween_property(button_node, "position:x", default_x_position, 0.4)
	
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
	trigger_hide_and_emit()

func _input(_event):
	if Input.is_action_just_pressed("end_month") and not end_month_button.disabled:
		trigger_hide_and_emit()

func trigger_hide_and_emit() -> void:
	if end_month_button.disabled: return
	
	end_month_button.disabled = true
	start_new_month.emit()
	
	if move_tween: move_tween.kill()
	
	move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	move_tween.tween_property(button_node, "position:x", default_x_position + hide_offset, 0.3)

func _on_start_month_button_mouse_entered() -> void:
	if not end_month_button.disabled:
		if move_tween: move_tween.kill()
		
		move_tween = create_tween()
		move_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		move_tween.tween_property(button_node, "position:x", default_x_position - hover_offset, 0.2)

func _on_start_month_button_mouse_exited() -> void:
	if not end_month_button.disabled:
		if move_tween: move_tween.kill()
		
		move_tween = create_tween()
		move_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		move_tween.tween_property(button_node, "position:x", default_x_position, 0.2)
