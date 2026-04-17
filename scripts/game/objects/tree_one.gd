extends Node3D


@export var object: Node3D

@export var default: Node3D
@export var winter: Node3D


func _ready() -> void:
	var offset_x = randf_range(-0.2, 0.2)
	var offset_z = randf_range(-0.2, 0.2)
	var rotation_y = randf_range(-180.0, 180.0)
	var scale_mult = randf_range(0.8, 1.2)

	object.position += Vector3(offset_x, 0, offset_z)
	object.rotation.y = rotation_y
	object.scale *= scale_mult
