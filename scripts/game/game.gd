extends Node3D

@export var camera: Camera3D
@export var ground: Node3D

@export var human_resource = 4
@export var max_human_resource = 10
@export var wood_resource = 250
@export var max_wood_resource = 100
@export var plant_food_resource = 10
@export var animal_food_resource = 8
@export var max_food_resource = 30

var building_action = -999


func _input(_event):
	if Input.is_action_just_pressed("reload_game_scene"):
		SceneManager.change_scene("res://scenes/active_scenes/game.tscn")
