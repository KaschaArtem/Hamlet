extends Node3D


@export var game: Node3D


signal builded(building_index: int)


const TILE_TYPES = {
	"res://scenes/game_scenes/objects/field.tscn": "field",
	"res://scenes/game_scenes/objects/house.tscn": "house",
	"res://scenes/game_scenes/objects/main_tile.tscn": "main_tile",
	"res://scenes/game_scenes/objects/pasture.tscn": "pasture",
	"res://scenes/game_scenes/objects/tile.tscn": "tile",
	"res://scenes/game_scenes/objects/tree_one.tscn": "tree",
	"res://scenes/game_scenes/objects/water.tscn": "water"
}

const GRID_SIZE = 51
const TILE_SIZE = 1
const GRID_CENTER = GRID_SIZE / 2

@export_group("Object Scenes")
@export var main_tile_scene: PackedScene   # index 999
@export var tile_scene: PackedScene        # index 0
@export var house_scene: PackedScene       # index 1
@export var field_scene: PackedScene       # index 2
@export var pasture_scene: PackedScene     # index 3
@export var tree_one_scene: PackedScene    # index -1
@export var water_scene: PackedScene       # index -2

@export_group("Generarion Settings")
@export_range(0.0, 0.15) var NOISE_FREQUENCY: float = 0.08
@export_range(0, 5) var NOISE_FRACTAL_OCTAVES: int = 2
@export_range(0.0, 1.0) var NOISE_FRACTAL_GAIN: float = 0.25
@export_range(1, 10) var BASE_RADIUS: int = 5
@export_range(-1.0, 1.0) var WOOD_SPAWN: float = 0.15
@export_range(-1.0, 1.0) var WATER_SPAWN: float = -0.67

var noise := FastNoiseLite.new()


var ground_grid = []
var house_amount = 0
var field_amount = 0
var pasture_amount = 0
var wood_amount = 0
var water_amount = 0

var current_to_cut_tree = null


func get_tile_type_name(tile: Node) -> String:
	if tile == null:
		return "null"
	var path = tile.scene_file_path
	if TILE_TYPES.has(path):
		return TILE_TYPES[path]
	return "null"

func decrease_tile_amount(building_index) -> void:
	match building_index:
		1:
			house_amount -= 1
		2:
			field_amount -= 1
		3:
			pasture_amount -= 1
		-1:
			wood_amount -= 1
		-2:
			water_amount -= 1

func increase_tile_amount(building_index) -> void:
	match building_index:
		1:
			house_amount += 1
		2:
			field_amount += 1
		3:
			pasture_amount += 1
		-1:
			wood_amount += 1
		-2:
			water_amount += 1

func get_nearest_tile_distance(target_type: int) -> int:

	var visited = []
	for z in range(GRID_SIZE):
		visited.append([])
		for x in range(GRID_SIZE):
			visited[z].append(false)

	var queue = []

	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if ground_grid[z][x]["type"] == 1 or ground_grid[z][x]["type"] == 999:
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

		if ground_grid[z][x]["type"] == target_type:
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

	ground_grid[z][x]["type"] = 0
	decrease_tile_amount(tile_type)

	var world_pos = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)

	for child in get_children():
		if child.position == world_pos:
			child.queue_free()
			break

	add_empty_tile(x, z)


func remove_to_cut_tree() -> void:
	var pos = current_to_cut_tree.global_position
	remove_tile_at(int(pos.x), int(pos.z), -1)
	current_to_cut_tree = null

func get_nearest_water_distance() -> int:
	return get_nearest_tile_distance(-2)

func get_city_bounds():
	var top = GRID_SIZE
	var bottom = 0
	var left = GRID_SIZE
	var right = 0
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			if ground_grid[i][j]["type"] > 0:
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
			if ground_grid[z][x]["type"] != -2:
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
				if ground_grid[nz][nx]["type"] == -2:
					water_neighbors += 1
			if water_neighbors == 0:
				new_grid[z][x]["type"] = 0
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
			ground_grid[z].append({"type": value})
	ground_grid[GRID_CENTER][GRID_CENTER] = {"type": 999}
	clean_water()

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
	var tree = tree_one_scene.instantiate()
	tree.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(tree)
func add_water_tile(x, z):
	var water = water_scene.instantiate()
	water.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(water)

func generate_grid():
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			var value = ground_grid[z][x]["type"]
			match value:
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
		for cell in row:
			if cell["type"] > 0:
				original_positive += 1
	ground_grid[z][x]["type"] = 0
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
		if ground_grid[cz][cx]["type"] > 0:
			reachable_positive += 1
		for dir in directions:
			var nx = cx + dir.x
			var nz = cz + dir.y
			if nx >= 0 and nx < GRID_SIZE and nz >= 0 and nz < GRID_SIZE:
				if not visited[nz][nx] and ground_grid[nz][nx]["type"] > 0:
					visited[nz][nx] = true
					queue.append(Vector2i(nx, nz))
	ground_grid[z][x]["type"] = 1
	return reachable_positive == original_positive - 1
func can_build_building_tile(x, z) -> bool:
	if ground_grid[z][x]["type"] != 0:
		return false
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
			var value = ground_grid[nz][nx]["type"]
			if value == 999:
				return true
			if value == 1:
				return true
	return false

func build_empty_tile(tile_object, x, z):
	tile_object.queue_free()
	add_empty_tile(x, z)
	decrease_tile_amount(ground_grid[z][x]["type"])
	ground_grid[z][x]["type"] = 0
func build_house_tile(tile_object, x, z):
	tile_object.queue_free()
	add_house_tile(x, z)
	increase_tile_amount(1)
	ground_grid[z][x]["type"] = 1
func build_field_tile(tile_object, x, z):
	tile_object.queue_free()
	add_field_tile(x, z)
	increase_tile_amount(2)
	ground_grid[z][x]["type"] = 2
func build_pasture_tile(tile_object, x, z):
	tile_object.queue_free()
	add_pasture_tile(x, z)
	increase_tile_amount(3)
	ground_grid[z][x]["type"] = 3


func build_grid_tile(tile_object, building_index) -> void:
	var x = int(tile_object.position.x / TILE_SIZE)
	var z = int(tile_object.position.z / TILE_SIZE)
	if ground_grid[z][x]["type"] == 999 or \
		ground_grid[z][x]["type"] == building_index or \
		ground_grid[z][x]["type"] < 0:
		return
	match building_index:
		0:
			if !can_build_empty_tile(x, z):
				return
			build_empty_tile(tile_object, x, z)
			return
		1:
			if !can_build_building_tile(x, z):
				return
			if !game.is_house_build_allowed():
				return
			build_house_tile(tile_object, x, z)
		2:
			if !can_build_building_tile(x, z):
				return
			if !game.is_field_build_allowed():
				return
			build_field_tile(tile_object, x, z)
		3:
			if !can_build_building_tile(x, z):
				return
			if !game.is_pasture_build_allowed():
				return
			build_pasture_tile(tile_object, x, z)
	builded.emit(building_index)

func select_to_cut_tree(to_cut_tree) -> void:
	if current_to_cut_tree != null:
		current_to_cut_tree.hide_axe_icon()
	current_to_cut_tree = to_cut_tree
	current_to_cut_tree.show_axe_icon()
