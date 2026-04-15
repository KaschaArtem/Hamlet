extends Node


@export var ground: Node3D
@export var camera: Node3D

@export var buildings_ui: Control


const TILES_INFO = {
	"house": ["House", "Increase max amount of PEOPLE, WOOD, FOOD. Increase resource income, when stands near resource tile."],
	"field": ["Field", "Produce plant food. Doesn't work on winter."],
	"pasture": ["Pasture", "Produce animal food. Works less efficient on winter."]
}

@export var object_name: Label
@export var object_info: Label

func _ready() -> void:
	camera.selected_tile_changed.connect(update_info_on_selected)
	buildings_ui.building_action_clear.connect(update_info_on_clear)
	buildings_ui.building_action_set.connect(update_info_on_set)
	self.visible = false


func clear_info() -> void:
	self.visible = false
	object_name.text = ""
	object_info.text = ""

func update_info_on_selected(selected_tile) -> void:
	if GameManager.building_action != -999 or GameManager.is_input_allowed == false:
		return
	
	match ground.get_tile_type_name(selected_tile):
		"house":
			self.visible = true
			object_name.text = TILES_INFO["house"][0]
			object_info.text = TILES_INFO["house"][1]
		"field":
			self.visible = true
			object_name.text = TILES_INFO["field"][0]
			object_info.text = TILES_INFO["field"][1]
		"pasture":
			self.visible = true
			object_name.text = TILES_INFO["pasture"][0]
			object_info.text = TILES_INFO["pasture"][1]
		_:
			clear_info()

func update_info_on_clear() -> void:
	clear_info()
	camera.force_handle_select()

func update_info_on_set() -> void:
	match GameManager.building_action:
		1:
			self.visible = true
			object_name.text = TILES_INFO["house"][0]
			object_info.text = TILES_INFO["house"][1]
		2:
			self.visible = true
			object_name.text = TILES_INFO["field"][0]
			object_info.text = TILES_INFO["field"][1]
		3:
			self.visible = true
			object_name.text = TILES_INFO["pasture"][0]
			object_info.text = TILES_INFO["pasture"][1]
		_:
			clear_info()