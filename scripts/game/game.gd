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


func end_month() -> void:
	month_count += 1
	turn_ended.emit(month_count)


func _input(_event):
	if Input.is_action_just_pressed("reload_game_scene"):
		SceneManager.change_scene("res://scenes/active_scenes/game.tscn")
