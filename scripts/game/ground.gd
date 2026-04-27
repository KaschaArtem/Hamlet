extends Node3D


@onready var game = get_parent()

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

@export_group("Water Textures")
@export var three_step_loading_1: Texture2D
@export var three_step_loading_2: Texture2D
@export var three_step_loading_3: Texture2D
@export var fish_icon_texture: Texture2D

signal builded()
signal sawmill_changed
signal fishing_station_changed
signal active_tree_changed
signal active_water_changed


const BUILD_TILES = ["house", "road", "field", "pasture", "sawmill", "fishing_station"]
const ALLOWING_BUILD_TILES = ["house", "road"]
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

# Grid State
var noise := FastNoiseLite.new()
var ground_grid = []
var possible_build_tiles = []
var allowed_tree_tiles = []
var allowed_water_tiles = []

# Tile Counts
var wood_amount = 0
var water_amount = 0
var house_amount = 0
var road_amount = 0
var field_amount = 0
var pasture_amount = 0
var sawmill_amount = 0
var fishing_station_amount = 0

# Water Management
var water_clusters = []
var water_map = []

# Selected Management
var current_to_cut_tree = null
var current_water_cluster = null


func _ready() -> void:
	game.player_action_started.connect(on_player_action_started)
	init_ground_grid()
	initialize_water_clusters()
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

# Water Initialization & Flood Fill
func initialize_water_clusters() -> void:
	water_clusters.clear()
	water_map = []
	var visited = []
	
	for z in range(GRID_SIZE):
		water_map.append([])
		visited.append([])
		for x in range(GRID_SIZE):
			water_map[z].append(-1)
			visited[z].append(false)
			
	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if ground_grid[z][x]["type"] == "water" and not visited[z][x]:
				var cluster_index = water_clusters.size()
				var cells = _flood_fill(x, z, visited, cluster_index)
				var world_center = _calculate_world_center(cells)
				
				var cluster_data = {
					"cells": cells,
					"center_world_pos": world_center,
					"fish_value": _calculate_diminishing_value(cells.size()),
					"cooldown": 0,
					"icon_node": _create_cluster_icon(world_center)
				}
				water_clusters.append(cluster_data)

func _flood_fill(start_x: int, start_z: int, visited: Array, cluster_idx: int) -> Array:
	var cluster_cells = []
	var queue = [Vector2i(start_x, start_z)]
	visited[start_z][start_x] = true
	
	while queue.size() > 0:
		var curr = queue.pop_front()
		cluster_cells.append(curr)
		water_map[curr.y][curr.x] = cluster_idx
		
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var nx = curr.x + dir.x
			var nz = curr.y + dir.y
			if nx >= 0 and nx < GRID_SIZE and nz >= 0 and nz < GRID_SIZE:
				if not visited[nz][nx] and ground_grid[nz][nx]["type"] == "water":
					visited[nz][nx] = true
					queue.append(Vector2i(nx, nz))
	return cluster_cells

func _calculate_diminishing_value(size: int) -> float:
	var total = 0.0
	for i in range(size):
		total += pow(0.8, i)
	return total

func _create_cluster_icon(pos: Vector3) -> Sprite3D:
	var sprite = Sprite3D.new()
	sprite.texture = fish_icon_texture
	sprite.visible = false
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.8)
	sprite.position = Vector3(pos.x, 2.0, pos.z)
	sprite.scale = Vector3(0.6, 0.6, 0.6)
	add_child(sprite)
	return sprite

func _calculate_world_center(cells: Array) -> Vector3:
	var sum_x = 0.0
	var sum_z = 0.0
	for cell in cells:
		sum_x += cell.x
		sum_z += cell.y
	return Vector3((sum_x / cells.size()) + 0.5, 0, (sum_z / cells.size()) + 0.5)

# Spawning & Grid Construction
func generate_grid() -> void:
	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			_spawn_tile_by_type(ground_grid[z][x]["type"], z, x)

func _spawn_tile_by_type(type: String, z: int, x: int) -> void:
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

# Building Placement & Mechanics
func clear_possible_build_tiles() -> void:
	possible_build_tiles = []

func unhover_possible_build_tiles() -> void:
	for tile in possible_build_tiles:
		if tile:
			tile.set_highlight(false) 
	clear_possible_build_tiles()

func update_possible_build_tiles() -> void:
	clear_possible_build_tiles()
	var directions = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if ground_grid[z][x]["type"] == "tile":
				for dir in directions:
					var nx = x + dir.x
					var nz = z + dir.y
					if nx >= 0 and nx < GRID_SIZE and nz >= 0 and nz < GRID_SIZE:
						if ground_grid[nz][nx]["type"] in ALLOWING_BUILD_TILES:
							possible_build_tiles.append(ground_grid[z][x]["node"])
							break

func hover_possible_build_tiles() -> void:
	update_possible_build_tiles()
	for tile in possible_build_tiles:
		if tile:
			tile.set_highlight(true)

func build_grid_tile(tile_object, building_action) -> void:
	var x = int(tile_object.position.x / TILE_SIZE)
	var z = int(tile_object.position.z / TILE_SIZE)
	
	var current_type = ground_grid[z][x]["type"]
	
	if current_type == "main_tile" or WORLD_TILES.has(current_type):
		return
	if building_action == "none":
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
	
	unhover_possible_build_tiles()
	hover_possible_build_tiles()

	game.subtract_building_cost(building_action)
	builded.emit()

func _replace_tile(old_obj, x, z, new_type: String, scene) -> void:
	decrease_tile_amount(ground_grid[z][x]["type"])
	old_obj.queue_free()
	ground_grid[z][x]["type"] = new_type

	var instance = scene.instantiate()
	instance.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(instance)
	ground_grid[z][x]["node"] = instance
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
	ground_grid[z][x]["node"] = instance

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
	
	_spawn_tile_by_type("tile", z, x)

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

