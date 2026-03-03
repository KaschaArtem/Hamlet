extends Node

const x_offset = 0.0
const y_offset = 2.5
const z_offset = 0.0

@export var ground: Node3D

func get_city_bounds(grid):
	var n = grid.size()
	var top = n
	var bottom = -1
	var left = n
	var right = -1

	for i in range(n):
		for j in range(n):
			if grid[i][j] > 0:
				top = min(top, i)
				bottom = max(bottom, i)
				left = min(left, j)
				right = max(right, j)

	return {"top": top, "bottom": bottom, "left": left, "right": right}


func update_position():
	var bounds = get_city_bounds(ground.ground_grid)
	var x = (bounds["left"] + bounds["right"]) * 0.25
	var y = max(bounds["right"] - bounds["left"], bounds["bottom"] - bounds["top"]) * 0.35
	var z = (bounds["top"] + bounds["bottom"]) * 0.25
	
	self.position = Vector3(x_offset + x, y_offset + y, z_offset + z)
