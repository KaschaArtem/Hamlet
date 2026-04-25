extends Control


@export_group("Links")
@export var game: Node3D
@export var toggle_ui: Control

@export_group("Buttons")
@export var house_button: Button
@export var road_button: Button
@export var field_button: Button
@export var pasture_button: Button
@export var sawmill_button: Button
@export var fishing_station_button: Button
@export var delete_button: Button

@export_group("Info Panels")
@export var house_info: PanelContainer
@export var road_info: PanelContainer
@export var field_info: PanelContainer
@export var pasture_info: PanelContainer
@export var sawmill_info: PanelContainer
@export var fishing_station_info: PanelContainer
@export var delete_info: PanelContainer

@export_group("Info Labels")
@export var house_name_label: Label
@export var road_name_label: Label
@export var field_name_label: Label
@export var pasture_name_label: Label
@export var sawmill_name_label: Label
@export var fishing_station_name_label: Label
@export var delete_name_label: Label

@export var house_info_label: Label
@export var road_info_label: Label
@export var field_info_label: Label
@export var pasture_info_label: Label
@export var sawmill_info_label: Label
@export var fishing_station_info_label: Label
@export var delete_info_label: Label

var last_action_frame = -1

var hovered = { "button": null, "panel": null }
var selected = { "button": null, "panel": null }

var button_panels = {}
var all_buttons = []

var default_y_positions = {}
var hide_offset = 150.0
var hover_offset = 6.0
var select_offset = 16.0

var active_tweens = {}

var is_ui_transitioning: bool = false

func _ready() -> void:
	game.player_action_started.connect(on_player_action_started)
	game.player_action_ended.connect(on_player_action_ended)
	toggle_ui.fade_out.connect(on_fade_out)
	toggle_ui.fade_in.connect(on_fade_in)
	
	all_buttons = [house_button, road_button, field_button, pasture_button, sawmill_button, fishing_station_button, delete_button]
	
	button_panels = {
		house_button: house_info,
		road_button: road_info,
		field_button: field_info,
		pasture_button: pasture_info,
		sawmill_button: sawmill_info,
		fishing_station_button: fishing_station_info,
		delete_button: delete_info
	}

	setup_info_tabs()
	for btn in [house_button, road_button, field_button, pasture_button, sawmill_button, fishing_station_button, delete_button]:
		default_y_positions[btn] = btn.position.y

func setup_info_tabs() -> void:
	house_name_label.text = game.TILES_INFO["house"][0]
	road_name_label.text = game.TILES_INFO["road"][0]
	field_name_label.text = game.TILES_INFO["field"][0]
	pasture_name_label.text = game.TILES_INFO["pasture"][0]
	sawmill_name_label.text = game.TILES_INFO["sawmill"][0]
	fishing_station_name_label.text = game.TILES_INFO["fishing_station"][0]
	delete_name_label.text = "Destroy"

	house_info_label.text = game.TILES_INFO["house"][1]
	road_info_label.text = game.TILES_INFO["road"][1]
	field_info_label.text = game.TILES_INFO["field"][1]
	pasture_info_label.text = game.TILES_INFO["pasture"][1]
	sawmill_info_label.text = game.TILES_INFO["sawmill"][1]
	fishing_station_info_label.text = game.TILES_INFO["fishing_station"][1]
	delete_info_label.text = "Used for destroying buildings. Resorces will NOT be returned."

func _create_clean_tween(node: Node) -> Tween:
	if active_tweens.has(node) and active_tweens[node].is_valid():
		active_tweens[node].kill()
	var tween = create_tween()
	active_tweens[node] = tween
	return tween

func on_player_action_started() -> void:
	var delay = 0.0
	for btn in [house_button, road_button, field_button, pasture_button, sawmill_button, fishing_station_button, delete_button]:
		btn.disabled = false
		var tween = _create_clean_tween(btn)
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "position:y", default_y_positions[btn], 0.4).set_delay(delay)
		delay += 0.05

func on_player_action_ended() -> void:
	clear_building_action()
	for btn in [house_button, road_button, field_button, pasture_button, sawmill_button, fishing_station_button, delete_button]:
		btn.disabled = true
		var tween = _create_clean_tween(btn)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(btn, "position:y", default_y_positions[btn] + hide_offset, 0.3)

func on_fade_out() -> void:
	is_ui_transitioning = true
	for btn in active_tweens.keys():
		if active_tweens[btn].is_valid():
			active_tweens[btn].kill()

func on_fade_in() -> void:
	is_ui_transitioning = false
	if selected["button"]:
		animate_button_state(selected["button"], "selected")

func select_building_action() -> void:
	if GameManager.is_build_allowed == false or selected["button"] == null:
		return

	if last_action_frame == Engine.get_frames_drawn():
		return
	last_action_frame = Engine.get_frames_drawn()

	var button = selected["button"]
	var action: String = ""

	match button:
		house_button: action = "house"
		road_button: action = "road"
		field_button: action = "field"
		pasture_button: action = "pasture"
		sawmill_button: action = "sawmill"
		fishing_station_button: action = "fishing_station"
		delete_button: action = "tile"
		_: return

	if GameManager.building_action == action:
		clear_building_action()
		return

	for btn in all_buttons:
		if btn != button:
			hide_info_forced(btn)
			animate_button_state(btn, "normal")

	GameManager.building_action = action
	animate_button_state(button, "selected")
	show_info_logic(button_panels[button])