func can_build_building_tile(x, z) -> bool:
	if ground_grid[z][x]["type"] != "tile": return false
	for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var nx = x + dir.x
		var nz = z + dir.y
		if nx >= 0 and nx < GRID_SIZE and nz >= 0 and nz < GRID_SIZE:
			var type = ground_grid[nz][nx]["type"]
			if type == "main_tile" or type == "house" or type == "road": return true
	return false

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

# Trees & Sawmill Logic
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
		if tree:
			tree.set_highlight(false)

	for tree in new_allowed_tree_tiles:
		if tree:
			tree.set_highlight(true)

	return new_allowed_tree_tiles

func _handle_sawmill_changed() -> void:
	allowed_tree_tiles = _update_allowed_trees()
	_validate_to_cut_tree()
	sawmill_changed.emit()

# Water Interactions & Fishing Logic
func get_current_water_cluster():
	return current_water_cluster 

func select_water_cluster(water_tile: Node3D) -> void:
	if !allowed_water_tiles.has(water_tile):
		return
	
	var x = int(round(water_tile.position.x / TILE_SIZE))
	var z = int(round(water_tile.position.z / TILE_SIZE))
	_select_cluster_by_coords(x, z)

func _select_cluster_by_coords(x: int, z: int) -> void:
	var idx = water_map[z][x]
	if idx == -1: return
	
	var cluster = water_clusters[idx]
	if cluster.cooldown > 0: return
	
	var prev_cluster = current_water_cluster
	if current_water_cluster == cluster:
		current_water_cluster = null
	else:
		current_water_cluster = cluster
	
	if prev_cluster: _update_cluster_visuals(prev_cluster)
	_update_cluster_visuals(cluster)
	
	active_water_changed.emit()

func get_water_bonus() -> float:
	if current_water_cluster == null:
		return 0.0
	return snapped(current_water_cluster.fish_value, 0.1)

func lock_water() -> void:
	if current_water_cluster == null:
		return
	
	for cell in current_water_cluster["cells"]:
		var tile_data = ground_grid[cell.y][cell.x]
		if tile_data.has("node"):
			tile_data["node"].set_highlight(false)

	var cluster_to_lock = current_water_cluster
	current_water_cluster = null
	cluster_to_lock.cooldown = 4

	_update_cluster_visuals(cluster_to_lock)
	active_water_changed.emit()

func _update_cluster_visuals(cluster: Dictionary) -> void:
	if cluster.cooldown > 0:
		cluster.icon_node.visible = true
		match cluster.cooldown:
			3: cluster.icon_node.texture = three_step_loading_1
			2: cluster.icon_node.texture = three_step_loading_2
			1: cluster.icon_node.texture = three_step_loading_3
	else:
		var is_choosable = false
		for cell in cluster["cells"]:
			var tile_data = ground_grid[cell.y][cell.x]
			if tile_data.has("node") and tile_data["node"] in allowed_water_tiles:
				is_choosable = true
				break
		
		if is_choosable:
			for cell in cluster["cells"]:
				var tile_data = ground_grid[cell.y][cell.x]
				if tile_data.has("node"):
					tile_data["node"].set_highlight(true)

		cluster.icon_node.texture = fish_icon_texture
		cluster.icon_node.visible = (current_water_cluster == cluster)

func _validate_current_water_cluster() -> void:
	if current_water_cluster == null:
		return

	var is_still_valid = false
	
	for cell in current_water_cluster["cells"]:
		var tile_data = ground_grid[cell.y][cell.x]
		if tile_data.has("node"):
			var node_ref = tile_data["node"]
			if allowed_water_tiles.has(node_ref):
				is_still_valid = true
				break
	
	if not is_still_valid:
		for cell in current_water_cluster["cells"]:
			var tile_data = ground_grid[cell.y][cell.x]
			if tile_data.has("node"):
				tile_data["node"].set_highlight(false)
		
		var cluster_to_reset = current_water_cluster
		current_water_cluster = null
		_update_cluster_visuals(cluster_to_reset)
		active_water_changed.emit()

func _update_allowed_water() -> Array:
	var new_allowed_water_nodes = []
	var added_clusters = {} 
	
	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile = ground_grid[z][x]
			
			if tile["type"] == "fishing_station":
				var radius = game.fishing_station_radius
				
				for dz in range(-radius, radius + 1):
					for dx in range(-radius, radius + 1):
						var nz = z + dz
						var nx = x + dx
						
						if nx >= 0 and nx < GRID_SIZE and nz >= 0 and nz < GRID_SIZE:
							var cluster_idx = water_map[nz][nx]
							
							if cluster_idx != -1 and not added_clusters.has(cluster_idx):
								var cluster = water_clusters[cluster_idx]
								
								if cluster.cooldown == 0:
									for cell in cluster["cells"]:
										var water_tile_data = ground_grid[cell.y][cell.x]
										if water_tile_data.has("node"):
											new_allowed_water_nodes.append(water_tile_data["node"])
									
									added_clusters[cluster_idx] = true
	
	for water in allowed_water_tiles:
		water.set_highlight(false)
	
	for water in new_allowed_water_nodes:
		water.set_highlight(true)

	return new_allowed_water_nodes

func _handle_fishing_station_changed() -> void:
	allowed_water_tiles = _update_allowed_water()
	_validate_current_water_cluster()
	fishing_station_changed.emit()

# Turn Processing & Utilities
func on_player_action_started() -> void:
	for cluster in water_clusters:
		if cluster.cooldown > 0:
			cluster.cooldown -= 1
			_update_cluster_visuals(cluster)

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