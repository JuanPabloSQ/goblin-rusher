extends Node2D

const BONE_PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectiles/bone_projectile.tscn")
const ENEMY_SCENES: Array[PackedScene] = [
	preload("res://scenes/enemies/enemy_basic.tscn"),
	preload("res://scenes/enemies/enemy_spider.tscn"),
	preload("res://scenes/enemies/enemy_hobgoblin.tscn"),
]
const CLICK_DAMAGE: int = 1
const PLAYER_STARTING_HEALTH: int = 10
const ENEMY_ATTACK_INTERVAL: float = 2.0

@export var advance_interval: float = 1.25
@export var respawn_delay: float = 0.8

@onready var center_slots_root: Node2D = $DepthSlots/CenterSlots
@onready var wall_left_slots_root: Node2D = $DepthSlots/WallLeftSlots
@onready var wall_right_slots_root: Node2D = $DepthSlots/WallRightSlots
@onready var goblin_hands: GoblinHands = $GoblinHands
@onready var projectile_layer: Node2D = $ProjectileLayer
@onready var enemy_layer: Node2D = $EnemyLayer
@onready var hud: GameHud = $GameHud
@onready var advance_timer: Timer = $AdvanceTimer
@onready var respawn_timer: Timer = $RespawnTimer
@onready var enemy_attack_timer: Timer = $EnemyAttackTimer

var _center_depth_slots: Array[Marker2D] = []
var _wall_left_depth_slots: Array[Marker2D] = []
var _wall_right_depth_slots: Array[Marker2D] = []
var _current_enemy: Enemy
var _enemies_defeated: int = 0
var _next_enemy_scene_index: int = 0
var _next_wall_path_type: int = Enemy.PathType.WALL_LEFT
var _player_health: int = PLAYER_STARTING_HEALTH
var _damage_shake_tween: Tween
var _is_game_over: bool = false
var _is_paused: bool = false


func _ready() -> void:
	_center_depth_slots = _collect_depth_slots(center_slots_root)
	_wall_left_depth_slots = _collect_depth_slots(wall_left_slots_root)
	_wall_right_depth_slots = _collect_depth_slots(wall_right_slots_root)
	goblin_hands.process_mode = Node.PROCESS_MODE_PAUSABLE
	enemy_layer.process_mode = Node.PROCESS_MODE_PAUSABLE
	projectile_layer.process_mode = Node.PROCESS_MODE_PAUSABLE
	advance_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	respawn_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	enemy_attack_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	_reset_game_state()

	if _center_depth_slots.is_empty():
		return

	advance_timer.timeout.connect(_on_advance_timer_timeout)
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	enemy_attack_timer.timeout.connect(_on_enemy_attack_timer_timeout)
	hud.restart_requested.connect(_on_restart_requested)
	hud.resume_requested.connect(_on_resume_requested)
	advance_timer.wait_time = advance_interval
	respawn_timer.wait_time = respawn_delay
	enemy_attack_timer.wait_time = ENEMY_ATTACK_INTERVAL

	_spawn_enemy()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_game") or event.is_echo():
		return

	if _is_game_over:
		return

	if _is_paused:
		_resume_game()
		return

	_pause_game()


func _collect_depth_slots(slots_root: Node) -> Array[Marker2D]:
	var depth_slots: Array[Marker2D] = []

	if slots_root == null:
		return depth_slots

	for child in slots_root.get_children():
		if child is Marker2D:
			depth_slots.append(child as Marker2D)

	return depth_slots


func _on_advance_timer_timeout() -> void:
	if _is_game_over or _is_paused:
		advance_timer.stop()
		return

	if not is_instance_valid(_current_enemy) or not _current_enemy.is_alive():
		advance_timer.stop()
		return

	if _current_enemy.is_at_final_slot():
		advance_timer.stop()
		return

	_current_enemy.advance_to_next_slot()
	_update_enemy_stage_ui()
	_update_enemy_attack_state()

	if _current_enemy.is_at_final_slot():
		advance_timer.stop()


func _on_enemy_clicked(clicked_enemy: Enemy) -> void:
	if _is_game_over or _is_paused:
		return

	if not is_instance_valid(clicked_enemy) or not clicked_enemy.is_alive():
		return

	goblin_hands.play_throw()

	var projectile: BoneProjectile = BONE_PROJECTILE_SCENE.instantiate() as BoneProjectile
	projectile.process_mode = Node.PROCESS_MODE_PAUSABLE
	projectile_layer.add_child(projectile)
	projectile.impacted.connect(_on_projectile_impacted)
	projectile.global_position = goblin_hands.get_right_hand_spawn_global_position()
	projectile.setup(clicked_enemy, CLICK_DAMAGE)


func _on_enemy_died(dead_enemy: Enemy) -> void:
	if _is_game_over or _is_paused:
		return

	if dead_enemy != _current_enemy:
		return

	advance_timer.stop()
	enemy_attack_timer.stop()
	_current_enemy = null
	_enemies_defeated += 1
	hud.set_kill_count(_enemies_defeated)
	hud.set_waiting_for_enemy()
	respawn_timer.start()


func _on_respawn_timer_timeout() -> void:
	if _is_game_over or _is_paused:
		return

	_spawn_enemy()


