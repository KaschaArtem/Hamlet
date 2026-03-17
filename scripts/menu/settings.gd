extends Control


@export var menu: CanvasLayer
@export var main: Control

@export var display_mode_button: Button
@export var display_mode_label: Label
@export var display_resolution_button: Button
@export var dislpay_resolution_label: Label


func update_display_mode() -> void:
	var mode = DisplayServer.window_get_mode()
	match mode:
		DisplayServer.WINDOW_MODE_WINDOWED:
			display_mode_label.text = "Windowed"
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			display_mode_label.text = "Borderless"
func update_display_resolution(resolution) -> void:
	dislpay_resolution_label.text = str(resolution.x) + "x" + str(resolution.y)

func _ready() -> void:
	update_display_mode()
	toggle_display_resolution_button()
	self.visible = false


func _on_back_pressed() -> void:
	menu.update(main)


func toggle_display_resolution_button() -> void:
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_WINDOWED:
		update_display_resolution(DisplayServer.window_get_size())
		display_resolution_button.disabled = false
	else:
		update_display_resolution(DisplayServer.screen_get_size())
		display_resolution_button.disabled = true

func _on_display_mode_pressed() -> void:
	ConfigManager.toggle_display_mode()
	update_display_mode()
	toggle_display_resolution_button()

func _on_display_resolution_pressed() -> void:
	ConfigManager.decrease_resolution()
	update_display_resolution(DisplayServer.window_get_size())


func _input(_event) -> void:
	if Input.is_action_just_pressed("abort_key"):
		menu.update(main)
