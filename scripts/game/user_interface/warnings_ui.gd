extends Control


@export_group("Links")
@export var game: Node3D
@export var ground: Node3D

@export_group("Warnings")
@export var people_starving: PanelContainer
@export var people_freezing: PanelContainer
@export var assign_logging: PanelContainer
@export var assign_fishing: PanelContainer
@export var choose_tree: PanelContainer
@export var choose_water: PanelContainer

@export_group("Warnings Info")
@export var people_starving_info: PanelContainer
@export var people_freezing_info: PanelContainer
@export var assign_logging_info: PanelContainer
@export var assign_fishing_info: PanelContainer
@export var choose_tree_info: PanelContainer
@export var choose_water_info: PanelContainer


var active_tweens: Dictionary = {}
var original_x_position: float


func _ready() -> void:
	original_x_position = position.x
	
	game.player_action_started.connect(on_player_action_started)
	game.player_action_ended.connect(on_player_action_ended)
	game.people_assignment_changed.connect(on_people_assignment_changed)
	game.resources_changed.connect(on_resources_changed)
	ground.active_tree_changed.connect(on_active_tree_changed)
	ground.active_water_changed.connect(on_active_water_changed)
	init_hide()

func init_hide() -> void:
	var all_panels = [
		people_starving, people_freezing, assign_logging, 
		assign_fishing, choose_tree, choose_water,
		people_starving_info, people_freezing_info, assign_logging_info,
		assign_fishing_info, choose_tree_info, choose_water_info
	]
	for panel in all_panels:
		panel.visible = false
		panel.modulate.a = 0
		panel.scale = Vector2.ONE

func animate_warning(panel: Control, should_show: bool, use_scale: bool = true) -> void:
	if panel.visible == should_show and not active_tweens.has(panel):
		return
	
	if active_tweens.has(panel):
		active_tweens[panel].kill()
		active_tweens.erase(panel)

	panel.pivot_offset = panel.size / 2
	
	var tween = create_tween().set_parallel(true)
	active_tweens[panel] = tween
	
	if should_show:
		panel.visible = true
		tween.tween_property(panel, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if use_scale:
			tween.tween_property(panel, "scale", Vector2.ONE, 0.3).from(Vector2(0.8, 0.8)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			panel.scale = Vector2.ONE
	else:
		tween.tween_property(panel, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		if use_scale:
			tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		
		tween.chain().step_finished.connect(func(_idx): 
			panel.visible = false
			active_tweens.erase(panel)
		)

func on_player_action_started() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position:x", original_x_position, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func on_player_action_ended() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position:x", original_x_position + 150, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func _on_people_starving_mouse_entered() -> void: animate_warning(people_starving_info, true, false)
func _on_people_starving_mouse_exited() -> void: animate_warning(people_starving_info, false, false)

func _on_people_freezing_mouse_entered() -> void: animate_warning(people_freezing_info, true, false)
func _on_people_freezing_mouse_exited() -> void: animate_warning(people_freezing_info, false, false)

func _on_assign_logging_mouse_entered() -> void: animate_warning(assign_logging_info, true, false)
func _on_assign_logging_mouse_exited() -> void: animate_warning(assign_logging_info, false, false)

func _on_assign_fishing_mouse_entered() -> void: animate_warning(assign_fishing_info, true, false)
func _on_assign_fishing_mouse_exited() -> void: animate_warning(assign_fishing_info, false, false)

func _on_choose_tree_mouse_entered() -> void: animate_warning(choose_tree_info, true, false)
func _on_choose_tree_mouse_exited() -> void: animate_warning(choose_tree_info, false, false)

func _on_choose_water_mouse_entered() -> void: animate_warning(choose_water_info, true, false)
func _on_choose_water_mouse_exited() -> void: animate_warning(choose_water_info, false, false)

func check_people_starving() -> void:
	animate_warning(people_starving, !game.is_enough_food_consumption())

func check_people_freezing() -> void:
	animate_warning(people_freezing, !game.is_enough_wood_consumption())

func check_assign_logging() -> void:
	animate_warning(assign_logging, game.people_on_wood == 0 and ground.current_to_cut_tree != null)

func check_assign_fishing() -> void:
	animate_warning(assign_fishing, game.people_on_fish == 0 and ground.get_current_water_cluster() != null)

func check_choose_tree() -> void:
	animate_warning(choose_tree, game.people_on_wood > 0 and ground.current_to_cut_tree == null)

func check_choose_water() -> void:
	animate_warning(choose_water, game.people_on_fish > 0 and ground.get_current_water_cluster() == null)

func on_people_assignment_changed() -> void:
	check_assign_logging()
	check_assign_fishing()
	check_choose_tree()
	check_choose_water()

func on_resources_changed() -> void:
	check_people_starving()
	check_people_freezing()

func on_active_tree_changed() -> void:
	check_assign_logging()
	check_choose_tree()

func on_active_water_changed() -> void:
	check_assign_fishing()
	check_choose_water()
