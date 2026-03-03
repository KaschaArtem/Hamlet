extends Camera3D

const x_offset = 0.0
const y_offset = 2.5
const z_offset = 0.0
const ROTATION_SPEED = 1.2

@export var ground: Node3D

func update_position():
	var bounds = ground.get_city_bounds()
	var x = (bounds["left"] + bounds["right"]) * 0.25
	var y = max(bounds["right"] - bounds["left"], bounds["bottom"] - bounds["top"]) * 0.35
	var z = (bounds["top"] + bounds["bottom"]) * 0.25
	
	self.position = Vector3(x_offset + x, y_offset + y, z_offset + z)


func _process(delta):
	if Input.is_action_pressed("rotate_camera_left"):
		self.rotate_y(-ROTATION_SPEED * delta)
	elif Input.is_action_pressed("rotate_camera_right"):
		self.rotate_y(ROTATION_SPEED * delta)
