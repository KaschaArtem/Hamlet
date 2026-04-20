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
@export var field_cost: float = 24.0
@export var pasture_cost: float = 32.0

@export_group("Base Income")
@export var base_wood_income: float = 15.0
@export var base_plant_food_income: float = 3.0
@export var base_animal_food_income: float = 3.0
@export var base_fish_food_income: float = 1.0

@export_group("Death Penalty")
@export var wood_penalty: float = 5.0
@export var food_penalty: float = 1.0

@export_group("Start Resources")
@export var start_human_resource = 4
@export var start_wood_resource = 80
@export var start_plant_food_resource = 10
@export var start_animal_food_resource = 8

signal resources_changed
signal player_action_started
signal player_action_ended
signal turn_ended

var TILES_INFO = {
	"house": ["House", "Increase max amount of PEOPLE, WOOD, FOOD. Increase resource income, when stands near resource tile."],
	"field": ["Field", "Produce plant food. Doesn't work on winter."],
	"pasture": ["Pasture", "Produce animal food. Works less efficient on winter."],
	"tree": ["Tree", "Cut to get WOOD. Press F on this tile to choose this tree for cutting during next month. Tree tile will desappeared after this."],
	"water": ["Water", "Used for fishing. Press F on water cluster to choose it for fishing during next month. This will take some fish from this water cluster."]
}

var human_resource : int = start_human_resource
var wood_resource : float = start_wood_resource
var plant_food_resource : float = start_plant_food_resource
var animal_food_resource : float = start_animal_food_resource

var max_human_resource
var max_wood_resource
var max_food_resource

var people_on_wood: int = 0
var people_on_plant: int = 0
var people_on_animal: int = 0
var people_on_fish: int = 0

var month_count = 0
var start_next_month: bool = false

var plant_season_mod := 1.0
var animal_season_mod := 1.0
var fish_season_mod := 1.0
var hunt_season_mod := 1.0
var wood_season_mod := 1.0


func update_max_values() -> void:
	max_human_resource = ground.house_amount * house_human_capacity + main_tile_human_capacity
	max_wood_resource = ground.house_amount * house_wood_capacity + main_tile_wood_capacity
	max_food_resource = ground.house_amount * house_food_capacity + main_tile_food_capacity


func _ready() -> void:
	player_action_started.connect(on_player_action_started)
	player_action_ended.connect(on_player_action_ended)
	ground.builded.connect(on_builded)
	timer.end_month.connect(on_end_month)
	update_max_values()
	start_first_month()


func is_house_build_allowed() -> bool:
	return house_cost <= wood_resource


func is_field_build_allowed() -> bool:
	return field_cost <= wood_resource


func is_pasture_build_allowed() -> bool:
	return pasture_cost <= wood_resource


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
	if people_on_wood <= 0:
		return
	if ground.current_to_cut_tree == null:
		return
	ground.remove_to_cut_tree()

	var production = base_wood_income * people_on_wood * wood_season_mod

	wood_resource += round(production * 10) / 10.0


func calculate_food_production() -> void:
	
	var plant_prod = base_plant_food_income * people_on_plant * ground.field_amount * plant_season_mod
	var animal_prod = base_animal_food_income * people_on_animal * ground.pasture_amount * animal_season_mod
	
	plant_food_resource += round(plant_prod * 10) / 10.0
	animal_food_resource += round(animal_prod * 10) / 10.0


func calculate_fish_production() -> void:
	if people_on_fish <= 0:
		return
	if ground.current_water_cluster == null:
		return
	
	var production = ground.count_fish_decreasement(base_fish_food_income * people_on_fish * fish_season_mod)

	animal_food_resource += round(production * 10) / 10.0

func get_effective_workers(workers: int, capacity: int, k: float = 2.0) -> float:
	if capacity <= 0:
		return 0.0
	
	var w = float(workers)
	var c = float(capacity)

	return (w * c) / (c + k * w) * 2

func calculate_wood_consumption(multiplier: float) -> void:

	wood_resource -= round(human_resource * 0.5 * multiplier * 10) / 10.0

	if wood_resource < 0:
		human_resource -= int(round(wood_resource / wood_penalty))
		wood_resource = 0


func calculate_food_consumption() -> void:
	var total_food = snapped(plant_food_resource + animal_food_resource, 0.1)
	
	if total_food >= human_resource:
		if total_food > 0:
			var consumption_coeff = human_resource / total_food
			
			var plant_to_take = snapped(plant_food_resource * consumption_coeff, 0.1)
			var animal_to_take = snapped(human_resource - plant_to_take, 0.1)

			if animal_to_take > animal_food_resource:
				animal_to_take = animal_food_resource
				plant_to_take = snapped(human_resource - animal_to_take, 0.1)

			plant_food_resource = max(0.0, snapped(plant_food_resource - plant_to_take, 0.1))
			animal_food_resource = max(0.0, snapped(animal_food_resource - animal_to_take, 0.1))
			
	else:
		var deficit = snapped(human_resource - total_food, 0.1)
		var loss = snapped(deficit / food_penalty, 0.1)
		
		human_resource = max(0.0, snapped(human_resource - loss, 0.1))
		
		plant_food_resource = 0.0
		animal_food_resource = 0.0



func process_spring():
	plant_season_mod = 1.0
	animal_season_mod = 1.0
	fish_season_mod = 1.0
	wood_season_mod = 1.0

	calculate_wood_production()
	calculate_food_production()
	calculate_fish_production()

	calculate_food_consumption()


func process_summer():
	plant_season_mod = 1.5
	animal_season_mod = 1.0
	fish_season_mod = 1.2
	wood_season_mod = 1.0

	calculate_wood_production()
	calculate_food_production()
	calculate_fish_production()

	calculate_food_consumption()


func process_autumn():
	plant_season_mod = 0.8
	animal_season_mod = 1.2
	fish_season_mod = 1.0
	wood_season_mod = 1.0

	calculate_wood_production()
	calculate_food_production()
	calculate_fish_production()

	calculate_food_consumption()


func process_winter():
	plant_season_mod = 0.0
	animal_season_mod = 0.8
	fish_season_mod = 0.6
	wood_season_mod = 0.6

	calculate_wood_production()
	calculate_food_production()
	calculate_fish_production()

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
	await get_player_action()
	turn_ended.emit()


func on_end_month() -> void:
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
	resources_changed.emit()
	if human_resource <= 0:
		game_over()

	month_count += 1

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
