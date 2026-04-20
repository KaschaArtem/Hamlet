extends Node

@export_group("Links")
@export var game: Node3D
@export var ground: Node3D
@export var camera: Node3D

@export_group("Scene Objects")
@export var panel: PanelContainer
@export var container: VBoxContainer
@export var object_name: Label
@export var object_info: Label

var current_type: String = ""
var tween: Tween

func _ready() -> void:
	camera.selected_tile_changed.connect(update_info_on_selected)
	hide_instantly()

func hide_instantly() -> void:
	if tween: 
		tween.kill()
	if panel:
		panel.visible = false
		panel.modulate.a = 0
	clear_info()

func fade_in() -> void:
	if not panel: 
		return
	
	if tween: 
		tween.kill()
	
	panel.modulate.a = 0 
	panel.visible = true
	
	tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func clear_info() -> void:
	object_name.text = ""
	object_info.text = ""
	current_type = ""

func show_info(type: String) -> void:
	if type == current_type and panel and panel.visible:
		return
		
	if not game.TILES_INFO.has(type):
		hide_instantly()
		return
	
	current_type = type
	object_name.text = game.TILES_INFO[type][0]
	object_info.text = game.TILES_INFO[type][1]

	fade_in()

func update_info_on_selected(selected_tile) -> void:
	if GameManager.is_input_allowed == false:
		return
	
	var type = ground.get_tile_type_name(selected_tile)
	show_info(type)
