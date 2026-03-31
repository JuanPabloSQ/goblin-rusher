extends Enemy

@export var abdomen_color: Color = Color(0.15, 0.13, 0.2)
@export var cephalothorax_color: Color = Color(0.21, 0.17, 0.24)


func get_projectile_target_position() -> Vector2:
	return global_position + Vector2(0.0, -6.0 * scale.y)


func _draw() -> void:
	draw_circle(Vector2(0.0, 18.0), 24.0, Color(0.0, 0.0, 0.0, 0.34))

	var left_leg_paths: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(-7.0, -8.0), Vector2(-18.0, -12.0), Vector2(-30.0, -8.0), Vector2(-39.0, -2.0)]),
		PackedVector2Array([Vector2(-10.0, -3.0), Vector2(-23.0, -1.0), Vector2(-35.0, 5.0), Vector2(-43.0, 11.0)]),
		PackedVector2Array([Vector2(-11.0, 1.0), Vector2(-24.0, 7.0), Vector2(-34.0, 14.0), Vector2(-40.0, 20.0)]),
		PackedVector2Array([Vector2(-8.0, 5.0), Vector2(-17.0, 15.0), Vector2(-25.0, 24.0), Vector2(-31.0, 30.0)]),
	]

	for leg_points in left_leg_paths:
		_draw_leg(leg_points)
		_draw_leg(_mirror_points(leg_points))

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


func _draw_leg(points: PackedVector2Array) -> void:
	draw_polyline(points, outline_color, 5.5)
	draw_polyline(points, body_color, 2.8)


func _mirror_points(points: PackedVector2Array) -> PackedVector2Array:
	var mirrored_points: PackedVector2Array = PackedVector2Array()

	for point in points:
		mirrored_points.append(Vector2(-point.x, point.y))

	return mirrored_points
