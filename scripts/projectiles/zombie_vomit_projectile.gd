class_name ZombieVomitProjectile
extends Area2D

signal hit_player(damage: int)
signal destroyed
signal clicked(projectile: ZombieVomitProjectile)

@export var speed: float = 150.0
@export var impact_distance: float = 10.0
@export var max_lifetime: float = 3.0
@export var damage: int = 1
@export var body_color: Color = Color(0.28, 0.82, 0.24)
@export var glow_color: Color = Color(0.58, 1.0, 0.42, 0.72)
@export var outline_color: Color = Color(0.12, 0.3, 0.08)

var _target_position: Vector2 = Vector2.ZERO
var _lifetime: float = 0.0


func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)
	z_index = 48
	queue_redraw()


func setup(target_position: Vector2, projectile_damage: int) -> void:
	_target_position = target_position
	damage = maxi(projectile_damage, 1)


func take_damage(amount: int) -> bool:
	if amount <= 0:
		return false

	_destroy()
	return true


func _process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= max_lifetime:
		_destroy()
		return

	var to_target: Vector2 = _target_position - global_position
	var distance: float = to_target.length()
	if distance <= impact_distance:
		hit_player.emit(damage)
		_destroy()
		return

	if distance > 0.0:
		global_position += to_target.normalized() * speed * delta
		rotation += delta * 5.2


func _destroy() -> void:
	destroyed.emit()
	queue_free()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
			clicked.emit(self)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 12.0, glow_color)
	draw_circle(Vector2.ZERO, 9.0, outline_color)
	draw_circle(Vector2.ZERO, 7.0, body_color)
	draw_circle(Vector2(-2.0, -3.0), 2.5, Color(0.78, 1.0, 0.68, 0.86))
