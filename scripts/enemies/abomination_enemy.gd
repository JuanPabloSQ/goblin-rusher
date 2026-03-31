extends Enemy

@export var flesh_color: Color = Color(0.44, 0.26, 0.21)
@export var wound_color: Color = Color(0.67, 0.18, 0.15)
@export var bone_color: Color = Color(0.82, 0.77, 0.67)


func get_projectile_target_position() -> Vector2:
	return global_position + Vector2(0.0, -34.0 * scale.y)


func _draw() -> void:
	draw_circle(Vector2(0.0, 34.0), 34.0, Color(0.0, 0.0, 0.0, 0.38))

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-34.0, -34.0),
			Vector2(-18.0, -58.0),
			Vector2(-8.0, -26.0),
		]),
		outline_color
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(34.0, -34.0),
			Vector2(18.0, -58.0),
			Vector2(8.0, -26.0),
		]),
		outline_color
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-30.0, -33.0),
			Vector2(-18.0, -50.0),
			Vector2(-9.0, -27.0),
		]),
		bone_color
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(30.0, -33.0),
			Vector2(18.0, -50.0),
			Vector2(9.0, -27.0),
		]),
		bone_color
	)

	draw_circle(Vector2(0.0, -14.0), 28.0, outline_color)
	draw_circle(Vector2(0.0, 24.0), 32.0, outline_color)
	draw_circle(Vector2(0.0, -14.0), 24.0, flesh_color)
	draw_circle(Vector2(0.0, 24.0), 28.0, body_color)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-18.0, -4.0),
			Vector2(18.0, -4.0),
			Vector2(14.0, 28.0),
			Vector2(-14.0, 28.0),
		]),
		flesh_color
	)

	draw_line(Vector2(-28.0, -6.0), Vector2(-46.0, 20.0), outline_color, 9.0)
	draw_line(Vector2(28.0, -6.0), Vector2(46.0, 20.0), outline_color, 9.0)
	draw_line(Vector2(-20.0, 40.0), Vector2(-24.0, 62.0), outline_color, 9.0)
	draw_line(Vector2(20.0, 40.0), Vector2(24.0, 62.0), outline_color, 9.0)
	draw_line(Vector2(-28.0, -6.0), Vector2(-46.0, 20.0), flesh_color, 5.0)
	draw_line(Vector2(28.0, -6.0), Vector2(46.0, 20.0), flesh_color, 5.0)
	draw_line(Vector2(-20.0, 40.0), Vector2(-24.0, 62.0), body_color, 5.0)
	draw_line(Vector2(20.0, 40.0), Vector2(24.0, 62.0), body_color, 5.0)

	draw_circle(Vector2(-10.0, -18.0), 4.5, eye_color)
	draw_circle(Vector2(10.0, -18.0), 4.5, eye_color)
	draw_circle(Vector2(-10.0, -18.0), 2.0, Color.WHITE)
	draw_circle(Vector2(10.0, -18.0), 2.0, Color.WHITE)
	draw_line(Vector2(-18.0, -2.0), Vector2(18.0, -2.0), outline_color, 7.0)
	draw_line(Vector2(-18.0, -2.0), Vector2(18.0, -2.0), wound_color, 4.0)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-18.0, -1.0),
			Vector2(-10.0, 11.0),
			Vector2(-5.0, -1.0),
		]),
		bone_color
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-2.0, -1.0),
			Vector2(0.0, 10.0),
			Vector2(2.0, -1.0),
		]),
		bone_color
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(18.0, -1.0),
			Vector2(10.0, 11.0),
			Vector2(5.0, -1.0),
		]),
		bone_color
	)
