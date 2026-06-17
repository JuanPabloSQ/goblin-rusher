class_name ZombieEnemy
extends Enemy

const ZOMBIE_VOMIT_PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectiles/zombie_vomit_projectile.tscn")

@export var skin_color: Color = Color(0.33, 0.5, 0.22)
@export var wound_color: Color = Color(0.46, 0.14, 0.12)
@export var cloth_color: Color = Color(0.18, 0.22, 0.17)
@export var vomit_damage: int = 1

var _has_active_vomit_projectile: bool = false


func get_projectile_target_position() -> Vector2:
	return global_position + Vector2(0.0, -30.0 * scale.y)


func can_use_special_attack() -> bool:
	return is_alive() and not _has_active_vomit_projectile


func perform_special_attack(projectile_layer: Node2D, player_target_position: Vector2) -> void:
	if projectile_layer == null or not can_use_special_attack():
		return

	var vomit_projectile: ZombieVomitProjectile = ZOMBIE_VOMIT_PROJECTILE_SCENE.instantiate() as ZombieVomitProjectile
	if vomit_projectile == null:
		return

	_has_active_vomit_projectile = true
	vomit_projectile.process_mode = Node.PROCESS_MODE_PAUSABLE
	projectile_layer.add_child(vomit_projectile)
	vomit_projectile.global_position = get_projectile_target_position()
	vomit_projectile.setup(player_target_position, vomit_damage)
	if projectile_layer.get_parent().has_method("register_enemy_projectile"):
		projectile_layer.get_parent().register_enemy_projectile(vomit_projectile)
	vomit_projectile.tree_exited.connect(_on_vomit_projectile_tree_exited)


func _draw() -> void:
	draw_circle(Vector2(0.0, 28.0), 30.0, Color(0.0, 0.0, 0.0, 0.36))

	draw_circle(Vector2(0.0, -14.0), 24.0, outline_color)
	draw_circle(Vector2(0.0, 18.0), 26.0, outline_color)
	draw_circle(Vector2(0.0, -14.0), 20.0, skin_color)
	draw_circle(Vector2(0.0, 18.0), 22.0, cloth_color)

	draw_line(Vector2(-24.0, 2.0), Vector2(-36.0, 22.0), outline_color, 8.0)
	draw_line(Vector2(24.0, 2.0), Vector2(36.0, 22.0), outline_color, 8.0)
	draw_line(Vector2(-16.0, 36.0), Vector2(-22.0, 56.0), outline_color, 8.0)
	draw_line(Vector2(16.0, 36.0), Vector2(22.0, 56.0), outline_color, 8.0)
	draw_line(Vector2(-24.0, 2.0), Vector2(-36.0, 22.0), skin_color, 4.0)
	draw_line(Vector2(24.0, 2.0), Vector2(36.0, 22.0), skin_color, 4.0)
	draw_line(Vector2(-16.0, 36.0), Vector2(-22.0, 56.0), cloth_color, 4.0)
	draw_line(Vector2(16.0, 36.0), Vector2(22.0, 56.0), cloth_color, 4.0)

	draw_circle(Vector2(-8.0, -18.0), 3.2, eye_color)
	draw_circle(Vector2(8.0, -18.0), 3.2, eye_color)
	draw_circle(Vector2(-6.0, -2.0), 4.0, wound_color)
	draw_circle(Vector2(10.0, 8.0), 5.0, wound_color)
	draw_line(Vector2(-10.0, -4.0), Vector2(9.0, -2.0), outline_color, 5.0)
	draw_line(Vector2(-10.0, -4.0), Vector2(9.0, -2.0), Color(0.16, 0.34, 0.12), 2.0)
	draw_circle(Vector2(2.0, -2.0), 4.0, Color(0.26, 0.86, 0.24, 0.92))
	draw_circle(Vector2(5.0, 3.0), 2.6, Color(0.68, 1.0, 0.48, 0.72))


func _on_vomit_projectile_tree_exited() -> void:
	_has_active_vomit_projectile = false
