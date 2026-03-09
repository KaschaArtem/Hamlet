extends CanvasLayer

@export var game: Node3D

@export var house_button: Button
@export var field_button: Button
@export var pasture_button: Button
@export var delete_button: Button
@export var r_to_cancel_label: Label

@export var actual_people: Label
@export var max_people: Label
@export var actual_wood: Label
@export var max_wood: Label
@export var actual_plant_food: Label
@export var actual_animal_food: Label
@export var max_food: Label


var prev_button: Button

func _ready() -> void:
	game.resources_changed.connect(update_resources)
	update_resources()
	r_to_cancel_label.visible = false

func update_resources() -> void:
	actual_people.text = str(game.human_resource)
	max_people.text = str(game.max_human_resource)
	actual_wood.text = str(game.wood_resource)
	max_wood.text = str(game.max_wood_resource)
	actual_plant_food.text = str(game.plant_food_resource)
	actual_animal_food.text = str(game.animal_food_resource)
	max_food.text = str(game.max_food_resource)


func handle_building(action_index: int, button: Button) -> void:
	game.building_action = action_index
	r_to_cancel_label.visible = true
	if prev_button:
		prev_button.remove_theme_color_override("font_color")
		button.add_theme_color_override("font_color", Color.YELLOW)
		prev_button = button
	else:
		button.add_theme_color_override("font_color", Color.YELLOW)
		prev_button = button
func handle_cancel_building() -> void:
	game.building_action = -999
	r_to_cancel_label.visible = false
	if prev_button:
		prev_button.remove_theme_color_override("font_color")
		prev_button = null

func _on_house_button_pressed() -> void:
	handle_building(1, house_button)
func _on_field_button_pressed() -> void:
	handle_building(2, field_button)
func _on_pasture_button_pressed() -> void:
	handle_building(3, pasture_button)
func _on_delete_button_pressed() -> void:
	handle_building(0, delete_button)


func _input(_event):
	if Input.is_action_just_pressed("set_build_to_house"):
		handle_building(1, house_button)
	elif Input.is_action_just_pressed("set_build_to_field"):
		handle_building(2, field_button)
	elif Input.is_action_just_pressed("set_build_to_pasture"):
		handle_building(3, pasture_button)
	elif Input.is_action_just_pressed("set_build_to_tile"):
		handle_building(0, delete_button)
	elif Input.is_action_just_pressed("clear_building_action"):
		handle_cancel_building()
