extends Node3D

@export_group("Links")
@export var ground: Node3D
@export var camera: Camera3D


signal selected_tile_changed(new_tile)


@export_group("Settings")
@export var MOUSE_SENSITIVITY := 0.3

@export_range(1.0, 5.0) var ROTATION_SPEED: float = 1.2
@export_range(2.0, 20.0) var MOVE_SPEED: float = 10.0

@export_range(2.0, 20.0) var ZOOM_SPEED = 10.0
const MIN_RADIUS = 2.0
const MAX_RADIUS = 16.0

@export_range(0, 150) var PITCH_SPEED = 60
const MIN_PITCH_DEG = -89.9
const MAX_PITCH_DEG = -25.0

var radius: float
var pitch_deg: float

var is_dragging := false
var last_mouse_pos := Vector2.ZERO

var target_position: Vector3
var target_radius: float
var target_pitch: float
var target_yaw: float

@export var SMOOTHNESS := 12.0

var current_mouse_position : Vector2
var current_selected_tile = null


func update_camera_position():
	var pitch_rad = deg_to_rad(pitch_deg)
	var horizontal_distance = radius * cos(-pitch_rad)
	var vertical_offset = radius * sin(-pitch_rad)
	camera.position = Vector3(0, vertical_offset, horizontal_distance)
	camera.look_at(position)
func update_initial_position():
	var bounds = ground.get_city_bounds()
	var x = (bounds["left"] + bounds["right"]) * 0.5
	var z = (bounds["top"] + bounds["bottom"]) * 0.5
	position = Vector3(x * ground.TILE_SIZE, 0, z * ground.TILE_SIZE)
	update_camera_position()

func _ready():
	radius = 4.0
	pitch_deg = -80
	
	update_initial_position()
	
	target_radius = radius
	target_pitch = pitch_deg
	target_position = position
	target_yaw = rotation.y


func handle_rotation(delta):
	if !GameManager.is_input_allowed:
		return
	if Input.is_action_pressed("rotate_camera_left"):
		target_yaw -= ROTATION_SPEED * delta
	if Input.is_action_pressed("rotate_camera_right"):
		target_yaw += ROTATION_SPEED * delta

func handle_movement(delta):
	if !GameManager.is_input_allowed:
		return
	var input_dir = Vector3.ZERO

	if Input.is_action_pressed("move_camera_forward"): input_dir.z += 1
	if Input.is_action_pressed("move_camera_back"):    input_dir.z -= 1
	if Input.is_action_pressed("move_camera_left"):    input_dir.x -= 1
	if Input.is_action_pressed("move_camera_right"):   input_dir.x += 1

	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized() * MOVE_SPEED * delta
		var forward = -transform.basis.z
		var right = transform.basis.x
		target_position += forward * input_dir.z + right * input_dir.x

	var max_coord = ground.GRID_SIZE * ground.TILE_SIZE
	var margin = ground.TILE_SIZE
	target_position.x = clamp(target_position.x, -margin, max_coord + margin)
	target_position.z = clamp(target_position.z, -margin, max_coord + margin)

func zoom_in(delta):
	target_radius -= ZOOM_SPEED * delta
	target_radius = clamp(target_radius, MIN_RADIUS, MAX_RADIUS)
	update_camera_position()
func zoom_out(delta):
	target_radius += ZOOM_SPEED * delta
	target_radius = clamp(target_radius, MIN_RADIUS, MAX_RADIUS)
	update_camera_position()

func handle_zoom(delta):
	if !GameManager.is_input_allowed:
		return
	if Input.is_action_pressed("zoom_camera_in"):
		zoom_in(delta)
	if Input.is_action_pressed("zoom_camera_out"):
		zoom_out(delta)

func tilt_up(delta):
	target_pitch += PITCH_SPEED * delta
	target_pitch = clamp(target_pitch, MIN_PITCH_DEG, MAX_PITCH_DEG)
	update_camera_position()
