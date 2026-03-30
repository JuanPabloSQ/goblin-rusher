class_name Enemy
extends Area2D

@export var move_duration: float = 0.4
@export var body_color: Color = Color(0.84, 0.82, 0.72)
@export var eye_color: Color = Color(1.0, 0.2, 0.14)

var _depth_slots: Array[Marker2D] = []
var _current_slot_index: int = -1
var _move_tween: Tween


func _ready() -> void:
	queue_redraw()


func setup_depth_slots(depth_slots: Array[Marker2D]) -> void:
	_depth_slots.clear()
	_depth_slots.append_array(depth_slots)

	if _depth_slots.is_empty():
		return

	_current_slot_index = 0
	_apply_slot(_current_slot_index, true)


func advance_to_next_slot() -> bool:
	if _depth_slots.is_empty():
		return false

	if is_at_final_slot():
		_apply_slot(_depth_slots.size() - 1, true)
		return false

	_current_slot_index += 1
	_apply_slot(_current_slot_index, false)
	return true


func is_at_final_slot() -> bool:
	return not _depth_slots.is_empty() and _current_slot_index >= _depth_slots.size() - 1


func _apply_slot(slot_index: int, immediate: bool) -> void:
	var slot: Marker2D = _depth_slots[slot_index]
	z_index = slot_index + 1

	if is_instance_valid(_move_tween):
		_move_tween.kill()

	if immediate:
		global_position = slot.global_position
		scale = slot.scale
		return

	_move_tween = create_tween()
	_move_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(self, "global_position", slot.global_position, move_duration)
	_move_tween.parallel().tween_property(self, "scale", slot.scale, move_duration)


func _draw() -> void:
	draw_circle(Vector2(0.0, 17.0), 18.0, Color(0.0, 0.0, 0.0, 0.35))
	draw_circle(Vector2(0.0, -20.0), 10.0, body_color)
	draw_line(Vector2(0.0, -10.0), Vector2(0.0, 12.0), body_color, 3.0)
	draw_line(Vector2(-10.0, -2.0), Vector2(10.0, -2.0), body_color, 3.0)
	draw_line(Vector2(-6.0, 12.0), Vector2(-11.0, 29.0), body_color, 3.0)
	draw_line(Vector2(6.0, 12.0), Vector2(11.0, 29.0), body_color, 3.0)
	draw_line(Vector2(-10.0, -2.0), Vector2(-17.0, 8.0), body_color, 3.0)
	draw_line(Vector2(10.0, -2.0), Vector2(17.0, 8.0), body_color, 3.0)
	draw_circle(Vector2(-4.0, -22.0), 1.6, eye_color)
	draw_circle(Vector2(4.0, -22.0), 1.6, eye_color)
