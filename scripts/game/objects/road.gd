extends Node3D


@export var ground: Node3D

var possible_destroy_hover = preload("res://materials/tile/possible_destroy_hover.tres")


func _ready() -> void:
	pass

func set_destroy_highlight(active: bool) -> void:
	if active:
		ground.material_overlay = possible_destroy_hover
	else:
		ground.material_overlay = null
