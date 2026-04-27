extends Node3D


@export var ground: Node3D
@export var MenuUI: CanvasLayer
@onready var time_ui = $UserInterface/TimeUI
@onready var timer = $Timer

@export_group("Capacity")
@export var main_tile_human_capacity: int = 10
@export var main_tile_wood_capacity: int = 100
@export var main_tile_food_capacity: int = 24
@export var house_human_capacity: int = 4
@export var house_wood_capacity: int = 18
@export var house_food_capacity: int = 8

@export_group("Cost")
@export var house_cost: float = 40.0
@export var road_cost: float = 6.0
@export var field_cost: float = 24.0
@export var pasture_cost: float = 32.0
@export var sawmill_cost: float = 20.0
@export var fishing_station_cost: float = 48.0

@export_group("Stations Radius")
@export var sawmill_radius: int = 3
@export var fishing_station_radius: int = 1

@export_group("Pow Value")
@export var people_on_wood_eff: float = 0.5
@export var people_on_plant_eff: float = 0.9
@export var people_on_animal_eff: float = 0.8
@export var people_on_fish_eff: float = 0.5

@export_group("Base Income")
@export var base_wood_income: float = 15.0
@export var base_plant_food_income: float = 1.0
@export var base_animal_food_income: float = 1.0
@export var base_fish_food_income: float = 1.0

@export_group("Base Consumption")
@export var base_wood_consumption: float = 2.0
@export var base_good_diet_food_consumption: float = 1.5
@export var base_normal_diet_food_consumption: float = 1.0
@export var base_saving_diet_food_consumption: float = 0.8

@export_group("Base Goals")
@export var needed_new_human_progress_value: int = 10

@export_group("Mults")
@export var new_human_progress_mult: float = 1.0
@export var base_good_diet_mult: float = 0.5
@export var base_normal_diet_mult: float = 0.2
@export var base_saving_diet_mult: float = 0.0

@export_group("Death Penalty")
@export var wood_penalty: float = 5.0
@export var food_penalty: float = 1.0

@export_group("Start Resources")
@export var start_human_resource = 4
@export var start_wood_resource = 80
@export var start_plant_food_resource = 10
@export var start_animal_food_resource = 8

signal resources_changed
signal people_changed
signal people_assignment_changed
signal people_diet_bases_changed
signal new_human_progress_changed
signal season_changed
signal player_action_started
signal player_action_ended
signal turn_ended

var TILES_INFO = {
	"tree": ["Tree", "Being cutted to get WOOD. Press F on this tile if in SAWMILL radius to choose this tree for cutting during next month. Tree tile will desappeared after this."],
	"water": ["Water", "Being used to get FISH. Press F on water cluster if in FISHING STATION to choose it for fishing during next month. After fishing this water cluster will not be available for 3 months."],
	"house": ["House", "Increasing max amount of PEOPLE, WOOD, FOOD. Allowing to build for its neighboor tiles."],
	"road": ["Road", "Allowing to build for its neighboor tiles."],
	"field": ["Field", "Produce plant food. Doesn't work on winter."],
	"pasture": ["Pasture", "Produce animal food. Works less efficient on winter."],
	"sawmill": ["Sawmill", "Allowing to select trees for cutting in some radius."],
	"fishing_station": ["Fishing Station", "Allowing to select water for fishing in some radius."]
}

var human_resource : int = start_human_resource
var wood_resource : float = start_wood_resource
var plant_food_resource : float = start_plant_food_resource
var animal_food_resource : float = start_animal_food_resource

var max_human_resource
var max_wood_resource
var max_food_resource


var wood_season_mod = 1.0
var plant_season_mod = 1.0
var animal_season_mod = 1.0
var fish_season_mod = 1.0

var people_on_wood: int = 0:
	set(v):
		people_on_wood = _clamp_resource_value(people_on_wood, v)
		people_assignment_changed.emit()

var people_on_plant: int = 0:
	set(v):
		people_on_plant = _clamp_resource_value(people_on_plant, v)
		people_assignment_changed.emit()

var people_on_animal: int = 0:
	set(v):
		people_on_animal = _clamp_resource_value(people_on_animal, v)
		people_assignment_changed.emit()

var people_on_fish: int = 0:
	set(v):
		people_on_fish = _clamp_resource_value(people_on_fish, v)
		people_assignment_changed.emit()

enum Season { SPRING, SUMMER, AUTUMN, WINTER }
var month_count: int = 0
var current_season: Season = Season.SPRING

var current_human_progress: int = 0
var current_food_consumpton: float = base_normal_diet_food_consumption
var current_base_human_progress: float = base_normal_diet_mult


func get_total_assigned() -> int:
	return people_on_wood + people_on_plant + people_on_animal + people_on_fish

func _clamp_resource_value(current: int, new_val: int) -> int:
	var available = human_resource - get_total_assigned() + current
	return int(clamp(new_val, 0, available))

