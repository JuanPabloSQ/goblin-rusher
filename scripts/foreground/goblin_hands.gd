class_name GoblinHands
extends Node2D

const HUD_HEIGHT: float = 44.0
const HAND_COLOR: Color = Color(0.53, 0.73, 0.18)
const HAND_SHADOW_COLOR: Color = Color(0.2, 0.29, 0.08)
const OUTLINE_COLOR: Color = Color(0.09, 0.08, 0.05)
const CLAW_COLOR: Color = Color(0.82, 0.27, 0.18)

@onready var left_hand_anchor: Marker2D = $LeftHandAnchor
@onready var right_hand_anchor: Marker2D = $RightHandAnchor
@onready var right_hand_bone_spawn: Marker2D = $RightHandAnchor/RightHandBoneSpawn

var _throw_kick: float = 0.0
var _throw_tween: Tween


func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_update_anchor_positions()
	_update_right_hand_pose()
	queue_redraw()


func play_throw() -> void:
	if is_instance_valid(_throw_tween):
		_throw_tween.kill()

	_throw_tween = create_tween()
	_throw_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_throw_tween.tween_method(_set_throw_kick, 0.0, 1.0, 0.05)
	_throw_tween.tween_method(_set_throw_kick, 1.0, 0.0, 0.12)


func get_right_hand_spawn_global_position() -> Vector2:
	return right_hand_bone_spawn.global_position


func _on_viewport_size_changed() -> void:
	_update_anchor_positions()
	queue_redraw()


func _update_anchor_positions() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var gameplay_bottom: float = viewport_size.y - HUD_HEIGHT

	left_hand_anchor.position = Vector2(76.0, gameplay_bottom + 6.0)
	left_hand_anchor.rotation = deg_to_rad(-26.0)
	right_hand_anchor.position = Vector2(viewport_size.x - 78.0, gameplay_bottom + 6.0)
	_update_right_hand_pose()


func _update_right_hand_pose() -> void:
	right_hand_anchor.rotation = deg_to_rad(28.0 - _throw_kick * 10.0)
	right_hand_anchor.position.y = (get_viewport_rect().size.y - HUD_HEIGHT + 6.0) - _throw_kick * 5.0
	right_hand_anchor.position.x = (get_viewport_rect().size.x - 78.0) + _throw_kick * 4.0


func _draw() -> void:
	_draw_hand(left_hand_anchor, false)
	_draw_hand(right_hand_anchor, true)


func _draw_hand(anchor: Marker2D, is_right_hand: bool) -> void:
	var hand_scale: Vector2 = Vector2.ONE if is_right_hand else Vector2(-1.0, 1.0)
	draw_set_transform(anchor.position, anchor.rotation, hand_scale)

	var forearm_points: PackedVector2Array = PackedVector2Array([
		Vector2(-10.0, 2.0),
		Vector2(10.0, 2.0),
		Vector2(16.0, 40.0),
		Vector2(-16.0, 40.0),
	])
	draw_colored_polygon(forearm_points, OUTLINE_COLOR)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-7.0, 5.0),
			Vector2(7.0, 5.0),
			Vector2(12.0, 38.0),
			Vector2(-12.0, 38.0),
		]),
		HAND_SHADOW_COLOR
	)

	var palm_outline: PackedVector2Array = PackedVector2Array([
		Vector2(-14.0, -3.0),
		Vector2(14.0, -3.0),
		Vector2(18.0, -18.0),
		Vector2(10.0, -28.0),
		Vector2(-10.0, -28.0),
		Vector2(-18.0, -18.0),
	])
	draw_colored_polygon(palm_outline, OUTLINE_COLOR)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-11.0, -4.0),
			Vector2(11.0, -4.0),
			Vector2(15.0, -17.0),
			Vector2(8.0, -26.0),
			Vector2(-8.0, -26.0),
			Vector2(-15.0, -17.0),
		]),
		HAND_COLOR
	)

	var finger_bases: Array[float] = [-10.0, -3.0, 4.0, 11.0]
	var finger_tips: Array[Vector2] = [
		Vector2(-13.0, -41.0),
		Vector2(-5.0, -46.0),
		Vector2(3.0, -44.0),
		Vector2(12.0, -36.0),
	]

	for finger_index in range(finger_bases.size()):
		var base_position: Vector2 = Vector2(finger_bases[finger_index], -20.0)
		var tip_position: Vector2 = finger_tips[finger_index]
		draw_line(base_position, tip_position, OUTLINE_COLOR, 8.0)
		draw_line(base_position, tip_position, HAND_COLOR, 6.0)
		_draw_claw(tip_position, finger_index - 1.5)

	var thumb_base: Vector2 = Vector2(-12.0, -8.0)
	var thumb_tip: Vector2 = Vector2(-24.0, -18.0)
	draw_line(thumb_base, thumb_tip, OUTLINE_COLOR, 8.0)
	draw_line(thumb_base, thumb_tip, HAND_COLOR, 6.0)
	_draw_claw(thumb_tip, -1.0)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_claw(tip_position: Vector2, horizontal_bias: float) -> void:
	var claw_points: PackedVector2Array = PackedVector2Array([
		tip_position,
		tip_position + Vector2(2.0 + horizontal_bias, 6.0),
		tip_position + Vector2(-2.0 + horizontal_bias, 5.0),
	])
	draw_colored_polygon(claw_points, CLAW_COLOR)


func _set_throw_kick(value: float) -> void:
	_throw_kick = value
	_update_right_hand_pose()
	queue_redraw()
