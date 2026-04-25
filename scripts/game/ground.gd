extends Node3D


@onready var game = get_parent()
@onready var water_manager = $WaterManager

@export_group("Object Scenes")
@export var tile_scene: PackedScene
@export var tree_one_scene: PackedScene
@export var water_scene: PackedScene
@export var main_tile_scene: PackedScene
@export var house_scene: PackedScene
@export var road_scene: PackedScene
@export var field_scene: PackedScene
@export var pasture_scene: PackedScene
@export var sawmill_scene: PackedScene
@export var fishing_station_scene: PackedScene


@export_group("Generation Settings")
@export_range(0.0, 0.15) var NOISE_FREQUENCY: float = 0.08
@export_range(0, 5) var NOISE_FRACTAL_OCTAVES: int = 2
@export_range(0.0, 1.0) var NOISE_FRACTAL_GAIN: float = 0.25
@export_range(1, 10) var BASE_RADIUS: int = 5
@export_range(-1.0, 1.0) var WOOD_SPAWN: float = 0.15
@export_range(-1.0, 1.0) var WATER_SPAWN: float = -0.67

signal builded(building_action: String)
signal sawmill_changed
signal fishing_station_changed
signal active_tree_changed
signal active_water_changed


const BUILD_TILES = ["house", "road", "field", "pasture", "sawmill", "fishing_station"]
const WORLD_TILES = ["tree", "water"]

const TILE_TYPES = {
	"res://scenes/game_scenes/objects/tile.tscn": "tile",
	"res://scenes/game_scenes/objects/tree_one.tscn": "tree",
	"res://scenes/game_scenes/objects/water.tscn": "water",
	"res://scenes/game_scenes/objects/main_tile.tscn": "main_tile",
	"res://scenes/game_scenes/objects/house.tscn": "house",
	"res://scenes/game_scenes/objects/road.tscn": "road",
	"res://scenes/game_scenes/objects/field.tscn": "field",
	"res://scenes/game_scenes/objects/pasture.tscn": "pasture",
	"res://scenes/game_scenes/objects/sawmill.tscn": "sawmill",
	"res://scenes/game_scenes/objects/fishing_station.tscn": "fishing_station"
}

const GRID_SIZE = 51
const TILE_SIZE = 1.0
const GRID_CENTER = GRID_SIZE / 2

var noise := FastNoiseLite.new()
var ground_grid = []
var allowed_tree_tiles = []
var allowed_water_tiles = []

var wood_amount = 0
var water_amount = 0
var house_amount = 0
var road_amount = 0
var field_amount = 0
var pasture_amount = 0
var sawmill_amount = 0
var fishing_station_amount = 0


var current_to_cut_tree = null


func _ready() -> void:
	game.player_action_started.connect(on_player_action_started)
	water_manager.water_changed.connect(on_active_water_changed)
	init_ground_grid()
	
	water_manager.initialize(GRID_SIZE, ground_grid)
	generate_grid()

func setup_noise() -> void:
	noise.seed = randi()
	noise.frequency = NOISE_FREQUENCY
	noise.fractal_octaves = NOISE_FRACTAL_OCTAVES
	noise.fractal_gain = NOISE_FRACTAL_GAIN

func init_ground_grid() -> void:
	setup_noise()
	for z in range(GRID_SIZE):
		ground_grid.append([])
		for x in range(GRID_SIZE):
			var type_str = "tile"
			var dist = sqrt(pow(x - GRID_CENTER, 2) + pow(z - GRID_CENTER, 2))
			
			if dist >= BASE_RADIUS:
				var n = noise.get_noise_2d(x, z)
				var dist_factor = clamp(dist / (GRID_SIZE / 2.0), 0.0, 1.0)
				n -= (1.0 - dist_factor) * 0.35
				
				if n < WATER_SPAWN: type_str = "water"
				elif n > WOOD_SPAWN: type_str = "tree"
				else: type_str = "tile"
				
			ground_grid[z].append({"type": type_str})
			
	ground_grid[GRID_CENTER][GRID_CENTER] = {"type": "main_tile"}
	ground_grid[GRID_CENTER - 1][GRID_CENTER] = {"type": "road"}
	ground_grid[GRID_CENTER + 1][GRID_CENTER] = {"type": "road"}
	ground_grid[GRID_CENTER][GRID_CENTER - 1] = {"type": "road"}
	ground_grid[GRID_CENTER][GRID_CENTER + 1] = {"type": "road"}
	clean_water_artifacts()

