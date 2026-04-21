extends Control


@export_group("Links")
@export var game: Node3D
@export var ground: Node3D

@export_group("Wood UI")
@export var less_5_wood: Button
@export var less_wood: Button
@export var current_wood: Label
@export var more_wood: Button
@export var more_5_wood: Button

@export_group("Wood Formula")
@export var wood_base: Label
@export var wood_people: Label
@export var wood_season: Label
@export var wood_total: Label

@export_group("Plant UI")
@export var less_5_plant: Button
@export var less_plant: Button
@export var current_plant: Label
@export var more_plant: Button
@export var more_5_plant: Button

@export_group("Plant Formula")
@export var plant_base: Label
@export var plant_people: Label
@export var plant_fields: Label
@export var plant_season: Label
@export var plant_total: Label

@export_group("Animal UI")
@export var less_5_animal: Button
@export var less_animal: Button
@export var current_animal: Label
@export var more_animal: Button
@export var more_5_animal: Button

@export_group("Animal Formula")
@export var animal_base: Label
@export var animal_people: Label
@export var animal_pastures: Label
@export var animal_season: Label
@export var animal_total: Label

@export_group("Fish UI")
@export var less_5_fish: Button
@export var less_fish: Button
@export var current_fish: Label
@export var more_fish: Button
@export var more_5_fish: Button

@export_group("Fish Formula")
@export var fish_base: Label
@export var fish_people: Label
@export var fish_water_bonus: Label
@export var fish_season: Label
@export var fish_total: Label

@export_group("Formulas Info")
@export var wood_formula_info: PanelContainer
@export var plant_formula_info: PanelContainer
@export var animal_formula_info: PanelContainer
@export var fish_formula_info: PanelContainer

@export_group("Control UI")
@export var panel: PanelContainer
@export var open_close_button: Button


var tween: Tween
var active_tweens: Dictionary = {}
var initial_pos_x: float
var target_offset: float = 316.0
var is_open: bool = false


func _ready() -> void:
	initial_pos_x = self.position.x
	
	game.player_action_started.connect(on_player_action_started)
	game.player_action_ended.connect(on_player_action_ended)
	ground.builded.connect(on_builded)
	ground.active_tree_changed.connect(on_active_tree_changed)
	ground.active_water_changed.connect(on_active_water_changed)
	open_close_button.disabled = true

	init_formulas_info()
	update_all_formulas()

func init_formulas_info() -> void:
	var info_panels = [wood_formula_info, plant_formula_info, animal_formula_info, fish_formula_info]
	for p in info_panels:
		p.visible = false
		p.modulate.a = 0

