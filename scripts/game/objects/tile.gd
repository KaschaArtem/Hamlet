extends Node3D


@export var tile: MeshInstance3D

var possible_build_hover = preload("res://materials/tile/possible_build_hover.tres")


func _ready() -> void:
	pass


func set_highlight(active: bool) -> void:
	if active:
		tile.material_overlay = possible_build_hover
	else:
		tile.material_overlay = null