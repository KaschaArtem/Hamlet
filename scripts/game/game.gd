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

@export var start_human_resource = 4
@export var start_wood_resource = 250
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

func calculate_wood_production():

	var dist = ground.get_nearest_forest_distance()

	if dist == -1:
		return 0

	var efficiency = clamp(8 - dist, 1, 6)

	return human_resource * efficiency

func calculate_food_production():

	var workers = human_resource

	var field_workers = min(workers, ground.field_amount)
	var pasture_workers = min(workers - field_workers, ground.pasture_amount * 2)

	# производство растений
	var plant_production = field_workers
	plant_food_resource += plant_production


	# пастбища

	var base_animal_production = pasture_workers

	var required_plant_food = ground.pasture_amount

	var delivered_food = min(plant_food_resource, required_plant_food)

	var percent = 0.0

	if required_plant_food > 0:
		percent = float(delivered_food) / float(required_plant_food)

	percent = clamp(percent, 0.0, 1.0)

	var animal_production = int(base_animal_production * percent * percent * 2.5)

	plant_food_resource -= delivered_food

	animal_food_resource += animal_production

func calculate_food_consumption():
	var human_food_need = human_resource
	var pasture_food_need = ground.pasture_amount
	
	var total_food_need = human_food_need + pasture_food_need
	
	var plant_used = min(plant_food_resource, total_food_need)
	plant_food_resource -= plant_used
	
	total_food_need -= plant_used
	
	var animal_used = min(animal_food_resource, total_food_need)
	animal_food_resource -= animal_used

func calculate_wood_consumption(base_cost: int):
	var cost = base_cost + int(human_resource * 0.5)
	
	wood_resource -= cost
	
	if wood_resource < 0:
		wood_resource = 0

func process_spring():
	calculate_food_consumption()
	calculate_wood_consumption(2)
	wood_resource += calculate_wood_production()
	calculate_food_production()

func process_summer():
	calculate_food_consumption()
	wood_resource += calculate_wood_production()
	calculate_food_production()

func process_autumn():
	calculate_food_consumption()
	calculate_wood_consumption(3)
	wood_resource += calculate_wood_production()
	calculate_food_production()

func process_winter():
	calculate_food_consumption()
	calculate_wood_consumption(6)
	wood_resource += calculate_wood_production()
	calculate_food_production()

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
	clamp_resources()
	month_count += 1
	resources_changed.emit()
	turn_ended.emit(month_count)

func _input(_event):
	if Input.is_action_just_pressed("reload_game_scene"):
		SceneManager.change_scene("res://scenes/active_scenes/game.tscn")
