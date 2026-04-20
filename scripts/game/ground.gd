extends Node3D


@onready var game = get_parent()  
@onready var water_manager = $WaterManager

@export_group("Object Scenes")
@export var main_tile_scene: PackedScene
@export var tile_scene: PackedScene
@export var house_scene: PackedScene
@export var field_scene: PackedScene
@export var pasture_scene: PackedScene
@export var tree_one_scene: PackedScene
@export var water_scene: PackedScene

@export_group("Generation Settings")
@export_range(0.0, 0.15) var NOISE_FREQUENCY: float = 0.08
@export_range(0, 5) var NOISE_FRACTAL_OCTAVES: int = 2
@export_range(0.0, 1.0) var NOISE_FRACTAL_GAIN: float = 0.25
@export_range(1, 10) var BASE_RADIUS: int = 5
@export_range(-1.0, 1.0) var WOOD_SPAWN: float = 0.15
@export_range(-1.0, 1.0) var WATER_SPAWN: float = -0.67

signal builded(building_index: int)
signal active_tree_changed
signal active_water_changed


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
const TILE_SIZE = 1.0
const GRID_CENTER = GRID_SIZE / 2

var noise := FastNoiseLite.new()
var ground_grid = []

var house_amount = 0
var field_amount = 0
var pasture_amount = 0
var wood_amount = 0
var water_amount = 0

var current_to_cut_tree = null


func _ready() -> void:
	game.player_action_started.connect(on_player_action_started)
	init_ground_grid()
	
	if water_manager:
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
			var value = 0
			var dist = sqrt(pow(x - GRID_CENTER, 2) + pow(z - GRID_CENTER, 2))
			
			if dist < BASE_RADIUS:
				value = 0
			else:
				var n = noise.get_noise_2d(x, z)
				var dist_factor = clamp(dist / (GRID_SIZE / 2.0), 0.0, 1.0)
				n -= (1.0 - dist_factor) * 0.35
				
				if n < WATER_SPAWN: value = -2
				elif n > WOOD_SPAWN: value = -1
				else: value = 0
				
			ground_grid[z].append({"type": value})
			
	ground_grid[GRID_CENTER][GRID_CENTER] = {"type": 999}
	clean_water_artifacts()

func clean_water_artifacts() -> void:
	var new_grid = ground_grid.duplicate(true)
	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if ground_grid[z][x]["type"] != -2: continue
			
			var neighbors = 0
			for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				var nx = x + dir.x
				var nz = z + dir.y
				if nx >= 0 and nz >= 0 and nx < GRID_SIZE and nz < GRID_SIZE:
					if ground_grid[nz][nx]["type"] == -2: neighbors += 1
			
			if neighbors == 0:
				new_grid[z][x]["type"] = 0
	ground_grid = new_grid

func generate_grid() -> void:
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			_spawn_tile_by_type(ground_grid[z][x]["type"], x, z)

func _spawn_tile_by_type(type: int, x: int, z: int) -> void:
	var pos = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	var scene = null
	
	match type:
		999: scene = main_tile_scene
		0:   scene = tile_scene
		1:   scene = house_scene
		2:   scene = field_scene
		3:   scene = pasture_scene
		-1:  scene = tree_one_scene
		-2:  scene = water_scene
		
	if scene:
		var instance = scene.instantiate()
		instance.position = pos
		add_child(instance)
		if type == 0: apply_chess_color(instance, x, z)
		if type != 0 and type != 999: increase_tile_amount(type)

func apply_chess_color(tile, x, z) -> void:
	var mesh = tile.get_node_or_null("MeshInstance3D")
	if not mesh: return
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.9) if (x + z) % 2 == 0 else Color(0.5, 0.5, 0.5)
	mesh.material_override = mat

func get_current_water_cluster():
	return water_manager.current_water_cluster 

func get_tile_type_name(tile: Node) -> String:
	if tile == null:
		return "null"
	var path = tile.scene_file_path
	if TILE_TYPES.has(path):
		return TILE_TYPES[path]
	return "null"

func get_city_bounds() -> Dictionary:
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

func select_to_cut_tree(to_cut_tree) -> void:
	if current_to_cut_tree != null:
		current_to_cut_tree.hide_axe_icon()
	
	if current_to_cut_tree == to_cut_tree:
		current_to_cut_tree = null
	else:
		current_to_cut_tree = to_cut_tree
		current_to_cut_tree.show_axe_icon()
	active_tree_changed.emit()

