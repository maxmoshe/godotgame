extends "res://scripts/combat_animal.gd"

const SheepScene := preload("res://assets/characters/quaternius/animals/Sheep.fbx")

const FACTION_FRIENDLY := "friendly"
const SIZE_SCALE := 1.3


func _actor_max_health() -> int:
	return 28


func _actor_faction() -> String:
	return FACTION_FRIENDLY


func _actor_display_name() -> String:
	return "Sheep"


func _actor_scene() -> PackedScene:
	return SheepScene


func _visual_scale() -> float:
	return 0.2 * SIZE_SCALE


func _body_radius() -> float:
	return 0.12 * SIZE_SCALE


func _body_height() -> float:
	return 0.44 * SIZE_SCALE


func _body_center_y() -> float:
	return 0.24 * SIZE_SCALE


func _head_center() -> Vector3:
	return Vector3(0.0, 0.33, -0.23) * SIZE_SCALE


func _head_radius() -> Vector3:
	return Vector3(0.1, 0.09, 0.1) * SIZE_SCALE


func _label_position() -> Vector3:
	return Vector3(0.0, 0.64, 0.0) * SIZE_SCALE


func _label_color() -> Color:
	return Color("#dff0c7")


func _on_actor_ready() -> void:
	for animation_name in ["Armature|Idle", "Idle"]:
		if _animation_player != null and _animation_player.has_animation(animation_name):
			_play_animation(animation_name)
			return
