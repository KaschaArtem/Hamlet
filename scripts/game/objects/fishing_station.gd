extends Node3D


@export var ground: MeshInstance3D

@export var object: Node3D

@export var default: Node3D

var possible_destroy_hover = preload("res://materials/tile/possible_destroy_hover.tres")


func _ready() -> void:
	var rotation_y = randi_range(0, 3) * 90.0

	object.rotation_degrees.y = rotation_y

func set_destroy_highlight(active: bool) -> void:
	if active:
		ground.material_overlay = possible_destroy_hover
	else:
		ground.material_overlay = null