func remove_to_cut_tree() -> void:
	if current_to_cut_tree:
		var pos = current_to_cut_tree.global_position
		remove_tile_at(int(pos.x), int(pos.z), -1)
		current_to_cut_tree = null
		active_tree_changed.emit()

func select_water_cluster(water_tile: Node3D) -> void:
	if water_manager:
		var x = int(round(water_tile.position.x / TILE_SIZE))
		var z = int(round(water_tile.position.z / TILE_SIZE))
		water_manager.select_cluster(x, z)
		active_water_changed.emit()

func get_water_bonus() -> float:
	if water_manager:
		return water_manager.get_water_bonus()
	return 0.0

func on_player_action_started() -> void:
	if water_manager:
		water_manager.process_turn()

func on_player_action_ended() -> void:
	if water_manager:
		water_manager.lock_water()

func build_grid_tile(tile_object, building_index) -> void:
	var x = int(tile_object.position.x / TILE_SIZE)
	var z = int(tile_object.position.z / TILE_SIZE)
	
	if ground_grid[z][x]["type"] == 999 or ground_grid[z][x]["type"] == building_index or ground_grid[z][x]["type"] < 0:
		return

	match building_index:
		0:
			if !can_build_empty_tile(x, z): return
			_replace_tile(tile_object, x, z, 0, tile_scene)
			apply_chess_color(get_child(get_child_count()-1), x, z)
		1:
			if !can_build_building_tile(x, z) or !game.is_house_build_allowed(): return
			_replace_tile(tile_object, x, z, 1, house_scene)
		2:
			if !can_build_building_tile(x, z) or !game.is_field_build_allowed(): return
			_replace_tile(tile_object, x, z, 2, field_scene)
		3:
			if !can_build_building_tile(x, z) or !game.is_pasture_build_allowed(): return
			_replace_tile(tile_object, x, z, 3, pasture_scene)
			
	builded.emit(building_index)

func _replace_tile(old_obj, x, z, new_type, scene) -> void:
	decrease_tile_amount(ground_grid[z][x]["type"])
	old_obj.queue_free()
	ground_grid[z][x]["type"] = new_type
	
	var instance = scene.instantiate()
	instance.position = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	add_child(instance)
	increase_tile_amount(new_type)

func remove_tile_at(x: int, z: int, tile_type: int) -> void:
	ground_grid[z][x]["type"] = 0
	decrease_tile_amount(tile_type)
	
	var world_pos = Vector3(x * TILE_SIZE, 0, z * TILE_SIZE)
	for child in get_children():
		if child.position.is_equal_approx(world_pos):
			child.queue_free()
			break
	
	_spawn_tile_by_type(0, x, z)

func can_build_empty_tile(x, z) -> bool:
	var original_type = ground_grid[z][x]["type"]
	var total_buildings = 0
	for r in ground_grid:
		for c in r: 
			if c["type"] > 0: total_buildings += 1
			
	ground_grid[z][x]["type"] = 0
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
		if ground_grid[curr.y][curr.x]["type"] > 0: count += 1
		
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var n = curr + dir
			if n.x >= 0 and n.x < GRID_SIZE and n.y >= 0 and n.y < GRID_SIZE:
				if not visited[n.y][n.x] and ground_grid[n.y][n.x]["type"] > 0:
					visited[n.y][n.x] = true
					queue.append(n)
	return count

func can_build_building_tile(x, z) -> bool:
	if ground_grid[z][x]["type"] != 0: return false
	for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var nx = x + dir.x
		var nz = z + dir.y
		if nx >= 0 and nx < GRID_SIZE and nz >= 0 and nz < GRID_SIZE:
			var type = ground_grid[nz][nx]["type"]
			if type == 999 or type == 1: return true
	return false

func increase_tile_amount(type) -> void:
	match type:
		1: house_amount += 1
		2: field_amount += 1
		3: pasture_amount += 1
		-1: wood_amount += 1
		-2: water_amount += 1

func decrease_tile_amount(type) -> void:
	match type:
		1: house_amount -= 1
		2: field_amount -= 1
		3: pasture_amount -= 1
		-1: wood_amount -= 1
		-2: water_amount -= 1