func clear_building_action() -> void:
	GameManager.building_action = "none"
	var old_btn = selected["button"]
	clear_selected()
	
	if old_btn:
		hide_info_forced(old_btn)
		var next_state = "hover" if old_btn.is_hovered() else "normal"
		animate_button_state(old_btn, next_state)
	
	for btn in all_buttons:
		if btn.is_hovered() and not btn.disabled:
			animate_button_state(btn, "hover")
			show_info_logic(button_panels[btn])

func animate_button_state(button: Button, state: String) -> void:
	if is_ui_transitioning or not is_visible_in_tree():
		return
	if button.disabled:
		return
		
	var target_y = default_y_positions[button]
	var duration = 0.2
	
	match state:
		"hover":
			target_y -= hover_offset
		"selected":
			target_y -= select_offset
		"normal":
			target_y = default_y_positions[button]
	
	var tween = _create_clean_tween(button)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "position:y", target_y, duration)

func show_info() -> void:
	var btn = hovered["button"]
	if btn == null or btn.disabled: return
	
	if selected["button"] != null and selected["button"] != btn:
		return
	
	if selected["button"] != btn:
		animate_button_state(btn, "hover")
		
	show_info_logic(hovered["panel"])

func hide_info() -> void:
	if not is_visible_in_tree():
		return

	for btn in all_buttons:
		if btn != selected["button"]:
			if not btn.is_hovered():
				animate_button_state(btn, "normal")
				hide_info_forced(btn)

func show_info_logic(panel: PanelContainer) -> void:
	panel.visible = true
	var p_tween = _create_clean_tween(panel)
	p_tween.tween_property(panel, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_CUBIC)

func hide_info_forced(button: Button) -> void:
	var panel = button_panels[button]
	panel.visible = false
	panel.modulate.a = 0.0
	if active_tweens.has(panel) and active_tweens[panel].is_valid():
		active_tweens[panel].kill()


func set_hovered(button, panel) -> void:
	hovered["button"] = button
	hovered["panel"] = panel

func clear_hovered() -> void:
	hovered["button"] = null
	hovered["panel"] = null

func set_selected(button, panel) -> void:
	selected["button"] = button
	selected["panel"] = panel

func clear_selected() -> void:
	selected["button"] = null
	selected["panel"] = null


func _on_house_button_mouse_entered() -> void: set_hovered(house_button, house_info); show_info()
func _on_house_button_mouse_exited() -> void: clear_hovered(); hide_info()

func _on_road_button_mouse_entered() -> void: set_hovered(road_button, road_info); show_info()
func _on_road_button_mouse_exited() -> void: clear_hovered(); hide_info()

func _on_field_button_mouse_entered() -> void: set_hovered(field_button, field_info); show_info()
func _on_field_button_mouse_exited() -> void: clear_hovered(); hide_info()

func _on_pasture_button_mouse_entered() -> void: set_hovered(pasture_button, pasture_info); show_info()
func _on_pasture_button_mouse_exited() -> void: clear_hovered(); hide_info()

func _on_sawmill_button_mouse_entered() -> void: set_hovered(sawmill_button, sawmill_info); show_info()
func _on_sawmill_button_mouse_exited() -> void: clear_hovered(); hide_info()

func _on_fishing_station_button_mouse_entered() -> void: set_hovered(fishing_station_button, fishing_station_info); show_info()
func _on_fishing_station_button_mouse_exited() -> void: clear_hovered(); hide_info()

func _on_delete_button_mouse_entered() -> void: set_hovered(delete_button, delete_info); show_info()
func _on_delete_button_mouse_exited() -> void: clear_hovered(); hide_info()

func _on_house_button_pressed() -> void: set_selected(house_button, house_info); select_building_action()
func _on_road_button_pressed() -> void: set_selected(road_button, road_info); select_building_action()
func _on_field_button_pressed() -> void: set_selected(field_button, field_info); select_building_action()
func _on_pasture_button_pressed() -> void: set_selected(pasture_button, pasture_info); select_building_action()
func _on_sawmill_button_pressed() -> void: set_selected(sawmill_button, sawmill_info); select_building_action()
func _on_fishing_station_button_pressed() -> void: set_selected(fishing_station_button, fishing_station_info); select_building_action()
func _on_delete_button_pressed() -> void: set_selected(delete_button, delete_info); select_building_action()

func _input(event):
	if event.is_echo(): return
	
	if Input.is_action_just_pressed("set_build_to_1"): _on_house_button_pressed()
	elif Input.is_action_just_pressed("set_build_to_2"): _on_road_button_pressed()
	elif Input.is_action_just_pressed("set_build_to_3"): _on_field_button_pressed()
	elif Input.is_action_just_pressed("set_build_to_4"): _on_pasture_button_pressed()
	elif Input.is_action_just_pressed("set_build_to_5"): _on_sawmill_button_pressed()
	elif Input.is_action_just_pressed("set_build_to_6"): _on_fishing_station_button_pressed()
	elif Input.is_action_just_pressed("set_build_to_0"): _on_delete_button_pressed()
	elif Input.is_action_just_pressed("clear_building_action"): clear_building_action()
