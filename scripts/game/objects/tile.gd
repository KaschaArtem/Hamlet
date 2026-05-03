extends Node3D


@export var tile: MeshInstance3D

var possible_build_hover = preload("res://materials/tile/possible_build_hover.tres")

var spring_material = preload("res://materials/tile/seasons/spring_tile.tres")
var summer_material = preload("res://materials/tile/seasons/summer_tile.tres")
var autumn_material = preload("res://materials/tile/seasons/autumn_tile.tres")
var winter_material = preload("res://materials/tile/seasons/winter_tile.tres")


func _ready() -> void:
	pass


func set_build_highlight(active: bool) -> void:
	if active:
		tile.material_overlay = possible_build_hover
	else:
		tile.material_overlay = null

func set_season_material(season: String) -> void:
	match season:
		"spring": tile.material_override = spring_material
		"summer": tile.material_override = summer_material
		"autumn": tile.material_override = autumn_material
		"winter": tile.material_override = winter_material
