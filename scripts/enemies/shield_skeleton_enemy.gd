extends Enemy

@export_range(1, 99, 1) var base_health: int = 3
@export_range(0, 99, 1) var shield_health_bonus: int = 2
@export var shield_color: Color = Color(0.42, 0.44, 0.5)
@export var sword_color: Color = Color(0.74, 0.78, 0.84)
@export var strap_color: Color = Color(0.35, 0.2, 0.12)


func _ready() -> void:
	max_health = base_health + shield_health_bonus
	super._ready()


func take_damage(amount: int) -> bool:
	var had_shield: bool = _has_shield_layer()
	var was_hit: bool = super.take_damage(amount)

	if was_hit and had_shield and not _has_shield_layer() and is_alive():
		queue_redraw()

	return was_hit


func _has_shield_layer() -> bool:
	return shield_health_bonus > 0 and _current_health > base_health


func _draw() -> void:
	super._draw()

	if not _has_shield_layer():
		return

	draw_line(Vector2(7.0, -4.0), Vector2(22.0, -18.0), outline_color, 5.0)
	draw_line(Vector2(22.0, -18.0), Vector2(26.0, -34.0), outline_color, 4.0)
	draw_line(Vector2(7.0, -4.0), Vector2(22.0, -18.0), sword_color, 3.0)
	draw_line(Vector2(22.0, -18.0), Vector2(26.0, -34.0), sword_color, 2.0)
	draw_line(Vector2(15.0, -12.0), Vector2(24.0, -12.0), strap_color, 3.0)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-18.0, -10.0),
			Vector2(-30.0, -4.0),
			Vector2(-28.0, 18.0),
			Vector2(-14.0, 24.0),
			Vector2(-4.0, 8.0),
			Vector2(-5.0, -6.0),
		]),
		outline_color
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-16.0, -8.0),
			Vector2(-27.0, -3.0),
			Vector2(-25.0, 16.0),
			Vector2(-14.0, 20.0),
			Vector2(-7.0, 7.0),
			Vector2(-8.0, -4.0),
		]),
		shield_color
	)
	draw_line(Vector2(-23.0, 0.0), Vector2(-8.0, 8.0), strap_color, 2.0)
	draw_line(Vector2(-22.0, 10.0), Vector2(-11.0, -2.0), strap_color, 2.0)