func clean_water_artifacts() -> void:
	var new_grid = ground_grid.duplicate(true)
	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if ground_grid[z][x]["type"] != "water": continue
			
			var neighbors = 0
			for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				var nx = x + dir.x
				var nz = z + dir.y
				if nx >= 0 and nz >= 0 and nx < GRID_SIZE and nz < GRID_SIZE:
					if ground_grid[nz][nx]["type"] == "water": neighbors += 1
			
			if neighbors == 0:
				new_grid[z][x]["type"] = "tile"
	ground_grid = new_grid

func generate_grid() -> void:
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			_spawn_tile_by_type(ground_grid[z][x]["type"], x, z)

func _spawn_tile_by_type(type: String, x: int, z: int) -> void:
	var pos = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	var scene = null
	
	match type:
		"tile":      scene = tile_scene
		"tree":      scene = tree_one_scene
		"water":     scene = water_scene
		"main_tile": scene = main_tile_scene
		"house":     scene = house_scene
		"road":      scene = road_scene
		"field":     scene = field_scene
		"pasture":   scene = pasture_scene
		"sawmill":   scene = sawmill_scene
		"fishing_station": scene = fishing_station_scene
		
	if scene:
		var instance = scene.instantiate()
		instance.position = pos
		add_child(instance)
		ground_grid[z][x]["node"] = instance
		increase_tile_amount(type)

func get_current_water_cluster():
	return water_manager.current_water_cluster 

func get_tile_type_name(tile: Node) -> String:
	if tile == null:
		return "null"
	var path = tile.scene_file_path
	return TILE_TYPES.get(path, "null")

func get_city_bounds() -> Dictionary:
	var top = GRID_SIZE
	var bottom = 0
	var left = GRID_SIZE
	var right = 0
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			if ground_grid[i][j]["type"] in BUILD_TILES or ground_grid[i][j]["type"] == "main_tile":
				top = min(top, i)
				bottom = max(bottom, i)
				left = min(left, j)
				right = max(right, j)
	return {"top": top, "bottom": bottom, "left": left, "right": right}

func _validate_to_cut_tree() -> void:
	if !allowed_tree_tiles.has(current_to_cut_tree) and current_to_cut_tree != null:
		current_to_cut_tree.set_axe_icon(true)
		current_to_cut_tree = null

func select_to_cut_tree(to_cut_tree) -> void:
	if !allowed_tree_tiles.has(to_cut_tree):
		return

	if current_to_cut_tree != null:
		current_to_cut_tree.set_axe_icon(false)
	
	if current_to_cut_tree == to_cut_tree:
		current_to_cut_tree = null
	else:
		current_to_cut_tree = to_cut_tree
		current_to_cut_tree.set_axe_icon(true)
	active_tree_changed.emit()

func remove_to_cut_tree() -> void:
	if current_to_cut_tree:
		var pos = current_to_cut_tree.global_position
		remove_tile_at(int(pos.x), int(pos.z), "tree")
		current_to_cut_tree = null
		active_tree_changed.emit()

func on_active_water_changed() -> void:
	active_water_changed.emit()

func select_water_cluster(water_tile: Node3D) -> void:
	var x = int(round(water_tile.position.x / TILE_SIZE))
	var z = int(round(water_tile.position.z / TILE_SIZE))
	water_manager.select_cluster(x, z)

