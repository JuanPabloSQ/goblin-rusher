extends Node2D

@export var advance_interval: float = 1.25

@onready var depth_slots_root: Node2D = $DepthSlots
@onready var enemy: Enemy = $EnemyLayer/EnemyBasic
@onready var advance_timer: Timer = $AdvanceTimer


func _ready() -> void:
	var depth_slots: Array[Marker2D] = _collect_depth_slots()
	enemy.setup_depth_slots(depth_slots)

	if depth_slots.size() <= 1:
		return

	advance_timer.timeout.connect(_on_advance_timer_timeout)
	advance_timer.wait_time = advance_interval
	advance_timer.start()


func _collect_depth_slots() -> Array[Marker2D]:
	var depth_slots: Array[Marker2D] = []

	for child in depth_slots_root.get_children():
		if child is Marker2D:
			depth_slots.append(child as Marker2D)

	return depth_slots


func _on_advance_timer_timeout() -> void:
	if enemy.is_at_final_slot():
		advance_timer.stop()
		return

	enemy.advance_to_next_slot()

	if enemy.is_at_final_slot():
		advance_timer.stop()
