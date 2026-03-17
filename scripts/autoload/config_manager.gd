extends Node


var RESOLUTIONS = [
	Vector2i(800, 600),
	Vector2i(1024, 768),
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

func _ready() -> void:
	calc_valid_resolutions()
	apply_best_resolution()


func center_window():
	var screen_size = DisplayServer.screen_get_size()
	var window_size = DisplayServer.window_get_size()
	var new_position = (screen_size - window_size) / 2
	DisplayServer.window_set_position(new_position)

func toggle_display_mode():
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(valid_resolutions[-1])
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_size(valid_resolutions[-1])
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		center_window()

func apply_best_resolution():
	if valid_resolutions.size() == 0:
		DisplayServer.window_set_size(DisplayServer.screen_get_size())
		return
	var best_res = valid_resolutions[0]
	for res in valid_resolutions:
		if res.x * res.y > best_res.x * best_res.y:
			best_res = res
	DisplayServer.window_set_size(best_res)
	get_tree().root.size = DisplayServer.window_get_size()
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
