class_name GameHud
extends CanvasLayer

signal restart_requested

@onready var player_health_value_label: Label = $Root/BottomBar/PlayerHealthValueLabel
@onready var stage_value_label: Label = $Root/BottomBar/StageValueLabel
@onready var kills_value_label: Label = $Root/BottomBar/KillsValueLabel
@onready var impact_flash: ColorRect = $Root/ImpactFlash
@onready var damage_flash: ColorRect = $Root/DamageFlash
@onready var game_over_overlay: Control = $Root/GameOverOverlay
@onready var restart_button: Button = $Root/GameOverOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RestartButton

var _impact_flash_tween: Tween
var _damage_flash_tween: Tween


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_button_pressed)
	reset()


func set_player_health(player_health: int) -> void:
	player_health_value_label.text = "%02d" % maxi(player_health, 0)


func set_enemy_stage(current_stage: int, total_stages: int) -> void:
	if current_stage <= 0 or total_stages <= 0:
		set_waiting_for_enemy()
		return

	stage_value_label.text = "%02d / %02d" % [current_stage, total_stages]


func set_waiting_for_enemy() -> void:
	stage_value_label.text = "-- / --"


func set_kill_count(kill_count: int) -> void:
	kills_value_label.text = "%03d" % maxi(kill_count, 0)


func reset() -> void:
	if is_instance_valid(_impact_flash_tween):
		_impact_flash_tween.kill()

	if is_instance_valid(_damage_flash_tween):
		_damage_flash_tween.kill()

	set_player_health(10)
	set_waiting_for_enemy()
	set_kill_count(0)
	hide_game_over()
	impact_flash.modulate = Color(1.0, 1.0, 1.0, 0.0)
	damage_flash.modulate = Color(1.0, 1.0, 1.0, 0.0)


func show_game_over() -> void:
	game_over_overlay.visible = true
	restart_button.grab_focus()


func hide_game_over() -> void:
	game_over_overlay.visible = false


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
