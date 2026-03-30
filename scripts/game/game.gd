extends Node2D

const BONE_PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectiles/bone_projectile.tscn")

@export var advance_interval: float = 1.25
@export_range(0, 20, 1) var click_damage: int = 1

@onready var depth_slots_root: Node2D = $DepthSlots
@onready var enemy: Enemy = $EnemyLayer/EnemyBasic
@onready var projectile_layer: Node2D = $ProjectileLayer
@onready var projectile_spawn_point: Marker2D = $ProjectileSpawnPoint
@onready var enemy_health_label: Label = $UI/EnemyHealthLabel
@onready var advance_timer: Timer = $AdvanceTimer


func _ready() -> void:
	var depth_slots: Array[Marker2D] = _collect_depth_slots()
	enemy.clicked.connect(_on_enemy_clicked)
	enemy.health_changed.connect(_on_enemy_health_changed)
	enemy.died.connect(_on_enemy_died)
	enemy.setup_depth_slots(depth_slots)
	_update_enemy_health_label(enemy.get_current_health(), enemy.max_health)

	if depth_slots.size() <= 1:
		return

	advance_timer.timeout.connect(_on_advance_timer_timeout)
	advance_timer.wait_time = advance_interval
	advance_timer.start()


func _collect_depth_slots() -> Array[Marker2D]:
	var depth_slots: Array[Marker2D] = []

	for child in depth_slots_root.get_children():
		if child is Marker2D:
			depth_slots.append(child as Marker2D)

	return depth_slots


func _on_advance_timer_timeout() -> void:
	if not is_instance_valid(enemy) or not enemy.is_alive():
		advance_timer.stop()
		return

	if enemy.is_at_final_slot():
		advance_timer.stop()
		return

	enemy.advance_to_next_slot()

	if enemy.is_at_final_slot():
		advance_timer.stop()


func _on_enemy_clicked(clicked_enemy: Enemy) -> void:
	if not is_instance_valid(clicked_enemy) or not clicked_enemy.is_alive():
		return

	var projectile: BoneProjectile = BONE_PROJECTILE_SCENE.instantiate() as BoneProjectile
	projectile_layer.add_child(projectile)
	projectile.global_position = projectile_spawn_point.global_position
	projectile.setup(clicked_enemy, click_damage)


func _on_enemy_health_changed(current_health: int, max_health: int) -> void:
	_update_enemy_health_label(current_health, max_health)


func _on_enemy_died(dead_enemy: Enemy) -> void:
	advance_timer.stop()
	_update_enemy_health_label(0, dead_enemy.max_health, true)


func _update_enemy_health_label(current_health: int, max_health: int, is_dead: bool = false) -> void:
	if is_dead:
		enemy_health_label.text = "Enemy HP: 0/%d DEAD" % max_health
		return

	enemy_health_label.text = "Enemy HP: %d/%d  DMG: %d" % [current_health, max_health, click_damage]
