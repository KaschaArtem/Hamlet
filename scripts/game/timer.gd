extends Node3D


@onready var game = get_parent()
@export var day_night_cycle: Node3D
@export var event_generator: Node3D

signal end_month

@export_group("Settings")
@export var month_time: float = 6.0 
@export var events_per_cycle: int = 3

const FULL_CIRCLE = TAU
const SUN_START_ANGLE = -PI / 3 
const MOON_START_ANGLE = SUN_START_ANGLE + PI 

var milestones: Array = []
var next_milestone_index: int = 0

var current_time: float = 0.0
var is_running: bool = false


func _ready() -> void:
	day_night_cycle._update_lights(0.0)
	game.turn_ended.connect(start_cycle)
	_calculate_milestones()

func _process(delta: float) -> void:
	if not is_running:
		return

	current_time += delta

	if next_milestone_index < milestones.size():
		if current_time >= milestones[next_milestone_index]:
			_trigger_mid_cycle_event()
			next_milestone_index += 1

	var progress = current_time / month_time
	day_night_cycle._update_lights(progress)

	if current_time >= month_time:
		finish_cycle()

func _calculate_milestones() -> void:
	milestones.clear()
	var interval = month_time / (events_per_cycle + 1)
	
	for i in range(1, events_per_cycle + 1):
		milestones.append(interval * i)

func start_cycle() -> void:
	_calculate_milestones()
	current_time = 0.0
	next_milestone_index = 0
	is_running = true
	event_generator.is_event_triggered = false

func _trigger_mid_cycle_event() -> void:
	is_running = false
	await event_generator.try_generate_event()
	is_running = true

func finish_cycle() -> void:
	is_running = false
	day_night_cycle._update_lights(0.0)
	end_month.emit()
