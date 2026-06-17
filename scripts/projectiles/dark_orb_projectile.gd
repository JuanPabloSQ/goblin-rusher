extends ZombieVomitProjectile


func _init() -> void:
	body_color = Color(0.22, 0.14, 0.34)
	glow_color = Color(0.58, 0.34, 0.86, 0.72)
	outline_color = Color(0.05, 0.02, 0.1)
	speed = 165.0
	damage = 2


func _draw() -> void:
	draw_circle(Vector2.ZERO, 13.0, glow_color)
	draw_circle(Vector2.ZERO, 10.0, outline_color)
	draw_circle(Vector2.ZERO, 7.5, body_color)
	draw_circle(Vector2(-2.5, -2.0), 2.8, Color(0.86, 0.72, 1.0, 0.82))
