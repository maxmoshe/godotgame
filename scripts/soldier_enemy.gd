extends CharacterBody3D

const HumanProjectile := preload("res://scripts/human_projectile.gd")

const WEAPON_SWORD := "sword"
const WEAPON_SPEAR := "spear"
const WEAPON_BOW := "bow"
const WEAPON_SLING := "sling"
const FACTION_ENEMY := "enemy"
const FACTION_FRIENDLY := "friendly"
const ORDER_CHARGE := "charge"
const ORDER_HOLD := "hold"
const SOLDIER_GROUP := "combat_soldiers"

const GRAVITY := 22.0
const GROUND_STICK_VELOCITY := -0.25
const MAX_STAT := 50
const MIN_STAT := 1
const BASE_MELEE_DAMAGE := 7
const BASE_ARROW_DAMAGE := 5
const ARROW_SPEED := 22.0
const ARROW_RELEASE_HEIGHT := 1.05
const ARROW_FORWARD_OFFSET := 0.55
const BOW_AIM_HEIGHT := 0.86
const MAX_ARROW_LEAD_SECONDS := 1.2
const SWORD_ATTACK_RANGE := 1.85
const BOW_ATTACK_RANGE := 18.0
const SWORD_ATTACK_COOLDOWN := 1.05
const BOW_CHARGE_SECONDS := 2.1
const BOW_CHARGING_MOVE_MULTIPLIER := 0.35
const FRIENDLY_FIRE_LANE_RADIUS := 0.82
const FRIENDLY_FIRE_SCORE_PENALTY := 1000.0
const HOLD_POSITION_ARRIVAL_DISTANCE := 0.55
const HOLD_DEFEND_RADIUS := 8.0
const ATTACK_SECONDS := 0.62
const ATTACK_STRIKE_TIME := 0.32
const HEADSHOT_MULTIPLIER := 3
const HEAD_CENTER := Vector3(0.0, 1.62, 0.0)
const HEAD_RADIUS := Vector3(0.42, 0.38, 0.42)
const HEADSHOT_MIN_Y := 1.30
const HEADSHOT_FLAT_RADIUS := 0.54
const DETAIL_MESH_GROUP := "soldier_detail_mesh"

@export var move_speed := 3.4
@export var aggro_range := 34.0
@export var max_health := 58
@export var weapon_type := WEAPON_SWORD
@export var has_shield := false
@export var faction := FACTION_ENEMY
@export var power := 5
@export var speed := 5
@export var dexterity := 3

var player_target: Node3D
var terrain_owner: Node
var health := max_health

var _active_target: Node3D
var _attack_cooldown := 0.75
var _attack_time := 0.0
var _has_struck := false
var _order_mode := ORDER_CHARGE
var _order_position := Vector3.ZERO
var _formation_index := 0
var _has_order_position := false
var _flash_time := 0.0
var _animation_time := 0.0
var _label: Label3D
var _base_material: StandardMaterial3D
var _hit_material: StandardMaterial3D
var _metal_material: StandardMaterial3D
var _leather_material: StandardMaterial3D
var _cloth_material: StandardMaterial3D
var _body_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D
var _left_arm_mesh: MeshInstance3D
var _right_arm_mesh: MeshInstance3D
var _left_leg_mesh: MeshInstance3D
var _right_leg_mesh: MeshInstance3D
var _sword_blade_mesh: MeshInstance3D
var _sword_handle_mesh: MeshInstance3D
var _sword_guard_mesh: MeshInstance3D
var _bow_mesh: MeshInstance3D
var _bow_string_mesh: MeshInstance3D
var _loaded_arrow_mesh: MeshInstance3D
var _animated_meshes: Array[MeshInstance3D] = []
var _base_positions: Array[Vector3] = []
var _base_rotations: Array[Vector3] = []
var _base_scales: Array[Vector3] = []


func setup(new_target: Node3D, new_terrain_owner: Node, new_weapon_type := WEAPON_SWORD, new_has_shield := false, new_faction := FACTION_ENEMY, new_power := 5, new_speed := 5, new_dexterity := 3) -> void:
	player_target = new_target
	terrain_owner = new_terrain_owner
	weapon_type = new_weapon_type
	has_shield = new_has_shield
	faction = new_faction
	power = clampi(new_power, MIN_STAT, MAX_STAT)
	speed = clampi(new_speed, MIN_STAT, MAX_STAT)
	dexterity = clampi(new_dexterity, MIN_STAT, MAX_STAT)


