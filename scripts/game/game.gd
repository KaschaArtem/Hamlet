extends Node3D

@export var camera: Camera3D
@export var ground: Node3D

signal resources_changed

@export var house_cost: int = 40
@export var field_cost: int = 24
@export var pasture_cost: int = 32

@export var human_resource = 4
@export var max_human_resource = 10
@export var wood_resource = 250
@export var max_wood_resource = 100
@export var plant_food_resource = 10
@export var animal_food_resource = 8
@export var max_food_resource = 30

var building_action = -999


func is_house_build_allowed() -> bool:
	if house_cost <= wood_resource:
		wood_resource -= house_cost
		resources_changed.emit()
		return true
	return false
func is_field_build_allowed() -> bool:
	if field_cost <= wood_resource:
		wood_resource -= field_cost
		resources_changed.emit()
		return true
	return false
func is_pasture_build_allowed() -> bool:
	if pasture_cost <= wood_resource:
		wood_resource -= pasture_cost
		resources_changed.emit()
		return true
	return false


func _input(_event):
	if Input.is_action_just_pressed("reload_game_scene"):
		SceneManager.change_scene("res://scenes/active_scenes/game.tscn")