func tilt_down(delta):
	target_pitch -= PITCH_SPEED * delta
	target_pitch = clamp(target_pitch, MIN_PITCH_DEG, MAX_PITCH_DEG)
	update_camera_position()

func handle_pitch(delta):
	if !GameManager.is_input_allowed:
		return
	if Input.is_action_pressed("tilt_camera_up"):
		tilt_up(delta)
	if Input.is_action_pressed("tilt_camera_down"):
		tilt_down(delta)

func apply_border_safety(target_r: float) -> float:
	var pitch_rad = deg_to_rad(pitch_deg)
	var horizontal_distance = target_r * cos(-pitch_rad)
	
	var forward_dir = transform.basis.z.normalized()
	var offset = Vector3(forward_dir.x, 0, forward_dir.z) * horizontal_distance
	
	var camera_xz_pos = position + offset

	var max_coord = ground.GRID_SIZE * ground.TILE_SIZE
	
	var out_left = max(0.0, -camera_xz_pos.x)
	var out_right = max(0.0, camera_xz_pos.x - max_coord)
	var out_top = max(0.0, -camera_xz_pos.z)
	var out_bottom = max(0.0, camera_xz_pos.z - max_coord)
	
	var total_out = out_left + out_right + out_top + out_bottom
	
	if total_out > 0:
		var penalty = total_out * 1.5
		return clamp(target_r - penalty, MIN_RADIUS, MAX_RADIUS)
	
	return target_r


func get_tile_under_mouse():
	var mouse_pos = current_mouse_position
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	var ray_end = ray_origin + ray_dir * 1000
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	
	if result:
		return result.collider.owner
	return null


func handle_select():
	var new_selected_tile = get_tile_under_mouse()
	if current_selected_tile != new_selected_tile:
		current_selected_tile = new_selected_tile
		selected_tile_changed.emit(current_selected_tile)

func force_handle_select():
	var new_selected_tile = get_tile_under_mouse()
	current_selected_tile = new_selected_tile
	selected_tile_changed.emit(current_selected_tile)

func _process(delta):
	handle_select()
	handle_rotation(delta)
	handle_movement(delta)
	handle_zoom(delta)
	handle_pitch(delta)

	position = position.lerp(target_position, SMOOTHNESS * delta)
	pitch_deg = lerp(pitch_deg, target_pitch, SMOOTHNESS * delta)
	rotation.y = lerp(rotation.y, target_yaw, SMOOTHNESS * delta)
	var desired_radius = lerp(radius, target_radius, SMOOTHNESS * delta)
	radius = apply_border_safety(desired_radius)

	update_camera_position()


func handle_build_selection() -> void:
	var result = get_tile_under_mouse()
	if !result:
		return
	if GameManager.building_action != -999 and GameManager.is_build_allowed != false:
		ground.build_grid_tile(result, GameManager.building_action)

func handle_resource_selection() -> void:
	var result = get_tile_under_mouse()
	if !result:
		return
	if GameManager.building_action == -999 and ground.get_tile_type_name(result) == "tree":
		ground.select_to_cut_tree(result)
	elif GameManager.building_action == -999 and ground.get_tile_type_name(result) == "water":
		ground.select_water_cluster(result)

func _input(event: InputEvent) -> void:
	if not GameManager.is_input_allowed:
		return

	if event is InputEventMouseMotion:
		current_mouse_position = event.position
		
		if is_dragging:
			target_yaw -= event.relative.x * MOUSE_SENSITIVITY * 0.01
			target_pitch -= event.relative.y * MOUSE_SENSITIVITY
			target_pitch = clamp(target_pitch, MIN_PITCH_DEG, MAX_PITCH_DEG)

	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				is_dragging = event.pressed
			
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					handle_build_selection()
			
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed: zoom_in(0.2)
			
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed: zoom_out(0.2)

	if event.is_action_pressed("select_resource"):
		handle_resource_selection()


func _notification(what):
	if what == NOTIFICATION_PAUSED:
		is_dragging = false
	elif what == NOTIFICATION_UNPAUSED:
		is_dragging = false
