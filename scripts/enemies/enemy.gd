class_name Enemy
extends Area2D

signal clicked(enemy: Enemy)
signal died(enemy: Enemy)

enum PathType {
	CENTER,
	WALL_LEFT,
	WALL_RIGHT,
}

const PATH_FLAG_CENTER: int = 1 << PathType.CENTER
const PATH_FLAG_WALL_LEFT: int = 1 << PathType.WALL_LEFT
const PATH_FLAG_WALL_RIGHT: int = 1 << PathType.WALL_RIGHT

@export_range(1, 99, 1) var max_health: int = 3
@export var move_duration: float = 0.4
@export var body_color: Color = Color(0.84, 0.82, 0.72)
@export var eye_color: Color = Color(1.0, 0.2, 0.14)
@export var hit_flash_color: Color = Color(1.0, 0.45, 0.35)
@export var outline_color: Color = Color(0.08, 0.05, 0.05)
@export_flags("Centro", "Muralla izquierda", "Muralla derecha") var allowed_paths: int = PATH_FLAG_CENTER

var _depth_slots: Array[Marker2D] = []
var _current_slot_index: int = -1
var _current_health: int = 0
var _is_dead: bool = false
var _path_type: int = PathType.CENTER
var _move_tween: Tween
var _flash_tween: Tween


func _ready() -> void:
	_current_health = max_health
	input_pickable = true
	input_event.connect(_on_input_event)
	_on_path_type_changed()


func setup_depth_slots(depth_slots: Array[Marker2D], path_type: int = PathType.CENTER) -> void:
	_depth_slots.clear()
	_depth_slots.append_array(depth_slots)
	_path_type = path_type
	_on_path_type_changed()

	if _depth_slots.is_empty():
		return

	_current_slot_index = 0
	_apply_slot(_current_slot_index, true)


func advance_to_next_slot() -> bool:
	if _depth_slots.is_empty() or _is_dead:
		return false

	if is_at_final_slot():
		_apply_slot(_depth_slots.size() - 1, true)
		return false

	_current_slot_index += 1
	_apply_slot(_current_slot_index, false)
	return true


func is_at_final_slot() -> bool:
	return not _depth_slots.is_empty() and _current_slot_index >= _depth_slots.size() - 1


func is_alive() -> bool:
	return not _is_dead


func can_use_path(path_type: int) -> bool:
	return (allowed_paths & (1 << path_type)) != 0


func get_path_type() -> int:
	return _path_type


func is_wall_path() -> bool:
	return _path_type == PathType.WALL_LEFT or _path_type == PathType.WALL_RIGHT


func get_projectile_target_position() -> Vector2:
	return global_position + Vector2(0.0, -18.0 * scale.y)


func get_current_stage() -> int:
	if _depth_slots.is_empty():
		return 0

	return _current_slot_index + 1


func get_total_stages() -> int:
	return _depth_slots.size()


func take_damage(amount: int) -> void:
	if _is_dead:
		return

	var applied_damage: int = maxi(amount, 0)
	if applied_damage <= 0:
		return

	_current_health = maxi(_current_health - applied_damage, 0)
	_play_hit_flash()

	if _current_health == 0:
		_die()


func freeze() -> void:
	input_pickable = false
	monitoring = false
	monitorable = false

	if is_instance_valid(_move_tween):
		_move_tween.kill()

	if is_instance_valid(_flash_tween):
		_flash_tween.kill()


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

	var pop_scale: Vector2 = slot.scale * 1.12
	_move_tween.parallel().tween_property(self, "scale", pop_scale, move_duration * 0.72)
	_move_tween.tween_property(self, "scale", slot.scale, move_duration * 0.18)


func _play_hit_flash() -> void:
	if is_instance_valid(_flash_tween):
		_flash_tween.kill()

	modulate = Color.WHITE
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", hit_flash_color, 0.05)
	_flash_tween.tween_property(self, "modulate", Color.WHITE, 0.09)


func _die() -> void:
	if _is_dead:
		return

	_is_dead = true
	input_pickable = false
	monitoring = false
	monitorable = false

	if is_instance_valid(_move_tween):
		_move_tween.kill()

	if is_instance_valid(_flash_tween):
		_flash_tween.kill()

	died.emit(self)
	modulate = hit_flash_color

	var death_tween: Tween = create_tween()
	death_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	death_tween.tween_property(self, "modulate", Color(hit_flash_color.r, hit_flash_color.g, hit_flash_color.b, 0.0), 0.12)
	death_tween.parallel().tween_property(self, "scale", scale * 1.12, 0.12)
	death_tween.tween_callback(Callable(self, "queue_free"))


func _on_path_type_changed() -> void:
	queue_redraw()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _is_dead:
		return

	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
			clicked.emit(self)


func _draw() -> void:
	draw_circle(Vector2(0.0, 17.0), 18.0, Color(0.0, 0.0, 0.0, 0.35))
	draw_circle(Vector2(0.0, -20.0), 12.0, outline_color)
	draw_line(Vector2(0.0, -10.0), Vector2(0.0, 12.0), outline_color, 5.0)
	draw_line(Vector2(-10.0, -2.0), Vector2(10.0, -2.0), outline_color, 5.0)
	draw_line(Vector2(-6.0, 12.0), Vector2(-11.0, 29.0), outline_color, 5.0)
	draw_line(Vector2(6.0, 12.0), Vector2(11.0, 29.0), outline_color, 5.0)
	draw_line(Vector2(-10.0, -2.0), Vector2(-17.0, 8.0), outline_color, 5.0)
	draw_line(Vector2(10.0, -2.0), Vector2(17.0, 8.0), outline_color, 5.0)
	draw_circle(Vector2(0.0, -20.0), 10.0, body_color)
	draw_line(Vector2(0.0, -10.0), Vector2(0.0, 12.0), body_color, 3.0)
	draw_line(Vector2(-10.0, -2.0), Vector2(10.0, -2.0), body_color, 3.0)
	draw_line(Vector2(-6.0, 12.0), Vector2(-11.0, 29.0), body_color, 3.0)
	draw_line(Vector2(6.0, 12.0), Vector2(11.0, 29.0), body_color, 3.0)
	draw_line(Vector2(-10.0, -2.0), Vector2(-17.0, 8.0), body_color, 3.0)
	draw_line(Vector2(10.0, -2.0), Vector2(17.0, 8.0), body_color, 3.0)
	draw_circle(Vector2(-4.0, -22.0), 1.6, eye_color)
	draw_circle(Vector2(4.0, -22.0), 1.6, eye_color)
