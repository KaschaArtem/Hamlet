extends Control


@export var game: Node3D

@export var less_wood: Button
@export var current_wood: Label
@export var more_wood: Button
@export var less_plant: Button
@export var current_plant: Label
@export var more_plant: Button
@export var less_animal: Button
@export var current_animal: Label
@export var more_animal: Button


func _ready() -> void:
	game.player_action_started.connect(on_player_action_started)
	game.player_action_ended.connect(on_player_action_ended)
	self.visible = false


func update_current_wood() -> void:
	current_wood.text = str(game.people_on_wood)
func update_current_plant() -> void:
	current_plant.text = str(game.people_on_plant)
func update_current_animal() -> void:
	current_animal.text = str(game.people_on_animal)

func init_update_values() -> void:
	current_wood.text = str(game.people_on_wood)
	current_plant.text = str(game.people_on_plant)
	current_animal.text = str(game.people_on_animal)

func disable_more_assignment() -> void:
	more_wood.disabled = true
	more_plant.disabled = true
	more_animal.disabled = true
func enable_more_assignment() -> void:
	more_wood.disabled = false
	more_plant.disabled = false
	more_animal.disabled = false

func disable_all_assignment() -> void:
	less_wood.disabled = true
	less_plant.disabled = true
	less_animal.disabled = true
	more_wood.disabled = true
	more_plant.disabled = true
	more_animal.disabled = true

func check_less_wood_button() -> void:
	if game.people_on_wood == 0:
		less_wood.disabled = true
	else:
		less_wood.disabled = false
func check_less_plant_button() -> void:
	if game.people_on_plant == 0:
		less_plant.disabled = true
	else:
		less_plant.disabled = false
func check_less_animal_button() -> void:
	if game.people_on_animal == 0:
		less_animal.disabled = true
	else:
		less_animal.disabled = false
func check_more_buttons() -> void:
	if (game.people_on_wood + game.people_on_plant + game.people_on_animal) == game.human_resource:
		disable_more_assignment()
	else:
		enable_more_assignment()

func on_player_action_started() -> void:
	var people_on_wood = game.people_on_wood
	var people_on_plant = game.people_on_plant
	var people_on_animal = game.people_on_animal
	var total_working = people_on_wood + people_on_plant + people_on_animal
	var overload = total_working - game.human_resource
	
	if overload > 0:
		for i in range(overload):
			continue
	
	game.people_on_wood = people_on_wood
	game.people_on_plant = people_on_plant
	game.people_on_animal = people_on_animal
	init_update_values()
	
	check_less_wood_button()
	check_less_plant_button()
	check_less_animal_button()
	check_more_buttons()
	
	self.visible = true


func on_player_action_ended() -> void:
	disable_all_assignment()
	self.visible = false


func _on_less_wood_pressed() -> void:
	game.people_on_wood -= 1
	update_current_wood()
	check_less_wood_button()
	check_more_buttons()


func _on_more_wood_pressed() -> void:
	game.people_on_wood += 1
	update_current_wood()
	check_less_wood_button()
	check_more_buttons()


func _on_less_plant_pressed() -> void:
	game.people_on_plant -= 1
	update_current_plant()
	check_less_plant_button()
	check_more_buttons()


func _on_more_plant_pressed() -> void:
	game.people_on_plant += 1
	update_current_plant()
	check_less_plant_button()
	check_more_buttons()


func _on_less_animal_pressed() -> void:
	game.people_on_animal -= 1
	update_current_animal()
	check_less_animal_button()
	check_more_buttons()


func _on_more_animal_pressed() -> void:
	game.people_on_animal += 1
	update_current_animal()
	check_less_animal_button()
	check_more_buttons()
