@tool
extends Node

const GRID_SIZE = 31
const TILE_SIZE = 0.5

@export var camera: Camera3D

@export var tile_scene: PackedScene
@export var house_scene: PackedScene
@export var field_scene: PackedScene
@export var pasture_scene: PackedScene

var ground_grid = []

func _ready() -> void:
	init_ground_grid()
	generate_grid()


func init_ground_grid():
	for i in range(GRID_SIZE):
		ground_grid.append([])
		for j in range(GRID_SIZE):
			ground_grid[i].append(0)


func apply_chess_color(tile, x, z):
	var mesh_instance = tile.get_node("MeshInstance3D")
	var material = StandardMaterial3D.new()
	if (x + z) % 2 == 0:
		material.albedo_color = Color(0.9, 0.9, 0.9)
	else:
		material.albedo_color = Color(0.5, 0.5, 0.5)
	mesh_instance.material_override = material


func generate_grid():
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			var tile = tile_scene.instantiate()
			tile.position = Vector3(
				x * TILE_SIZE,
				0,
				z * TILE_SIZE
			)
			add_child(tile)
			apply_chess_color(tile, x, z)

	var center = GRID_SIZE / 2
	ground_grid[center][center] = 1
	camera.update_position()
