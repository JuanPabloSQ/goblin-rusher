extends Enemy

const DARK_ORB_PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectiles/dark_orb_projectile.tscn")

@export var robe_color: Color = Color(0.22, 0.16, 0.32)
@export var skull_color: Color = Color(0.84, 0.82, 0.76)
@export var staff_color: Color = Color(0.38, 0.24, 0.14)
@export var rune_color: Color = Color(0.7, 0.46, 0.94)
@export var orb_damage: int = 2

var _has_active_dark_orb: bool = false


func get_projectile_target_position() -> Vector2:
	return global_position + Vector2(0.0, -36.0 * scale.y)


func can_use_special_attack() -> bool:
	return is_alive() and not _has_active_dark_orb


func perform_special_attack(projectile_layer: Node2D, player_target_position: Vector2) -> void:
	if projectile_layer == null or not can_use_special_attack():
		return

	var dark_orb: ZombieVomitProjectile = DARK_ORB_PROJECTILE_SCENE.instantiate() as ZombieVomitProjectile
	if dark_orb == null:
		return

	_has_active_dark_orb = true
	dark_orb.process_mode = Node.PROCESS_MODE_PAUSABLE
	projectile_layer.add_child(dark_orb)
	dark_orb.global_position = get_projectile_target_position()
	dark_orb.setup(player_target_position, orb_damage)
	if projectile_layer.get_parent().has_method("register_enemy_projectile"):
		projectile_layer.get_parent().register_enemy_projectile(dark_orb)
	dark_orb.tree_exited.connect(_on_dark_orb_tree_exited)


func _draw() -> void:
	draw_circle(Vector2(0.0, 34.0), 34.0, Color(0.0, 0.0, 0.0, 0.4))

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-34.0, 30.0),
			Vector2(-26.0, -2.0),
			Vector2(-12.0, -28.0),
			Vector2(12.0, -28.0),
			Vector2(26.0, -2.0),
			Vector2(34.0, 30.0),
			Vector2(10.0, 22.0),
			Vector2(0.0, 34.0),
			Vector2(-10.0, 22.0),
		]),
		outline_color
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-28.0, 26.0),
			Vector2(-22.0, 0.0),
			Vector2(-10.0, -22.0),
			Vector2(10.0, -22.0),
			Vector2(22.0, 0.0),
			Vector2(28.0, 26.0),
			Vector2(8.0, 18.0),
			Vector2(0.0, 28.0),
			Vector2(-8.0, 18.0),
		]),
		robe_color
	)

	draw_circle(Vector2(0.0, -26.0), 18.0, outline_color)
	draw_circle(Vector2(0.0, -26.0), 14.0, skull_color)
	draw_circle(Vector2(-5.0, -28.0), 2.8, eye_color)
	draw_circle(Vector2(5.0, -28.0), 2.8, eye_color)
	draw_line(Vector2(-6.0, -17.0), Vector2(6.0, -17.0), outline_color, 3.0)
	draw_line(Vector2(-8.0, -11.0), Vector2(8.0, -11.0), outline_color, 2.0)

	draw_line(Vector2(18.0, -4.0), Vector2(36.0, -48.0), outline_color, 6.0)
	draw_line(Vector2(18.0, -4.0), Vector2(36.0, -48.0), staff_color, 3.0)
	draw_circle(Vector2(40.0, -54.0), 8.0, Color(0.12, 0.06, 0.18, 1.0))
	draw_circle(Vector2(40.0, -54.0), 6.0, rune_color)

	draw_line(Vector2(-10.0, -2.0), Vector2(-22.0, 14.0), outline_color, 6.0)
	draw_line(Vector2(-10.0, -2.0), Vector2(-22.0, 14.0), skull_color, 3.0)
	draw_line(Vector2(10.0, 0.0), Vector2(24.0, 18.0), outline_color, 6.0)
	draw_line(Vector2(10.0, 0.0), Vector2(24.0, 18.0), skull_color, 3.0)

	draw_circle(Vector2(0.0, 2.0), 5.0, rune_color)
	draw_circle(Vector2(-12.0, 10.0), 3.0, rune_color)
	draw_circle(Vector2(12.0, 12.0), 3.0, rune_color)


func _on_dark_orb_tree_exited() -> void:
	_has_active_dark_orb = false