func _ready() -> void:
	health = max_health
	add_to_group(SOLDIER_GROUP)
	_apply_stats()
	_base_material = _make_material(Color("#9b6b45"), 0.88)
	_hit_material = _make_material(Color("#8d251f"), 0.72)
	_metal_material = _make_material(Color("#aeb7b5"), 0.35)
	_leather_material = _make_material(Color("#4e2e1d"), 0.92)
	_cloth_material = _make_material(_cloth_color(), 0.94)
	_build_body()
	_build_equipment()
	_add_health_label()
	_update_health_label()


func _physics_process(delta: float) -> void:
	if health <= 0:
		return

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_flash_time = maxf(0.0, _flash_time - delta)
	_update_hit_flash()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = GROUND_STICK_VELOCITY

	var flat_speed := 0.0
	_active_target = _choose_target()
	if _active_target != null:
		flat_speed = _think_and_move(delta, _active_target)
	elif _should_hold_position():
		flat_speed = _move_to_order_position(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * delta)

	move_and_slide()
	_animate_soldier(delta, flat_speed)
	_update_health_label()


func take_hit(damage: int) -> void:
	_apply_damage(damage)


func take_damage(damage: int, _source_position := Vector3.ZERO) -> void:
	_apply_damage(damage)


func take_projectile_hit(damage: int, hit_position: Vector3) -> int:
	var final_damage := damage
	if _is_headshot(hit_position):
		final_damage *= HEADSHOT_MULTIPLIER
	_apply_damage(final_damage)
	return final_damage


func take_projectile_hit_shape(damage: int, hit_position: Vector3, hit_shape_name: String) -> int:
	var final_damage := damage
	if hit_shape_name == "HeadHitShape" or _is_headshot(hit_position):
		final_damage *= HEADSHOT_MULTIPLIER
	_apply_damage(final_damage)
	return final_damage


func get_faction() -> String:
	return faction


func is_alive() -> bool:
	return health > 0


func receive_order(order_mode: String, order_position: Vector3, formation_index: int) -> void:
	if faction != FACTION_FRIENDLY:
		return

	_order_mode = order_mode
	_formation_index = formation_index
	if order_mode == ORDER_HOLD:
		_order_position = order_position
		_has_order_position = true
	elif order_mode == ORDER_CHARGE:
		_has_order_position = false
	_attack_time = 0.0
	_has_struck = false


func _think_and_move(delta: float, attack_target: Node3D) -> float:
	var to_target := attack_target.global_position - global_position
	var flat_to_target := Vector3(to_target.x, 0.0, to_target.z)
	var distance := flat_to_target.length()
	var direction := Vector3.ZERO
	if distance > 0.05:
		direction = flat_to_target / distance
		_face_direction(direction, delta)

	if _attack_time > 0.0:
		_attack_time = maxf(0.0, _attack_time - delta)
		if weapon_type == WEAPON_BOW:
			_move_while_charging_bow(delta, direction, distance)
		else:
			velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 4.0)
			velocity.z = move_toward(velocity.z, 0.0, move_speed * delta * 4.0)
		_check_attack_strike(distance)
		return Vector3(velocity.x, 0.0, velocity.z).length()

	if distance <= _attack_range() and _attack_cooldown <= 0.0:
		_start_attack()
	elif _should_hold_position():
		_move_to_order_position(delta)
	elif distance <= aggro_range and direction != Vector3.ZERO:
		var desired_distance := 0.0 if weapon_type == WEAPON_SWORD else BOW_ATTACK_RANGE * 0.65
		var move_direction := direction
		if desired_distance > 0.0 and distance < desired_distance:
			move_direction = -direction
		velocity.x = move_direction.x * move_speed
		velocity.z = move_direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * delta)

	return Vector3(velocity.x, 0.0, velocity.z).length()


func _start_attack() -> void:
	_attack_time = _attack_duration_seconds()
	_attack_cooldown = _attack_cooldown_seconds()
	_has_struck = false


func _check_attack_strike(distance: float) -> void:
	if _has_struck:
		return

	var elapsed := _attack_duration_seconds() - _attack_time
	if elapsed < _attack_strike_time_seconds():
		return

	_has_struck = true
	if _active_target == null or distance > _attack_range() + 0.35:
		return

	if weapon_type == WEAPON_BOW:
		if _shot_has_friendly_fire_risk(_active_target):
			return
		_fire_arrow(_active_target)
	elif _active_target.has_method("take_damage"):
		_active_target.take_damage(_damage_from_power(BASE_MELEE_DAMAGE), global_position)


