extends Node2D

const BONE_PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectiles/bone_projectile.tscn")
const ENEMY_BASIC_SCENE: PackedScene = preload("res://scenes/enemies/enemy_basic.tscn")
const ENEMY_SPIDER_SCENE: PackedScene = preload("res://scenes/enemies/enemy_spider.tscn")
const ENEMY_HOBGOBLIN_SCENE: PackedScene = preload("res://scenes/enemies/enemy_hobgoblin.tscn")
const ENEMY_ABOMINATION_SCENE: PackedScene = preload("res://scenes/enemies/enemy_abomination.tscn")
const CLICK_DAMAGE: int = 1
const PLAYER_STARTING_HEALTH: int = 10
const ENEMY_ATTACK_INTERVAL: float = 2.0
const ENEMIES_PER_GAME_STAGE: int = 10
const EARLY_GAME_MAX_STAGE: int = 10
const EARLY_GAME_SPAWN_DELAY: float = 5.0
const HOBGOBLIN_UNLOCK_STAGE: int = 5
const ABOMINATION_BOSS_STAGE: int = 10
const BOSS_TRANSITION_DELAY: float = 2.0

@export var advance_interval: float = 1.25
@export var min_spawn_delay: float = 0.35
@export var max_spawn_delay: float = 2.0
@export_range(1, 3, 1) var max_spawn_burst: int = 3

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
var _active_enemies: Array[Enemy] = []
var _enemies_defeated: int = 0
var _current_game_stage: int = 1
var _debug_forced_stage: int = 0
var _player_health: int = PLAYER_STARTING_HEALTH
var _damage_shake_tween: Tween
var _is_game_over: bool = false
var _is_paused: bool = false
var _is_boss_transitioning: bool = false


func _ready() -> void:
	randomize()
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
	hud.debug_stage_requested.connect(_on_debug_stage_requested)
	hud.boss_transition_finished.connect(_on_boss_transition_finished)
	advance_timer.wait_time = advance_interval
	enemy_attack_timer.wait_time = ENEMY_ATTACK_INTERVAL

	advance_timer.start()
	enemy_attack_timer.start()
	_schedule_next_spawn()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_game") or event.is_echo():
		return

	if _is_game_over or _is_boss_transitioning:
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
	if _is_game_over or _is_paused or _is_boss_transitioning:
		return

	_cleanup_inactive_enemies()

	for path_type in [Enemy.PathType.CENTER, Enemy.PathType.WALL_LEFT, Enemy.PathType.WALL_RIGHT]:
		_advance_path_enemies(path_type)


func _advance_path_enemies(path_type: int) -> void:
	var path_enemies: Array[Enemy] = _get_active_enemies_for_path(path_type)
	path_enemies.sort_custom(_sort_enemy_by_depth_descending)

	var occupied_slots: Dictionary = {}

	for enemy in path_enemies:
		var target_slot_index: int = enemy.get_current_slot_index()
		var next_slot_index: int = mini(target_slot_index + 1, enemy.get_total_steps() - 1)

		if next_slot_index > target_slot_index and not occupied_slots.has(next_slot_index) and enemy.can_advance_on_current_tick():
			enemy.advance_to_next_slot()
			target_slot_index = next_slot_index

		occupied_slots[target_slot_index] = true


func _on_enemy_clicked(clicked_enemy: Enemy) -> void:
	if _is_game_over or _is_paused or _is_boss_transitioning:
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
	_remove_active_enemy(dead_enemy)
	_enemies_defeated += 1
	_refresh_stage_state()

	if dead_enemy.is_boss_enemy():
		_start_boss_transition()
		return

	if not _is_game_over and not _is_paused and respawn_timer.is_stopped():
		_schedule_next_spawn()


func _on_respawn_timer_timeout() -> void:
	if _is_game_over or _is_paused or _is_boss_transitioning:
		return

	if _has_active_boss_enemy():
		return

	_spawn_enemy_wave()
	_schedule_next_spawn()


func _spawn_enemy_wave() -> void:
	var available_paths: Array[int] = _get_spawnable_paths()
	if available_paths.is_empty():
		return

	available_paths.shuffle()
	var spawn_count: int = _get_spawn_count_for_current_stage(available_paths.size())

	for spawn_index in range(spawn_count):
		if available_paths.is_empty():
			break

		var enemy_instance: Enemy = _create_enemy_for_available_paths(available_paths)
		if enemy_instance == null:
			break

		var spawn_path_type: int = int(enemy_instance.get_meta("spawn_path_type"))
		available_paths.erase(spawn_path_type)
		_finish_spawning_enemy(enemy_instance, spawn_path_type)



