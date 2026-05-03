extends Control


@export var game: Node3D

const BASE_RESOURCES_INFO = {
	"people": "You can allocate PEOPLE to do certain work. The more PEOPLE you allocate at one work, the more efficient this work will be.",
	"wood": "Resource for build. On winter will be used to warm up PEOPLE ({0} WOOD per HUMAN). Consumption counts AFTER production.",
	"food": "Resource for PEOPLE's sustenance. If not enough, PEOPLE will die. Consumption counts AFTER production."
}

var PENALTIES_INFO = {
	"wood": "\nIf PEOPLE will not burn {0} of WOOD to the end of the month, at least 1 human will die.\nBase WOOD PENALTY: {1}",
	"food": "\nIf PEOPLE will not eat {0} of FOOD to the end of the month, at least 1 human will die.\nBase FOOD PENALTY: {1}"
}

@export var actual_people: Label
@export var max_people: Label
@export var actual_wood: Label
@export var max_wood: Label
@export var actual_plant_food: Label
@export var actual_animal_food: Label
@export var max_food: Label

@export_group("Info Nodes")
@export var people_info: Control
@export var wood_info: Control
@export var food_info: Control

@export var people_info_label: Label
@export var wood_info_label: Label
@export var food_info_label: Label

var active_tweens: Dictionary = {}

func _ready() -> void:
	game.player_action_started.connect(on_player_action_started)
	game.resources_changed.connect(update_resources)
	update_info_tabs()
	update_resources()

	for node in [people_info, wood_info, food_info]:
		node.visible = false
		node.modulate.a = 0
		node.pivot_offset = node.size / 2


func on_player_action_started() -> void:
	update_info_tabs()


func update_info_tabs() -> void:
	people_info_label.text = BASE_RESOURCES_INFO["people"]
	if game.current_season == game.Season.WINTER:
		wood_info_label.text = BASE_RESOURCES_INFO["wood"].format([game.base_wood_consumption]) + PENALTIES_INFO["wood"].format([snapped((game.wood_penalty - game.current_wood_penalty), 0.1), game.wood_penalty])
		food_info_label.text = BASE_RESOURCES_INFO["food"] + PENALTIES_INFO["food"].format([snapped((game.food_penalty - game.current_food_penalty), 0.1), game.food_penalty])
	else:
		wood_info_label.text = BASE_RESOURCES_INFO["wood"].format([game.base_wood_consumption])
		food_info_label.text = BASE_RESOURCES_INFO["food"] + PENALTIES_INFO["food"].format([snapped((game.food_penalty - game.current_food_penalty), 0.1), game.food_penalty])

func update_resources() -> void:
	actual_people.text = str(game.human_resource)
	max_people.text = str(game.max_human_resource)
	actual_wood.text = str(game.wood_resource)
	max_wood.text = str(game.max_wood_resource)
	actual_plant_food.text = str(game.plant_food_resource)
	actual_animal_food.text = str(game.animal_food_resource)
	max_food.text = str(game.max_food_resource)


func fade_node(node: Control, is_showing: bool) -> void:
	if active_tweens.has(node):
		active_tweens[node].kill()
	
	var tween = create_tween()
	active_tweens[node] = tween
	
	if is_showing:
		node.visible = true
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "modulate:a", 1.0, 0.15)
	else:
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(node, "modulate:a", 0.0, 0.1)
		tween.finished.connect(func(): node.visible = false)


func _on_people_mouse_entered() -> void:
	fade_node(people_info, true)

func _on_people_mouse_exited() -> void:
	fade_node(people_info, false)

func _on_wood_mouse_entered() -> void:
	fade_node(wood_info, true)

func _on_wood_mouse_exited() -> void:
	fade_node(wood_info, false)

func _on_food_mouse_entered() -> void:
	fade_node(food_info, true)

func _on_food_mouse_exited() -> void:
	fade_node(food_info, false)