func get_water_bonus() -> float:
	if water_manager:
		return water_manager.get_water_bonus()
	return 0.0

func on_player_action_started() -> void:
	water_manager.process_turn()

func lock_water() -> void:
	water_manager.lock_water()

func build_grid_tile(tile_object, building_action) -> void:
	var x = int(tile_object.position.x / TILE_SIZE)
	var z = int(tile_object.position.z / TILE_SIZE)
	
	var current_type = ground_grid[z][x]["type"]
	
	if current_type == "main_tile" or WORLD_TILES.has(current_type):
		return

	match building_action:
		"house":
			if !can_build_building_tile(x, z) or !game.is_house_build_allowed(): return
			_replace_tile(tile_object, x, z, "house", house_scene)
		"road":
			if !can_build_building_tile(x, z) or !game.is_road_build_allowed(): return
			_replace_tile(tile_object, x, z, "road", road_scene)
		"field":
			if !can_build_building_tile(x, z) or !game.is_field_build_allowed(): return
			_replace_tile(tile_object, x, z, "field", field_scene)
		"pasture":
			if !can_build_building_tile(x, z) or !game.is_pasture_build_allowed(): return
			_replace_tile(tile_object, x, z, "pasture", pasture_scene)
		"sawmill":
			if !can_build_building_tile(x, z) or !game.is_sawmill_build_allowed(): return
			_replace_tile(tile_object, x, z, "sawmill", sawmill_scene)
		"fishing_station":
			if !can_build_building_tile(x, z) or !game.is_fishing_station_build_allowed(): return
			_replace_tile(tile_object, x, z, "fishing_station", fishing_station_scene)
		"tile":
			if current_type == "tile": return
			if !can_build_empty_tile(x, z): return
			_delete_tile(tile_object, x, z)
			
	builded.emit(building_action)

func _update_allowed_trees() -> Array:
	var new_allowed_tree_tiles = []
	var visited = {} 
	var queue = []

	for z in range(ground_grid.size()):
		for x in range(ground_grid[z].size()):
			if ground_grid[z][x]["type"] == "sawmill":
				var start_pos = Vector2(z, x)
				queue.append({"pos": start_pos, "dist": 0})
				visited[start_pos] = true

	while queue.size() > 0:
		var current = queue.pop_front()
		var pos = current["pos"]
		var dist = current["dist"]

		var tile = ground_grid[pos.x][pos.y]

		if tile["type"] == "tree":
			var tree_instance = tile.get("node")
			
			if tree_instance and not new_allowed_tree_tiles.has(tree_instance):
				new_allowed_tree_tiles.append(tree_instance)

		if dist < 3:
			var directions = [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]
			for dir in directions:
				var next_pos = pos + dir
				
				if next_pos.x >= 0 and next_pos.x < ground_grid.size() and \
				   next_pos.y >= 0 and next_pos.y < ground_grid.size():
					
					if not visited.has(next_pos):
						visited[next_pos] = true
						queue.append({"pos": next_pos, "dist": dist + 1})

	for tree in allowed_tree_tiles:
		if !new_allowed_tree_tiles.has(tree):
			tree.set_highlight(false)
		else:
			tree.set_highlight(true)

	for tree in new_allowed_tree_tiles:
		tree.set_highlight(true)

	return new_allowed_tree_tiles

func _handle_sawmill_changed() -> void:
	allowed_tree_tiles = _update_allowed_trees()
	_validate_to_cut_tree()
	sawmill_changed.emit()

func _recount_allowed_water() -> Array:
	var new_allowed_water_tiles = []
	for tile in ground_grid:
		if tile["type"] != "fishing_station":
			continue
	
	return new_allowed_water_tiles

func _handle_fishing_station_changed() -> void:
	allowed_water_tiles = _recount_allowed_water()
	fishing_station_changed.emit()

