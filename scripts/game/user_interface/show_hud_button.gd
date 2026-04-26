extends Control


@export_group("UI Links")
@export var warnings_ui: Control
@export var resources_ui: Control
@export var buildings_ui: Control
@export var time_ui: Control
@export var people_control_ui: Control
@export var object_info_ui: Control

@export var fade_duration: float = 0.1

signal fade_out
signal fade_in


var is_hidden = false
var tween: Tween


func _on_button_pressed() -> void:
	is_hidden = !is_hidden
	toggle_ui()
	match is_hidden:
		true: fade_out.emit()
		false: fade_in.emit()


func toggle_ui() -> void:
	if tween and tween.is_running():
		tween.kill()

	var target_alpha = 0.0 if is_hidden else 1.0
	var ui_elements = [warnings_ui, resources_ui, buildings_ui, time_ui, people_control_ui, object_info_ui]
	
	tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)

	if not is_hidden:
		for ui in ui_elements:
			if ui: 
				ui.visible = true
	
	for ui in ui_elements:
		if ui:
			tween.tween_property(ui, "modulate:a", target_alpha, fade_duration)

	if is_hidden:
		tween.chain().tween_callback(func():
			if is_hidden:
				for ui in ui_elements:
					if ui: 
						ui.visible = false
		)


func _on_button_mouse_exited() -> void:
	GameManager.is_ui_hovered = false

func _on_button_mouse_entered() -> void:
	GameManager.is_ui_hovered = true
