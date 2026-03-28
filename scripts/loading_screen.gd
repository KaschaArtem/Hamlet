extends CanvasLayer


signal loading_screen_ready

@export var animation_player: AnimationPlayer


func _ready() -> void:
	GameManager.is_input_allowed = false
	get_tree().paused = false
	await animation_player.animation_finished
	loading_screen_ready.emit()


func _on_progress_changed(_new_value: float) -> void:
	pass


func _on_load_finished() -> void:
	animation_player.play_backwards("transition")
	await animation_player.animation_finished
	GameManager.is_input_allowed = true
	queue_free()
