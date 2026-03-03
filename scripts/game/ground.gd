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
var grid_center = GRID_SIZE / 2

func _ready() -> void:
	init_ground_grid()
	generate_grid()
	
	ground_grid[grid_center][grid_center] = 999
	camera.update_position()


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
			tile.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
			add_child(tile)
			apply_chess_color(tile, x, z)


func update_grid_tile(tile_object, tile_position, to_state):
	var tile_x = int(tile_position.x / TILE_SIZE)
	var tile_z = int(tile_position.z / TILE_SIZE)
	if ground_grid[tile_z][tile_x] == 999:
		return
	if ground_grid[tile_z][tile_x] != to_state:
		ground_grid[tile_z][tile_x] = to_state
	else:
		return
	tile_object.queue_free()
	match to_state:
		0:
			var tile = tile_scene.instantiate()
			tile.position = Vector3(tile_position.x, 0, tile_position.z)
			add_child(tile)
			apply_chess_color(tile, tile_x, tile_z)
		1:
			var house = house_scene.instantiate()
			house.position = Vector3(tile_position.x, 0, tile_position.z)
			add_child(house)
		2:
			var field = field_scene.instantiate()
			field.position = Vector3(tile_position.x, 0, tile_position.z)
			add_child(field)
		3:
			var pasture = pasture_scene.instantiate()
			pasture.position = Vector3(tile_position.x, 0, tile_position.z)
			add_child(pasture)
