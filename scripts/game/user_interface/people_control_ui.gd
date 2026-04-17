extends Control


@export var game: Node3D


@export_group("Wood UI")
@export var less_5_wood: Button
@export var less_wood: Button
@export var current_wood: Label
@export var more_wood: Button
@export var more_5_wood: Button

@export_group("Plant UI")
@export var less_5_plant: Button
@export var less_plant: Button
@export var current_plant: Label
@export var more_plant: Button
@export var more_5_plant: Button

@export_group("Animal UI")
@export var less_5_animal: Button
@export var less_animal: Button
@export var current_animal: Label
@export var more_animal: Button
@export var more_5_animal: Button

@export_group("Fish UI")
@export var less_5_fish: Button
@export var less_fish: Button
@export var current_fish: Label
@export var more_fish: Button
@export var more_5_fish: Button

@export_group("Hunt UI")
@export var less_5_hunt: Button
@export var less_hunt: Button
@export var current_hunt: Label
@export var more_hunt: Button
@export var more_5_hunt: Button

@export_group("Panels")
@export var panel_main: Panel
@export var panel_sub: Panel


var initial_pos_x: float
var current_target_x: float
var target_offset: float = 316.0


func _ready() -> void:
	initial_pos_x = self.position.x
	current_target_x = initial_pos_x
	
	game.player_action_started.connect(on_player_action_started)
	game.player_action_ended.connect(on_player_action_ended)
	self.visible = false

func change_resource(resource_name: String, amount: int) -> void:
	var prop_name = "people_on_" + resource_name
	var current_val: int = game.get(prop_name)
	var total_assigned = game.people_on_wood + game.people_on_plant + game.people_on_animal + game.people_on_fish + game.people_on_hunt
	var available_people = game.human_resource - total_assigned
	
	var final_change = clamp(amount, -current_val, available_people)
	game.set(prop_name, current_val + final_change)
	
	update_all_ui()

func update_all_ui() -> void:
	current_wood.text = str(game.people_on_wood)
	current_plant.text = str(game.people_on_plant)
	current_animal.text = str(game.people_on_animal)
	current_fish.text = str(game.people_on_fish)
	current_hunt.text = str(game.people_on_hunt)
	
	check_all_buttons()

func check_all_buttons() -> void:
	var total = game.people_on_wood + game.people_on_plant + game.people_on_animal + game.people_on_fish + game.people_on_hunt
	var full = total >= game.human_resource
	
	less_wood.disabled = game.people_on_wood <= 0
	less_5_wood.disabled = game.people_on_wood <= 0
	more_wood.disabled = full
	more_5_wood.disabled = full
	
	less_plant.disabled = game.people_on_plant <= 0
	less_5_plant.disabled = game.people_on_plant <= 0
	more_plant.disabled = full
	more_5_plant.disabled = full
	
	less_animal.disabled = game.people_on_animal <= 0
	less_5_animal.disabled = game.people_on_animal <= 0
	more_animal.disabled = full
	more_5_animal.disabled = full
	
	less_fish.disabled = game.people_on_fish <= 0
	less_5_fish.disabled = game.people_on_fish <= 0
	more_fish.disabled = full
	more_5_fish.disabled = full
	
	less_hunt.disabled = game.people_on_hunt <= 0
	less_5_hunt.disabled = game.people_on_hunt <= 0
	more_hunt.disabled = full
	more_5_hunt.disabled = full


func _process(delta: float) -> void:
	if not self.visible:
		return

	var mouse_pos = get_global_mouse_position()
	var is_hovering = panel_main.get_global_rect().has_point(mouse_pos) or \
					  panel_sub.get_global_rect().has_point(mouse_pos)

	if is_hovering:
		current_target_x = initial_pos_x + target_offset
	else:
		current_target_x = initial_pos_x

	self.position.x = lerp(self.position.x, current_target_x, 15.0 * delta)


func on_player_action_started() -> void:
	update_all_ui()
	self.visible = true

func on_player_action_ended() -> void:
	self.visible = false


func _on_less_5_wood_pressed() -> void: change_resource("wood", -5)
func _on_less_wood_pressed() -> void: change_resource("wood", -1)
func _on_more_wood_pressed() -> void: change_resource("wood", 1)
func _on_more_5_wood_pressed() -> void: change_resource("wood", 5)

func _on_less_5_plant_pressed() -> void: change_resource("plant", -5)
func _on_less_plant_pressed() -> void: change_resource("plant", -1)
func _on_more_plant_pressed() -> void: change_resource("plant", 1)
func _on_more_5_plant_pressed() -> void: change_resource("plant", 5)

func _on_less_5_animal_pressed() -> void: change_resource("animal", -5)
func _on_less_animal_pressed() -> void: change_resource("animal", -1)
func _on_more_animal_pressed() -> void: change_resource("animal", 1)
func _on_more_5_animal_pressed() -> void: change_resource("animal", 5)

func _on_less_5_fish_pressed() -> void: change_resource("fish", -5)
func _on_less_fish_pressed() -> void: change_resource("fish", -1)
func _on_more_fish_pressed() -> void: change_resource("fish", 1)
func _on_more_5_fish_pressed() -> void: change_resource("fish", 5)

func _on_less_5_hunt_pressed() -> void: change_resource("hunt", -5)
func _on_less_hunt_pressed() -> void: change_resource("hunt", -1)
func _on_more_hunt_pressed() -> void: change_resource("hunt", 1)
func _on_more_5_hunt_pressed() -> void: change_resource("hunt", 5)