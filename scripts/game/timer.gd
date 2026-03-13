extends Node3D


@export var game: Node3D

signal end_month

@export var month_time: float = 1.0


func _ready() -> void:
	game.turn_ended.connect(start_timer)


func start_timer() -> void:
	await get_tree().create_timer(month_time).timeout
	end_month.emit()