func _create_enemy_for_available_paths(available_paths: Array[int]) -> Enemy:
	if _should_spawn_abomination_boss():
		return _create_boss_enemy_for_available_paths(available_paths)

	var shuffled_scenes: Array[PackedScene] = _get_enemy_pool_for_current_stage()
	shuffled_scenes.shuffle()

	for enemy_scene in shuffled_scenes:
		var enemy_instance: Enemy = enemy_scene.instantiate() as Enemy
		var valid_paths: Array[int] = []

		for path_type in available_paths:
			if enemy_instance.can_use_path(path_type):
				valid_paths.append(path_type)

		if valid_paths.is_empty():
			enemy_instance.queue_free()
			continue

		valid_paths.shuffle()
		enemy_instance.set_meta("spawn_path_type", valid_paths[0])
		return enemy_instance

	return null


func _create_boss_enemy_for_available_paths(available_paths: Array[int]) -> Enemy:
	var boss_enemy: Enemy = ENEMY_ABOMINATION_SCENE.instantiate() as Enemy
	var valid_paths: Array[int] = []

	for path_type in available_paths:
		if boss_enemy.can_use_path(path_type):
			valid_paths.append(path_type)

	if valid_paths.is_empty():
		boss_enemy.queue_free()
		return null

	valid_paths.shuffle()
	boss_enemy.set_meta("spawn_path_type", valid_paths[0])
	return boss_enemy


func _finish_spawning_enemy(enemy_instance: Enemy, path_type: int) -> void:
	enemy_instance.process_mode = Node.PROCESS_MODE_PAUSABLE

	var depth_slots: Array[Marker2D] = _get_depth_slots_for_path(path_type)
	if depth_slots.is_empty():
		enemy_instance.queue_free()
		return

	enemy_layer.add_child(enemy_instance)
	enemy_instance.clicked.connect(_on_enemy_clicked)
	enemy_instance.died.connect(_on_enemy_died)
	enemy_instance.setup_depth_slots(depth_slots, path_type)
	_active_enemies.append(enemy_instance)


func _on_projectile_impacted() -> void:
	if _is_game_over or _is_paused or _is_boss_transitioning:
		return

	hud.play_hit_flash()


func _on_enemy_attack_timer_timeout() -> void:
	if _is_game_over or _is_paused or _is_boss_transitioning:
		return

	_cleanup_inactive_enemies()

	var total_damage: int = 0
	for enemy in _active_enemies:
		if enemy.is_at_final_slot():
			total_damage += enemy.get_contact_damage()

	if total_damage <= 0:
		return

	_apply_player_damage(total_damage)

	if _player_health <= 0:
		_enter_game_over()


func _get_depth_slots_for_path(path_type: int) -> Array[Marker2D]:
	match path_type:
		Enemy.PathType.WALL_LEFT:
			return _wall_left_depth_slots
		Enemy.PathType.WALL_RIGHT:
			return _wall_right_depth_slots
		_:
			return _center_depth_slots


func _apply_player_damage(amount: int) -> void:
	if _is_game_over or _is_paused or _is_boss_transitioning or amount <= 0 or _player_health <= 0:
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
	_is_boss_transitioning = false
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

	for enemy in _active_enemies:
		if is_instance_valid(enemy):
			enemy.freeze()

	for projectile in projectile_layer.get_children():
		projectile.queue_free()


func _reset_game_state() -> void:
	get_tree().paused = false
	_is_game_over = false
	_is_paused = false
	_is_boss_transitioning = false
	_active_enemies.clear()
	_enemies_defeated = 0
	_debug_forced_stage = 0
	_current_game_stage = 1
	_player_health = PLAYER_STARTING_HEALTH
	position = Vector2.ZERO
	hud.reset()
	hud.set_player_health(_player_health)
	_refresh_stage_state()


func _on_restart_requested() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_resume_requested() -> void:
	_resume_game()


func _on_debug_stage_requested(requested_stage: int) -> void:
	_debug_forced_stage = maxi(requested_stage, 1)
	_refresh_stage_state()
	_schedule_next_spawn()
	hud.set_debug_feedback("Etapa forzada: %d" % _current_game_stage, Color(0.62, 0.94, 0.48, 1.0))


func _pause_game() -> void:
	if _is_paused or _is_game_over or _is_boss_transitioning:
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


