extends Camera3D

const X_OFFSET = 0.0
const Y_OFFSET = 2.5
const Z_OFFSET = 0.0
const ROTATION_SPEED = 1.2

@export var ground: Node3D

func _ready():
	update_position()


func update_position():
	var bounds = ground.get_city_bounds()
	var x = (bounds["left"] + bounds["right"]) * 0.25
	var y = max(bounds["right"] - bounds["left"], bounds["bottom"] - bounds["top"]) * 0.35
	var z = (bounds["top"] + bounds["bottom"]) * 0.25
	
	self.position = Vector3(X_OFFSET + x, Y_OFFSET + y, Z_OFFSET + z)


func _process(delta):
	if Input.is_action_pressed("rotate_camera_left"):
		self.rotate_y(-ROTATION_SPEED * delta)
	elif Input.is_action_pressed("rotate_camera_right"):
		self.rotate_y(ROTATION_SPEED * delta)