func animate_info_panel(info_panel: Control, should_show: bool) -> void:
	if info_panel.visible == should_show and not active_tweens.has(info_panel):
		return
	
	if active_tweens.has(info_panel):
		active_tweens[info_panel].kill()
		active_tweens.erase(info_panel)

	var tw = create_tween().set_parallel(true)
	active_tweens[info_panel] = tw
	
	if should_show:
		info_panel.visible = true
		tw.tween_property(info_panel, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_property(info_panel, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.chain().step_finished.connect(func(_idx): 
			info_panel.visible = false
			active_tweens.erase(info_panel)
		)

func update_all_formulas() -> void:
	update_wood_formula()
	update_plant_formula()
	update_animal_formula()
	update_fish_formula()

func update_wood_formula() -> void:
	wood_base.text = str(game.base_wood_income)
	wood_people.text = " * " + str(game.get_people_coeff(game.people_on_wood))
	wood_season.text = " * " + str(game.wood_season_mod)
	wood_total.text = " = " + str(game.get_wood_production())

func update_plant_formula() -> void:
	plant_base.text = str(game.base_plant_food_income)
	plant_people.text = " * " + str(game.get_people_coeff(game.people_on_plant))
	plant_fields.text = " * " + str(ground.field_amount)
	plant_season.text = " * " + str(game.plant_season_mod)
	plant_total.text = " = " + str(game.get_plant_food_production())

func update_animal_formula() -> void:
	animal_base.text = str(game.base_animal_food_income)
	animal_people.text = " * " + str(game.get_people_coeff(game.people_on_animal))
	animal_pastures.text = " * " + str(ground.pasture_amount)
	animal_season.text = " * " + str(game.animal_season_mod)
	animal_total.text = " = " + str(game.get_animal_food_production())

func update_fish_formula() -> void:
	fish_base.text = str(game.base_fish_food_income)
	fish_people.text = " * " + str(game.get_people_coeff(game.people_on_fish))
	fish_water_bonus.text = " * " + str(ground.get_water_bonus())
	fish_season.text = " * " + str(game.fish_season_mod)
	fish_total.text = " = " + str(game.get_fish_production())

func change_resource(resource_name: String, amount: int) -> void:
	var prop_name = "people_on_" + resource_name
	var current_val: int = game.get(prop_name)
	game.set(prop_name, current_val + amount)
	update_all_buttons()

func update_all_buttons() -> void:
	current_wood.text = str(game.people_on_wood)
	current_plant.text = str(game.people_on_plant)
	current_animal.text = str(game.people_on_animal)
	current_fish.text = str(game.people_on_fish)
	
	check_all_buttons()

func check_all_buttons() -> void:
	var total = game.people_on_wood + game.people_on_plant + game.people_on_animal + game.people_on_fish
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


func on_player_action_started() -> void:
	update_all_buttons()
	open_close_button.disabled = false

func on_player_action_ended() -> void:
	open_close_button.disabled = true
	if is_open:
		is_open = !is_open
		move_panel(initial_pos_x)


func on_builded(_build_index) -> void:
	update_plant_formula()
	update_animal_formula()

func on_active_tree_changed() -> void:
	update_wood_formula()

func on_active_water_changed() -> void:
	update_fish_formula() 


func _on_less_5_wood_pressed() -> void: 
	change_resource("wood", -5)
	update_wood_formula()
func _on_less_wood_pressed() -> void: 
	change_resource("wood", -1)
	update_wood_formula()
func _on_more_wood_pressed() -> void: 
	change_resource("wood", 1)
	update_wood_formula()
func _on_more_5_wood_pressed() -> void: 
	change_resource("wood", 5)
	update_wood_formula()

func _on_less_5_plant_pressed() -> void:
	change_resource("plant", -5)
	update_plant_formula()
func _on_less_plant_pressed() -> void:
	change_resource("plant", -1)
	update_plant_formula()
func _on_more_plant_pressed() -> void:
	change_resource("plant", 1)
	update_plant_formula()
func _on_more_5_plant_pressed() -> void:
	change_resource("plant", 5)
	update_plant_formula()

func _on_less_5_animal_pressed() -> void:
	change_resource("animal", -5)
	update_animal_formula()
func _on_less_animal_pressed() -> void:
	change_resource("animal", -1)
	update_animal_formula()
func _on_more_animal_pressed() -> void:
	change_resource("animal", 1)
	update_animal_formula()
func _on_more_5_animal_pressed() -> void:
	change_resource("animal", 5)
	update_animal_formula()

func _on_less_5_fish_pressed() -> void: 
	change_resource("fish", -5)
	update_fish_formula()
func _on_less_fish_pressed() -> void: 
	change_resource("fish", -1)
	update_fish_formula()
func _on_more_fish_pressed() -> void: 
	change_resource("fish", 1)
	update_fish_formula()
func _on_more_5_fish_pressed() -> void: 
	change_resource("fish", 5)
	update_fish_formula()

func move_panel(target_x: float) -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", target_x, 0.3)

func _on_open_close_pressed() -> void:
	is_open = !is_open
	
	if is_open:
		move_panel(initial_pos_x + target_offset)
	else:
		move_panel(initial_pos_x)


func _on_wood_formula_mouse_entered() -> void: animate_info_panel(wood_formula_info, true)
func _on_wood_formula_mouse_exited() -> void: animate_info_panel(wood_formula_info, false)

func _on_plant_formula_mouse_entered() -> void: animate_info_panel(plant_formula_info, true)
func _on_plant_formula_mouse_exited() -> void: animate_info_panel(plant_formula_info, false)

func _on_animal_formula_mouse_entered() -> void: animate_info_panel(animal_formula_info, true)
func _on_animal_formula_mouse_exited() -> void: animate_info_panel(animal_formula_info, false)

func _on_fish_formula_mouse_entered() -> void: animate_info_panel(fish_formula_info, true)
func _on_fish_formula_mouse_exited() -> void: animate_info_panel(fish_formula_info, false)