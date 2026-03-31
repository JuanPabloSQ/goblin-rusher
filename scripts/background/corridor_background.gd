extends Node2D

const BACKGROUND_COLOR: Color = Color(0.03, 0.02, 0.05)
const VOID_COLOR: Color = Color(0.01, 0.01, 0.02)
const CEILING_NEAR_COLOR: Color = Color(0.16, 0.11, 0.16)
const CEILING_FAR_COLOR: Color = Color(0.08, 0.06, 0.1)
const WALL_NEAR_COLOR: Color = Color(0.26, 0.16, 0.14)
const WALL_FAR_COLOR: Color = Color(0.14, 0.09, 0.1)
const FLOOR_NEAR_COLOR: Color = Color(0.31, 0.16, 0.1)
const FLOOR_FAR_COLOR: Color = Color(0.16, 0.09, 0.08)
const FLOOR_PATH_NEAR_COLOR: Color = Color(0.82, 0.48, 0.22)
const FLOOR_PATH_FAR_COLOR: Color = Color(0.44, 0.24, 0.15)
const FRAME_NEAR_COLOR: Color = Color(0.72, 0.42, 0.24)
const FRAME_FAR_COLOR: Color = Color(0.38, 0.2, 0.16)
const CEILING_EDGE_COLOR: Color = Color(0.42, 0.25, 0.24)
const WALL_ROUTE_COLOR: Color = Color(0.79, 0.48, 0.24, 0.82)
const WALL_ROUTE_DOT_COLOR: Color = Color(0.95, 0.74, 0.42, 0.95)
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
	var stage_rects: Array[Rect2] = _build_stage_rects(gameplay_bottom)

	draw_rect(Rect2(Vector2.ZERO, viewport_size), BACKGROUND_COLOR, true)

	if stage_rects.is_empty():
		return

	var outer_rect: Rect2 = stage_rects[stage_rects.size() - 1]
	_draw_front_shell(viewport_size, gameplay_bottom, outer_rect)

	for stage_index in range(stage_rects.size() - 1, 0, -1):
		var outer_stage: Rect2 = stage_rects[stage_index]
		var inner_stage: Rect2 = stage_rects[stage_index - 1]
		var depth_t: float = _get_stage_ratio(stage_index, stage_rects.size())
		_draw_stage_segment(outer_stage, inner_stage, depth_t)

	_draw_floor_path_segments(stage_rects)
	_draw_stage_frames(stage_rects)
	_draw_wall_route_marks("WallLeftSlots", true)
	_draw_wall_route_marks("WallRightSlots", false)
	_draw_tunnel_void(stage_rects[0])
	_draw_vignette(viewport_size, gameplay_bottom)


func _build_stage_rects(gameplay_bottom: float) -> Array[Rect2]:
	var stage_rects: Array[Rect2] = []
	var center_slots: Array[Marker2D] = _get_route_slots("CenterSlots")
	var wall_left_slots: Array[Marker2D] = _get_route_slots("WallLeftSlots")
	var wall_right_slots: Array[Marker2D] = _get_route_slots("WallRightSlots")
	var stage_count: int = mini(center_slots.size(), mini(wall_left_slots.size(), wall_right_slots.size()))

	for stage_index in range(stage_count):
		var depth_t: float = _get_stage_ratio(stage_index, stage_count)
		var center_slot: Marker2D = center_slots[stage_index]
		var wall_left_slot: Marker2D = wall_left_slots[stage_index]
		var wall_right_slot: Marker2D = wall_right_slots[stage_index]

		var bottom_y: float = min(center_slot.position.y + lerpf(6.0, 18.0, depth_t), gameplay_bottom - 4.0)
		var rect_height: float = lerpf(20.0, gameplay_bottom * 0.86, depth_t)
		var top_y: float = max(bottom_y - rect_height, 6.0)
		var left_x: float = wall_left_slot.position.x
		var right_x: float = wall_right_slot.position.x

		if right_x - left_x < 24.0:
			continue

		stage_rects.append(
			Rect2(
				Vector2(left_x, top_y),
				Vector2(right_x - left_x, bottom_y - top_y)
			)
		)

	return stage_rects


func _draw_front_shell(viewport_size: Vector2, gameplay_bottom: float, outer_rect: Rect2) -> void:
	var top_left: Vector2 = outer_rect.position
	var top_right: Vector2 = Vector2(outer_rect.end.x, outer_rect.position.y)
	var bottom_left: Vector2 = Vector2(outer_rect.position.x, outer_rect.end.y)
	var bottom_right: Vector2 = outer_rect.end

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0.0, 0.0),
			Vector2(viewport_size.x, 0.0),
			top_right,
			top_left,
		]),
		CEILING_NEAR_COLOR
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0.0, 0.0),
			top_left,
			bottom_left,
			Vector2(0.0, gameplay_bottom),
		]),
		WALL_NEAR_COLOR
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(viewport_size.x, 0.0),
			top_right,
			bottom_right,
			Vector2(viewport_size.x, gameplay_bottom),
		]),
		WALL_NEAR_COLOR
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0.0, gameplay_bottom),
			Vector2(viewport_size.x, gameplay_bottom),
			bottom_right,
			bottom_left,
		]),
		FLOOR_NEAR_COLOR
	)


