extends "res://scripts/combat_animal.gd"

const WolfScene := preload("res://assets/characters/quaternius/animals/Wolf.gltf")

const FACTION_PREDATOR := "predator"
const TARGET_REFRESH_SECONDS := 0.22
const SIZE_SCALE := 1.56

@export var chase_speed := 5.6
@export var aggro_range := 32.0
@export var bite_range := 0.68
@export var bite_damage := 10
@export var bite_cooldown_seconds := 1.05

var player_target: Node3D

var _active_target: Node3D
var _target_refresh_time := 0.0
var _bite_cooldown := 0.35
var _attack_animation_time := 0.0


func _on_setup(first_node: Node, _second_node: Node) -> void:
	player_target = first_node as Node3D


func _actor_max_health() -> int:
	return 64


func _actor_faction() -> String:
	return FACTION_PREDATOR


func _actor_display_name() -> String:
	return "Wild wolf"


func _actor_scene() -> PackedScene:
	return WolfScene


func _visual_scale() -> float:
	return 0.26 * SIZE_SCALE


func _visual_offset() -> Vector3:
	return Vector3(0.0, -0.02, 0.0)


func _body_radius() -> float:
	return 0.12 * SIZE_SCALE


func _body_height() -> float:
	return 0.46 * SIZE_SCALE


func _body_center_y() -> float:
	return 0.24 * SIZE_SCALE


func _head_center() -> Vector3:
	return Vector3(0.0, 0.34, -0.26) * SIZE_SCALE


func _head_radius() -> Vector3:
	return Vector3(0.11, 0.1, 0.11) * SIZE_SCALE


func _label_position() -> Vector3:
	return Vector3(0.0, 0.66, 0.0) * SIZE_SCALE


func _label_color() -> Color:
	return Color("#ffb56d")


func _label_outline_color() -> Color:
	return Color("#140909")


func _on_actor_ready() -> void:
	if _animation_player != null:
		_animation_player.speed_scale = 1.0
	_play_animation("Idle")


func _tick_actor(delta: float) -> void:
	_target_refresh_time = maxf(0.0, _target_refresh_time - delta)
	_bite_cooldown = maxf(0.0, _bite_cooldown - delta)
	_attack_animation_time = maxf(0.0, _attack_animation_time - delta)

	if _target_refresh_time <= 0.0 or not _is_attack_target_valid(_active_target, aggro_range + 4.0):
		_active_target = _choose_target()
		_target_refresh_time = TARGET_REFRESH_SECONDS

	if _active_target != null:
		_move_toward_target(delta, _active_target)
	else:
		velocity.x = move_toward(velocity.x, 0.0, chase_speed * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0.0, chase_speed * delta * 5.0)


func _after_actor_move(_delta: float) -> void:
	var flat_speed := Vector3(velocity.x, 0.0, velocity.z).length()
	if _attack_animation_time > 0.0:
		_play_animation("Attack")
	elif flat_speed > 0.2:
		_play_animation("Gallop")
	else:
		_play_animation("Idle")


func _on_actor_died() -> void:
	_play_animation("Death")
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(Callable(self, "queue_free"))


func _move_toward_target(delta: float, target: Node3D) -> void:
	var to_target := target.global_position - global_position
	var flat_to_target := Vector3(to_target.x, 0.0, to_target.z)
	var distance := flat_to_target.length()
	if distance <= 0.05:
		return

	var direction := flat_to_target / distance
	_face_direction(direction, delta)

	if distance <= bite_range:
		velocity.x = move_toward(velocity.x, 0.0, chase_speed * delta * 6.0)
		velocity.z = move_toward(velocity.z, 0.0, chase_speed * delta * 6.0)
		_try_bite(target)
	else:
		velocity.x = direction.x * chase_speed
		velocity.z = direction.z * chase_speed


func _try_bite(target: Node3D) -> void:
	if _bite_cooldown > 0.0 or target == null:
		return

	_bite_cooldown = bite_cooldown_seconds
	_attack_animation_time = 0.45
	_play_animation("Attack")
	if target.has_method("take_damage"):
		target.call("take_damage", bite_damage, global_position)


func _choose_target() -> Node3D:
	var best_target: Node3D
	var best_distance_squared := aggro_range * aggro_range

	if _is_attack_target_valid(player_target, aggro_range):
		best_target = player_target
		best_distance_squared = global_position.distance_squared_to(player_target.global_position)

	for node in _nearby_combat_soldiers(global_position, aggro_range):
		var candidate := node as Node3D
		if candidate == self or not _is_attack_target_valid(candidate, aggro_range):
			continue

		var distance_squared := global_position.distance_squared_to(candidate.global_position)
		if distance_squared <= best_distance_squared:
			best_target = candidate
			best_distance_squared = distance_squared

	return best_target


func _is_attack_target_valid(target: Node3D, range: float) -> bool:
	if target == null or not is_instance_valid(target) or target == self:
		return false
	if target.has_method("is_alive") and not target.call("is_alive"):
		return false
	if target.has_method("get_faction") and String(target.call("get_faction")) == FACTION_PREDATOR:
		return false

	var target_health = target.get("health")
	if target_health != null and int(target_health) <= 0:
		return false

	return global_position.distance_squared_to(target.global_position) <= range * range


func _nearby_combat_soldiers(center: Vector3, radius: float) -> Array:
	if terrain_owner != null and is_instance_valid(terrain_owner) and terrain_owner.has_method("get_nearby_combat_soldiers"):
		return terrain_owner.call("get_nearby_combat_soldiers", center, radius)
	return get_tree().get_nodes_in_group(SOLDIER_GROUP)


func _face_direction(direction: Vector3, delta: float) -> void:
	if direction.length() <= 0.01:
		return
	var desired_yaw := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, desired_yaw, minf(delta * 9.0, 1.0))
