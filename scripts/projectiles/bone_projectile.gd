class_name BoneProjectile
extends Node2D

@export var speed: float = 240.0
@export var impact_distance: float = 12.0
@export var body_color: Color = Color(0.93, 0.9, 0.82)

var damage: int = 1
var _target: Enemy
var _lifetime: float = 0.0


func _ready() -> void:
	z_index = 50
	queue_redraw()


func setup(target_enemy: Enemy, projectile_damage: int) -> void:
	_target = target_enemy
	damage = maxi(projectile_damage, 0)

	if is_instance_valid(_target):
		rotation = (_target.get_projectile_target_position() - global_position).angle()


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

	if distance > 0.0:
		var step_distance: float = min(speed * delta, distance)
		global_position += to_target / distance * step_distance
		rotation = to_target.angle()


func _impact() -> void:
	if is_instance_valid(_target) and _target.is_alive() and damage > 0:
		_target.take_damage(damage)

	queue_free()


func _draw() -> void:
	draw_line(Vector2(-6.0, 0.0), Vector2(6.0, 0.0), body_color, 3.0)
	draw_circle(Vector2(-7.5, -2.0), 2.2, body_color)
	draw_circle(Vector2(-7.5, 2.0), 2.2, body_color)
	draw_circle(Vector2(7.5, -2.0), 2.2, body_color)
	draw_circle(Vector2(7.5, 2.0), 2.2, body_color)
