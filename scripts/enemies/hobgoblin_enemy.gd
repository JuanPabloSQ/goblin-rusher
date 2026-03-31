extends Enemy

@export var skin_color: Color = Color(0.43, 0.27, 0.15)
@export var armor_color: Color = Color(0.3, 0.18, 0.1)
@export var tusk_color: Color = Color(0.87, 0.8, 0.66)


func get_projectile_target_position() -> Vector2:
	return global_position + Vector2(0.0, -28.0 * scale.y)


func _draw() -> void:
	draw_circle(Vector2(0.0, 26.0), 28.0, Color(0.0, 0.0, 0.0, 0.35))

	var ears_outline: PackedVector2Array = PackedVector2Array([
		Vector2(-30.0, -36.0),
		Vector2(-14.0, -48.0),
		Vector2(-10.0, -26.0),
	])
	var ears_fill: PackedVector2Array = PackedVector2Array([
		Vector2(-27.0, -34.0),
		Vector2(-15.0, -43.0),
		Vector2(-12.0, -27.0),
	])
	draw_colored_polygon(ears_outline, outline_color)
	draw_colored_polygon(_mirror_points(ears_outline), outline_color)
	draw_colored_polygon(ears_fill, skin_color)
	draw_colored_polygon(_mirror_points(ears_fill), skin_color)

	draw_circle(Vector2(0.0, -16.0), 22.0, outline_color)
	draw_circle(Vector2(0.0, 16.0), 24.0, outline_color)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-22.0, -1.0),
			Vector2(22.0, -1.0),
			Vector2(18.0, 28.0),
			Vector2(-18.0, 28.0),
		]),
		outline_color
	)

	draw_circle(Vector2(0.0, -16.0), 18.0, skin_color)
	draw_circle(Vector2(0.0, 16.0), 20.0, armor_color)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-18.0, 2.0),
			Vector2(18.0, 2.0),
			Vector2(15.0, 26.0),
			Vector2(-15.0, 26.0),
		]),
		body_color
	)

	draw_line(Vector2(-21.0, -2.0), Vector2(-32.0, 16.0), outline_color, 7.0)
	draw_line(Vector2(21.0, -2.0), Vector2(32.0, 16.0), outline_color, 7.0)
	draw_line(Vector2(-13.0, 32.0), Vector2(-17.0, 50.0), outline_color, 7.0)
	draw_line(Vector2(13.0, 32.0), Vector2(17.0, 50.0), outline_color, 7.0)
	draw_line(Vector2(-21.0, -2.0), Vector2(-32.0, 16.0), skin_color, 4.0)
	draw_line(Vector2(21.0, -2.0), Vector2(32.0, 16.0), skin_color, 4.0)
	draw_line(Vector2(-13.0, 32.0), Vector2(-17.0, 50.0), armor_color, 4.0)
	draw_line(Vector2(13.0, 32.0), Vector2(17.0, 50.0), armor_color, 4.0)

	draw_line(Vector2(-8.0, -20.0), Vector2(-2.0, -17.0), outline_color, 4.0)
	draw_line(Vector2(8.0, -20.0), Vector2(2.0, -17.0), outline_color, 4.0)
	draw_circle(Vector2(-7.0, -20.0), 2.4, eye_color)
	draw_circle(Vector2(7.0, -20.0), 2.4, eye_color)
	draw_line(Vector2(-9.0, -7.0), Vector2(9.0, -7.0), outline_color, 4.0)
	draw_line(Vector2(-9.0, -7.0), Vector2(9.0, -7.0), Color(0.18, 0.08, 0.04), 2.0)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-9.0, -6.0),
			Vector2(-3.0, 5.0),
			Vector2(-1.0, -6.0),
		]),
		tusk_color
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(9.0, -6.0),
			Vector2(3.0, 5.0),
			Vector2(1.0, -6.0),
		]),
		tusk_color
	)


func _mirror_points(points: PackedVector2Array) -> PackedVector2Array:
	var mirrored_points: PackedVector2Array = PackedVector2Array()

	for point in points:
		mirrored_points.append(Vector2(-point.x, point.y))

	return mirrored_points
