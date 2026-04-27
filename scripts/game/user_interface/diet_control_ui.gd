extends Control


@export_group("Links")
@export var game: Node3D
@export var people_control_ui: Control

@export_group("Good Diet")
@export var good_diet_button: Button
@export var good_diet_amount_label: Label
@export var good_diet_total_label: Label

@export_group("Normal Diet")
@export var normal_diet_button: Button
@export var normal_diet_amount_label: Label
@export var normal_diet_total_label: Label

@export_group("Saving Diet")
@export var saving_diet_button: Button
@export var saving_diet_amount_label: Label
@export var saving_diet_total_label: Label

@export_group("Formula")
@export var progress_formula: HBoxContainer
@export var base: Label
@export var people: Label
@export var progress_mult: Label
@export var total: Label

@export_group("Human Progress")
@export var current_progress_label: Label
@export var needed_progress_label: Label
@export var progress_bar: HSlider

@export_group("Formula Info")
@export var progress_formula_info: PanelContainer

@export_group("Control UI")
@export var panel: PanelContainer
@export var open_close_button: Button


var tween: Tween
var info_panel_tween: Tween
var initial_pos_x: float
var target_offset: float = 196.0
var is_open: bool = false


func _ready() -> void:
	initial_pos_x = self.position.x

	game.player_action_started.connect(on_player_action_started)
	game.player_action_ended.connect(on_player_action_ended)
	game.people_diet_bases_changed.connect(on_people_diet_bases_changed)
	game.people_changed.connect(on_people_changed)
	game.new_human_progress_changed.connect(on_new_human_progress_changed)
	
	open_close_button.disabled = true
	progress_formula_info.modulate.a = 0.0

	_init_info()


func _init_info() -> void:
	_on_normal_diet_button_pressed()
	_update_bases()
	_update_total()


func on_player_action_started() -> void:
	open_close_button.disabled = false

func on_player_action_ended() -> void:
	open_close_button.disabled = true
	if is_open:
		is_open = !is_open
		move_panel(initial_pos_x)


func _update_bases() -> void:
	good_diet_amount_label.text = str(game.base_good_diet_food_consumption)
	normal_diet_amount_label.text = str(game.base_normal_diet_food_consumption)
	saving_diet_amount_label.text = str(game.base_saving_diet_food_consumption)
	progress_mult.text = " * " + str(game.new_human_progress_mult)
	needed_progress_label.text = str(game.needed_new_human_progress_value)
	progress_bar.max_value = game.needed_new_human_progress_value

func _update_total() -> void:
	good_diet_total_label.text = str(game.get_good_diet_food_consumption())
	normal_diet_total_label.text = str(game.get_normal_diet_food_consumption())
	saving_diet_total_label.text = str(game.get_saving_diet_food_consumption())

func _update_formula() -> void:
	base.text = str(game.current_base_human_progress)
	people.text = " * " + str(game.human_resource)
	total.text = " ≈ " + str(game.get_new_human_progress())

func _update_new_human_progress() -> void:
	current_progress_label.text = str(game.current_human_progress)
	progress_bar.value = game.current_human_progress


func on_people_diet_bases_changed() -> void:
	_update_bases()
	_update_total()
	_update_formula()

func on_people_changed() -> void:
	_update_total()
	_update_formula()

func on_new_human_progress_changed() -> void:
	_update_new_human_progress()


func move_panel(target_x: float) -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", target_x, 0.186)

func disable_on_open() -> void:
	if is_open:
		move_panel(initial_pos_x)
		is_open = !is_open
	open_close_button.visible = false
	
func enable_on_close() -> void:
	open_close_button.visible = true

func _on_open_close_pressed() -> void:
	is_open = !is_open
	
	if is_open:
		move_panel(initial_pos_x + target_offset)
		people_control_ui.disable_on_open()
	else:
		move_panel(initial_pos_x)
		people_control_ui.enable_on_close()


func _on_good_diet_button_pressed() -> void:
	good_diet_button.disabled = true
	normal_diet_button.disabled = false
	saving_diet_button.disabled = false
	game.set_diet_to_good()
	_update_formula()

func _on_normal_diet_button_pressed() -> void:
	good_diet_button.disabled = false
	normal_diet_button.disabled = true
	saving_diet_button.disabled = false
	game.set_diet_to_normal()
	_update_formula()

func _on_saving_diet_button_pressed() -> void:
	good_diet_button.disabled = false
	normal_diet_button.disabled = false
	saving_diet_button.disabled = true
	game.set_diet_to_saving()
	_update_formula()


func animate_info_panel(should_show: bool) -> void:
	if info_panel_tween:
		info_panel_tween.kill()

	info_panel_tween = create_tween()
	
	if should_show:
		progress_formula_info.visible = true
		info_panel_tween.tween_property(progress_formula_info, "modulate:a", 1.0, 0.3)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)
	else:
		info_panel_tween.tween_property(progress_formula_info, "modulate:a", 0.0, 0.2)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_IN)
		info_panel_tween.tween_callback(func(): progress_formula_info.visible = false)

func _on_progress_formula_mouse_entered() -> void:
	animate_info_panel(true)

func _on_progress_formula_mouse_exited() -> void:
	animate_info_panel(false)


func _on_panel_container_mouse_exited() -> void:
	GameManager.is_ui_hovered = false

func _on_panel_container_mouse_entered() -> void:
	GameManager.is_ui_hovered = true

func _on_open_close_mouse_exited() -> void:
	GameManager.is_ui_hovered = false

func _on_open_close_mouse_entered() -> void:
	GameManager.is_ui_hovered = true
