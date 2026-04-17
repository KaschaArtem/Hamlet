extends Node


@export var game: Node3D
@export var ground: Node3D
@export var camera: Node3D

@export var buildings_ui: Control


var TILES_INFO = {
	"house": ["House", "Increase max amount of PEOPLE, WOOD, FOOD. Increase resource income, when stands near resource tile."],
	"field": ["Field", "Produce plant food. Doesn't work on winter."],
	"pasture": ["Pasture", "Produce animal food. Works less efficient on winter."]
}

@export var object_name: Label
@export var object_info: Label

var tween: Tween


func _ready() -> void:
	camera.selected_tile_changed.connect(update_info_on_selected)
	buildings_ui.building_action_clear.connect(update_info_on_clear)
	buildings_ui.building_action_set.connect(update_info_on_set)
	self.modulate.a = 0
	self.visible = false


func fade_in() -> void:
	if tween: tween.kill()
	
	self.visible = true
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func fade_out() -> void:
	if tween: tween.kill()
	
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.finished.connect(func(): self.visible = false)


func clear_info() -> void:
	object_name.text = ""
	object_info.text = ""

func show_info(type: String) -> void:
	if not TILES_INFO.has(type):
		clear_info()
		if self.visible:
			fade_out()
		return
		
	object_name.text = TILES_INFO[type][0]
	object_info.text = TILES_INFO[type][1]
	
	if not self.visible or self.modulate.a < 0.1:
		fade_in()

func update_info_on_selected(selected_tile) -> void:
	if GameManager.building_action != -999 or GameManager.is_input_allowed == false:
		return
	
	var type = ground.get_tile_type_name(selected_tile)
	show_info(type)

func update_info_on_clear() -> void:
	clear_info()
	camera.force_handle_select()

func update_info_on_set() -> void:
	match GameManager.building_action:
		1: show_info("house")
		2: show_info("field")
		3: show_info("pasture")
		_: 
			clear_info()
			fade_out()
