extends Node3D

@export var game: Node3D

signal builded(building_index: int)

const GRID_SIZE = 51
const TILE_SIZE = 0.5
const GRID_CENTER = GRID_SIZE / 2

var noise := FastNoiseLite.new()

@export var main_tile_scene: PackedScene   # index 999
@export var tile_scene: PackedScene        # index 0
@export var house_scene: PackedScene       # index 1
@export var field_scene: PackedScene       # index 2
@export var pasture_scene: PackedScene     # index 3
@export var tree_scene: PackedScene        # index -1
@export var water_scene: PackedScene       # index -2

@export_range(0.0, 0.15) var NOISE_FREQUENCY: float = 0.08
@export_range(0, 5) var NOISE_FRACTAL_OCTAVES: int = 2
@export_range(0.0, 1.0) var NOISE_FRACTAL_GAIN: float = 0.25
@export_range(1, 10) var BASE_RADIUS: int = 5
@export_range(-1.0, 1.0) var WOOD_SPAWN: float = 0.15
@export_range(-1.0, 1.0) var WATER_SPAWN: float = -0.67

var ground_grid = []
var house_amount = 0
var field_amount = 0
var pasture_amount = 0
var wood_amount = 0
var water_amount = 0


func make_tile_value(base: int) -> int:
	return base * 10 + randi() % 4

func get_tile_type(value: int) -> int:
	return value / 10

func get_tile_variant(value: int) -> int:
	return abs(value) % 10


func decrease_tile_amount(building_index) -> void:
	match building_index:
		1: house_amount -= 1
		2: field_amount -= 1
		3: pasture_amount -= 1
		-1: wood_amount -= 1
		-2: water_amount -= 1

func increase_tile_amount(building_index) -> void:
	match building_index:
		1: house_amount += 1
		2: field_amount += 1
		3: pasture_amount += 1
		-1: wood_amount += 1
		-2: water_amount += 1


func get_nearest_tile_distance(target_type: int, remove_tile: bool = false) -> int:

	var visited = []
	for z in range(GRID_SIZE):
		visited.append([])
		for x in range(GRID_SIZE):
			visited[z].append(false)

	var queue = []

	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var type = get_tile_type(ground_grid[z][x])
			if type == 1 or type == 999:
				queue.append({"pos": Vector2i(x, z), "dist": 0})
				visited[z][x] = true

	var directions = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	while queue.size() > 0:

		var current = queue.pop_front()
		var x = current.pos.x
		var z = current.pos.y
		var dist = current.dist

		if get_tile_type(ground_grid[z][x]) == target_type:

			if remove_tile:
				remove_tile_at(x, z, target_type)

			return dist

		for dir in directions:
			var nx = x + dir.x
			var nz = z + dir.y

			if nx >= 0 and nx < GRID_SIZE and nz >= 0 and nz < GRID_SIZE:
				if !visited[nz][nx]:
					visited[nz][nx] = true
					queue.append({
						"pos": Vector2i(nx, nz),
						"dist": dist + 1
					})

	return -1


func remove_tile_at(x: int, z: int, tile_type: int) -> void:

	ground_grid[z][x] = make_tile_value(0)
	decrease_tile_amount(tile_type)

	var world_pos = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)

	for child in get_children():
		if child.position == world_pos:
			child.queue_free()
			break

	add_empty_tile(x, z)


func get_nearest_forest_distance(remove_tree: bool) -> int:
	return get_nearest_tile_distance(-1, remove_tree)

func get_nearest_water_distance() -> int:
	return get_nearest_tile_distance(-2, false)


func get_city_bounds():
	var top = GRID_SIZE
	var bottom = 0
	var left = GRID_SIZE
	var right = 0
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			if get_tile_type(ground_grid[i][j]) > 0:
				top = min(top, i)
				bottom = max(bottom, i)
				left = min(left, j)
				right = max(right, j)
	return {"top": top, "bottom": bottom, "left": left, "right": right}


func setup_noise():
	noise.seed = randi()
	noise.frequency = NOISE_FREQUENCY
	noise.fractal_octaves = NOISE_FRACTAL_OCTAVES
	noise.fractal_gain = NOISE_FRACTAL_GAIN


func clean_water():
	var new_grid = ground_grid.duplicate(true)
	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if get_tile_type(ground_grid[z][x]) != -2:
				continue
			var water_neighbors = 0
			for dir in [
				Vector2i(1,0),
				Vector2i(-1,0),
				Vector2i(0,1),
				Vector2i(0,-1)
			]:
				var nx = x + dir.x
				var nz = z + dir.y
				if nx < 0 or nz < 0 or nx >= GRID_SIZE or nz >= GRID_SIZE:
					continue
				if get_tile_type(ground_grid[nz][nx]) == -2:
					water_neighbors += 1
			if water_neighbors == 0:
				new_grid[z][x] = make_tile_value(0)
	ground_grid = new_grid


