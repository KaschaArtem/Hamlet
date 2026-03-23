extends Control


@export var menu: CanvasLayer
@export var main: Control

@export var display_mode_button: Button
@export var display_mode_label: Label
@export var display_resolution_button: Button
@export var dislpay_resolution_label: Label

@export var main_value: Label
@export var main_slider: HSlider
@export var music_value: Label
@export var music_slider: HSlider
@export var effects_value: Label
@export var effects_slider: HSlider


func update_display_mode() -> void:
	var mode = DisplayServer.window_get_mode()
	match mode:
		DisplayServer.WINDOW_MODE_WINDOWED:
			display_mode_label.text = "Windowed"
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			display_mode_label.text = "Borderless"
func update_display_resolution(resolution) -> void:
	dislpay_resolution_label.text = str(resolution.x) + "x" + str(resolution.y)
func update_main_value() -> void:
	main_value.text = str(int(main_slider.value))
func update_music_value() -> void:
	music_value.text = str(int(music_slider.value))
func update_effects_value() -> void:
	effects_value.text = str(int(effects_slider.value))
func update_main_slider() -> void:
	main_slider.value = ConfigManager.cur_main_bus_value
func update_music_slider() -> void:
	music_slider.value = ConfigManager.cur_music_bus_value
func update_effects_slider() -> void:
	effects_slider.value = ConfigManager.cur_effects_bus_value

func _ready() -> void:
	update_display_mode()
	toggle_display_resolution_button()
	update_main_slider()
	update_music_slider()
	update_effects_slider()
	self.visible = false


func _on_back_pressed() -> void:
	menu.update(main)
	ConfigManager.save_config()


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


func _on_main_slider_value_changed(value: float) -> void:
	ConfigManager.update_main_bus(int(value))
	update_main_value()

func _on_music_slider_value_changed(value: float) -> void:
	ConfigManager.update_music_bus(int(value))
	update_music_value()

func _on_effects_slider_value_changed(value: float) -> void:
	ConfigManager.update_effects_bus(int(value))
	update_effects_value()


func _input(_event) -> void:
	if Input.is_action_just_pressed("abort_key"):
		menu.update(main)
		ConfigManager.save_config()