func _apply_damage(damage: int) -> void:
	if health <= 0:
		return

	health = maxi(0, health - damage)
	_flash_time = 0.18
	_update_health_label()
	if health <= 0:
		_die()


func _die() -> void:
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	if _label != null:
		_label.visible = false
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.0, 0.15, 1.0), 0.18)
	tween.tween_callback(Callable(self, "queue_free"))


func _choose_target() -> Node3D:
	if _should_hold_position():
		return _choose_hold_defense_target()
	if weapon_type == WEAPON_BOW:
		return _choose_bow_target()

	var best_target: Node3D
	var best_distance := aggro_range

	if faction == FACTION_ENEMY and player_target != null:
		best_target = _nearest_target(best_target, best_distance, player_target)
		if best_target != null:
			best_distance = global_position.distance_to(best_target.global_position)

	for node in get_tree().get_nodes_in_group(SOLDIER_GROUP):
		if node == self:
			continue
		if not node.has_method("get_faction") or not node.has_method("is_alive"):
			continue
		if not node.is_alive() or node.get_faction() == faction:
			continue
		best_target = _nearest_target(best_target, best_distance, node)
		if best_target != null:
			best_distance = global_position.distance_to(best_target.global_position)

	return best_target


func _choose_hold_defense_target() -> Node3D:
	var best_target: Node3D
	var best_score := 999999.0

	for node in get_tree().get_nodes_in_group(SOLDIER_GROUP):
		if node == self:
			continue
		if not node.has_method("get_faction") or not node.has_method("is_alive"):
			continue
		if not node.is_alive() or node.get_faction() == faction:
			continue
		var candidate := node as Node3D
		if candidate == null:
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if weapon_type == WEAPON_BOW:
			if distance > BOW_ATTACK_RANGE:
				continue
		elif candidate.global_position.distance_to(_order_position) > HOLD_DEFEND_RADIUS:
			continue
		var score := distance
		if weapon_type == WEAPON_BOW:
			score += _friendly_fire_risk_for_target(candidate) * FRIENDLY_FIRE_SCORE_PENALTY
		if score < best_score:
			best_score = score
			best_target = candidate

	return best_target


func _choose_bow_target() -> Node3D:
	var candidates: Array[Node3D] = []
	if faction == FACTION_ENEMY and player_target != null:
		candidates.append(player_target)

	for node in get_tree().get_nodes_in_group(SOLDIER_GROUP):
		if node == self:
			continue
		if not node.has_method("get_faction") or not node.has_method("is_alive"):
			continue
		if not node.is_alive() or node.get_faction() == faction:
			continue
		var candidate := node as Node3D
		if candidate != null:
			candidates.append(candidate)

	var best_target: Node3D
	var best_score := 999999.0
	for candidate in candidates:
		var distance := global_position.distance_to(candidate.global_position)
		if distance > aggro_range:
			continue
		var friendly_fire_risk := _friendly_fire_risk_for_target(candidate)
		var score := distance + friendly_fire_risk * FRIENDLY_FIRE_SCORE_PENALTY
		if score < best_score:
			best_score = score
			best_target = candidate

	return best_target


func _nearest_target(current_best: Node3D, current_best_distance: float, candidate: Node3D) -> Node3D:
	var distance := global_position.distance_to(candidate.global_position)
	if distance <= current_best_distance:
		return candidate
	return current_best


func _apply_stats() -> void:
	power = clampi(power, MIN_STAT, MAX_STAT)
	speed = clampi(speed, MIN_STAT, MAX_STAT)
	dexterity = clampi(dexterity, MIN_STAT, MAX_STAT)
	move_speed = 2.7 + float(speed) * 0.14


func _attack_range() -> float:
	if weapon_type == WEAPON_BOW:
		return BOW_ATTACK_RANGE
	return SWORD_ATTACK_RANGE


func _damage_from_power(base_damage: int) -> int:
	return maxi(1, int(round(float(base_damage) * (0.65 + float(power) / 10.0))))


func _arrow_damage_from_dexterity() -> int:
	return maxi(1, int(round(float(BASE_ARROW_DAMAGE) * (1.0 + float(dexterity) / 20.0))))


