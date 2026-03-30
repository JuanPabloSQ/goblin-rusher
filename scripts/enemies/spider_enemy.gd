extends Enemy

@export var abdomen_color: Color = Color(0.15, 0.13, 0.2)
@export var cephalothorax_color: Color = Color(0.21, 0.17, 0.24)


func get_projectile_target_position() -> Vector2:
	return global_position + Vector2(0.0, -10.0 * scale.y)


func _draw() -> void:
	draw_circle(Vector2(0.0, 15.0), 20.0, Color(0.0, 0.0, 0.0, 0.32))

	var leg_pairs: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(-6.0, -16.0), Vector2(-18.0, -24.0), Vector2(-29.0, -20.0)]),
		PackedVector2Array([Vector2(-8.0, -10.0), Vector2(-24.0, -10.0), Vector2(-33.0, -4.0)]),
		PackedVector2Array([Vector2(-8.0, -4.0), Vector2(-24.0, 2.0), Vector2(-31.0, 11.0)]),
		PackedVector2Array([Vector2(-6.0, 2.0), Vector2(-16.0, 14.0), Vector2(-22.0, 25.0)]),
		PackedVector2Array([Vector2(6.0, -16.0), Vector2(18.0, -24.0), Vector2(29.0, -20.0)]),
		PackedVector2Array([Vector2(8.0, -10.0), Vector2(24.0, -10.0), Vector2(33.0, -4.0)]),
		PackedVector2Array([Vector2(8.0, -4.0), Vector2(24.0, 2.0), Vector2(31.0, 11.0)]),
		PackedVector2Array([Vector2(6.0, 2.0), Vector2(16.0, 14.0), Vector2(22.0, 25.0)]),
	]

	for leg_points in leg_pairs:
		draw_polyline(leg_points, outline_color, 6.0)

	draw_circle(Vector2(0.0, -5.0), 14.0, outline_color)
	draw_circle(Vector2(0.0, -18.0), 10.0, outline_color)

	for leg_points in leg_pairs:
		draw_polyline(leg_points, body_color, 3.0)

	draw_circle(Vector2(0.0, -5.0), 11.0, abdomen_color)
	draw_circle(Vector2(0.0, -18.0), 7.5, cephalothorax_color)

	draw_circle(Vector2(-5.0, -20.0), 1.8, eye_color)
	draw_circle(Vector2(-1.5, -22.0), 1.5, eye_color)
	draw_circle(Vector2(1.5, -22.0), 1.5, eye_color)
	draw_circle(Vector2(5.0, -20.0), 1.8, eye_color)
