extends Node


@export var game: Node3D
@export var ground: Node3D
@export var camera: Node3D
@export var buildings_ui: Control


var TILES_INFO = {
	"house": ["House", "Increase max amount of PEOPLE, WOOD, FOOD. Increase resource income, when stands near resource tile."],
	"field": ["Field", "Produce plant food. Doesn't work on winter."],
	"pasture": ["Pasture", "Produce animal food. Works less efficient on winter."],
	"tree": ["Tree", "Cut to get WOOD. Press F on this tile to choose this tree for cutting during next month."]
}

@export var panel: Panel
@export var container: VBoxContainer
@export var object_name: Label
@export var object_info: Label

var current_type: String = ""
var tween: Tween

func _ready() -> void:
	camera.selected_tile_changed.connect(update_info_on_selected)
	buildings_ui.building_action_clear.connect(update_info_on_clear)
	buildings_ui.building_action_set.connect(update_info_on_set)
	hide_instantly()

func hide_instantly() -> void:
	if tween: tween.kill()
	self.visible = false
	self.modulate.a = 0
	clear_info()

func fade_in() -> void:
	if tween: tween.kill()
	
	self.modulate.a = 0 
	self.visible = true
	
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func clear_info() -> void:
	object_name.text = ""
	object_info.text = ""
	current_type = ""

func show_info(type: String) -> void:
	if type == current_type and self.visible:
		return
		
	if not TILES_INFO.has(type):
		hide_instantly()
		return
	
	current_type = type
	object_name.text = TILES_INFO[type][0]
	object_info.text = TILES_INFO[type][1]

	fade_in()

func update_info_on_selected(selected_tile) -> void:
	if GameManager.building_action != -999 or GameManager.is_input_allowed == false:
		return
	
	var type = ground.get_tile_type_name(selected_tile)
	show_info(type)

func update_info_on_clear() -> void:
	hide_instantly()
	camera.force_handle_select()

func update_info_on_set() -> void:
	match GameManager.building_action:
		1: show_info("house")
		2: show_info("field")
		3: show_info("pasture")
		_: 
			hide_instantly()
