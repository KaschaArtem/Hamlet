extends Node3D


@export var game: Node3D
@export var day_night_cycle: Node3D

signal end_month

@export_group("Settings")
@export var month_time: float = 24.0 

const FULL_CIRCLE = TAU
const SUN_START_ANGLE = -PI / 3 
const MOON_START_ANGLE = SUN_START_ANGLE + PI 

var current_time: float = 0.0
var is_running: bool = false


func _ready() -> void:
	day_night_cycle._update_lights(0.0)
	game.turn_ended.connect(start_cycle)

func _process(delta: float) -> void:
	if not is_running:
		return

	current_time += delta
	var progress = current_time / month_time
	
	day_night_cycle._update_lights(progress)

	if current_time >= month_time:
		finish_cycle()

func start_cycle() -> void:
	current_time = 0.0
	is_running = true

func finish_cycle() -> void:
	is_running = false
	day_night_cycle._update_lights(0.0)
	end_month.emit()
