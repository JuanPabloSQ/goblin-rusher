class_name GameHud
extends CanvasLayer

@onready var stage_value_label: Label = $Root/BottomBar/StageValueLabel
@onready var kills_value_label: Label = $Root/BottomBar/KillsValueLabel


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
