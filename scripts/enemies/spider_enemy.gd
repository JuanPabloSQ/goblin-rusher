extends Enemy

@export var abdomen_color: Color = Color(0.15, 0.13, 0.2)
@export var cephalothorax_color: Color = Color(0.21, 0.17, 0.24)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func get_projectile_target_position() -> Vector2:
	if is_wall_path():
		return global_position + Vector2(6.0 * _get_room_side_sign() * scale.x, -8.0 * scale.y)

	return global_position + Vector2(0.0, -6.0 * scale.y)


func _on_path_type_changed() -> void:
	_update_collision_shape_for_path()
	queue_redraw()


func _draw() -> void:
	if is_wall_path():
		_draw_wall_spider()
		return

	_draw_floor_spider()


func _draw_floor_spider() -> void:
	draw_circle(Vector2(0.0, 18.0), 24.0, Color(0.0, 0.0, 0.0, 0.34))

	var left_leg_paths: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(-7.0, -8.0), Vector2(-18.0, -12.0), Vector2(-30.0, -8.0), Vector2(-39.0, -2.0)]),
		PackedVector2Array([Vector2(-10.0, -3.0), Vector2(-23.0, -1.0), Vector2(-35.0, 5.0), Vector2(-43.0, 11.0)]),
		PackedVector2Array([Vector2(-11.0, 1.0), Vector2(-24.0, 7.0), Vector2(-34.0, 14.0), Vector2(-40.0, 20.0)]),
		PackedVector2Array([Vector2(-8.0, 5.0), Vector2(-17.0, 15.0), Vector2(-25.0, 24.0), Vector2(-31.0, 30.0)]),
	]

	for leg_points in left_leg_paths:
		_draw_leg(leg_points)
		_draw_leg(_transform_points(leg_points, -1.0))

	draw_circle(Vector2(0.0, 0.0), 16.0, outline_color)
	draw_circle(Vector2(0.0, -8.0), 10.5, outline_color)
	draw_circle(Vector2(0.0, 0.0), 12.5, abdomen_color)
	draw_circle(Vector2(0.0, -8.0), 8.0, cephalothorax_color)

	draw_line(Vector2(-4.0, -2.0), Vector2(-8.0, 5.0), outline_color, 3.0)
	draw_line(Vector2(4.0, -2.0), Vector2(8.0, 5.0), outline_color, 3.0)
	draw_line(Vector2(-4.0, -2.0), Vector2(-8.0, 5.0), body_color, 1.5)
	draw_line(Vector2(4.0, -2.0), Vector2(8.0, 5.0), body_color, 1.5)

	draw_circle(Vector2(-6.5, -10.0), 1.7, eye_color)
	draw_circle(Vector2(-2.0, -12.0), 1.4, eye_color)
	draw_circle(Vector2(2.0, -12.0), 1.4, eye_color)
	draw_circle(Vector2(6.5, -10.0), 1.7, eye_color)


func _draw_wall_spider() -> void:
	var room_side_sign: float = _get_room_side_sign()
	draw_colored_polygon(
		_make_ellipse_points(
			Vector2(-12.0 * room_side_sign, 1.0),
			Vector2(8.0, 22.0),
			14
		),
		Color(0.0, 0.0, 0.0, 0.18)
	)

	var base_leg_paths: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(6.0, -22.0), Vector2(18.0, -27.0), Vector2(29.0, -23.0)]),
		PackedVector2Array([Vector2(8.0, -11.0), Vector2(22.0, -14.0), Vector2(34.0, -8.0)]),
		PackedVector2Array([Vector2(8.0, 1.0), Vector2(22.0, 4.0), Vector2(34.0, 10.0)]),
		PackedVector2Array([Vector2(6.0, 13.0), Vector2(18.0, 18.0), Vector2(27.0, 25.0)]),
		PackedVector2Array([Vector2(-5.0, -20.0), Vector2(-10.0, -26.0), Vector2(-14.0, -22.0)]),
		PackedVector2Array([Vector2(-7.0, -10.0), Vector2(-13.0, -13.0), Vector2(-17.0, -9.0)]),
		PackedVector2Array([Vector2(-7.0, 0.0), Vector2(-13.0, 5.0), Vector2(-17.0, 11.0)]),
		PackedVector2Array([Vector2(-5.0, 11.0), Vector2(-10.0, 18.0), Vector2(-14.0, 25.0)]),
	]

	for leg_points in base_leg_paths:
		_draw_leg(_transform_points(leg_points, room_side_sign))

	draw_circle(Vector2(0.0, 7.0), 14.5, outline_color)
	draw_circle(Vector2(0.0, -11.0), 10.0, outline_color)
	draw_line(Vector2(0.0, -2.0), Vector2(0.0, 0.0), outline_color, 4.5)

	draw_circle(Vector2(0.0, 7.0), 11.5, abdomen_color)
	draw_circle(Vector2(0.0, -11.0), 7.3, cephalothorax_color)
	draw_line(Vector2(0.0, -2.0), Vector2(0.0, 0.0), body_color, 2.2)

	var fang_base: Vector2 = Vector2(3.0 * room_side_sign, -7.0)
	var fang_tip_upper: Vector2 = Vector2(9.0 * room_side_sign, -3.0)
	var fang_tip_lower: Vector2 = Vector2(9.0 * room_side_sign, 1.0)
	draw_line(fang_base, fang_tip_upper, outline_color, 2.8)
	draw_line(fang_base, fang_tip_lower, outline_color, 2.8)
	draw_line(fang_base, fang_tip_upper, body_color, 1.4)
	draw_line(fang_base, fang_tip_lower, body_color, 1.4)

	draw_circle(Vector2(4.5 * room_side_sign, -13.0), 1.6, eye_color)
	draw_circle(Vector2(7.0 * room_side_sign, -9.5), 1.3, eye_color)
	draw_circle(Vector2(6.0 * room_side_sign, -15.5), 1.2, eye_color)


func _draw_leg(points: PackedVector2Array) -> void:
	draw_polyline(points, outline_color, 5.5)
	draw_polyline(points, body_color, 2.8)


func _transform_points(points: PackedVector2Array, horizontal_sign: float) -> PackedVector2Array:
	var transformed_points: PackedVector2Array = PackedVector2Array()

	for point in points:
		transformed_points.append(Vector2(point.x * horizontal_sign, point.y))

	return transformed_points


func _make_ellipse_points(center: Vector2, radius: Vector2, point_count: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()

	for point_index in range(point_count + 1):
		var angle: float = TAU * float(point_index) / float(point_count)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))

	return points


func _update_collision_shape_for_path() -> void:
	if collision_shape == null:
		return

	var rectangle_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
	if rectangle_shape == null:
		return

	if is_wall_path():
		rectangle_shape.size = Vector2(48.0, 74.0)
		collision_shape.position = Vector2(0.0, 2.0)
		return

	rectangle_shape.size = Vector2(78.0, 44.0)
	collision_shape.position = Vector2(0.0, 6.0)


func _get_room_side_sign() -> float:
	return 1.0 if get_path_type() == Enemy.PathType.WALL_LEFT else -1.0