func _attack_duration_seconds() -> float:
	if weapon_type == WEAPON_BOW:
		return BOW_CHARGE_SECONDS
	return ATTACK_SECONDS


func _attack_strike_time_seconds() -> float:
	if weapon_type == WEAPON_BOW:
		return BOW_CHARGE_SECONDS
	return ATTACK_STRIKE_TIME


func _attack_cooldown_seconds() -> float:
	if weapon_type == WEAPON_BOW:
		return 0.0
	return SWORD_ATTACK_COOLDOWN


func _move_while_charging_bow(delta: float, direction: Vector3, distance: float) -> void:
	if _should_hold_position():
		_move_to_order_position(delta, BOW_CHARGING_MOVE_MULTIPLIER)
		return

	if direction == Vector3.ZERO:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * delta)
		return

	var desired_distance := BOW_ATTACK_RANGE * 0.65
	var move_direction := direction
	if distance < desired_distance:
		move_direction = -direction
	var charge_speed := move_speed * BOW_CHARGING_MOVE_MULTIPLIER
	velocity.x = move_direction.x * charge_speed
	velocity.z = move_direction.z * charge_speed


func _should_hold_position() -> bool:
	return faction == FACTION_FRIENDLY and _order_mode == ORDER_HOLD and _has_order_position


func _move_to_order_position(delta: float, speed_multiplier := 1.0) -> float:
	var to_position := _order_position - global_position
	var flat_to_position := Vector3(to_position.x, 0.0, to_position.z)
	var distance := flat_to_position.length()
	if distance <= HOLD_POSITION_ARRIVAL_DISTANCE:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 3.0)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * delta * 3.0)
		return Vector3(velocity.x, 0.0, velocity.z).length()

	var direction := flat_to_position / distance
	_face_direction(direction, delta)
	var order_speed := move_speed * speed_multiplier
	velocity.x = direction.x * order_speed
	velocity.z = direction.z * order_speed
	return order_speed


func _aim_spread_radians() -> float:
	var dexterity_ratio := clampf(float(dexterity) / float(MAX_STAT), 0.0, 1.0)
	return lerpf(deg_to_rad(5.0), 0.0, dexterity_ratio)


func _fire_arrow(attack_target: Node3D) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		return

	var arrow_origin := _bow_arrow_origin()
	var aim_point := _predicted_bow_aim_point(arrow_origin, attack_target)
	var direction := (aim_point - arrow_origin).normalized()
	var spread := _aim_spread_radians()
	direction = direction.rotated(Vector3.UP, randf_range(-spread, spread))
	direction = direction.rotated(global_transform.basis.x.normalized(), randf_range(-spread * 0.55, spread * 0.55))

	var arrow := Area3D.new()
	arrow.name = "HumanArrow"
	arrow.set_script(HumanProjectile)
	parent.add_child(arrow)
	arrow.call("start", arrow_origin, direction, ARROW_SPEED, _arrow_damage_from_dexterity(), faction, self)


func _bow_arrow_origin() -> Vector3:
	return global_position + Vector3(0.0, ARROW_RELEASE_HEIGHT, 0.0) - global_transform.basis.z * ARROW_FORWARD_OFFSET


func _shot_has_friendly_fire_risk(attack_target: Node3D) -> bool:
	return _friendly_fire_risk_for_target(attack_target) > 0.0


func _friendly_fire_risk_for_target(attack_target: Node3D) -> float:
	var arrow_origin := _bow_arrow_origin()
	var aim_point := _predicted_bow_aim_point(arrow_origin, attack_target)
	var risk := 0.0

	for node in get_tree().get_nodes_in_group(SOLDIER_GROUP):
		if node == self or node == attack_target:
			continue
		if not node.has_method("get_faction") or not node.has_method("is_alive"):
			continue
		if not node.is_alive() or node.get_faction() != faction:
			continue
		var blocker := node as Node3D
		if blocker == null:
			continue
		risk += _friendly_fire_risk_for_position(arrow_origin, aim_point, blocker.global_position + Vector3(0.0, BOW_AIM_HEIGHT, 0.0))

	if faction == FACTION_FRIENDLY and player_target != null and player_target != attack_target:
		risk += _friendly_fire_risk_for_position(arrow_origin, aim_point, player_target.global_position + Vector3(0.0, BOW_AIM_HEIGHT, 0.0))

	return risk


