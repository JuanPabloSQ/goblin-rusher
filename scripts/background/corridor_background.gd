extends Node2D

const BACKGROUND_COLOR: Color = Color(0.03, 0.02, 0.05)
const CEILING_COLOR: Color = Color(0.11, 0.08, 0.13)
const WALL_COLOR: Color = Color(0.18, 0.11, 0.11)
const WALL_HIGHLIGHT_COLOR: Color = Color(0.24, 0.15, 0.14)
const FLOOR_COLOR: Color = Color(0.23, 0.12, 0.09)
const FLOOR_RUNNER_COLOR: Color = Color(0.3, 0.14, 0.09)
const FLOOR_EDGE_COLOR: Color = Color(0.53, 0.26, 0.13)
const FLOOR_STRIPE_COLOR: Color = Color(0.48, 0.23, 0.12)
const TUNNEL_VOID_COLOR: Color = Color(0.01, 0.01, 0.02)
const ARCH_COLOR: Color = Color(0.34, 0.18, 0.15)
const SIDE_PILLAR_COLOR: Color = Color(0.15, 0.09, 0.1)
const SIDE_RUBBLE_COLOR: Color = Color(0.16, 0.1, 0.08)
const TORCH_METAL_COLOR: Color = Color(0.42, 0.31, 0.18)
const TORCH_FIRE_COLOR: Color = Color(1.0, 0.62, 0.18)
const TORCH_GLOW_OUTER_COLOR: Color = Color(0.96, 0.42, 0.14, 0.08)
const TORCH_GLOW_INNER_COLOR: Color = Color(1.0, 0.78, 0.32, 0.16)
const VIGNETTE_COLOR: Color = Color(0.0, 0.0, 0.0, 0.18)
const HUD_HEIGHT: float = 44.0


func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	queue_redraw()


func _on_viewport_size_changed() -> void:
	queue_redraw()


