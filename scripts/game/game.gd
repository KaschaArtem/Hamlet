extends Node3D

@export var camera: Camera3D
@export var ground: Node3D

func _ready() -> void:
	pass


func _input(event):
	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_dir = camera.project_ray_normal(mouse_pos)
		var ray_end = ray_origin + ray_dir * 1000
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		var result = get_world_3d().direct_space_state.intersect_ray(query)
		if result:
			var tile_body = result.collider
			var tile = tile_body.get_parent()
			var tile_position = tile.position
			ground.update_grid_tile(tile, tile_position, 1)