func _friendly_fire_risk_for_position(arrow_origin: Vector3, aim_point: Vector3, blocker_position: Vector3) -> float:
	var distance := _distance_to_segment_3d(blocker_position, arrow_origin, aim_point)
	if distance > FRIENDLY_FIRE_LANE_RADIUS:
		return 0.0
	return 1.0 + (FRIENDLY_FIRE_LANE_RADIUS - distance) / FRIENDLY_FIRE_LANE_RADIUS


func _distance_to_segment_3d(point: Vector3, start: Vector3, finish: Vector3) -> float:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)


func _predicted_bow_aim_point(arrow_origin: Vector3, attack_target: Node3D) -> Vector3:
	var target_position := attack_target.global_position + Vector3(0.0, BOW_AIM_HEIGHT, 0.0)
	var target_velocity := _target_velocity(attack_target)
	var flight_time := _arrow_intercept_time(arrow_origin, target_position, target_velocity)
	return target_position + target_velocity * flight_time


func _arrow_intercept_time(origin: Vector3, target_position: Vector3, target_velocity: Vector3) -> float:
	var offset := target_position - origin
	var speed_squared := ARROW_SPEED * ARROW_SPEED
	var a := target_velocity.length_squared() - speed_squared
	var b := 2.0 * offset.dot(target_velocity)
	var c := offset.length_squared()
	var fallback_time := sqrt(c) / ARROW_SPEED
	var intercept_time := fallback_time

	if absf(a) < 0.001:
		if absf(b) > 0.001:
			intercept_time = -c / b
	else:
		var discriminant := b * b - 4.0 * a * c
		if discriminant >= 0.0:
			var root := sqrt(discriminant)
			var time_a := (-b - root) / (2.0 * a)
			var time_b := (-b + root) / (2.0 * a)
			intercept_time = _smallest_positive_time(time_a, time_b, fallback_time)

	return clampf(intercept_time, 0.0, MAX_ARROW_LEAD_SECONDS)


func _smallest_positive_time(time_a: float, time_b: float, fallback_time: float) -> float:
	var best_time := fallback_time
	if time_a > 0.0:
		best_time = time_a
	if time_b > 0.0 and (best_time <= 0.0 or time_b < best_time):
		best_time = time_b
	return best_time


func _target_velocity(attack_target: Node3D) -> Vector3:
	var character := attack_target as CharacterBody3D
	if character != null:
		return character.velocity

	var rigid_body := attack_target as RigidBody3D
	if rigid_body != null:
		return rigid_body.linear_velocity

	return Vector3.ZERO


func _face_direction(direction: Vector3, delta: float) -> void:
	if direction == Vector3.ZERO:
		return

	var desired_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, desired_yaw, minf(delta * 8.0, 1.0))


func _is_headshot(hit_position: Vector3) -> bool:
	var local_hit := to_local(hit_position)
	var normalized_offset := Vector3(
		(local_hit.x - HEAD_CENTER.x) / HEAD_RADIUS.x,
		(local_hit.y - HEAD_CENTER.y) / HEAD_RADIUS.y,
		(local_hit.z - HEAD_CENTER.z) / HEAD_RADIUS.z
	)
	if normalized_offset.length() <= 1.0:
		return true

	var flat_offset := Vector2(local_hit.x - HEAD_CENTER.x, local_hit.z - HEAD_CENTER.z)
	return local_hit.y >= HEADSHOT_MIN_Y and flat_offset.length() <= HEADSHOT_FLAT_RADIUS


func _build_body() -> void:
	var body_shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.22
	body_shape.shape = capsule
	body_shape.position.y = 0.7
	add_child(body_shape)

	var head_shape := CollisionShape3D.new()
	head_shape.name = "HeadHitShape"
	var head_sphere := SphereShape3D.new()
	head_sphere.radius = 0.38
	head_shape.shape = head_sphere
	head_shape.position = HEAD_CENTER
	add_child(head_shape)

	_body_mesh = _add_capsule("Body", Vector3(0.0, 0.86, 0.0), 0.29, 1.05, _cloth_material)
	_head_mesh = _add_sphere("Head", HEAD_CENTER, Vector3(0.4, 0.37, 0.4), _base_material)
	_add_capsule("Helmet", Vector3(0.0, 1.75, 0.0), 0.42, 0.24, _metal_material, true)
	_add_box("NoseGuard", Vector3(0.0, 1.6, -0.36), Vector3(0.045, 0.25, 0.035), _metal_material, true)
	_add_box("Belt", Vector3(0.0, 0.86, -0.01), Vector3(0.39, 0.08, 0.33), _leather_material, true)

	_left_arm_mesh = _add_limb("LeftArm", Vector3(-0.35, 1.04, -0.03), -8.0)
	_right_arm_mesh = _add_limb("RightArm", Vector3(0.35, 1.04, -0.03), 8.0)
	_left_leg_mesh = _add_limb("LeftLeg", Vector3(-0.16, 0.28, 0.0), 4.0, 1.12)
	_right_leg_mesh = _add_limb("RightLeg", Vector3(0.16, 0.28, 0.0), -4.0, 1.12)


