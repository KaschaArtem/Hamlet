extends Node3D


@export_group("Links")
@export var game: Node3D
@export var ground: Node3D

@export_group("Event UI")
@export var event_ui: Control

var is_event_triggered: bool


func try_generate_event() -> void:
	if randf() <= 0.2:
		is_event_triggered = true
		var event_id = randi_range(0, 3)
		
		match event_id:
			0: await _event_working_fuse_1()
			1: await _event_working_fuse_2()
			2: await _event_working_fuse_3()
			3: await _event_working_fuse_4()


func _event_working_fuse_1() -> void:
	var choice = await event_ui.get_event_input(
		"Working Fuse",
		"People gain experience while working. In what area are they best suited to succeed?",
		"Increase base Logging value",
		"Increase base Cultivating value"
	)
	
	match choice:
		1:
			game.base_wood_income += 1.0
		2:
			game.base_plant_food_income += 0.1
	game.invoke_base_income_changed()

func _event_working_fuse_2() -> void:
	var choice = await event_ui.get_event_input(
		"Working Fuse",
		"People gain experience while working. In what area are they best suited to succeed?",
		"Increase base Cultivating value",
		"Increase base Ranching value"
	)
	
	match choice:
		1:
			game.base_plant_food_income += 0.1
		2:
			game.base_animal_food_income += 0.1
	game.invoke_base_income_changed()

func _event_working_fuse_3() -> void:
	var choice = await event_ui.get_event_input(
		"Working Fuse",
		"People gain experience while working. In what area are they best suited to succeed?",
		"Increase base Ranching value",
		"Increase base Fishing value"
	)
	
	match choice:
		1:
			game.base_animal_food_income += 0.1
		2:
			game.base_fish_food_income += 0.1
	game.invoke_base_income_changed()

func _event_working_fuse_4() -> void:
	var choice = await event_ui.get_event_input(
		"Working Fuse",
		"People gain experience while working. In what area are they best suited to succeed?",
		"Increase base Logging value",
		"Increase base Fishing value"
	)
	
	match choice:
		1:
			game.base_wood_income += 1.0
		2:
			game.base_fish_food_income += 0.1
	game.invoke_base_income_changed()
