extends Node3D

@export var ground: Node3D

signal resources_changed
signal turn_ended(month_count)

@export var main_tile_human_capacity: int = 10
@export var main_tile_wood_capacity: int = 100
@export var main_tile_food_capacity: int = 24
@export var house_human_capacity: int = 4
@export var house_wood_capacity: int = 18
@export var house_food_capacity: int = 8

@export var house_cost: int = 40
@export var field_cost: int = 24
@export var pasture_cost: int = 32

@export var base_wood_income: int = 14
@export var base_plant_food_income: int = 3
@export var base_animal_food_income: int = 3

@export var wood_penalty: int = 5
@export var food_penalty: int = 1

@export var start_human_resource = 4
@export var start_wood_resource = 50
@export var start_plant_food_resource = 10
@export var start_animal_food_resource = 8

var human_resource = start_human_resource
var wood_resource = start_wood_resource
var plant_food_resource = start_plant_food_resource
var animal_food_resource = start_animal_food_resource

var max_human_resource
var max_wood_resource
var max_food_resource


var month_count = 0


func update_max_values() -> void:
	max_human_resource = ground.house_amount * house_human_capacity + main_tile_human_capacity
	max_wood_resource = ground.house_amount * house_wood_capacity + main_tile_wood_capacity
	max_food_resource = ground.house_amount * house_food_capacity + main_tile_food_capacity

func _ready() -> void:
	ground.builded.connect(on_builded)
	update_max_values()
	resources_changed.emit()


func is_house_build_allowed() -> bool:
	if house_cost <= wood_resource:
		return true
	return false
func is_field_build_allowed() -> bool:
	if field_cost <= wood_resource:
		return true
	return false
func is_pasture_build_allowed() -> bool:
	if pasture_cost <= wood_resource:
		return true
	return false

func on_builded(building_index) -> void:
	match building_index:
		1:
			wood_resource -= house_cost
		2:
			wood_resource -= field_cost
		3:
			wood_resource -= pasture_cost
	update_max_values()
	resources_changed.emit()


func calculate_wood_production() -> void:
	var dist = ground.get_nearest_forest_distance()
	if dist == -1:
		return
	var efficiency = clamp(1 - (dist - 1) * 0.125, 0.5, 1)
	wood_resource = int(round(wood_resource + base_wood_income * (human_resource * 0.7) * efficiency))
func calculate_food_production() -> void:
	plant_food_resource += int(round((human_resource * 0.7) * ground.field_amount))
	animal_food_resource += int(round((human_resource * 0.3) * ground.pasture_amount))
func calculate_wood_consumption(multiplier: float) -> void:
	wood_resource -= int(round(human_resource * 0.5 * multiplier))
	if wood_resource < 0:
		human_resource -= int(round(wood_resource)) / wood_penalty
		wood_resource = 0
func calculate_food_consumption() -> void:
	var total_food = plant_food_resource + animal_food_resource
	if (total_food - human_resource) >= 0:
		var plant_food_consumption = int(round(human_resource * float(plant_food_resource) / total_food))
		var animal_food_consumption = human_resource - plant_food_consumption
		print(plant_food_consumption, " ", animal_food_consumption)
		plant_food_resource -= plant_food_consumption
		animal_food_resource -= animal_food_consumption
	else:
		human_resource -= int(round((human_resource - total_food))) / food_penalty
		plant_food_resource = 0
		animal_food_resource = 0

func process_spring():
	calculate_wood_production()
	calculate_food_production()
	calculate_wood_consumption(0.8)
	calculate_food_consumption()
func process_summer():
	calculate_wood_production()
	calculate_food_production()
	calculate_wood_consumption(0.0)
	calculate_food_consumption()
func process_autumn():
	calculate_wood_production()
	calculate_food_production()
	calculate_wood_consumption(1.2)
	calculate_food_consumption()
func process_winter():
	calculate_wood_production()
	calculate_food_production()
	calculate_wood_consumption(2.4)
	calculate_food_consumption()

func clamp_resources():
	human_resource = min(human_resource, max_human_resource)
	wood_resource = min(wood_resource, max_wood_resource)

	var total_food = plant_food_resource + animal_food_resource
	if total_food > max_food_resource:
		var overflow = total_food - max_food_resource
		if animal_food_resource >= overflow:
			animal_food_resource -= overflow
		else:
			overflow -= animal_food_resource
			animal_food_resource = 0
			plant_food_resource = max(0, plant_food_resource - overflow)

func game_over() -> void:
	SceneManager.change_scene("res://scenes/active_scenes/game.tscn")

func end_month() -> void:
	var month = month_count % 12 + 1
	if month >= 1 and month <= 3:
		process_spring()
	elif month >= 4 and month <= 6:
		process_summer()
	elif month >= 7 and month <= 9:
		process_autumn()
	elif month >= 10 and month <= 12:
		process_winter()
	if human_resource <= 0:
		game_over()
	clamp_resources()
	month_count += 1
	resources_changed.emit()
	turn_ended.emit(month_count)

func _input(_event):
	if Input.is_action_just_pressed("reload_game_scene"):
		SceneManager.change_scene("res://scenes/active_scenes/game.tscn")