func _build_equipment() -> void:
	if weapon_type == WEAPON_SWORD:
		_build_sword()
	elif weapon_type == WEAPON_BOW:
		_build_bow()
	else:
		_build_sword()

	if has_shield:
		_build_round_shield()


func _build_sword() -> void:
	_sword_blade_mesh = _add_box("SwordBlade", Vector3(0.46, 1.05, -0.58), Vector3(0.055, 0.035, 0.58), _metal_material, true)
	_sword_handle_mesh = _add_capsule("SwordGrip", Vector3(0.46, 1.0, -0.2), 0.035, 0.22, _leather_material, true)
	_sword_handle_mesh.rotation_degrees.x = 90.0
	_sword_guard_mesh = _add_box("SwordGuard", Vector3(0.46, 1.01, -0.31), Vector3(0.24, 0.045, 0.045), _metal_material, true)
	_remember_animation_node(_sword_blade_mesh)
	_remember_animation_node(_sword_handle_mesh)
	_remember_animation_node(_sword_guard_mesh)


func _build_round_shield() -> void:
	var shield := _add_capsule("RoundShield", Vector3(-0.5, 1.0, -0.2), 0.34, 0.08, _leather_material, true)
	shield.rotation_degrees.x = 90.0


func _build_bow() -> void:
	_bow_mesh = _add_capsule("Bow", Vector3(0.47, 1.05, -0.24), 0.025, 1.05, _leather_material, true)
	_bow_mesh.rotation_degrees = Vector3(0.0, 0.0, 16.0)
	_bow_string_mesh = _add_box("BowString", Vector3(0.47, 1.05, -0.33), Vector3(0.012, 1.0, 0.012), _make_material(Color("#d8c58d"), 0.95), true)
	_loaded_arrow_mesh = _add_box("LoadedArrow", Vector3(0.47, 1.04, -0.56), Vector3(0.025, 0.025, 0.68), _make_material(Color("#6b4328"), 0.88), true)
	_remember_animation_node(_bow_mesh)
	_remember_animation_node(_bow_string_mesh)
	_remember_animation_node(_loaded_arrow_mesh)


