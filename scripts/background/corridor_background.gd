extends Node2D

const BACKGROUND_COLOR: Color = Color(0.03, 0.02, 0.05)
const CEILING_COLOR: Color = Color(0.11, 0.08, 0.13)
const WALL_COLOR: Color = Color(0.18, 0.11, 0.11)
const FLOOR_COLOR: Color = Color(0.23, 0.12, 0.09)
const FLOOR_STRIPE_COLOR: Color = Color(0.48, 0.23, 0.12)
const TUNNEL_VOID_COLOR: Color = Color(0.01, 0.01, 0.02)
const ARCH_COLOR: Color = Color(0.34, 0.18, 0.15)


func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	queue_redraw()


func _on_viewport_size_changed() -> void:
	queue_redraw()


func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return

	var center_x: float = viewport_size.x * 0.5
	var horizon_y: float = viewport_size.y * 0.36
	var corridor_half_width: float = viewport_size.x * 0.14
	var floor_half_width: float = viewport_size.x * 0.34

	draw_rect(Rect2(Vector2.ZERO, viewport_size), BACKGROUND_COLOR, true)

	var ceiling_points: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(viewport_size.x, 0.0),
		Vector2(center_x + corridor_half_width, horizon_y),
		Vector2(center_x - corridor_half_width, horizon_y),
	])
	draw_colored_polygon(ceiling_points, CEILING_COLOR)

	var floor_points: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, viewport_size.y),
		Vector2(viewport_size.x, viewport_size.y),
		Vector2(center_x + floor_half_width, horizon_y),
		Vector2(center_x - floor_half_width, horizon_y),
	])
	draw_colored_polygon(floor_points, FLOOR_COLOR)

	var left_wall_points: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(center_x - corridor_half_width, horizon_y),
		Vector2(center_x - floor_half_width, viewport_size.y),
		Vector2(0.0, viewport_size.y),
	])
	draw_colored_polygon(left_wall_points, WALL_COLOR)

	var right_wall_points: PackedVector2Array = PackedVector2Array([
		Vector2(viewport_size.x, 0.0),
		Vector2(center_x + corridor_half_width, horizon_y),
		Vector2(center_x + floor_half_width, viewport_size.y),
		Vector2(viewport_size.x, viewport_size.y),
	])
	draw_colored_polygon(right_wall_points, WALL_COLOR)

	var tunnel_opening: PackedVector2Array = _make_ellipse_points(
		Vector2(center_x, horizon_y + 4.0),
		Vector2(24.0, 16.0),
		28
	)
	draw_colored_polygon(tunnel_opening, TUNNEL_VOID_COLOR)

	for index in range(5):
		var ring_t: float = float(index) / 4.0
		var ring_center: Vector2 = Vector2(
			center_x,
			lerp(horizon_y + 5.0, viewport_size.y * 0.60, ring_t)
		)
		var ring_radius: Vector2 = Vector2(
			lerp(28.0, viewport_size.x * 0.34, ring_t),
			lerp(18.0, viewport_size.y * 0.28, ring_t)
		)
		var ring_points: PackedVector2Array = _make_ellipse_points(ring_center, ring_radius, 40)
		draw_polyline(ring_points, ARCH_COLOR, 2.0)

	for stripe_index in range(6):
		var stripe_t: float = float(stripe_index) / 5.0
		var stripe_y: float = lerp(horizon_y + 18.0, viewport_size.y - 14.0, stripe_t)
		var stripe_half_width: float = lerp(8.0, viewport_size.x * 0.16, stripe_t)
		draw_line(
			Vector2(center_x - stripe_half_width, stripe_y),
			Vector2(center_x + stripe_half_width, stripe_y),
			FLOOR_STRIPE_COLOR,
			2.0
		)


func _make_ellipse_points(center: Vector2, radius: Vector2, point_count: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()

	for point_index in range(point_count + 1):
		var angle: float = TAU * float(point_index) / float(point_count)
		points.append(
			center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		)

	return points