func _draw_stage_segment(outer_stage: Rect2, inner_stage: Rect2, depth_t: float) -> void:
	var ceiling_color: Color = CEILING_FAR_COLOR.lerp(CEILING_NEAR_COLOR, depth_t)
	var wall_color: Color = WALL_FAR_COLOR.lerp(WALL_NEAR_COLOR, depth_t)
	var floor_color: Color = FLOOR_FAR_COLOR.lerp(FLOOR_NEAR_COLOR, depth_t)

	draw_colored_polygon(
		PackedVector2Array([
			outer_stage.position,
			Vector2(outer_stage.end.x, outer_stage.position.y),
			Vector2(inner_stage.end.x, inner_stage.position.y),
			inner_stage.position,
		]),
		ceiling_color
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(outer_stage.position.x, outer_stage.position.y),
			Vector2(inner_stage.position.x, inner_stage.position.y),
			Vector2(inner_stage.position.x, inner_stage.end.y),
			Vector2(outer_stage.position.x, outer_stage.end.y),
		]),
		wall_color
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(outer_stage.end.x, outer_stage.position.y),
			Vector2(inner_stage.end.x, inner_stage.position.y),
			Vector2(inner_stage.end.x, inner_stage.end.y),
			Vector2(outer_stage.end.x, outer_stage.end.y),
		]),
		wall_color
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(outer_stage.position.x, outer_stage.end.y),
			Vector2(outer_stage.end.x, outer_stage.end.y),
			inner_stage.end,
			Vector2(inner_stage.position.x, inner_stage.end.y),
		]),
		floor_color
	)


func _draw_floor_path_segments(stage_rects: Array[Rect2]) -> void:
	for stage_index in range(stage_rects.size() - 1, 0, -1):
		var outer_stage: Rect2 = stage_rects[stage_index]
		var inner_stage: Rect2 = stage_rects[stage_index - 1]
		var depth_t: float = _get_stage_ratio(stage_index, stage_rects.size())
		var outer_half_width: float = outer_stage.size.x * 0.13
		var inner_half_width: float = inner_stage.size.x * 0.13
		var path_color: Color = FLOOR_PATH_FAR_COLOR.lerp(FLOOR_PATH_NEAR_COLOR, depth_t)

		draw_colored_polygon(
			PackedVector2Array([
				Vector2(outer_stage.get_center().x - outer_half_width, outer_stage.end.y),
				Vector2(outer_stage.get_center().x + outer_half_width, outer_stage.end.y),
				Vector2(inner_stage.get_center().x + inner_half_width, inner_stage.end.y),
				Vector2(inner_stage.get_center().x - inner_half_width, inner_stage.end.y),
			]),
			path_color
		)


func _draw_stage_frames(stage_rects: Array[Rect2]) -> void:
	for stage_index in range(stage_rects.size()):
		var stage_rect: Rect2 = stage_rects[stage_index]
		var depth_t: float = _get_stage_ratio(stage_index, stage_rects.size())
		var frame_color: Color = FRAME_FAR_COLOR.lerp(FRAME_NEAR_COLOR, depth_t)
		var floor_color: Color = FLOOR_PATH_FAR_COLOR.lerp(FLOOR_PATH_NEAR_COLOR, depth_t)
		var line_width: float = 1.0 if stage_index <= 1 else 2.0

		draw_line(stage_rect.position, Vector2(stage_rect.end.x, stage_rect.position.y), CEILING_EDGE_COLOR, line_width)
		draw_line(stage_rect.position, Vector2(stage_rect.position.x, stage_rect.end.y), frame_color, line_width)
		draw_line(Vector2(stage_rect.end.x, stage_rect.position.y), stage_rect.end, frame_color, line_width)
		draw_line(Vector2(stage_rect.position.x, stage_rect.end.y), stage_rect.end, floor_color, line_width + 1.0)

		var floor_center_x: float = stage_rect.get_center().x
		var floor_half_width: float = stage_rect.size.x * 0.16
		draw_line(
			Vector2(floor_center_x - floor_half_width, stage_rect.end.y),
			Vector2(floor_center_x + floor_half_width, stage_rect.end.y),
			Color(0.96, 0.74, 0.38, 0.95),
			line_width + 1.0
		)


func _draw_wall_route_marks(route_root_name: String, is_left_wall: bool) -> void:
	var horizontal_sign: float = 1.0 if is_left_wall else -1.0

	for slot in _get_route_slots(route_root_name):
		var wall_mark_start: Vector2 = slot.position + Vector2(-6.0 * horizontal_sign, -8.0)
		var wall_mark_end: Vector2 = slot.position + Vector2(10.0 * horizontal_sign, 8.0)
		draw_line(wall_mark_start, wall_mark_end, WALL_ROUTE_COLOR, 2.0)
		draw_circle(slot.position + Vector2(3.0 * horizontal_sign, 0.0), 1.8, WALL_ROUTE_DOT_COLOR)


func _draw_tunnel_void(farthest_stage: Rect2) -> void:
	var radius: float = maxf(minf(farthest_stage.size.x, farthest_stage.size.y) * 0.5 - 2.0, 2.0)
	draw_circle(farthest_stage.get_center(), radius, VOID_COLOR)


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


func _get_stage_ratio(stage_index: int, stage_count: int) -> float:
	if stage_count <= 1:
		return 1.0

	return float(stage_index) / float(stage_count - 1)


func _draw_vignette(viewport_size: Vector2, gameplay_bottom: float) -> void:
	draw_circle(Vector2(0.0, 0.0), 74.0, VIGNETTE_COLOR)
	draw_circle(Vector2(viewport_size.x, 0.0), 74.0, VIGNETTE_COLOR)
	draw_circle(Vector2(0.0, gameplay_bottom), 78.0, VIGNETTE_COLOR)
	draw_circle(Vector2(viewport_size.x, gameplay_bottom), 78.0, VIGNETTE_COLOR)