func _add_health_label() -> void:
	_label = Label3D.new()
	_label.name = "HealthLabel"
	_label.position = Vector3(0.0, 2.3, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 42
	_label.outline_size = 8
	_label.outline_modulate = Color("#1e1510")
	_label.modulate = _label_color()
	add_child(_label)


func _update_health_label() -> void:
	if _label == null:
		return

	var role := "Archer" if weapon_type == WEAPON_BOW else "Swordsman"
	var name_text := "Enemy %s" % role
	if faction == FACTION_FRIENDLY:
		name_text = "Ally %s" % role
	_label.text = "%s\n%d/%d" % [name_text, health, max_health]


func _cloth_color() -> Color:
	if faction == FACTION_FRIENDLY:
		return Color("#3f7450")
	return Color("#744434")


func _label_color() -> Color:
	if faction == FACTION_FRIENDLY:
		return Color("#6dff8d")
	return Color("#ff6c4f")


func _add_limb(node_name: String, position: Vector3, z_rotation: float, height_scale := 1.0) -> MeshInstance3D:
	var limb := _add_capsule(node_name, position, 0.085, 0.72, _base_material, false, false)
	limb.rotation_degrees.z = z_rotation
	limb.scale.y = height_scale
	_remember_animation_node(limb)
	return limb


func _add_capsule(node_name: String, position: Vector3, radius: float, height: float, material: Material, is_detail := false, remember := true) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = material
	if is_detail:
		mesh_instance.add_to_group(DETAIL_MESH_GROUP)
	add_child(mesh_instance)
	if not is_detail and remember:
		_remember_animation_node(mesh_instance)
	return mesh_instance


func _add_sphere(node_name: String, position: Vector3, node_scale: Vector3, material: Material, is_detail := false) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.scale = node_scale
	mesh_instance.material_override = material
	if is_detail:
		mesh_instance.add_to_group(DETAIL_MESH_GROUP)
	add_child(mesh_instance)
	if not is_detail:
		_remember_animation_node(mesh_instance)
	return mesh_instance


func _add_box(node_name: String, position: Vector3, size: Vector3, material: Material, is_detail := false) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = material
	if is_detail:
		mesh_instance.add_to_group(DETAIL_MESH_GROUP)
	add_child(mesh_instance)
	return mesh_instance


func _remember_animation_node(mesh: MeshInstance3D) -> void:
	_animated_meshes.append(mesh)
	_base_positions.append(mesh.position)
	_base_rotations.append(mesh.rotation_degrees)
	_base_scales.append(mesh.scale)


func _animate_soldier(delta: float, flat_speed: float) -> void:
	_animation_time += delta
	_restore_animation_pose()

	if _attack_time > 0.0:
		if weapon_type == WEAPON_BOW:
			_animate_bow_attack()
		else:
			_animate_sword_attack()
	elif flat_speed > 0.05:
		_animate_walk(flat_speed)
	else:
		_animate_idle()


func _restore_animation_pose() -> void:
	for index in range(_animated_meshes.size()):
		var mesh := _animated_meshes[index]
		if mesh == null:
			continue
		mesh.position = _base_positions[index]
		mesh.rotation_degrees = _base_rotations[index]
		mesh.scale = _base_scales[index]


func _animate_walk(flat_speed: float) -> void:
	var weight := clampf(flat_speed / move_speed, 0.0, 1.0)
	var phase := _animation_time * 8.0
	var bob := absf(sin(phase)) * 0.045 * weight
	_body_mesh.position.y += bob
	_head_mesh.position.y += bob * 0.6
	_left_arm_mesh.rotation_degrees.x += sin(phase) * 20.0 * weight
	_right_arm_mesh.rotation_degrees.x += sin(phase + PI) * 12.0 * weight
	_left_leg_mesh.rotation_degrees.x += sin(phase + PI) * 22.0 * weight
	_right_leg_mesh.rotation_degrees.x += sin(phase) * 22.0 * weight


func _animate_sword_attack() -> void:
	var elapsed := ATTACK_SECONDS - _attack_time
	var swing := smoothstep(0.0, 1.0, clampf(elapsed / ATTACK_SECONDS, 0.0, 1.0))
	var slash := sin(swing * PI)
	_right_arm_mesh.rotation_degrees.x -= 48.0 * slash
	_right_arm_mesh.rotation_degrees.y -= 20.0 * swing
	_sword_blade_mesh.rotation_degrees.x -= 72.0 * slash
	_sword_blade_mesh.rotation_degrees.y -= 24.0 * swing
	_sword_handle_mesh.rotation_degrees.x -= 72.0 * slash
	_sword_guard_mesh.rotation_degrees.x -= 72.0 * slash


func _animate_bow_attack() -> void:
	var elapsed := _attack_duration_seconds() - _attack_time
	var draw := smoothstep(0.0, 1.0, clampf(elapsed / _attack_duration_seconds(), 0.0, 1.0))
	_right_arm_mesh.rotation_degrees.x -= 32.0 * draw
	_left_arm_mesh.rotation_degrees.x -= 16.0 * draw
	_bow_string_mesh.position.z -= 0.16 * draw
	_loaded_arrow_mesh.position.z -= 0.18 * draw


func _animate_idle() -> void:
	var breath := sin(_animation_time * 1.8) * 0.018
	_body_mesh.scale.y += breath
	_head_mesh.position.y += breath * 0.35


func _update_hit_flash() -> void:
	for child in get_children():
		var mesh := child as MeshInstance3D
		if mesh != null and not child.is_in_group(DETAIL_MESH_GROUP):
			mesh.material_override = _material_for_body_mesh(mesh)


func _material_for_body_mesh(mesh: MeshInstance3D) -> Material:
	if _flash_time > 0.0:
		return _hit_material
	if mesh == _body_mesh:
		return _cloth_material
	return _base_material


func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
