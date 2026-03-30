class_name BoneProjectile
extends Node2D

signal impacted

@export var speed: float = 240.0
@export var impact_distance: float = 10.0
@export var body_color: Color = Color(0.93, 0.9, 0.82)
@export var outline_color: Color = Color(0.18, 0.12, 0.08)
@export var arc_height_factor: float = 0.2
@export var min_arc_height: float = 14.0
@export var max_arc_height: float = 28.0
@export var start_visual_scale: float = 1.15

var damage: int = 1
var _target: Enemy
var _start_position: Vector2 = Vector2.ZERO
var _flight_progress: float = 0.0
var _flight_duration: float = 0.35
var _lifetime: float = 0.0


func _ready() -> void:
	z_index = 50
	queue_redraw()


func setup(target_enemy: Enemy, projectile_damage: int) -> void:
	_target = target_enemy
	damage = maxi(projectile_damage, 0)
	_start_position = global_position
	scale = Vector2.ONE * start_visual_scale

	if is_instance_valid(_target):
		var target_position: Vector2 = _target.get_projectile_target_position()
		_flight_duration = clampf(_start_position.distance_to(target_position) / speed, 0.16, 0.42)
		rotation = (target_position - global_position).angle()


func _process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= 2.5:
		queue_free()
		return

	if not is_instance_valid(_target) or not _target.is_alive():
		queue_free()
		return

	var target_position: Vector2 = _target.get_projectile_target_position()
	var to_target: Vector2 = target_position - global_position
	var distance: float = to_target.length()

	if distance <= impact_distance:
		_impact()
		return

	_flight_progress = min(_flight_progress + delta / _flight_duration, 1.0)
	var arc_height: float = clampf(_start_position.distance_to(target_position) * arc_height_factor, min_arc_height, max_arc_height)
	var control_point: Vector2 = _start_position.lerp(target_position, 0.5) + Vector2(0.0, -arc_height)
	global_position = _quadratic_bezier(_start_position, control_point, target_position, _flight_progress)

	var tangent: Vector2 = _quadratic_bezier_tangent(_start_position, control_point, target_position, _flight_progress)
	if tangent.length_squared() > 0.0:
		rotation = tangent.angle()

	var target_scale: float = clampf(_target.scale.x * 0.95, 0.46, 1.0)
	scale = Vector2.ONE * lerpf(start_visual_scale, target_scale, _flight_progress)

	if _flight_progress >= 1.0:
		_impact()


func _impact() -> void:
	impacted.emit()

	if is_instance_valid(_target) and _target.is_alive() and damage > 0:
		_target.take_damage(damage)

	queue_free()


func _draw() -> void:
	draw_line(Vector2(-6.0, 0.0), Vector2(6.0, 0.0), outline_color, 5.0)
	draw_circle(Vector2(-7.5, -2.0), 3.3, outline_color)
	draw_circle(Vector2(-7.5, 2.0), 3.3, outline_color)
	draw_circle(Vector2(7.5, -2.0), 3.3, outline_color)
	draw_circle(Vector2(7.5, 2.0), 3.3, outline_color)
	draw_line(Vector2(-6.0, 0.0), Vector2(6.0, 0.0), body_color, 3.0)
	draw_circle(Vector2(-7.5, -2.0), 2.2, body_color)
	draw_circle(Vector2(-7.5, 2.0), 2.2, body_color)
	draw_circle(Vector2(7.5, -2.0), 2.2, body_color)
	draw_circle(Vector2(7.5, 2.0), 2.2, body_color)


func _quadratic_bezier(start: Vector2, control: Vector2, end: Vector2, t: float) -> Vector2:
	var inverse_t: float = 1.0 - t
	return inverse_t * inverse_t * start + 2.0 * inverse_t * t * control + t * t * end


func _quadratic_bezier_tangent(start: Vector2, control: Vector2, end: Vector2, t: float) -> Vector2:
	return 2.0 * (1.0 - t) * (control - start) + 2.0 * t * (end - control)
