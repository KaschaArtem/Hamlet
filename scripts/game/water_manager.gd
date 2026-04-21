extends Node3D


class_name WaterManager

@onready var grid_manager = get_parent()

@export_group("Textures")
@export var three_step_loading_1: Texture2D
@export var three_step_loading_2: Texture2D
@export var three_step_loading_3: Texture2D
@export var fish_icon_texture: Texture2D

signal water_changed


var water_clusters = []
var water_map = []
var current_water_cluster = null


func initialize(grid_size: int, ground_grid: Array) -> void:
	water_clusters.clear()
	water_map = []
	var visited = []
	
	for z in range(grid_size):
		water_map.append([])
		visited.append([])
		for x in range(grid_size):
			water_map[z].append(-1)
			visited[z].append(false)
			
	for z in range(grid_size):
		for x in range(grid_size):
			if ground_grid[z][x]["type"] == -2 and not visited[z][x]:
				var cluster_index = water_clusters.size()
				var cells = _flood_fill(x, z, visited, cluster_index, grid_size, ground_grid)
				var world_center = _calculate_world_center(cells)
				
				var cluster_data = {
					"cells": cells,
					"center_world_pos": world_center,
					"fish_value": _calculate_diminishing_value(cells.size()),
					"cooldown": 0,
					"icon_node": _create_cluster_icon(world_center)
				}
				water_clusters.append(cluster_data)

func _flood_fill(start_x, start_z, visited, cluster_idx, grid_size, ground_grid) -> Array:
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
			if nx >= 0 and nx < grid_size and nz >= 0 and nz < grid_size:
				if not visited[nz][nx] and ground_grid[nz][nx]["type"] == -2:
					visited[nz][nx] = true
					queue.append(Vector2i(nx, nz))
	return cluster_cells

func _calculate_diminishing_value(size: int) -> float:
	var total = 0.0
	for i in range(size):
		total += pow(0.9, i)
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

func _update_cluster_visuals(cluster: Dictionary) -> void:
	if cluster.cooldown > 0:
		cluster.icon_node.visible = true
		match cluster.cooldown:
			3: cluster.icon_node.texture = three_step_loading_1
			2: cluster.icon_node.texture = three_step_loading_2
			1: cluster.icon_node.texture = three_step_loading_3
	else:
		cluster.icon_node.texture = fish_icon_texture
		cluster.icon_node.visible = (current_water_cluster == cluster)

func select_cluster(x: int, z: int) -> void:
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
	
	water_changed.emit()

func process_turn() -> void:
	for cluster in water_clusters:
		if cluster.cooldown > 0:
			cluster.cooldown -= 1
			_update_cluster_visuals(cluster)

func get_water_bonus() -> float:
	if current_water_cluster == null:
		return 0.0
	return snapped(current_water_cluster.fish_value, 0.1)

func lock_water() -> void:
	if current_water_cluster == null:
		return
		
	var cluster_to_lock = current_water_cluster
	current_water_cluster = null
	cluster_to_lock.cooldown = 4
	_update_cluster_visuals(cluster_to_lock)
	water_changed.emit()
