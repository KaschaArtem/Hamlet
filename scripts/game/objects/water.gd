extends Node


@export var surface: MeshInstance3D
@export var water: MeshInstance3D

var water_default = preload("res://materials/water/water_default.tres")


func _ready() -> void:
	surface.visible = false
	water.material_override = water_default


func set_highlight(active: bool) -> void:
	if active:
		surface.visible = true
	else:
		surface.visible = false
