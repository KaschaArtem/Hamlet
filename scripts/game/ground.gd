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


func can_place_empty_tile(grid, x, z) -> bool:
	return true
func can_place_house_tile(x, z) -> bool:
	var directions = [
		Vector2(0, -1),
		Vector2(0, 1),
		Vector2(-1, 0),
		Vector2(1, 0)
	]
	for dir in directions:
		var nx = x + int(dir.x)
		var nz = z + int(dir.y)
		if nx >= 0 and nx < GRID_SIZE and nz >= 0 and nz < GRID_SIZE:
			var value = ground_grid[nz][nx]
			if value == 999:
				return true
			if value == 1:
				return true
	return false
func can_place_field_tile(grid, x, z) -> bool:
	return true
func can_place_pasture_tile(grid, x, z) -> bool:
	return true

func add_empty_tile(tile_object, x, z):
	if !can_place_empty_tile(ground_grid, x, z):
		return
	tile_object.queue_free()
	var tile = tile_scene.instantiate()
	tile.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(tile)
	apply_chess_color(tile, x, z)
	ground_grid[z][x] = 0
func add_house_tile(tile_object, x, z):
	if !can_place_house_tile(x, z):
		return
	ground_grid[z][x] = 1
	tile_object.queue_free()
	var house = house_scene.instantiate()
	house.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(house)
func add_field_tile(tile_object, x, z):
	if !can_place_field_tile(ground_grid, x, z):
		return
	tile_object.queue_free()
	var field = field_scene.instantiate()
	field.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(field)
	ground_grid[z][x] = 2
func add_pasture_tile(tile_object, x, z):
	if !can_place_pasture_tile(ground_grid, x, z):
		return
	tile_object.queue_free()
	var pasture = pasture_scene.instantiate()
	pasture.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(pasture)
	ground_grid[z][x] = 3

func update_grid_tile(tile_object, to_state):
	var x = int(tile_object.position.x / TILE_SIZE)
	var z = int(tile_object.position.z / TILE_SIZE)
	if ground_grid[z][x] == 999:
		return
	if ground_grid[z][x] == to_state:
		return
	match to_state:
		0:
			add_empty_tile(tile_object, x, z)
		1:
			add_house_tile(tile_object, x, z)
		2:
			add_field_tile(tile_object, x, z)
		3:
			add_pasture_tile(tile_object, x, z)
