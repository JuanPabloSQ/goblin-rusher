class_name GameHud
extends CanvasLayer

signal restart_requested
signal resume_requested
signal debug_stage_requested(stage: int)
signal upgrade_selected(upgrade_id: StringName)
signal boss_transition_finished

@onready var player_health_value_label: Label = $Root/BottomBar/PlayerHealthValueLabel
@onready var stage_value_label: Label = $Root/BottomBar/StageValueLabel
@onready var kills_value_label: Label = $Root/BottomBar/KillsValueLabel
@onready var impact_flash: ColorRect = $Root/ImpactFlash
@onready var damage_flash: ColorRect = $Root/DamageFlash
@onready var transition_veil: ColorRect = $Root/TransitionVeil
@onready var boss_reward_overlay: Control = $Root/BossRewardOverlay
@onready var chest_button: Button = $Root/BossRewardOverlay/CenterContainer/VBoxContainer/ChestButton
@onready var reward_panel: PanelContainer = $Root/BossRewardOverlay/CenterContainer/VBoxContainer/RewardPanel
@onready var hover_upgrade_button: Button = $Root/BossRewardOverlay/CenterContainer/VBoxContainer/RewardPanel/MarginContainer/VBoxContainer/HoverUpgradeButton
@onready var debug_toggle_button: Button = $Root/BottomBar/DebugToggleButton
@onready var debug_panel: PanelContainer = $Root/DebugPanel
@onready var debug_stage_input: LineEdit = $Root/DebugPanel/MarginContainer/VBoxContainer/DebugStageRow/DebugStageInput
@onready var debug_apply_button: Button = $Root/DebugPanel/MarginContainer/VBoxContainer/DebugStageRow/DebugApplyButton
@onready var debug_feedback_label: Label = $Root/DebugPanel/MarginContainer/VBoxContainer/DebugFeedbackLabel
@onready var game_over_overlay: Control = $Root/GameOverOverlay
@onready var restart_button: Button = $Root/GameOverOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RestartButton
@onready var pause_overlay: Control = $Root/PauseOverlay
@onready var continue_button: Button = $Root/PauseOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton
@onready var pause_restart_button: Button = $Root/PauseOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RestartButton

var _impact_flash_tween: Tween
var _damage_flash_tween: Tween
var _boss_transition_tween: Tween


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)
	pause_restart_button.pressed.connect(_on_restart_button_pressed)
	chest_button.pressed.connect(_on_chest_button_pressed)
	hover_upgrade_button.pressed.connect(_on_hover_upgrade_button_pressed)
	debug_toggle_button.pressed.connect(_on_debug_toggle_pressed)
	debug_apply_button.pressed.connect(_on_debug_apply_pressed)
	debug_stage_input.text_submitted.connect(_on_debug_stage_text_submitted)
	reset()


func set_player_health(player_health: int) -> void:
	player_health_value_label.text = "%02d" % maxi(player_health, 0)


func set_game_stage(game_stage: int) -> void:
	stage_value_label.text = "%02d" % maxi(game_stage, 1)


func set_kill_count(kill_count: int) -> void:
	kills_value_label.text = "%03d" % maxi(kill_count, 0)


func reset() -> void:
	if is_instance_valid(_impact_flash_tween):
		_impact_flash_tween.kill()

	if is_instance_valid(_damage_flash_tween):
		_damage_flash_tween.kill()

	if is_instance_valid(_boss_transition_tween):
		_boss_transition_tween.kill()

	set_player_health(10)
	set_game_stage(1)
	set_kill_count(0)
	set_debug_stage_value(1)
	set_debug_feedback("Debug listo", Color(0.8, 0.78, 0.66, 0.9))
	hide_debug_panel()
	hide_game_over()
	hide_pause()
	_hide_boss_reward()
	impact_flash.modulate = Color(1.0, 1.0, 1.0, 0.0)
	damage_flash.modulate = Color(1.0, 1.0, 1.0, 0.0)
	transition_veil.visible = false
	transition_veil.material.set_shader_parameter("wave_progress", 0.0)


func show_game_over() -> void:
	game_over_overlay.visible = true
	restart_button.grab_focus()


func hide_game_over() -> void:
	game_over_overlay.visible = false


func show_pause() -> void:
	pause_overlay.visible = true
	continue_button.grab_focus()


func hide_pause() -> void:
	pause_overlay.visible = false


func set_debug_stage_value(game_stage: int) -> void:
	debug_stage_input.text = str(maxi(game_stage, 1))