func init_ground_grid():
	setup_noise()
	for z in range(GRID_SIZE):
		ground_grid.append([])
		for x in range(GRID_SIZE):
			var value = 0
			var dist = sqrt(pow(x - GRID_CENTER, 2) + pow(z - GRID_CENTER, 2))
			if dist < BASE_RADIUS:
				value = 0
			else:
				var n = noise.get_noise_2d(x, z)
				var dist_factor = clamp(dist / (GRID_SIZE / 2.0), 0.0, 1.0)
				n -= (1.0 - dist_factor) * 0.35
				if n < WATER_SPAWN:
					value = -2
				elif n > WOOD_SPAWN:
					value = -1
				else:
					value = 0
			ground_grid[z].append(make_tile_value(value))

	ground_grid[GRID_CENTER][GRID_CENTER] = make_tile_value(999)
	clean_water()


func add_main_tile(x, z):
	var main_tile = main_tile_scene.instantiate()
	main_tile.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(main_tile)

func add_empty_tile(x, z):
	var tile = tile_scene.instantiate()
	tile.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(tile)

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
			var type = get_tile_type(value)

			match type:
				999:
					add_main_tile(x, z)
				0:
					add_empty_tile(x, z)
				1:
					add_house_tile(x, z)
					increase_tile_amount(1)
				2:
					add_field_tile(x, z)
					increase_tile_amount(2)
				3:
					add_pasture_tile(x, z)
					increase_tile_amount(3)
				-1:
					add_tree_tile(x, z)
					increase_tile_amount(-1)
				-2:
					add_water_tile(x, z)
					increase_tile_amount(-2)


func _ready() -> void:
	init_ground_grid()
	generate_grid()


func can_build_empty_tile(x, z) -> bool:
	var original_positive = 0
	for row in ground_grid:
		for value in row:
			if get_tile_type(value) > 0:
				original_positive += 1

	var old = ground_grid[z][x]
	ground_grid[z][x] = make_tile_value(0)

	var visited := []
	for i in range(GRID_SIZE):
		visited.append([])
		for j in range(GRID_SIZE):
			visited[i].append(false)

	var queue := []
	var reachable_positive := 0

	queue.append(Vector2i(GRID_CENTER, GRID_CENTER))
	visited[GRID_CENTER][GRID_CENTER] = true

	while queue.size() > 0:
		var current = queue.pop_front()
		var cx = current.x
		var cz = current.y

		if get_tile_type(ground_grid[cz][cx]) > 0:
			reachable_positive += 1

		for dir in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
			var nx = cx + dir.x
			var nz = cz + dir.y
			if nx >= 0 and nx < GRID_SIZE and nz >= 0 and nz < GRID_SIZE:
				if not visited[nz][nx] and get_tile_type(ground_grid[nz][nx]) > 0:
					visited[nz][nx] = true
					queue.append(Vector2i(nx, nz))

	ground_grid[z][x] = old
	return reachable_positive == original_positive - 1


func can_build_building_tile(x, z) -> bool:
	for dir in [Vector2(0,-1),Vector2(0,1),Vector2(-1,0),Vector2(1,0)]:
		var nx = x + int(dir.x)
		var nz = z + int(dir.y)
		if nx >= 0 and nx < GRID_SIZE and nz >= 0 and nz < GRID_SIZE:
			var type = get_tile_type(ground_grid[nz][nx])
			if type == 999 or type == 1:
				return true
	return false


func build_empty_tile(tile_object, x, z):
	tile_object.queue_free()
	add_empty_tile(x, z)
	decrease_tile_amount(get_tile_type(ground_grid[z][x]))
	ground_grid[z][x] = make_tile_value(0)

func build_house_tile(tile_object, x, z):
	tile_object.queue_free()
	add_house_tile(x, z)
	increase_tile_amount(1)
	ground_grid[z][x] = make_tile_value(1)

func build_field_tile(tile_object, x, z):
	tile_object.queue_free()
	add_field_tile(x, z)
	increase_tile_amount(2)
	ground_grid[z][x] = make_tile_value(2)

func build_pasture_tile(tile_object, x, z):
	tile_object.queue_free()
	add_pasture_tile(x, z)
	increase_tile_amount(3)
	ground_grid[z][x] = make_tile_value(3)


func build_grid_tile(tile_object, building_index):
	var x = int(tile_object.position.x / TILE_SIZE)
	var z = int(tile_object.position.z / TILE_SIZE)

	var type = get_tile_type(ground_grid[z][x])

	if type == 999 or type == building_index or type < 0:
		return

	match building_index:
		0:
			if !can_build_empty_tile(x, z):
				return
			build_empty_tile(tile_object, x, z)
			return
		1:
			if !can_build_building_tile(x, z): return
			if !game.is_house_build_allowed(): return
			build_house_tile(tile_object, x, z)
		2:
			if !can_build_building_tile(x, z): return
			if !game.is_field_build_allowed(): return
			build_field_tile(tile_object, x, z)
		3:
			if !can_build_building_tile(x, z): return
			if !game.is_pasture_build_allowed(): return
			build_pasture_tile(tile_object, x, z)

	builded.emit(building_index)
