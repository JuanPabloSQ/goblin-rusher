extends Enemy

const GHOST_MISS_TEXT: String = "MISS"

@export_range(0.0, 1.0, 0.01) var dodge_chance: float = 0.5
@export var haze_color: Color = Color(0.64, 0.88, 1.0, 0.38)
@export var core_color: Color = Color(0.9, 0.97, 1.0, 0.82)

var _miss_feedback_alpha: float = 0.0:
	set(value):
		_miss_feedback_alpha = value
		queue_redraw()
var _miss_feedback_offset: float = 0.0:
	set(value):
		_miss_feedback_offset = value
		queue_redraw()
var _miss_feedback_tween: Tween


func take_damage(amount: int) -> bool:
	if _is_dead:
		return false

	if randf() < dodge_chance:
		_play_miss_feedback()
		return false

	return super.take_damage(amount)


func _draw() -> void:
	var room_side_sign: float = 1.0 if get_path_type() == Enemy.PathType.WALL_LEFT else -1.0
	draw_circle(Vector2(0.0, 18.0), 20.0, Color(0.0, 0.0, 0.0, 0.22))
	draw_circle(Vector2(0.0, -18.0), 15.0, outline_color)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-16.0, -18.0),
			Vector2(16.0, -18.0),
			Vector2(18.0, 8.0),
			Vector2(10.0, 26.0),
			Vector2(0.0, 18.0),
			Vector2(-10.0, 26.0),
			Vector2(-18.0, 8.0),
		]),
		outline_color
	)
	draw_circle(Vector2(0.0, -18.0), 12.0, core_color)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-13.0, -18.0),
			Vector2(13.0, -18.0),
			Vector2(14.0, 7.0),
			Vector2(8.0, 21.0),
			Vector2(0.0, 14.0),
			Vector2(-8.0, 21.0),
			Vector2(-14.0, 7.0),
		]),
		haze_color
	)
	draw_circle(Vector2(-4.0 * room_side_sign, -20.0), 2.2, eye_color)
	draw_circle(Vector2(4.0 * room_side_sign, -20.0), 2.2, eye_color)
	draw_line(Vector2(-5.0 * room_side_sign, -11.0), Vector2(5.0 * room_side_sign, -11.0), outline_color, 2.0)

	if _miss_feedback_alpha > 0.0:
		var miss_position: Vector2 = Vector2(-14.0, -40.0 - _miss_feedback_offset)
		draw_string(
			ThemeDB.fallback_font,
			miss_position,
			GHOST_MISS_TEXT,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			12,
			Color(0.9, 0.97, 1.0, _miss_feedback_alpha)
		)


func _play_miss_feedback() -> void:
	if is_instance_valid(_miss_feedback_tween):
		_miss_feedback_tween.kill()

	_miss_feedback_alpha = 1.0
	_miss_feedback_offset = 0.0
	queue_redraw()

	_miss_feedback_tween = create_tween()
	_miss_feedback_tween.tween_property(self, "_miss_feedback_offset", 10.0, 0.22)
	_miss_feedback_tween.parallel().tween_property(self, "_miss_feedback_alpha", 0.0, 0.22)