func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return

	var gameplay_bottom: float = viewport_size.y - HUD_HEIGHT
	var center_x: float = viewport_size.x * 0.5
	var horizon_y: float = gameplay_bottom * 0.43
	var corridor_half_width: float = viewport_size.x * 0.11
	var floor_half_width: float = viewport_size.x * 0.34
	var runner_half_width: float = viewport_size.x * 0.11

	draw_rect(Rect2(Vector2.ZERO, viewport_size), BACKGROUND_COLOR, true)

	var ceiling_points: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(viewport_size.x, 0.0),
		Vector2(center_x + corridor_half_width, horizon_y),
		Vector2(center_x - corridor_half_width, horizon_y),
	])
	draw_colored_polygon(ceiling_points, CEILING_COLOR)

	var floor_points: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, gameplay_bottom),
		Vector2(viewport_size.x, gameplay_bottom),
		Vector2(center_x + floor_half_width, horizon_y),
		Vector2(center_x - floor_half_width, horizon_y),
	])
	draw_colored_polygon(floor_points, FLOOR_COLOR)

	var left_wall_points: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(center_x - corridor_half_width, horizon_y),
		Vector2(center_x - floor_half_width, gameplay_bottom),
		Vector2(0.0, gameplay_bottom),
	])
	draw_colored_polygon(left_wall_points, WALL_COLOR)

	var right_wall_points: PackedVector2Array = PackedVector2Array([
		Vector2(viewport_size.x, 0.0),
		Vector2(center_x + corridor_half_width, horizon_y),
		Vector2(center_x + floor_half_width, gameplay_bottom),
		Vector2(viewport_size.x, gameplay_bottom),
	])
	draw_colored_polygon(right_wall_points, WALL_COLOR)

	var runner_points: PackedVector2Array = PackedVector2Array([
		Vector2(center_x - runner_half_width, gameplay_bottom),
		Vector2(center_x + runner_half_width, gameplay_bottom),
		Vector2(center_x + corridor_half_width * 0.18, horizon_y + 8.0),
		Vector2(center_x - corridor_half_width * 0.18, horizon_y + 8.0),
	])
	draw_colored_polygon(runner_points, FLOOR_RUNNER_COLOR)

	draw_line(
		Vector2(center_x - runner_half_width, gameplay_bottom),
		Vector2(center_x - corridor_half_width * 0.18, horizon_y + 8.0),
		FLOOR_EDGE_COLOR,
		2.0
	)
	draw_line(
		Vector2(center_x + runner_half_width, gameplay_bottom),
		Vector2(center_x + corridor_half_width * 0.18, horizon_y + 8.0),
		FLOOR_EDGE_COLOR,
		2.0
	)

	_draw_pillar(
		Vector2(viewport_size.x * 0.18, horizon_y + 20.0),
		Vector2(28.0, gameplay_bottom - horizon_y - 20.0)
	)
	_draw_pillar(
		Vector2(viewport_size.x * 0.82, horizon_y + 20.0),
		Vector2(28.0, gameplay_bottom - horizon_y - 20.0)
	)

	var tunnel_opening: PackedVector2Array = _make_ellipse_points(
		Vector2(center_x, horizon_y + 4.0),
		Vector2(20.0, 16.0),
		28
	)
	draw_colored_polygon(tunnel_opening, TUNNEL_VOID_COLOR)

	for index in range(6):
		var arch_t: float = float(index) / 5.0
		var arch_center: Vector2 = Vector2(
			center_x,
			lerp(horizon_y - 5.0, gameplay_bottom * 0.52, arch_t)
		)
		var arch_radius: Vector2 = Vector2(
			lerp(24.0, viewport_size.x * 0.33, arch_t),
			lerp(26.0, gameplay_bottom * 0.34, arch_t)
		)
		var arch_points: PackedVector2Array = _make_arc_points(arch_center, arch_radius, PI, TAU, 28)
		draw_polyline(arch_points, ARCH_COLOR, 3.0 if index >= 3 else 2.0)

	for stripe_index in range(6):
		var stripe_t: float = float(stripe_index) / 6.0
		var stripe_y: float = lerp(horizon_y + 14.0, gameplay_bottom - 12.0, stripe_t)
		var stripe_half_width: float = lerp(6.0, viewport_size.x * 0.11, stripe_t)
		draw_line(
			Vector2(center_x - stripe_half_width, stripe_y),
			Vector2(center_x + stripe_half_width, stripe_y),
			FLOOR_STRIPE_COLOR,
			2.0
		)

	for stage_y in _get_stage_floor_lines(gameplay_bottom):
		var stage_t: float = inverse_lerp(horizon_y + 10.0, gameplay_bottom, stage_y)
		var stage_runner_half_width: float = lerp(corridor_half_width * 0.24, runner_half_width * 1.02, stage_t)
		var stage_floor_half_width: float = lerp(corridor_half_width * 0.62, floor_half_width * 0.92, stage_t)

		draw_line(
			Vector2(center_x - stage_floor_half_width, stage_y),
			Vector2(center_x + stage_floor_half_width, stage_y),
			Color(FLOOR_EDGE_COLOR.r, FLOOR_EDGE_COLOR.g, FLOOR_EDGE_COLOR.b, 0.28),
			1.0
		)
		draw_line(
			Vector2(center_x - stage_runner_half_width, stage_y),
			Vector2(center_x + stage_runner_half_width, stage_y),
			Color(0.85, 0.56, 0.24, 0.95),
			3.0
		)

	for wall_slot in _get_route_slots("WallLeftSlots"):
		_draw_wall_stage_mark(wall_slot.position, true)

	for wall_slot in _get_route_slots("WallRightSlots"):
		_draw_wall_stage_mark(wall_slot.position, false)

	draw_line(
		Vector2(center_x - floor_half_width * 0.96, gameplay_bottom),
		Vector2(center_x - corridor_half_width, horizon_y),
		WALL_HIGHLIGHT_COLOR,
		2.0
	)
	draw_line(
		Vector2(center_x + floor_half_width * 0.96, gameplay_bottom),
		Vector2(center_x + corridor_half_width, horizon_y),
		WALL_HIGHLIGHT_COLOR,
		2.0
	)

	_draw_torch(Vector2(56.0, horizon_y + 34.0))
	_draw_torch(Vector2(viewport_size.x - 56.0, horizon_y + 34.0))
	_draw_rubble(Vector2(42.0, gameplay_bottom - 8.0), 24.0)
	_draw_rubble(Vector2(viewport_size.x - 42.0, gameplay_bottom - 8.0), 24.0)
	_draw_vignette(viewport_size, gameplay_bottom)


