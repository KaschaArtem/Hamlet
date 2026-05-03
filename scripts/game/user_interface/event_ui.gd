extends Control

signal option_selected(index: int)

@export_group("Event Info")
@export var event_name: Label
@export var event_info: Label

@export_group("Event Buttons")
@export var option_1: Button
@export var option_2: Button
@export var option_3: Button


func _ready() -> void:
	self.visible = false


func get_event_input(event_name_text: String, event_info_text: String, option_1_text: String, option_2_text: String = "", option_3_text: String = "") -> int:
	event_name.text = event_name_text
	event_info.text = event_info_text
	
	option_1.text = option_1_text
	
	option_2.text = option_2_text
	option_2.visible = (option_2_text != "")
	
	option_3.text = option_3_text
	option_3.visible = (option_3_text != "")
	
	self.visible = true
	
	var result: int = await self.option_selected
	
	self.visible = false
	return result


func _on_option_1_pressed() -> void:
	option_selected.emit(1)

func _on_option_2_pressed() -> void:
	option_selected.emit(2)

func _on_option_3_pressed() -> void:
	option_selected.emit(3)
