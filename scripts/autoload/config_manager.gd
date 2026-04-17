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

var cur_main_bus_value: int = 10
var cur_music_bus_value: int = 10
var cur_effects_bus_value: int = 10


func calc_valid_resolutions():
	var screen_size = DisplayServer.screen_get_size()
	for res in RESOLUTIONS:
		if res.x <= screen_size.x and res.y <= screen_size.y:
			valid_resolutions.append(res)

func set_resolution(new_res: Vector2i):
	DisplayServer.window_set_size(new_res)
	get_tree().root.size = new_res
	center_window()

func center_window():
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		return
	var screen_size = DisplayServer.screen_get_size()
	var window_size = DisplayServer.window_get_size()
	var new_position = (screen_size - window_size) / 2
	DisplayServer.window_set_position(new_position)
	get_tree().root.size = DisplayServer.window_get_size()

func load_config() -> bool:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	if err != OK:
		return false
	set_resolution(config.get_value("display", "resolution", Vector2i(1152, 648)))
	DisplayServer.window_set_mode(config.get_value("display", "mode", DisplayServer.WINDOW_MODE_WINDOWED))
	center_window()
	update_main_bus(config.get_value("audio", "main", 10))
	update_music_bus(config.get_value("audio", "music", 10))
	update_effects_bus(config.get_value("audio", "effects", 10))
	return true

func save_config() -> void:
	var config = ConfigFile.new()
	config.set_value("display", "resolution", DisplayServer.window_get_size())
	config.set_value("display", "mode", DisplayServer.window_get_mode())
	config.set_value("audio", "main", cur_main_bus_value)
	config.set_value("audio", "music", cur_music_bus_value)
	config.set_value("audio", "effects", cur_effects_bus_value)
	var err = config.save(CONFIG_PATH)
	if err != OK:
		push_error("Failed to save config")

func _ready() -> void:
	calc_valid_resolutions()
	if load_config():
		pass
	else:
		save_config()


func toggle_display_mode():
	var mode = DisplayServer.window_get_mode()
	match mode:
		DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			set_resolution(valid_resolutions[-1])
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			set_resolution(valid_resolutions[-1])
			center_window()
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(valid_resolutions[-1])
			center_window()

func decrease_resolution():
	var current = DisplayServer.window_get_size()
	var index = valid_resolutions.find(current)
	if index == -1:
		index = valid_resolutions.size() - 1
	index = (index - 1 + valid_resolutions.size()) % valid_resolutions.size()
	DisplayServer.window_set_size(valid_resolutions[index])
	center_window()


func update_bus(value: int, bus_index: int) -> void:
	if value == 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		var db = linear_to_db(value / 10.0)
		AudioServer.set_bus_volume_db(bus_index, db)

func update_main_bus(value: int) -> void:
	cur_main_bus_value = value
	update_bus(value, AudioServer.get_bus_index("Master"))

func update_music_bus(value: int) -> void:
	cur_music_bus_value = value
	update_bus(value, AudioServer.get_bus_index("Music"))

func update_effects_bus(value: int) -> void:
	cur_effects_bus_value = value
	update_bus(value, AudioServer.get_bus_index("Effects"))
