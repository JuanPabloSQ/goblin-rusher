class_name GameHud
extends CanvasLayer

@onready var stage_value_label: Label = $Root/BottomBar/StageValueLabel
@onready var kills_value_label: Label = $Root/BottomBar/KillsValueLabel
@onready var impact_flash: ColorRect = $Root/ImpactFlash

var _impact_flash_tween: Tween


func _ready() -> void:
	set_waiting_for_enemy()
	set_kill_count(0)


func set_enemy_stage(current_stage: int, total_stages: int) -> void:
	if current_stage <= 0 or total_stages <= 0:
		set_waiting_for_enemy()
		return

	stage_value_label.text = "%02d / %02d" % [current_stage, total_stages]


func set_waiting_for_enemy() -> void:
	stage_value_label.text = "-- / --"


func set_kill_count(kill_count: int) -> void:
	kills_value_label.text = "%03d" % maxi(kill_count, 0)


func play_hit_flash() -> void:
	if is_instance_valid(_impact_flash_tween):
		_impact_flash_tween.kill()

	impact_flash.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_impact_flash_tween = create_tween()
	_impact_flash_tween.tween_property(impact_flash, "modulate", Color(1.0, 1.0, 1.0, 0.18), 0.04)
	_impact_flash_tween.tween_property(impact_flash, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.12)
