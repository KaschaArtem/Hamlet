extends Control


@export var game: Node3D

@export var actual_people: Label
@export var max_people: Label
@export var actual_wood: Label
@export var max_wood: Label
@export var actual_plant_food: Label
@export var actual_animal_food: Label
@export var max_food: Label


func _ready() -> void:
	game.resources_changed.connect(update_resources)
	update_resources()

func update_resources() -> void:
	actual_people.text = str(game.human_resource)
	max_people.text = str(game.max_human_resource)
	actual_wood.text = str(game.wood_resource)
	max_wood.text = str(game.max_wood_resource)
	actual_plant_food.text = str(game.plant_food_resource)
	actual_animal_food.text = str(game.animal_food_resource)
	max_food.text = str(game.max_food_resource)