func _replace_tile(old_obj, x, z, new_type: String, scene) -> void:
	decrease_tile_amount(ground_grid[z][x]["type"])
	old_obj.queue_free()
	ground_grid[z][x]["type"] = new_type

	var instance = scene.instantiate()
	instance.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(instance)
	increase_tile_amount(new_type)

	if new_type == "sawmill":
		_handle_sawmill_changed()
	elif new_type == "fishing_station":
		_handle_fishing_station_changed()

func _delete_tile(old_obj, x, z) -> void:
	var deleted_type = ground_grid[z][x]["type"]

	decrease_tile_amount(deleted_type)
	old_obj.queue_free()
	ground_grid[z][x]["type"] = "tile"

	var instance = tile_scene.instantiate()
	instance.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(instance)

	if deleted_type == "sawmill":
		_handle_sawmill_changed()
	elif deleted_type == "fishing_station":
		_handle_fishing_station_changed()

func remove_tile_at(x: int, z: int, tile_type: String) -> void:
	ground_grid[z][x]["type"] = "tile"
	decrease_tile_amount(tile_type)

	var world_pos = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	for child in get_children():
		if child is Node3D and child.position.is_equal_approx(world_pos):
			child.queue_free()
			break
	
	_spawn_tile_by_type("tile", x, z)

func can_build_empty_tile(x, z) -> bool:
	var original_type = ground_grid[z][x]["type"]
	var total_buildings = 0
	for r in ground_grid:
		for c in r: 
			if c["type"] in BUILD_TILES or c["type"] == "main_tile": 
				total_buildings += 1
			
	ground_grid[z][x]["type"] = "tile"
	var reachable = _count_reachable_buildings()
	ground_grid[z][x]["type"] = original_type
	
	return reachable == (total_buildings - 1)

func _count_reachable_buildings() -> int:
	var visited = []
	for i in range(GRID_SIZE):
		var row = []
		row.resize(GRID_SIZE)
		row.fill(false)
		visited.append(row)
	
	var queue = [Vector2i(GRID_CENTER, GRID_CENTER)]
	visited[GRID_CENTER][GRID_CENTER] = true
	var count = 0
	
	while queue.size() > 0:
		var curr = queue.pop_front()
		var type = ground_grid[curr.y][curr.x]["type"]
		
		if type in BUILD_TILES or type == "main_tile": 
			count += 1
		
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var n = curr + dir
			if n.x >= 0 and n.x < GRID_SIZE and n.y >= 0 and n.y < GRID_SIZE:
				var n_type = ground_grid[n.y][n.x]["type"]
				if not visited[n.y][n.x] and (n_type in BUILD_TILES or n_type == "main_tile"):
					visited[n.y][n.x] = true
					queue.append(n)
	return count

func can_build_building_tile(x, z) -> bool:
	if ground_grid[z][x]["type"] != "tile": return false
	for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var nx = x + dir.x
		var nz = z + dir.y
		if nx >= 0 and nx < GRID_SIZE and nz >= 0 and nz < GRID_SIZE:
			var type = ground_grid[nz][nx]["type"]
			if type == "main_tile" or type == "house" or type == "road": return true
	return false

func increase_tile_amount(type: String) -> void:
	match type:
		"tree": wood_amount += 1
		"water": water_amount += 1
		"house": house_amount += 1
		"road": road_amount += 1
		"field": field_amount += 1
		"pasture": pasture_amount += 1
		"sawmill": sawmill_amount += 1
		"fishing_station": fishing_station_amount += 1


func decrease_tile_amount(type: String) -> void:
	match type:
		"tree": wood_amount -= 1
		"water": water_amount -= 1
		"house": house_amount -= 1
		"road": road_amount -= 1
		"field": field_amount -= 1
		"pasture": pasture_amount -= 1
		"sawmill": sawmill_amount -= 1
		"fishing_station": fishing_station_amount -= 1
		