func _make_ellipse_points(center: Vector2, radius: Vector2, point_count: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()

	for point_index in range(point_count + 1):
		var angle: float = TAU * float(point_index) / float(point_count)
		points.append(
			center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		)

	return points


func _make_arc_points(center: Vector2, radius: Vector2, start_angle: float, end_angle: float, point_count: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()

	for point_index in range(point_count + 1):
		var t: float = float(point_index) / float(point_count)
		var angle: float = lerp(start_angle, end_angle, t)
		points.append(
			center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		)

	return points


func _get_stage_floor_lines(gameplay_bottom: float) -> Array[float]:
	var stage_lines: Array[float] = []
	for slot in _get_route_slots("CenterSlots"):
		var floor_y: float = min(slot.position.y + 12.0 * slot.scale.y, gameplay_bottom - 2.0)
		stage_lines.append(floor_y)

	return stage_lines


func _get_route_slots(route_root_name: String) -> Array[Marker2D]:
	var route_slots: Array[Marker2D] = []
	var parent_node: Node = get_parent()

	if parent_node == null:
		return route_slots

	var route_root: Node = parent_node.get_node_or_null("DepthSlots/%s" % route_root_name)
	if route_root == null:
		return route_slots

	for child in route_root.get_children():
		if child is Marker2D:
			route_slots.append(child as Marker2D)

	return route_slots


func _draw_pillar(center: Vector2, size: Vector2) -> void:
	var rect: Rect2 = Rect2(center - size * 0.5, size)
	draw_rect(rect, SIDE_PILLAR_COLOR, true)
	draw_line(rect.position, rect.position + Vector2(rect.size.x, 0.0), WALL_HIGHLIGHT_COLOR, 2.0)
	draw_line(
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		Color(0.08, 0.05, 0.06),
		2.0
	)


func _draw_torch(position: Vector2) -> void:
	draw_circle(position, 18.0, TORCH_GLOW_OUTER_COLOR)
	draw_circle(position, 11.0, TORCH_GLOW_INNER_COLOR)
	draw_rect(Rect2(position + Vector2(-1.5, -7.0), Vector2(3.0, 9.0)), TORCH_METAL_COLOR, true)
	draw_circle(position + Vector2(0.0, -1.0), 2.6, TORCH_FIRE_COLOR)
	draw_circle(position + Vector2(0.0, 0.0), 1.4, Color(1.0, 0.95, 0.75, 0.95))


func _draw_rubble(center: Vector2, width: float) -> void:
	for offset_index in range(4):
		var x_offset: float = (float(offset_index) - 1.5) * width * 0.22
		var y_offset: float = abs(float(offset_index) - 1.5) * 1.5
		draw_circle(center + Vector2(x_offset, y_offset), 5.0 - abs(float(offset_index) - 1.5), SIDE_RUBBLE_COLOR)


func _draw_wall_stage_mark(position: Vector2, is_left_wall: bool) -> void:
	var horizontal_sign: float = 1.0 if is_left_wall else -1.0
	var mark_color: Color = Color(0.79, 0.45, 0.23, 0.52)
	var mark_start: Vector2 = position + Vector2(-6.0 * horizontal_sign, -6.0)
	var mark_end: Vector2 = position + Vector2(10.0 * horizontal_sign, 6.0)
	draw_line(mark_start, mark_end, mark_color, 2.0)
	draw_circle(position + Vector2(4.0 * horizontal_sign, 0.0), 1.6, Color(0.95, 0.72, 0.38, 0.78))


func _draw_vignette(viewport_size: Vector2, gameplay_bottom: float) -> void:
	draw_circle(Vector2(0.0, 0.0), 74.0, VIGNETTE_COLOR)
	draw_circle(Vector2(viewport_size.x, 0.0), 74.0, VIGNETTE_COLOR)
	draw_circle(Vector2(0.0, gameplay_bottom), 78.0, VIGNETTE_COLOR)
	draw_circle(Vector2(viewport_size.x, gameplay_bottom), 78.0, VIGNETTE_COLOR)