func update_max_values() -> void:
	max_human_resource = ground.house_amount * house_human_capacity + main_tile_human_capacity
	max_wood_resource = ground.house_amount * house_wood_capacity + main_tile_wood_capacity
	max_food_resource = ground.house_amount * house_food_capacity + main_tile_food_capacity


func _ready() -> void:
	player_action_started.connect(on_player_action_started)
	player_action_ended.connect(on_player_action_ended)
	timer.end_month.connect(on_end_month)
	GameManager.building_action = "none"
	update_max_values()
	start_first_month()


func is_house_build_allowed() -> bool:
	return house_cost <= wood_resource

func is_road_build_allowed() -> bool:
	return road_cost <= wood_resource

func is_field_build_allowed() -> bool:
	return field_cost <= wood_resource

func is_pasture_build_allowed() -> bool:
	return pasture_cost <= wood_resource

func is_sawmill_build_allowed() -> bool:
	return sawmill_cost <= wood_resource

func is_fishing_station_build_allowed() -> bool:
	return fishing_station_cost <= wood_resource


func subtract_building_cost(building_action) -> void:
	match building_action:
		"house":
			wood_resource -= house_cost
		"road":
			wood_resource -= road_cost
		"field":
			wood_resource -= field_cost
		"pasture":
			wood_resource -= pasture_cost
		"sawmill":
			wood_resource -= sawmill_cost
		"fishing_station":
			wood_resource -= fishing_station_cost
	update_max_values()
	resources_changed.emit()


func get_people_coeff(people_on, pow_value) -> float:
	var people_coeff = 0.0
	for i in range(people_on):
		people_coeff += pow(pow_value, i)
	return snapped(people_coeff, 0.1)

func get_wood_production() -> float:
	return snapped(base_wood_income * get_people_coeff(people_on_wood, people_on_wood_eff) * wood_season_mod, 0.1)

func handle_wood_production() -> void:
	if ground.current_to_cut_tree == null:
		return
	if people_on_wood == 0:
		return

	wood_resource += get_wood_production()
	ground.remove_to_cut_tree()
	

func get_plant_food_production() -> float:
	return snapped(base_plant_food_income * get_people_coeff(people_on_plant, people_on_plant_eff) * ground.field_amount * plant_season_mod, 0.1)

func get_animal_food_production() -> float:
	return snapped(base_animal_food_income * get_people_coeff(people_on_animal, people_on_animal_eff) * ground.pasture_amount * animal_season_mod, 0.1)

func handle_food_production() -> void:
	plant_food_resource += get_plant_food_production()
	animal_food_resource += get_animal_food_production()


func get_fish_production() -> float:
	return snapped(base_fish_food_income * get_people_coeff(people_on_fish, people_on_fish_eff) * ground.get_water_bonus() * fish_season_mod, 0.1)

func handle_fish_production() -> void:
	if ground.get_current_water_cluster() == null:
		return
	if people_on_fish == 0:
		return

	animal_food_resource += get_fish_production()
	ground.lock_water()


func change_good_diet_base(value: float) -> void:
	base_good_diet_food_consumption += value
	people_diet_bases_changed.emit()

func change_normal_diet_base(value: float) -> void:
	base_normal_diet_food_consumption += value
	people_diet_bases_changed.emit()

func change_diet_base(value: float) -> void:
	base_saving_diet_food_consumption += value
	people_diet_bases_changed.emit()

func set_diet_to_good() -> void:
	current_food_consumpton = base_good_diet_food_consumption
	current_base_human_progress = base_good_diet_mult
	resources_changed.emit()

func set_diet_to_normal() -> void:
	current_food_consumpton = base_normal_diet_food_consumption
	current_base_human_progress = base_normal_diet_mult
	resources_changed.emit()

func set_diet_to_saving() -> void:
	current_food_consumpton = base_saving_diet_food_consumption
	current_base_human_progress = base_saving_diet_mult
	resources_changed.emit()

func get_new_human_progress() -> int:
	return round(current_base_human_progress * human_resource * new_human_progress_mult)

func handle_new_human_progress() -> void:
	var progress = get_new_human_progress()
	if progress == 0:
		return
	
	current_human_progress += progress
	if current_human_progress >= needed_new_human_progress_value:
		var human_income = current_human_progress / needed_new_human_progress_value
		var clamped_current_human_progress = current_human_progress % needed_new_human_progress_value

		human_resource += human_income
		current_human_progress = clamped_current_human_progress

		people_changed.emit()
	new_human_progress_changed.emit()


func get_wood_consumption() -> float:
	return snapped(human_resource * base_wood_consumption, 0.1)

func is_enough_wood_consumption() -> bool:
	if current_season != Season.WINTER:
		return true
	if wood_resource >= get_wood_consumption():
		return true
	else:
		return false

func handle_wood_consumption() -> void:
	wood_resource -= get_wood_consumption()

	if wood_resource < 0:
		human_resource -= int(round(wood_resource / wood_penalty))
		people_changed.emit()

		wood_resource = 0


