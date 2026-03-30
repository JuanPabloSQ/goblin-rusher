extends Node2D

const BONE_PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectiles/bone_projectile.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy_basic.tscn")
const CLICK_DAMAGE: int = 1

@export var advance_interval: float = 1.25
@export var respawn_delay: float = 0.8

@onready var depth_slots_root: Node2D = $DepthSlots
@onready var goblin_hands: GoblinHands = $GoblinHands
@onready var projectile_layer: Node2D = $ProjectileLayer
@onready var enemy_layer: Node2D = $EnemyLayer
@onready var hud: GameHud = $GameHud
@onready var advance_timer: Timer = $AdvanceTimer
@onready var respawn_timer: Timer = $RespawnTimer

var _depth_slots: Array[Marker2D] = []
var _current_enemy: Enemy
var _enemies_defeated: int = 0


func _ready() -> void:
	_depth_slots = _collect_depth_slots()
	hud.set_kill_count(_enemies_defeated)
	hud.set_waiting_for_enemy()

	if _depth_slots.is_empty():
		return

	advance_timer.timeout.connect(_on_advance_timer_timeout)
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	advance_timer.wait_time = advance_interval
	respawn_timer.wait_time = respawn_delay

	_spawn_enemy()


func _collect_depth_slots() -> Array[Marker2D]:
	var depth_slots: Array[Marker2D] = []

	for child in depth_slots_root.get_children():
		if child is Marker2D:
			depth_slots.append(child as Marker2D)

	return depth_slots


func _on_advance_timer_timeout() -> void:
	if not is_instance_valid(_current_enemy) or not _current_enemy.is_alive():
		advance_timer.stop()
		return

	if _current_enemy.is_at_final_slot():
		advance_timer.stop()
		return

	_current_enemy.advance_to_next_slot()
	_update_enemy_stage_ui()

	if _current_enemy.is_at_final_slot():
		advance_timer.stop()


func _on_enemy_clicked(clicked_enemy: Enemy) -> void:
	if not is_instance_valid(clicked_enemy) or not clicked_enemy.is_alive():
		return

	goblin_hands.play_throw()

	var projectile: BoneProjectile = BONE_PROJECTILE_SCENE.instantiate() as BoneProjectile
	projectile_layer.add_child(projectile)
	projectile.impacted.connect(_on_projectile_impacted)
	projectile.global_position = goblin_hands.get_right_hand_spawn_global_position()
	projectile.setup(clicked_enemy, CLICK_DAMAGE)


func _on_enemy_died(dead_enemy: Enemy) -> void:
	if dead_enemy != _current_enemy:
		return

	advance_timer.stop()
	_current_enemy = null
	_enemies_defeated += 1
	hud.set_kill_count(_enemies_defeated)
	hud.set_waiting_for_enemy()
	respawn_timer.start()


func _on_respawn_timer_timeout() -> void:
	_spawn_enemy()


func _spawn_enemy() -> void:
	if _depth_slots.is_empty():
		return

	var enemy_instance: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy_layer.add_child(enemy_instance)
	enemy_instance.clicked.connect(_on_enemy_clicked)
	enemy_instance.died.connect(_on_enemy_died)
	enemy_instance.setup_depth_slots(_depth_slots)
	_current_enemy = enemy_instance

	_update_enemy_stage_ui()
	advance_timer.start()


func _update_enemy_stage_ui() -> void:
	if not is_instance_valid(_current_enemy) or not _current_enemy.is_alive():
		hud.set_waiting_for_enemy()
		return

	hud.set_enemy_stage(_current_enemy.get_current_stage(), _current_enemy.get_total_stages())


func _on_projectile_impacted() -> void:
	hud.play_hit_flash()
