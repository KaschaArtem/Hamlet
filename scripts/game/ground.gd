@tool
extends Node3D

const GRID_SIZE = 31
const TILE_SIZE = 0.5
const GRID_CENTER = GRID_SIZE / 2

@export var camera: Camera3D

@export var main_tile_scene: PackedScene   # index 999
@export var tile_scene: PackedScene        # index 0
@export var house_scene: PackedScene       # index 1
@export var field_scene: PackedScene       # index 2
@export var pasture_scene: PackedScene     # index 3
@export var tree_scene: PackedScene        # index -1
@export var water_scene: PackedScene       # index -2

var ground_grid = []

var noise := FastNoiseLite.new()

func _ready() -> void:
	init_ground_grid()
	generate_grid()


func get_city_bounds():
	var top = GRID_SIZE
	var bottom = 0
	var left = GRID_SIZE
	var right = 0
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			if ground_grid[i][j] > 0:
				top = min(top, i)
				bottom = max(bottom, i)
				left = min(left, j)
				right = max(right, j)
	return {"top": top, "bottom": bottom, "left": left, "right": right}


func setup_noise():
	noise.seed = randi()
	noise.frequency = 0.1
	noise.fractal_octaves = 5
	noise.fractal_gain = 0.5
func init_ground_grid():
	setup_noise()
	for z in range(GRID_SIZE):
		ground_grid.append([])
		for x in range(GRID_SIZE):
			var value = 0
			var dist = sqrt(pow(x - GRID_CENTER, 2) + pow(z - GRID_CENTER, 2))
			if dist < 4:
				value = 0
			else:
				var n = noise.get_noise_2d(x, z)
				var dist_factor = clamp(dist / (GRID_SIZE / 2.0), 0.0, 1.0)
				n -= (1.0 - dist_factor) * 0.35
				if n < -0.6:
					value = -2
				elif n > 0.2:
					value = -1
				else:
					value = 0
			ground_grid[z].append(value)
	ground_grid[GRID_CENTER][GRID_CENTER] = 999

func apply_chess_color(tile, x, z):
	var mesh_instance = tile.get_node("MeshInstance3D")
	var material = StandardMaterial3D.new()
	if (x + z) % 2 == 0:
		material.albedo_color = Color(0.9, 0.9, 0.9)
	else:
		material.albedo_color = Color(0.5, 0.5, 0.5)
	mesh_instance.material_override = material
func add_main_tile(x, z):
	var main_tile = main_tile_scene.instantiate()
	main_tile.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(main_tile)
func add_empty_tile(x, z):
	var tile = tile_scene.instantiate()
	tile.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(tile)
	apply_chess_color(tile, x, z)
func add_house_tile(x, z):
	var house = house_scene.instantiate()
	house.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(house)
func add_field_tile(x, z):
	var field = field_scene.instantiate()
	field.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(field)
func add_pasture_tile(x, z):
	var pasture = pasture_scene.instantiate()
	pasture.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(pasture)
func add_tree_tile(x, z):
	var tree = tree_scene.instantiate()
	tree.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(tree)
func add_water_tile(x, z):
	var water = water_scene.instantiate()
	water.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(water)

func generate_grid():
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			var value = ground_grid[z][x]
			match value:
				999:
					add_main_tile(x, z)
				0:
					add_empty_tile(x, z)
				-1:
					add_tree_tile(x, z)
				-2:
					add_water_tile(x, z)


func can_place_empty_tile(grid, x, z) -> bool:
	var original_positive = 0
	for row in grid:
		for value in row:
			if value > 0:
				original_positive += 1
				
	grid[z][x] = 0
	
	var visited := []
	for i in range(GRID_SIZE):
		visited.append([])
		for j in range(GRID_SIZE):
			visited[i].append(false)

	var queue := []
	var reachable_positive := 0

	queue.append(Vector2i(GRID_CENTER, GRID_CENTER))
	visited[GRID_CENTER][GRID_CENTER] = true

	var directions = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	while queue.size() > 0:
		var current = queue.pop_front()
		var cx = current.x
		var cz = current.y
		
		if grid[cz][cx] > 0:
			reachable_positive += 1
		
		for dir in directions:
			var nx = cx + dir.x
			var nz = cz + dir.y
			
			if nx >= 0 and nx < GRID_SIZE and nz >= 0 and nz < GRID_SIZE:
				if not visited[nz][nx] and grid[nz][nx] > 0:
					visited[nz][nx] = true
					queue.append(Vector2i(nx, nz))
	
	grid[z][x] = 1
	return reachable_positive == original_positive - 1
func can_place_building_tile(x, z) -> bool:
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

func replace_with_empty_tile(tile_object, x, z):
	if !can_place_empty_tile(ground_grid, x, z):
		return
	tile_object.queue_free()
	add_empty_tile(x, z)
	ground_grid[z][x] = 0
func replace_with_house_tile(tile_object, x, z):
	if !can_place_building_tile(x, z):
		return
	tile_object.queue_free()
	add_house_tile(x, z)
	ground_grid[z][x] = 1
func replace_with_field_tile(tile_object, x, z):
	if !can_place_building_tile(x, z):
		return
	tile_object.queue_free()
	add_field_tile(x, z)
	ground_grid[z][x] = 2
func replace_with_pasture_tile(tile_object, x, z):
	if !can_place_building_tile(x, z):
		return
	tile_object.queue_free()
	add_pasture_tile(x, z)
	ground_grid[z][x] = 3

func update_grid_tile(tile_object, to_state):
	var x = int(tile_object.position.x / TILE_SIZE)
	var z = int(tile_object.position.z / TILE_SIZE)
	if ground_grid[z][x] == 999 or \
		ground_grid[z][x] == to_state or \
		ground_grid[z][x] < 0:
		return
	match to_state:
		0:
			replace_with_empty_tile(tile_object, x, z)
		1:
			replace_with_house_tile(tile_object, x, z)
		2:
			replace_with_field_tile(tile_object, x, z)
		3:
			replace_with_pasture_tile(tile_object, x, z)