func get_total_food() -> float:
	return snapped(plant_food_resource + animal_food_resource, 0.1)

func get_good_diet_food_consumption() -> float:
	return snapped(human_resource * base_good_diet_food_consumption, 0.1)

func get_normal_diet_food_consumption() -> float:
	return snapped(human_resource * base_normal_diet_food_consumption, 0.1)

func get_saving_diet_food_consumption() -> float:
	return snapped(human_resource * base_saving_diet_food_consumption, 0.1)

func get_food_consumption() -> float:
	return snapped(human_resource * current_food_consumpton, 0.1)

func is_enough_food_consumption() -> bool:
	var total_food = get_total_food()
	var food_consumption = get_food_consumption()

	if total_food >= food_consumption:
		return true
	else:
		return false

func handle_food_consumption() -> void:
	var total_food = get_total_food()
	var food_consumption = get_food_consumption()

	if total_food >= food_consumption:
		if total_food > 0:
			var consumption_coeff = food_consumption / total_food
			
			var plant_to_take = snapped(plant_food_resource * consumption_coeff, 0.1)
			var animal_to_take = snapped(food_consumption - plant_to_take, 0.1)

			if animal_to_take > animal_food_resource:
				animal_to_take = animal_food_resource
				plant_to_take = snapped(food_consumption - animal_to_take, 0.1)

			plant_food_resource = max(0.0, snapped(plant_food_resource - plant_to_take, 0.1))
			animal_food_resource = max(0.0, snapped(animal_food_resource - animal_to_take, 0.1))
			
	else:
		var deficit = snapped(human_resource - total_food, 0.1)
		var loss = snapped(deficit / food_penalty, 0.1)
		
		human_resource = max(0.0, snapped(human_resource - loss, 0.1))
		people_changed.emit()
		
		plant_food_resource = 0.0
		animal_food_resource = 0.0


func process_season() -> void:
	match current_season:
		Season.SPRING:
			process_spring()
		Season.SUMMER:
			process_summer()
		Season.AUTUMN: 
			process_autumn()
		Season.WINTER: 
			process_winter()

func process_spring():
	handle_wood_production()
	handle_food_production()
	handle_fish_production()

	handle_new_human_progress()
	handle_food_consumption()


func process_summer():
	handle_wood_production()
	handle_food_production()
	handle_fish_production()

	handle_new_human_progress()
	handle_food_consumption()


func process_autumn():
	handle_wood_production()
	handle_food_production()
	handle_fish_production()

	handle_new_human_progress()
	handle_food_consumption()


func process_winter():
	handle_wood_production()
	handle_food_production()
	handle_fish_production()

	handle_new_human_progress()
	handle_wood_consumption()
	handle_food_consumption()


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
	SceneManager.load_scene("res://scenes/active_scenes/game.tscn")


func on_player_action_started() -> void:
	GameManager.is_build_allowed = true


func on_player_action_ended() -> void:
	GameManager.is_build_allowed = false


func get_player_action() -> void:
	player_action_started.emit()
	await time_ui.start_new_month
	player_action_ended.emit()


func start_first_month() -> void:
	resources_changed.emit()
	update_current_season()
	await get_tree().create_timer(1.0).timeout
	await get_player_action()
	turn_ended.emit()

func update_current_season() -> void:
	var month = month_count % 12
	var new_season
	if month >= 0 and month <= 2:
		new_season = Season.SPRING
		plant_season_mod = 1.0
		animal_season_mod = 1.0
		fish_season_mod = 1.0
		wood_season_mod = 1.0
	elif month >= 3 and month <= 5:
		new_season = Season.SUMMER
		plant_season_mod = 1.5
		animal_season_mod = 1.0
		fish_season_mod = 1.2
		wood_season_mod = 1.0
	elif month >= 6 and month <= 8:
		new_season = Season.AUTUMN
		plant_season_mod = 0.8
		animal_season_mod = 1.2
		fish_season_mod = 1.0
		wood_season_mod = 1.0
	elif month >= 9 and month <= 11:
		new_season = Season.WINTER
		plant_season_mod = 0.0
		animal_season_mod = 0.8
		fish_season_mod = 0.6
		wood_season_mod = 0.6
	
	if current_season != new_season:
		current_season = new_season
		season_changed.emit()

func on_end_month() -> void:
	update_current_season()
	process_season()

	clamp_resources()
	resources_changed.emit()
	if human_resource <= 0:
		game_over()

	month_count += 1
	update_current_season()

	await get_player_action()
	turn_ended.emit()


func _input(event) -> void:
	if event is InputEventMouseMotion:
		return
	if Input.is_action_just_pressed("reload_game_scene"):
		SceneManager.load_scene("res://scenes/active_scenes/game.tscn")
	if !GameManager.is_input_allowed:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		SFXManager.play_sound("menu_nav_button")
		get_tree().paused = true
		MenuUI.visible = true