func _schedule_next_spawn() -> void:
	if _is_game_over:
		return

	if _has_active_boss_enemy():
		respawn_timer.stop()
		return

	respawn_timer.stop()
	respawn_timer.wait_time = _get_spawn_delay_for_current_stage()
	respawn_timer.start()


func _get_spawnable_paths() -> Array[int]:
	var spawnable_paths: Array[int] = []

	for path_type in [Enemy.PathType.CENTER, Enemy.PathType.WALL_LEFT, Enemy.PathType.WALL_RIGHT]:
		if _is_path_spawn_slot_free(path_type):
			spawnable_paths.append(path_type)

	return spawnable_paths


func _is_path_spawn_slot_free(path_type: int) -> bool:
	for enemy in _active_enemies:
		if enemy.get_path_type() == path_type and enemy.get_current_slot_index() <= 0:
			return false

	return true


func _get_active_enemies_for_path(path_type: int) -> Array[Enemy]:
	var path_enemies: Array[Enemy] = []

	for enemy in _active_enemies:
		if enemy.get_path_type() == path_type:
			path_enemies.append(enemy)

	return path_enemies


func _cleanup_inactive_enemies() -> void:
	var still_active: Array[Enemy] = []

	for enemy in _active_enemies:
		if is_instance_valid(enemy) and enemy.is_alive():
			still_active.append(enemy)

	_active_enemies = still_active


func _remove_active_enemy(enemy_to_remove: Enemy) -> void:
	var remaining_enemies: Array[Enemy] = []

	for enemy in _active_enemies:
		if enemy != enemy_to_remove and is_instance_valid(enemy) and enemy.is_alive():
			remaining_enemies.append(enemy)

	_active_enemies = remaining_enemies


func _sort_enemy_by_depth_descending(a: Enemy, b: Enemy) -> bool:
	return a.get_current_slot_index() > b.get_current_slot_index()


func _calculate_game_stage() -> int:
	if _debug_forced_stage > 0:
		return _debug_forced_stage

	return int(_enemies_defeated / ENEMIES_PER_GAME_STAGE) + 1


func _refresh_stage_state() -> void:
	_current_game_stage = _calculate_game_stage()
	hud.set_game_stage(_current_game_stage)
	hud.set_kill_count(_enemies_defeated)
	hud.set_debug_stage_value(_current_game_stage)


func _get_spawn_delay_for_current_stage() -> float:
	if _current_game_stage <= EARLY_GAME_MAX_STAGE:
		return EARLY_GAME_SPAWN_DELAY

	return randf_range(min(min_spawn_delay, max_spawn_delay), max(min_spawn_delay, max_spawn_delay))


func _get_spawn_count_for_current_stage(available_path_count: int) -> int:
	if _current_game_stage <= EARLY_GAME_MAX_STAGE:
		return 1

	return randi_range(1, mini(max_spawn_burst, available_path_count))


func _get_enemy_pool_for_current_stage() -> Array[PackedScene]:
	var enemy_pool: Array[PackedScene] = [
		ENEMY_BASIC_SCENE,
		ENEMY_SPIDER_SCENE,
	]

	if _current_game_stage >= HOBGOBLIN_UNLOCK_STAGE:
		enemy_pool.append(ENEMY_HOBGOBLIN_SCENE)

	return enemy_pool


func _start_boss_transition() -> void:
	if _is_game_over or _is_boss_transitioning:
		return

	_is_boss_transitioning = true
	advance_timer.stop()
	respawn_timer.stop()
	enemy_attack_timer.stop()

	for projectile in projectile_layer.get_children():
		projectile.queue_free()

	var transition_delay_tween: Tween = create_tween()
	transition_delay_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	transition_delay_tween.tween_interval(BOSS_TRANSITION_DELAY)
	transition_delay_tween.tween_callback(Callable(hud, "play_boss_transition"))


func _on_boss_transition_finished() -> void:
	if _is_game_over:
		return

	_is_boss_transitioning = false
	advance_timer.start()
	enemy_attack_timer.start()
	_schedule_next_spawn()


func _should_spawn_abomination_boss() -> bool:
	return _current_game_stage == ABOMINATION_BOSS_STAGE and _get_next_stage_enemy_number() == ENEMIES_PER_GAME_STAGE


func _get_next_stage_enemy_number() -> int:
	return (_enemies_defeated % ENEMIES_PER_GAME_STAGE) + 1


func _has_active_boss_enemy() -> bool:
	for enemy in _active_enemies:
		if enemy.is_boss_enemy():
			return true

	return false