func set_debug_feedback(message: String, color: Color = Color(0.8, 0.78, 0.66, 0.9)) -> void:
	debug_feedback_label.text = message
	debug_feedback_label.modulate = color


func play_boss_transition() -> void:
	if is_instance_valid(_boss_transition_tween):
		_boss_transition_tween.kill()

	_hide_boss_reward()
	transition_veil.visible = true
	transition_veil.material.set_shader_parameter("wave_progress", 0.0)
	_boss_transition_tween = create_tween()
	_boss_transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_boss_transition_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_boss_transition_tween.tween_method(_set_transition_wave_progress, 0.0, 1.15, 1.35)
	_boss_transition_tween.tween_callback(Callable(self, "_show_boss_reward"))


func show_debug_panel() -> void:
	debug_panel.visible = true
	debug_stage_input.grab_focus()
	debug_stage_input.caret_column = debug_stage_input.text.length()


func hide_debug_panel() -> void:
	debug_panel.visible = false


func toggle_debug_panel() -> void:
	debug_panel.visible = not debug_panel.visible
	if debug_panel.visible:
		debug_stage_input.grab_focus()
		debug_stage_input.caret_column = debug_stage_input.text.length()


func _set_transition_wave_progress(progress: float) -> void:
	transition_veil.material.set_shader_parameter("wave_progress", progress)


func _finish_boss_transition() -> void:
	_hide_boss_reward()
	transition_veil.visible = false
	transition_veil.material.set_shader_parameter("wave_progress", 0.0)
	boss_transition_finished.emit()


func _show_boss_reward() -> void:
	boss_reward_overlay.visible = true
	chest_button.visible = true
	chest_button.disabled = false
	reward_panel.visible = false
	chest_button.grab_focus()


func _hide_boss_reward() -> void:
	boss_reward_overlay.visible = false
	chest_button.visible = true
	chest_button.disabled = false
	reward_panel.visible = false


func _continue_boss_transition_after_reward() -> void:
	if is_instance_valid(_boss_transition_tween):
		_boss_transition_tween.kill()

	_boss_transition_tween = create_tween()
	_boss_transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_boss_transition_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_boss_transition_tween.tween_interval(0.4)
	_boss_transition_tween.tween_method(_set_transition_wave_progress, 1.15, 0.0, 1.55)
	_boss_transition_tween.tween_callback(Callable(self, "_finish_boss_transition"))


func play_hit_flash() -> void:
	if is_instance_valid(_impact_flash_tween):
		_impact_flash_tween.kill()

	impact_flash.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_impact_flash_tween = create_tween()
	_impact_flash_tween.tween_property(impact_flash, "modulate", Color(1.0, 1.0, 1.0, 0.18), 0.04)
	_impact_flash_tween.tween_property(impact_flash, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.12)


func play_player_hit_feedback() -> void:
	if is_instance_valid(_damage_flash_tween):
		_damage_flash_tween.kill()

	damage_flash.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(damage_flash, "modulate", Color(1.0, 1.0, 1.0, 0.28), 0.05)
	_damage_flash_tween.tween_property(damage_flash, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.14)


func _on_restart_button_pressed() -> void:
	restart_requested.emit()


func _on_continue_button_pressed() -> void:
	resume_requested.emit()


func _on_chest_button_pressed() -> void:
	chest_button.visible = false
	reward_panel.visible = true
	hover_upgrade_button.grab_focus()


func _on_hover_upgrade_button_pressed() -> void:
	upgrade_selected.emit(&"hover_auto_fire")
	_hide_boss_reward()
	_continue_boss_transition_after_reward()


func _on_debug_toggle_pressed() -> void:
	toggle_debug_panel()


func _on_debug_apply_pressed() -> void:
	_submit_debug_stage()


func _on_debug_stage_text_submitted(_new_text: String) -> void:
	_submit_debug_stage()


func _submit_debug_stage() -> void:
	var trimmed_value: String = debug_stage_input.text.strip_edges()
	if trimmed_value.is_empty():
		set_debug_feedback("Ingresa una etapa valida", Color(1.0, 0.56, 0.4, 1.0))
		return

	if not trimmed_value.is_valid_int():
		set_debug_feedback("Solo numeros enteros", Color(1.0, 0.56, 0.4, 1.0))
		return

	var requested_stage: int = maxi(trimmed_value.to_int(), 1)
	set_debug_stage_value(requested_stage)
	debug_stage_requested.emit(requested_stage)
	hide_debug_panel()
