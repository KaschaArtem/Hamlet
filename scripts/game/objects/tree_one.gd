extends Node3D


@export var object: Node3D
@export var default_ground: MeshInstance3D
@export var axe_icon: Sprite3D

var highlight_shader_material = preload("res://shaders/material/tree/allowed_tree.tres")


func _ready() -> void:
	var offset_x = randf_range(-0.2, 0.2)
	var offset_z = randf_range(-0.2, 0.2)
	var rotation_y = randf_range(-180.0, 180.0)
	var scale_mult = randf_range(0.8, 1.2)

	object.position += Vector3(offset_x, 0, offset_z)
	object.rotation_degrees.y = rotation_y
	object.scale *= scale_mult


func set_highlight(active: bool) -> void:
	var material_to_apply = highlight_shader_material if active else null
	_apply_overlay(object, material_to_apply)

func _apply_overlay(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_overlay = mat
	
	for child in node.get_children():
		_apply_overlay(child, mat)


func set_axe_icon(active: bool) -> void:
	if axe_icon:
		axe_icon.visible = active