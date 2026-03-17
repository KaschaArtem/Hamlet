extends Node


const CONFIG_PATH := "user://settings.cfg"

var RESOLUTIONS = [
	Vector2i(800, 600),
	Vector2i(1024, 768),
	Vector2i(1152, 648),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

var valid_resolutions: Array = []


func calc_valid_resolutions():
	var screen_size = DisplayServer.screen_get_size()
	valid_resolutions.clear()
	for res in RESOLUTIONS:
		if res.x <= screen_size.x and res.y <= screen_size.y:
			valid_resolutions.append(res)

func center_window():
	var screen_size = DisplayServer.screen_get_size()
	var window_size = DisplayServer.window_get_size()
	var new_position = (screen_size - window_size) / 2
	DisplayServer.window_set_position(new_position)
	get_tree().root.size = DisplayServer.window_get_size()

func save_config() -> void:
	var config = ConfigFile.new()
	config.set_value("display", "resolution", DisplayServer.window_get_size())
	config.set_value("display", "mode", DisplayServer.window_get_mode())
	var err = config.save(CONFIG_PATH)
	if err != OK:
		push_error("Failed to save config")

func apply_best_resolution():
	if valid_resolutions.size() == 0:
		DisplayServer.window_set_size(DisplayServer.screen_get_size())
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_size(valid_resolutions[-1])
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	get_tree().root.size = DisplayServer.window_get_size()

func apply_loaded_settings(resolution: Vector2i, mode: int):
	if resolution not in valid_resolutions:
		apply_best_resolution()
	else:
		DisplayServer.window_set_size(resolution)
		get_tree().root.size = resolution
	DisplayServer.window_set_mode(mode)
	if mode == DisplayServer.WINDOW_MODE_WINDOWED:
		center_window()

func load_config() -> bool:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	if err != OK:
		return false
	var resolution = config.get_value("display", "resolution", Vector2i(1152, 648))
	var mode = config.get_value("display", "mode", DisplayServer.WINDOW_MODE_FULLSCREEN)
	apply_loaded_settings(resolution, mode)
	return true

func _ready() -> void:
	calc_valid_resolutions()
	if load_config():
		pass
	else:
		apply_best_resolution()
		save_config()


func toggle_display_mode():
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(valid_resolutions[-1])
		get_tree().root.size = DisplayServer.window_get_size()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_size(valid_resolutions[-1])
		get_tree().root.size = DisplayServer.window_get_size()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		center_window()

func decrease_resolution():
	var current = DisplayServer.window_get_size()
	var index = valid_resolutions.find(current)
	if index == -1:
		index = valid_resolutions.size() - 1
	index = (index - 1 + valid_resolutions.size()) % valid_resolutions.size()
	DisplayServer.window_set_size(valid_resolutions[index])
	get_tree().root.size = DisplayServer.window_get_size()
	center_window()
