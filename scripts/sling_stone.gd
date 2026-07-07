extends RigidBody3D

const ImpactSparks := preload("res://scripts/impact_sparks.gd")
const DamageNumber := preload("res://scripts/damage_number.gd")
const LIFE_SECONDS := 8.0
const LAUNCH_SPEED_DAMAGE := 10.0
const LAUNCH_DAMAGE_SPEED := 45.0
const SLING_HIT_BASE_XP := 10
const SLING_XP_FALLBACK_MAP_DISTANCE := 100.0
const WORLD_COLLISION_MASK := 1
const SOLDIER_COLLISION_LAYER := 2
const STONE_COLLISION_LAYER := 4

var _age := 0.0
var _has_impacted := false
var _previous_position := Vector3.ZERO
var _launch_position := Vector3.ZERO
var _max_flight_speed := 0.0


func _ready() -> void:
	collision_layer = STONE_COLLISION_LAYER
	collision_mask = WORLD_COLLISION_MASK | SOLDIER_COLLISION_LAYER
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	_previous_position = global_position


func launch(origin: Vector3, direction: Vector3, speed: float) -> void:
	global_position = origin
	_previous_position = origin
	_launch_position = origin
	linear_velocity = direction.normalized() * speed
	angular_velocity = Vector3(10.0, 3.0, -6.0)
	_max_flight_speed = speed


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var current_speed := state.linear_velocity.length()
	_max_flight_speed = maxf(_max_flight_speed, current_speed)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFE_SECONDS:
		queue_free()
		return

	_previous_position = global_position


func _on_body_entered(body: Node) -> void:
	if _has_impacted:
		return
	if body.name == "Player":
		return

	_has_impacted = true
	var impact := _find_impact_surface()
	_spawn_impact_sparks(impact)

	if body.has_method("take_hit"):
		var impact_speed := _impact_speed()
		var damage := _damage_for_speed(impact_speed)
		var final_damage := damage
		var xp_info := _sling_xp_for_hit(body, impact)
		if body.has_method("take_projectile_hit_shape"):
			final_damage = int(body.call("take_projectile_hit_shape", damage, impact["position"], impact["shape_name"]))
		elif body.has_method("take_projectile_hit"):
			final_damage = int(body.call("take_projectile_hit", damage, impact["position"]))
		else:
			body.take_hit(damage)
		var xp_gain := _award_sling_xp(int(xp_info["xp"]))
		_report_sling_impact(impact_speed, final_damage, xp_gain, float(xp_info["multiplier"]), bool(xp_info["headshot"]), float(xp_info["distance"]))
		_spawn_damage_number(final_damage, impact["position"])

	queue_free()


func _impact_speed() -> float:
	return maxf(linear_velocity.length(), _max_flight_speed)


func _report_sling_impact(impact_speed: float, damage: int, xp_gain: int, xp_multiplier: float, was_headshot: bool, flight_distance: float) -> void:
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.has_method("set_last_sling_impact"):
		current_scene.set_last_sling_impact(impact_speed, damage, xp_gain, xp_multiplier, was_headshot, flight_distance)


func _sling_xp_for_hit(body: Node, impact: Dictionary) -> Dictionary:
	var flight_distance := _launch_position.distance_to(impact["position"])
	var distance_multiplier := _sling_distance_xp_multiplier(flight_distance)
	var was_headshot := _is_headshot_hit(body, impact)
	var headshot_multiplier := 2.0 if was_headshot else 1.0
	var xp_multiplier := distance_multiplier * headshot_multiplier
	return {
		"xp": maxi(1, int(round(float(SLING_HIT_BASE_XP) * xp_multiplier))),
		"multiplier": xp_multiplier,
		"headshot": was_headshot,
		"distance": flight_distance
	}


func _sling_distance_xp_multiplier(flight_distance: float) -> float:
	var map_distance := _sling_xp_map_distance()
	var distance_ratio := clampf(flight_distance / map_distance, 0.0, 1.0)
	return 1.0 + distance_ratio * 2.0


func _sling_xp_map_distance() -> float:
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.has_method("get_sling_xp_map_distance"):
		return maxf(1.0, float(current_scene.call("get_sling_xp_map_distance")))
	return SLING_XP_FALLBACK_MAP_DISTANCE


func _is_headshot_hit(body: Node, impact: Dictionary) -> bool:
	var hit_shape_name := String(impact.get("shape_name", ""))
	if body.has_method("is_projectile_headshot"):
		return bool(body.call("is_projectile_headshot", impact["position"], hit_shape_name))
	return hit_shape_name == "HeadHitShape"


func _award_sling_xp(xp: int) -> int:
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.has_method("award_player_sling_xp"):
		return int(current_scene.call("award_player_sling_xp", xp))
	return 0


func _damage_for_speed(impact_speed: float) -> int:
	return maxi(1, int(round(impact_speed / LAUNCH_DAMAGE_SPEED * LAUNCH_SPEED_DAMAGE)))


func _damage_color(damage: int) -> Color:
	var red_weight := clampf(float(damage) / LAUNCH_SPEED_DAMAGE, 0.0, 1.0)
	return Color.WHITE.lerp(Color("#ff2a1f"), red_weight)


func _spawn_damage_number(damage: int, position: Vector3) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		return

	var number := Label3D.new()
	number.name = "DamageNumber"
	number.set_script(DamageNumber)
	parent.add_child(number)
	number.start(damage, position, _damage_color(damage))


func _spawn_impact_sparks(impact: Dictionary) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		return

	var sparks := Node3D.new()
	sparks.name = "ImpactSparks"
	sparks.set_script(ImpactSparks)
	parent.add_child(sparks)

	sparks.burst(impact["position"], impact["normal"])


func _find_impact_surface() -> Dictionary:
	var fallback_normal := Vector3.UP
	if linear_velocity.length() > 0.01:
		fallback_normal = -linear_velocity.normalized()

	var fallback_position := global_position + fallback_normal * 0.12
	var world := get_world_3d()
	if world == null:
		return {"position": fallback_position, "normal": fallback_normal, "shape_name": ""}

	var travel_direction := global_position - _previous_position
	if travel_direction.length() < 0.01 and linear_velocity.length() > 0.01:
		travel_direction = linear_velocity.normalized()

	var ray_start := _previous_position - travel_direction.normalized() * 0.2
	var ray_end := global_position + travel_direction.normalized() * 0.65
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = [self]

	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {"position": fallback_position, "normal": fallback_normal, "shape_name": ""}

	var hit_normal: Vector3 = hit["normal"]
	var hit_position: Vector3 = hit["position"]
	return {
		"position": hit_position + hit_normal * 0.055,
		"normal": hit_normal,
		"shape_name": _hit_shape_name(hit)
	}


func _hit_shape_name(hit: Dictionary) -> String:
	var collider := hit["collider"] as CollisionObject3D
	if collider == null:
		return ""

	var shape_index := int(hit.get("shape", -1))
	if shape_index < 0:
		return ""

	var owner_id := collider.shape_find_owner(shape_index)
	if owner_id < 0:
		return ""

	var owner := collider.shape_owner_get_owner(owner_id) as Node
	if owner == null:
		return ""

	return owner.name
