extends Node3D


@export var object: Node3D

@export var default: Node3D


func _ready() -> void:
	var rotation_y = randi_range(0, 3) * 90.0

	object.rotation_degrees.y = rotation_y