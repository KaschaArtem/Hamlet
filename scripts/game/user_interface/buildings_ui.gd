extends Control


@export var game: Node3D

@export_group("Buttons")
@export var house_button: Button
@export var field_button: Button
@export var pasture_button: Button
@export var delete_button: Button

@export_group("Info Nodes")
@export var house_info: PanelContainer
@export var field_info: PanelContainer
@export var pasture_info: PanelContainer
@export var delete_info: PanelContainer

@export var house_name_label: Label
@export var field_name_label: Label
@export var pasture_name_label: Label
@export var delete_name_label: Label

@export var house_info_label: Label
@export var field_info_label: Label
@export var pasture_info_label: Label
@export var delete_info_label: Label

@onready var button_panels = {
	house_button: house_info,
	field_button: field_info,
	pasture_button: pasture_info,
	delete_button: delete_info
}


var prev_button: Button
var last_action_frame = -1

var default_y_positions = {}
var hide_offset = 100.0
var hover_offset = 6.0
var select_offset = 16.0

var active_tweens = {}


func _ready() -> void:
	game.player_action_started.connect(on_player_action_started)
	game.player_action_ended.connect(on_player_action_ended)
	
	setup_info_tabs()
	for btn in [house_button, field_button, pasture_button, delete_button]:
		default_y_positions[btn] = btn.position.y
		btn.position.y += hide_offset
		btn.disabled = true
		
		button_panels[btn].visible = false
		button_panels[btn].modulate.a = 0.0

func setup_info_tabs() -> void:
	house_name_label.text = game.TILES_INFO["house"][0]
	field_name_label.text = game.TILES_INFO["field"][0]
	pasture_name_label.text = game.TILES_INFO["pasture"][0]
	delete_name_label.text = "Destroy"

	house_info_label.text = game.TILES_INFO["house"][1]
	field_info_label.text = game.TILES_INFO["field"][1]
	pasture_info_label.text = game.TILES_INFO["pasture"][1]
	delete_info_label.text = "Used for destroying buildings. Resorces will NOT be returned."

func create_clean_tween(node: Node) -> Tween:
	if active_tweens.has(node) and active_tweens[node].is_valid():
		active_tweens[node].kill()
	
	var tween = create_tween()
	active_tweens[node] = tween
	return tween

func on_player_action_started() -> void:
	var delay = 0.0
	for btn in [house_button, field_button, pasture_button, delete_button]:
		btn.disabled = false
		var tween = create_clean_tween(btn)
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "position:y", default_y_positions[btn], 0.4).set_delay(delay)
		delay += 0.05

func on_player_action_ended() -> void:
	clear_building_action()
	
	for btn in [house_button, field_button, pasture_button, delete_button]:
		btn.disabled = true
		var tween = create_clean_tween(btn)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(btn, "position:y", default_y_positions[btn] + hide_offset, 0.3)

func handle_building(action_index: int, button: Button) -> void:
	if GameManager.is_build_allowed == false:
		return

	if last_action_frame == Engine.get_frames_drawn():
		return
	last_action_frame = Engine.get_frames_drawn()

	if prev_button == button:
		clear_building_action()
		return

	if prev_button:
		animate_button_selection(prev_button, false)
		hide_info_forced(prev_button)
	
	for btn in button_panels.keys():
		if btn != button:
			var tween = create_clean_tween(btn)
			tween.tween_property(btn, "position:y", default_y_positions[btn], 0.15)
			if btn.get_global_rect().has_point(get_global_mouse_position()):
				hide_info_forced(btn)

	GameManager.building_action = action_index
	prev_button = button
	animate_button_selection(button, true)
	show_info(button)

func clear_building_action() -> void:
	GameManager.building_action = -999
	if prev_button:
		var b = prev_button
		prev_button = null
		
		if b.get_global_rect().has_point(get_global_mouse_position()):
			var tween = create_clean_tween(b)
			tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(b, "position:y", default_y_positions[b] - hover_offset, 0.15)
		else:
			animate_button_selection(b, false)
			hide_info_forced(b)
	
	for btn in button_panels.keys():
		if btn.get_global_rect().has_point(get_global_mouse_position()):
			show_info(btn)

func animate_button_selection(button: Button, up: bool) -> void:
	var target_y = default_y_positions[button]
	if up:
		target_y -= select_offset
	
	var tween = create_clean_tween(button)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "position:y", target_y, 0.2)

func show_info(button: Button) -> void:
	if prev_button != null and prev_button != button:
		return
	
	if prev_button != button:
		var tween = create_clean_tween(button)
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "position:y", default_y_positions[button] - hover_offset, 0.15)

	var panel = button_panels[button]
	panel.visible = true
	var p_tween = create_clean_tween(panel)
	p_tween.tween_property(panel, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_CUBIC)

func hide_info(button: Button) -> void:
	if prev_button == button:
		return
		
	var tween = create_clean_tween(button)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(button, "position:y", default_y_positions[button], 0.15)
	hide_info_forced(button)

func hide_info_forced(button: Button) -> void:
	var panel = button_panels[button]
	panel.visible = false
	panel.modulate.a = 0.0
	if active_tweens.has(panel) and active_tweens[panel].is_valid():
		active_tweens[panel].kill()

# Сигналы
func _on_house_button_mouse_entered() -> void: show_info(house_button)
func _on_house_button_mouse_exited() -> void: hide_info(house_button)

func _on_field_button_mouse_entered() -> void: show_info(field_button)
func _on_field_button_mouse_exited() -> void: hide_info(field_button)

func _on_pasture_button_mouse_entered() -> void: show_info(pasture_button)
func _on_pasture_button_mouse_exited() -> void: hide_info(pasture_button)

func _on_delete_button_mouse_entered() -> void: show_info(delete_button)
func _on_delete_button_mouse_exited() -> void: hide_info(delete_button)

func _on_house_button_pressed() -> void: handle_building(1, house_button)
func _on_field_button_pressed() -> void: handle_building(2, field_button)
func _on_pasture_button_pressed() -> void: handle_building(3, pasture_button)
func _on_delete_button_pressed() -> void: handle_building(0, delete_button)

func _input(event):
	if event.is_echo(): return
	
	if Input.is_action_just_pressed("set_build_to_house"): handle_building(1, house_button)
	elif Input.is_action_just_pressed("set_build_to_field"): handle_building(2, field_button)
	elif Input.is_action_just_pressed("set_build_to_pasture"): handle_building(3, pasture_button)
	elif Input.is_action_just_pressed("set_build_to_tile"): handle_building(0, delete_button)
	elif Input.is_action_just_pressed("clear_building_action"): clear_building_action()
