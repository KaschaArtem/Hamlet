extends Node3D


@export var ground: MeshInstance3D

@export var object: Node3D

@export var default: Node3D
@export var winter: Node3D

@export var axe_icon: Sprite3D

var highlight_shader_material = preload("res://materials/tree/allowed_tree.tres")

var spring_material = preload("res://materials/tile/seasons/spring_tile.tres")
var summer_material = preload("res://materials/tile/seasons/summer_tile.tres")
var autumn_material = preload("res://materials/tile/seasons/autumn_tile.tres")
var winter_material = preload("res://materials/tile/seasons/winter_tile.tres")


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


func set_season_material(season: String) -> void:
	match season:
		"spring": 
			ground.material_override = spring_material
			winter.visible = false
			default.visible = true
		"summer": ground.material_override = summer_material
		"autumn": ground.material_override = autumn_material
		"winter": 
			ground.material_override = winter_material
			winter.visible = true
			default.visible = false