func _spawn_enemy() -> void:
	if _is_game_over or _is_paused or _center_depth_slots.is_empty():
		return

	enemy_attack_timer.stop()

	var enemy_scene: PackedScene = ENEMY_SCENES[_next_enemy_scene_index]
	_next_enemy_scene_index = (_next_enemy_scene_index + 1) % ENEMY_SCENES.size()

	var enemy_instance: Enemy = enemy_scene.instantiate() as Enemy
	enemy_instance.process_mode = Node.PROCESS_MODE_PAUSABLE
	var path_type: int = _choose_spawn_path(enemy_instance)
	var depth_slots: Array[Marker2D] = _get_depth_slots_for_path(path_type)

	if depth_slots.is_empty():
		depth_slots = _center_depth_slots
		path_type = Enemy.PathType.CENTER

	enemy_layer.add_child(enemy_instance)
	enemy_instance.clicked.connect(_on_enemy_clicked)
	enemy_instance.died.connect(_on_enemy_died)
	enemy_instance.setup_depth_slots(depth_slots, path_type)
	_current_enemy = enemy_instance

	_update_enemy_stage_ui()
	_update_enemy_attack_state()
	advance_timer.start()


func _update_enemy_stage_ui() -> void:
	if not is_instance_valid(_current_enemy) or not _current_enemy.is_alive():
		hud.set_waiting_for_enemy()
		return

	hud.set_enemy_stage(_current_enemy.get_current_stage(), _current_enemy.get_total_stages())


func _on_projectile_impacted() -> void:
	if _is_game_over or _is_paused:
		return

	hud.play_hit_flash()


func _on_enemy_attack_timer_timeout() -> void:
	if _is_game_over or _is_paused:
		enemy_attack_timer.stop()
		return

	if not is_instance_valid(_current_enemy) or not _current_enemy.is_alive() or not _current_enemy.is_at_final_slot():
		enemy_attack_timer.stop()
		return

	_apply_player_damage(_current_enemy.get_contact_damage())

	if _player_health <= 0:
		_enter_game_over()


func _choose_spawn_path(enemy_instance: Enemy) -> int:
	var available_paths: Array[int] = []

	for path_type in [Enemy.PathType.CENTER, Enemy.PathType.WALL_LEFT, Enemy.PathType.WALL_RIGHT]:
		if enemy_instance.can_use_path(path_type) and not _get_depth_slots_for_path(path_type).is_empty():
			available_paths.append(path_type)

	if available_paths.is_empty():
		return Enemy.PathType.CENTER

	if available_paths.has(_next_wall_path_type):
		var chosen_wall_path: int = _next_wall_path_type
		_next_wall_path_type = Enemy.PathType.WALL_RIGHT if _next_wall_path_type == Enemy.PathType.WALL_LEFT else Enemy.PathType.WALL_LEFT
		return chosen_wall_path

	return available_paths[0]


func _get_depth_slots_for_path(path_type: int) -> Array[Marker2D]:
	match path_type:
		Enemy.PathType.WALL_LEFT:
			return _wall_left_depth_slots
		Enemy.PathType.WALL_RIGHT:
			return _wall_right_depth_slots
		_:
			return _center_depth_slots


func _update_enemy_attack_state() -> void:
	if _is_game_over or _is_paused or not is_instance_valid(_current_enemy) or not _current_enemy.is_alive() or not _current_enemy.is_at_final_slot() or _player_health <= 0:
		enemy_attack_timer.stop()
		return

	if enemy_attack_timer.is_stopped():
		enemy_attack_timer.start()


func _apply_player_damage(amount: int) -> void:
	if _is_game_over or _is_paused or amount <= 0 or _player_health <= 0:
		return

	_player_health = maxi(_player_health - amount, 0)
	hud.set_player_health(_player_health)
	hud.play_player_hit_feedback()
	_play_player_damage_shake()

	if _player_health == 0:
		_enter_game_over()


func _play_player_damage_shake() -> void:
	if is_instance_valid(_damage_shake_tween):
		_damage_shake_tween.kill()

	position = Vector2.ZERO
	_damage_shake_tween = create_tween()
	_damage_shake_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_damage_shake_tween.tween_property(self, "position", Vector2(-4.0, 2.0), 0.03)
	_damage_shake_tween.tween_property(self, "position", Vector2(4.0, -2.0), 0.03)
	_damage_shake_tween.tween_property(self, "position", Vector2(-2.0, 1.0), 0.03)
	_damage_shake_tween.tween_property(self, "position", Vector2.ZERO, 0.04)


func _enter_game_over() -> void:
	if _is_game_over:
		return

	_is_game_over = true
	_is_paused = false
	_player_health = 0
	hud.set_player_health(_player_health)
	hud.hide_pause()
	_stop_gameplay_loop()
	hud.show_game_over()
	get_tree().paused = true


func _stop_gameplay_loop() -> void:
	advance_timer.stop()
	respawn_timer.stop()
	enemy_attack_timer.stop()

	if is_instance_valid(_damage_shake_tween):
		_damage_shake_tween.kill()

	position = Vector2.ZERO

	if is_instance_valid(_current_enemy):
		_current_enemy.freeze()

	for projectile in projectile_layer.get_children():
		projectile.queue_free()


func _reset_game_state() -> void:
	get_tree().paused = false
	_is_game_over = false
	_is_paused = false
	_current_enemy = null
	_enemies_defeated = 0
	_next_enemy_scene_index = 0
	_next_wall_path_type = Enemy.PathType.WALL_LEFT
	_player_health = PLAYER_STARTING_HEALTH
	position = Vector2.ZERO
	hud.reset()
	hud.set_player_health(_player_health)
	hud.set_kill_count(_enemies_defeated)
	hud.set_waiting_for_enemy()


func _on_restart_requested() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_resume_requested() -> void:
	_resume_game()


func _pause_game() -> void:
	if _is_paused or _is_game_over:
		return

	_is_paused = true
	get_tree().paused = true
	hud.show_pause()


func _resume_game() -> void:
	if not _is_paused or _is_game_over:
		return

	_is_paused = false
	hud.hide_pause()
	get_tree().paused = false
