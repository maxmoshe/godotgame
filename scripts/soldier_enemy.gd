extends CharacterBody3D

signal died(faction: String)
signal left_battlefield(faction: String)

const HumanProjectile := preload("res://scripts/human_projectile.gd")
const ImpactSparks := preload("res://scripts/impact_sparks.gd")
const DamageNumber := preload("res://scripts/damage_number.gd")
const QuaterniusSoldierVisualScene := preload("res://scenes/actors/quaternius_soldier_visual.tscn")

const WEAPON_SWORD := "sword"
const WEAPON_SPEAR := "spear"
const WEAPON_BOW := "bow"
const WEAPON_SLING := "sling"
const FACTION_ENEMY := "enemy"
const FACTION_FRIENDLY := "friendly"
const ORDER_CHARGE := "charge"
const ORDER_HOLD := "hold"
const SOLDIER_GROUP := "combat_soldiers"
const WORLD_COLLISION_MASK := 1
const SOLDIER_COLLISION_LAYER := 2

const GRAVITY := 22.0
const GROUND_STICK_VELOCITY := -0.25
const MAX_STAT := 50
const MIN_STAT := 1
const BASE_MELEE_DAMAGE := 8
const BASE_ARROW_DAMAGE := 12
const ARROW_SPEED := 45.0
const ARROW_RELEASE_HEIGHT := 1.05
const ARROW_FORWARD_OFFSET := 0.55
const BOW_AIM_HEIGHT := 0.86
const MAX_ARROW_LEAD_SECONDS := 1.2
const SWORD_ATTACK_RANGE := 1.85
const BOW_ATTACK_RANGE := 40.0
const SWORD_ATTACK_COOLDOWN := 0.95
const BOW_CHARGE_SECONDS := 2.1
const BOW_CHARGING_MOVE_MULTIPLIER := 0.35
const FRIENDLY_FIRE_LANE_RADIUS := 0.82
const FRIENDLY_FIRE_SCORE_PENALTY := 1000.0
const MAX_BOW_TARGET_CANDIDATES := 6
const TARGET_LEASH_EXTRA := 6.0
const MELEE_TARGET_REFRESH_MIN_SECONDS := 0.14
const MELEE_TARGET_REFRESH_MAX_SECONDS := 0.28
const BOW_TARGET_REFRESH_MIN_SECONDS := 0.30
const BOW_TARGET_REFRESH_MAX_SECONDS := 0.48
const HOLD_POSITION_ARRIVAL_DISTANCE := 0.55
const HOLD_DEFEND_RADIUS := 8.0
const BATTLE_SLOT_ARRIVAL_DISTANCE := 0.85
const BATTLE_SLOT_RELEASE_DISTANCE := 10.5
const BATTLE_SLOT_ARCHER_RELEASE_DISTANCE := 28.0
const ALLY_SEPARATION_RADIUS := 0.92
const ALLY_SEPARATION_STRENGTH := 0.55
const ALLY_SEPARATION_IDLE_MOVE_MULTIPLIER := 0.18
const ALLY_SEPARATION_MAX_NEIGHBORS := 8
const BOW_LANE_STEP_DISTANCE := 2.2
const BOW_LANE_MOVE_MULTIPLIER := 0.72
const BOW_LANE_MIN_RISK_IMPROVEMENT := 0.10
const BOW_LANE_COMMIT_SECONDS := 0.55
const BOW_RISK_REFRESH_SECONDS := 0.18
const LARGE_BATTLE_BOW_RISK_REFRESH_SECONDS := 0.34
const BOW_PANIC_DISTANCE := 3.2
const BOW_KITE_DISTANCE := 8.0
const BOW_REGROUP_DISTANCE := 7.0
const BOW_TERRAIN_SCORE_MAX_SOLDIERS := 96
const BOW_POSITION_RISK_PENALTY := 1200.0
const BOW_POSITION_RANGE_WEIGHT := 2.4
const BOW_POSITION_SLOT_WEIGHT := 0.35
const BOW_POSITION_HEIGHT_WEIGHT := 4.5
const BOW_POSITION_SLOPE_PENALTY := 14.0
const FLAT_ACCELERATION_MULTIPLIER := 10.0
const FLAT_BRAKE_MULTIPLIER := 8.0
const BACKPEDAL_SPEED_DIVISOR := 2.0
const STRAFE_SPEED_DIVISOR := 1.3
const MELEE_BACK_UP_DISTANCE := 1.05
const MELEE_ADVANCE_DISTANCE := 1.65
const BOW_BACK_UP_DISTANCE := 17.0
const BOW_ADVANCE_DISTANCE := 28.0
const BATTLE_SLOT_SOFT_RELEASE_DISTANCE := 2.2
const BATTLE_SLOT_MAX_STAGING_SECONDS := 2.8
const FATIGUE_MAX := 100.0
const FATIGUE_MOVE_GAIN_PER_SECOND := 1.35
const FATIGUE_ATTACK_GAIN_PER_SECOND := 5.2
const FATIGUE_BOW_DRAW_GAIN_PER_SECOND := 3.1
const FATIGUE_ROUT_GAIN_PER_SECOND := 3.0
const FATIGUE_RECOVERY_PER_SECOND := 4.4
const FATIGUE_SPEED_PENALTY := 0.24
const FATIGUE_ATTACK_COOLDOWN_PENALTY := 0.35
const FATIGUE_AIM_SPREAD_DEGREES := 2.6
const MORALE_MAX := 100.0
const BASE_MORALE := 70.0
const MORALE_POWER_BONUS := 0.42
const MORALE_CHECK_INTERVAL := 0.35
const MORALE_RECOVERY_PER_SECOND := 2.7
const MORALE_PRESSURE_LOSS_PER_SECOND := 4.6
const MORALE_WOUND_LOSS := 34.0
const MORALE_FATIGUE_LOSS := 14.0
const MORALE_NEARBY_RADIUS := 8.0
const MORALE_ALLY_SUPPORT := 2.4
const MORALE_ENEMY_PRESSURE := 2.8
const MORALE_OUTNUMBERED_LOSS := 4.5
const MORALE_DAMAGE_LOSS_PER_DAMAGE := 0.38
const MORALE_DEATH_EVENT_RADIUS := 11.0
const ALLY_DEATH_MORALE_LOSS := 11.0
const ENEMY_DEATH_MORALE_GAIN := 5.0
const MORALE_SHAKEN_THRESHOLD := 45.0
const MORALE_WAVERING_THRESHOLD := 30.0
const MORALE_ROUT_THRESHOLD := 16.0
const MORALE_RALLY_THRESHOLD := 40.0
const MORALE_ROUT_MIN_SECONDS := 4.2
const MORALE_ROUT_SPEED_MULTIPLIER := 1.18
const MORALE_ROUT_SEARCH_RADIUS := 16.0
const ATTACK_SECONDS := 0.56
const ATTACK_STRIKE_TIME := 0.24
const MELEE_KNOCKBACK := 2.7
const MELEE_HIT_HEIGHT := 1.05
const MELEE_DAMAGE_FULL_RED := 18.0
const MELEE_SPARK_CHANCE := 0.35
const MELEE_DAMAGE_NUMBER_CHANCE := 0.55
const LARGE_BATTLE_MELEE_FEEDBACK_MULTIPLIER := 0.25
const HEADSHOT_MULTIPLIER := 3
const HEAD_CENTER := Vector3(0.0, 1.62, 0.0)
const HEAD_RADIUS := Vector3(0.42, 0.38, 0.42)
const HEADSHOT_MIN_Y := 1.30
const HEADSHOT_FLAT_RADIUS := 0.54
const BODY_HIT_STAGGER_SECONDS := 0.50
const HEADSHOT_STAGGER_SECONDS := 0.90
const BODY_HIT_FLASH_SECONDS := 0.22
const HEADSHOT_HIT_FLASH_SECONDS := 0.38
const DETAIL_MESH_GROUP := "soldier_detail_mesh"
const AI_ACTION_IDLE := "Idle"
const AI_ACTION_ADVANCE := "Advance"
const AI_ACTION_ENGAGE := "Engage"
const AI_ACTION_HOLD := "Hold"
const AI_ACTION_DRAW := "Draw"
const AI_ACTION_STRIKE := "Strike"
const AI_ACTION_FIRE := "Fire"
const AI_ACTION_LANE := "Find lane"
const AI_ACTION_KITE := "Kite"
const AI_ACTION_REGROUP := "Regroup"
const AI_ACTION_PANIC := "Panic"
const AI_ACTION_ROUT := "Rout"
const MORALE_STEADY := "Steady"
const MORALE_SHAKEN := "Shaken"
const MORALE_WAVERING := "Wavering"
const MORALE_ROUTING := "Routing"
const LARGE_BATTLE_SOLDIER_COUNT := 96
const LARGE_BATTLE_TARGET_REFRESH_MULTIPLIER := 1.65
const LARGE_BATTLE_MORALE_CHECK_MULTIPLIER := 1.5
const LABEL_VISIBLE_MAX_SOLDIERS := 72
const LABEL_UPDATE_SECONDS := 0.22
const LARGE_BATTLE_VISUAL_UPDATE_SECONDS := 0.066
const SMALL_BATTLE_SEPARATION_REFRESH_SECONDS := 0.06
const LARGE_BATTLE_SEPARATION_REFRESH_SECONDS := 0.16
const AIM_CONFIDENCE_REQUIRED := 0.72
const AIM_CONFIDENCE_GAIN_PER_SECOND := 0.72
const AIM_CONFIDENCE_MOVE_LOSS_PER_SECOND := 0.55
const AIM_CONFIDENCE_UNSAFE_LOSS_PER_SECOND := 0.95
const AIM_CONFIDENCE_THREAT_LOSS_PER_SECOND := 1.15
const AIM_CONFIDENCE_DAMAGE_LOSS := 0.35
const AIM_CONFIDENCE_SHOT_COST := 0.55

@export var move_speed := 3.4
@export var aggro_range := 34.0
@export var max_health := 58
@export var weapon_type := WEAPON_SWORD
@export var has_shield := false
@export var faction := FACTION_ENEMY
@export var power := 5
@export var speed := 5
@export var dexterity := 3
@export var use_imported_visuals := true

var player_target: Node3D
var terrain_owner: Node
var health := max_health

var _active_target: Node3D
var _target_refresh_time := 0.0
var _attack_cooldown := 0.75
var _attack_time := 0.0
var _has_struck := false
var _order_mode := ORDER_CHARGE
var _order_position := Vector3.ZERO
var _formation_index := 0
var _has_order_position := false
var _battle_slot_position := Vector3.ZERO
var _battle_slot_index := 0
var _has_battle_slot := false
var _battle_slot_released := false
var _battle_slot_stage_time := 0.0
var _ai_action := AI_ACTION_IDLE
var _fatigue := 0.0
var _morale := BASE_MORALE
var _morale_state := MORALE_STEADY
var _morale_check_time := 0.0
var _rout_time := 0.0
var _rout_direction := Vector3.ZERO
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
var _sword_pivot: Node3D
var _bow_pivot: Node3D
var _bow_string_top: MeshInstance3D
var _bow_string_bottom: MeshInstance3D
var _loaded_arrow_mesh: MeshInstance3D
var _imported_visual: Node3D
var _animated_meshes: Array[Node3D] = []
var _base_positions: Array[Vector3] = []
var _base_rotations: Array[Vector3] = []
var _base_scales: Array[Vector3] = []
var _registered_with_combat := false
var _flash_visible := false
var _label_update_time := 0.0
var _last_label_text := ""
var _visual_update_time := 0.0
var _cached_separation_direction := Vector3.ZERO
var _separation_refresh_time := 0.0
var _aim_confidence := 0.0
var _bow_lane_direction := Vector3.ZERO
var _bow_lane_commit_time := 0.0
var _bow_risk_refresh_time := 0.0
var _cached_bow_risk := 0.0
var _cached_bow_risk_target: Node3D
var _left_battlefield := false
var _uses_imported_visuals := false

static var _capsule_mesh_cache := {}
static var _sphere_mesh: SphereMesh
static var _box_mesh_cache := {}
static var _material_cache := {}


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
	collision_layer = SOLDIER_COLLISION_LAYER
	collision_mask = WORLD_COLLISION_MASK
	max_slides = 2
	safe_margin = 0.035
	add_to_group(SOLDIER_GROUP)
	add_to_group(_faction_group(faction))
	_register_with_combat()
	_target_refresh_time = randf_range(0.0, _target_refresh_interval())
	_apply_stats()
	_morale = _base_morale()
	_morale_check_time = randf_range(0.0, _morale_check_interval())
	_label_update_time = randf_range(0.0, LABEL_UPDATE_SECONDS)
	_visual_update_time = randf_range(0.0, LARGE_BATTLE_VISUAL_UPDATE_SECONDS)
	_separation_refresh_time = randf_range(0.0, _separation_refresh_seconds())
	_base_material = _make_material(Color("#9b6b45"), 0.88)
	_hit_material = _make_material(Color("#8d251f"), 0.72)
	_metal_material = _make_material(Color("#aeb7b5"), 0.35)
	_leather_material = _make_material(Color("#4e2e1d"), 0.92)
	_cloth_material = _make_material(_cloth_color(), 0.94)
	_build_body()
	_build_equipment()
	_add_health_label()
	_update_health_label(0.0, true)


func _exit_tree() -> void:
	_unregister_from_combat()


func _physics_process(delta: float) -> void:
	if health <= 0 or _left_battlefield:
		return

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_flash_time = maxf(0.0, _flash_time - delta)
	_bow_lane_commit_time = maxf(0.0, _bow_lane_commit_time - delta)
	_bow_risk_refresh_time = maxf(0.0, _bow_risk_refresh_time - delta)
	_update_hit_flash()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = GROUND_STICK_VELOCITY

	var flat_speed := 0.0
	_ai_action = AI_ACTION_IDLE
	_update_morale(delta)
	if _is_routing():
		flat_speed = _move_routing(delta)
	else:
		_update_active_target(delta)
		if _active_target != null:
			flat_speed = _think_and_move(delta, _active_target)
		elif _should_hold_position():
			flat_speed = _move_to_order_position(delta)
		elif _has_battle_slot and not _battle_slot_released:
			flat_speed = _move_to_battle_slot(delta)
		else:
			flat_speed = _settle_or_separate(delta)

	move_and_slide()
	_update_fatigue(delta, flat_speed)
	_update_soldier_visuals(delta, flat_speed)
	_update_health_label(delta)


func take_hit(damage: int) -> void:
	_apply_damage(damage, false)


func take_damage(damage: int, source_position := Vector3.ZERO) -> void:
	_apply_damage(damage, false)
	_apply_melee_knockback(source_position)


func take_projectile_hit(damage: int, hit_position: Vector3) -> int:
	var final_damage := damage
	var was_headshot := is_projectile_headshot(hit_position)
	if was_headshot:
		final_damage *= HEADSHOT_MULTIPLIER
	_apply_damage(final_damage, was_headshot)
	return final_damage


func take_projectile_hit_shape(damage: int, hit_position: Vector3, hit_shape_name: String) -> int:
	var final_damage := damage
	var was_headshot := is_projectile_headshot(hit_position, hit_shape_name)
	if was_headshot:
		final_damage *= HEADSHOT_MULTIPLIER
	_apply_damage(final_damage, was_headshot)
	return final_damage


func is_projectile_headshot(hit_position: Vector3, hit_shape_name := "") -> bool:
	return hit_shape_name == "HeadHitShape" or _is_headshot(hit_position)


func get_faction() -> String:
	return faction


func get_weapon_type() -> String:
	return weapon_type


func is_alive() -> bool:
	return health > 0


func is_fleeing() -> bool:
	return _is_routing()


func leave_battlefield() -> void:
	if _left_battlefield or health <= 0:
		return

	_left_battlefield = true
	_unregister_from_combat()
	_active_target = null
	left_battlefield.emit(faction)
	remove_from_group(SOLDIER_GROUP)
	remove_from_group(_faction_group(faction))
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	if _label != null:
		_label.visible = false
	queue_free()


func receive_morale_event(dead_faction: String, death_position: Vector3) -> void:
	if health <= 0:
		return

	var distance := global_position.distance_to(death_position)
	if distance > MORALE_DEATH_EVENT_RADIUS:
		return

	var weight := 1.0 - distance / MORALE_DEATH_EVENT_RADIUS
	if dead_faction == faction:
		_change_morale(-ALLY_DEATH_MORALE_LOSS * weight)
	else:
		_change_morale(ENEMY_DEATH_MORALE_GAIN * weight)


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
		_has_battle_slot = false
		_battle_slot_released = true
	_active_target = null
	_target_refresh_time = 0.0
	_attack_time = 0.0
	_has_struck = false
	_aim_confidence = 0.0
	_bow_lane_commit_time = 0.0
	_bow_risk_refresh_time = 0.0


func assign_battle_slot(slot_position: Vector3, formation_index: int) -> void:
	_battle_slot_position = slot_position
	_battle_slot_index = formation_index
	_has_battle_slot = true
	_battle_slot_released = false
	_battle_slot_stage_time = BATTLE_SLOT_MAX_STAGING_SECONDS + randf_range(0.0, 0.55)
	_bow_lane_commit_time = 0.0


func _register_with_combat() -> void:
	if _registered_with_combat:
		return
	if terrain_owner != null and is_instance_valid(terrain_owner) and terrain_owner.has_method("register_combat_soldier"):
		terrain_owner.call("register_combat_soldier", self, faction)
		_registered_with_combat = true


func _unregister_from_combat() -> void:
	if not _registered_with_combat:
		return
	if terrain_owner != null and is_instance_valid(terrain_owner) and terrain_owner.has_method("unregister_combat_soldier"):
		terrain_owner.call("unregister_combat_soldier", self, faction)
	_registered_with_combat = false


func _think_and_move(delta: float, attack_target) -> float:
	if not _is_attack_target_valid(attack_target):
		_active_target = null
		return _brake_and_report(delta)

	var target := _valid_node3d(attack_target)
	if target == null:
		_active_target = null
		return _brake_and_report(delta)

	_ai_action = AI_ACTION_ENGAGE
	var to_target := target.global_position - global_position
	var flat_to_target := Vector3(to_target.x, 0.0, to_target.z)
	var distance := flat_to_target.length()
	var direction := Vector3.ZERO
	if distance > 0.05:
		direction = flat_to_target / distance
		_face_direction(direction, delta)

	if weapon_type == WEAPON_BOW:
		return _think_and_move_bow(delta, target, direction, distance)

	if _attack_time > 0.0:
		_attack_time = maxf(0.0, _attack_time - delta)
		_ai_action = AI_ACTION_STRIKE
		_brake_flat_velocity(delta)
		_check_attack_strike(distance)
		return Vector3(velocity.x, 0.0, velocity.z).length()

	if distance <= _attack_range():
		if _attack_cooldown <= 0.0:
			_start_attack()
		else:
			return _move_for_combat_range(delta, direction, distance)
	elif _should_hold_position():
		return _move_to_order_position(delta)
	elif _should_use_battle_slot(delta, distance):
		return _move_to_battle_slot(delta)
	elif distance <= aggro_range and direction != Vector3.ZERO:
		return _move_for_combat_range(delta, direction, distance)
	else:
		_settle_or_separate(delta)

	return Vector3(velocity.x, 0.0, velocity.z).length()


func _think_and_move_bow(delta: float, attack_target: Node3D, direction: Vector3, distance: float) -> float:
	var friendly_fire_risk := 0.0
	if distance <= BOW_ATTACK_RANGE + TARGET_LEASH_EXTRA:
		friendly_fire_risk = _cached_bow_friendly_fire_risk(attack_target)
	_update_bow_aim_confidence(delta, attack_target, distance, friendly_fire_risk)

	if distance <= BOW_PANIC_DISTANCE:
		return _move_bow_panic(delta, direction)
	if distance <= BOW_KITE_DISTANCE:
		return _move_bow_kite(delta, direction)

	if _attack_time > 0.0:
		_attack_time = maxf(0.0, _attack_time - delta)
		_ai_action = AI_ACTION_DRAW
		_move_while_charging_bow(delta, direction, distance)
		_check_attack_strike(distance)
		return Vector3(velocity.x, 0.0, velocity.z).length()

	if _should_move_to_order_position():
		return _move_to_order_position(delta)

	if _should_bow_regroup(distance, friendly_fire_risk):
		return _move_bow_regroup(delta, attack_target)

	if distance <= _attack_range():
		if friendly_fire_risk > 0.0:
			return _move_to_bow_lane(delta, attack_target, direction)
		if _attack_cooldown <= 0.0 and _bow_has_firing_confidence():
			_ai_action = AI_ACTION_FIRE
			_start_attack()
		else:
			return _hold_bow_aim(delta, direction, distance)
	elif _should_hold_position():
		return _move_to_order_position(delta)
	elif _should_use_battle_slot(delta, distance):
		return _move_to_battle_slot(delta)
	elif distance <= aggro_range and direction != Vector3.ZERO:
		return _move_for_combat_range(delta, direction, distance)
	else:
		return _settle_or_separate(delta)

	return Vector3(velocity.x, 0.0, velocity.z).length()


func _hold_bow_aim(delta: float, direction: Vector3, distance: float) -> float:
	_ai_action = AI_ACTION_FIRE
	if distance < BOW_BACK_UP_DISTANCE or distance > BOW_ADVANCE_DISTANCE:
		return _move_for_combat_range(delta, direction, distance)
	_face_direction(direction, delta)
	return _brake_and_report(delta)


func _move_bow_panic(delta: float, direction: Vector3) -> float:
	_ai_action = AI_ACTION_PANIC
	_cancel_bow_draw(AIM_CONFIDENCE_THREAT_LOSS_PER_SECOND * delta)
	if direction == Vector3.ZERO:
		return _brake_and_report(delta)

	_face_direction(direction, delta)
	var escape_direction := -direction
	if _has_battle_slot:
		var slot_direction := _flat_direction_to(_battle_slot_position)
		if slot_direction != Vector3.ZERO:
			escape_direction = (escape_direction + slot_direction * 0.45).normalized()
	_set_flat_velocity(escape_direction, move_speed * 1.08, delta, 1.0, direction)
	return Vector3(velocity.x, 0.0, velocity.z).length()


func _move_bow_kite(delta: float, direction: Vector3) -> float:
	_ai_action = AI_ACTION_KITE
	_cancel_bow_draw(AIM_CONFIDENCE_THREAT_LOSS_PER_SECOND * delta)
	if direction == Vector3.ZERO:
		return _brake_and_report(delta)

	_face_direction(direction, delta)
	var side := Vector3(-direction.z, 0.0, direction.x)
	if (_formation_index + _battle_slot_index) % 2 != 0:
		side = -side
	var kite_direction := (-direction + side.normalized() * 0.28).normalized()
	_set_flat_velocity(kite_direction, move_speed * 0.9, delta, 1.0, direction)
	return Vector3(velocity.x, 0.0, velocity.z).length()


func _should_bow_regroup(distance: float, friendly_fire_risk: float) -> bool:
	if not _has_battle_slot or not _battle_slot_released or _should_hold_position():
		return false
	if distance <= BOW_KITE_DISTANCE:
		return false
	if _flat_distance_to(_battle_slot_position) < BOW_REGROUP_DISTANCE:
		return false
	return distance > BOW_ADVANCE_DISTANCE or friendly_fire_risk > 0.0 or _aim_confidence < 0.25


func _move_bow_regroup(delta: float, attack_target: Node3D) -> float:
	_ai_action = AI_ACTION_REGROUP
	var direction_to_slot := _flat_direction_to(_battle_slot_position)
	if direction_to_slot == Vector3.ZERO:
		return _brake_and_report(delta)

	var facing_direction := direction_to_slot
	var target_direction := attack_target.global_position - global_position
	target_direction.y = 0.0
	if target_direction.length() > 0.05:
		facing_direction = target_direction.normalized()
		_face_direction(facing_direction, delta)
	else:
		_face_direction(direction_to_slot, delta)
	_set_flat_velocity(direction_to_slot, move_speed * 0.72, delta, 1.0, facing_direction)
	return Vector3(velocity.x, 0.0, velocity.z).length()


func _cancel_bow_draw(confidence_loss := 0.0) -> void:
	if weapon_type != WEAPON_BOW:
		return
	if _attack_time > 0.0:
		_attack_time = 0.0
		_has_struck = false
	if confidence_loss > 0.0:
		_aim_confidence = maxf(0.0, _aim_confidence - confidence_loss)


func _update_bow_aim_confidence(delta: float, attack_target: Node3D, distance: float, friendly_fire_risk: float) -> void:
	if weapon_type != WEAPON_BOW:
		return
	if attack_target == null or distance > BOW_ATTACK_RANGE or distance <= BOW_KITE_DISTANCE:
		_aim_confidence = maxf(0.0, _aim_confidence - AIM_CONFIDENCE_THREAT_LOSS_PER_SECOND * delta)
		return
	if friendly_fire_risk > 0.0:
		_aim_confidence = maxf(0.0, _aim_confidence - AIM_CONFIDENCE_UNSAFE_LOSS_PER_SECOND * delta)
		return

	var flat_speed := Vector3(velocity.x, 0.0, velocity.z).length()
	if flat_speed > 0.25:
		var move_loss := AIM_CONFIDENCE_MOVE_LOSS_PER_SECOND * clampf(flat_speed / maxf(move_speed, 0.01), 0.0, 1.5)
		_aim_confidence = maxf(0.0, _aim_confidence - move_loss * delta)
		return

	var dexterity_ratio := clampf(float(dexterity) / float(MAX_STAT), 0.0, 1.0)
	var gain := AIM_CONFIDENCE_GAIN_PER_SECOND * lerpf(0.8, 1.25, dexterity_ratio)
	if _morale_state == MORALE_SHAKEN:
		gain *= 0.72
	elif _morale_state == MORALE_WAVERING:
		gain *= 0.48
	_aim_confidence = clampf(_aim_confidence + gain * delta, 0.0, 1.0)


func _bow_has_firing_confidence() -> bool:
	return _aim_confidence >= AIM_CONFIDENCE_REQUIRED


func _cached_bow_friendly_fire_risk(attack_target: Node3D) -> float:
	if attack_target == null:
		_cached_bow_risk = 0.0
		_cached_bow_risk_target = null
		return 0.0
	if _cached_bow_risk_target != attack_target:
		_bow_risk_refresh_time = 0.0
	if _bow_risk_refresh_time <= 0.0:
		_cached_bow_risk_target = attack_target
		_cached_bow_risk = _friendly_fire_risk_for_target(attack_target)
		_bow_risk_refresh_time = _bow_risk_refresh_interval() + randf_range(0.0, 0.05)
	return _cached_bow_risk


func _bow_risk_refresh_interval() -> float:
	if _is_large_battle():
		return LARGE_BATTLE_BOW_RISK_REFRESH_SECONDS
	return BOW_RISK_REFRESH_SECONDS


func _start_attack() -> void:
	_attack_time = _attack_duration_seconds()
	_attack_cooldown = _attack_cooldown_seconds()
	_has_struck = false
	if _uses_imported_visuals and _imported_visual != null and _imported_visual.has_method("play_attack"):
		_imported_visual.call("play_attack", weapon_type)


func _check_attack_strike(distance: float) -> void:
	if _has_struck:
		return

	var elapsed := _attack_duration_seconds() - _attack_time
	if elapsed < _attack_strike_time_seconds():
		return

	_has_struck = true
	if not _is_attack_target_valid(_active_target) or distance > _attack_range() + 0.35:
		return
	var target := _valid_node3d(_active_target)
	if target == null:
		_active_target = null
		return

	if weapon_type == WEAPON_BOW:
		if _shot_has_friendly_fire_risk(target):
			_ai_action = AI_ACTION_LANE
			_aim_confidence = maxf(0.0, _aim_confidence - AIM_CONFIDENCE_UNSAFE_LOSS_PER_SECOND * 0.25)
			return
		_fire_arrow(target)
	elif target.has_method("take_damage"):
		var damage := _damage_from_power(BASE_MELEE_DAMAGE)
		target.take_damage(damage, global_position)
		_spawn_melee_hit_feedback(target, damage)


func _apply_damage(damage: int, was_headshot: bool) -> void:
	if health <= 0:
		return

	var stagger_seconds := HEADSHOT_STAGGER_SECONDS if was_headshot else BODY_HIT_STAGGER_SECONDS
	health = maxi(0, health - damage)
	_change_morale(-float(damage) * MORALE_DAMAGE_LOSS_PER_DAMAGE)
	_interrupt_attack_for_stagger(stagger_seconds)
	if weapon_type == WEAPON_BOW:
		_aim_confidence = maxf(0.0, _aim_confidence - AIM_CONFIDENCE_DAMAGE_LOSS)
	_flash_time = HEADSHOT_HIT_FLASH_SECONDS if was_headshot else BODY_HIT_FLASH_SECONDS
	_update_hit_flash()
	_update_health_label(0.0, true)
	if health <= 0:
		_die()
	elif _uses_imported_visuals and _imported_visual != null and _imported_visual.has_method("play_hit"):
		_imported_visual.call("play_hit", stagger_seconds)


func _interrupt_attack_for_stagger(stagger_seconds: float) -> void:
	if _attack_time > 0.0:
		_attack_time = 0.0
		_has_struck = false
	_attack_cooldown = maxf(_attack_cooldown, stagger_seconds)


func _apply_melee_knockback(source_position: Vector3) -> void:
	if source_position == Vector3.ZERO or health <= 0:
		return

	var knockback := global_position - source_position
	knockback.y = 0.0
	if knockback.length() <= 0.01:
		return

	knockback = knockback.normalized()
	velocity.x += knockback.x * MELEE_KNOCKBACK
	velocity.z += knockback.z * MELEE_KNOCKBACK
	velocity.y = maxf(velocity.y, 1.2)


func _spawn_melee_hit_feedback(target: Node3D, damage: int) -> void:
	var parent := get_tree().current_scene
	if parent == null or target == null:
		return
	var feedback_multiplier := LARGE_BATTLE_MELEE_FEEDBACK_MULTIPLIER if _is_large_battle() else 1.0
	var show_sparks := randf() <= MELEE_SPARK_CHANCE * feedback_multiplier
	var show_damage_number := randf() <= MELEE_DAMAGE_NUMBER_CHANCE * feedback_multiplier
	if not show_sparks and not show_damage_number:
		return

	var hit_direction := target.global_position - global_position
	hit_direction.y = 0.0
	if hit_direction.length() <= 0.01:
		hit_direction = -global_transform.basis.z
	hit_direction = hit_direction.normalized()

	var hit_position := target.global_position + Vector3.UP * MELEE_HIT_HEIGHT - hit_direction * 0.18
	if show_sparks:
		_spawn_melee_sparks(parent, hit_position, hit_direction)
	if show_damage_number:
		_spawn_melee_damage_number(parent, hit_position, damage)


func _spawn_melee_sparks(parent: Node, hit_position: Vector3, hit_direction: Vector3) -> void:
	var sparks := Node3D.new()
	sparks.name = "MeleeImpactSparks"
	sparks.set_script(ImpactSparks)
	parent.add_child(sparks)

	var burst_normal := (hit_direction + Vector3.UP * 0.45).normalized()
	sparks.burst(hit_position, burst_normal, false)


func _spawn_melee_damage_number(parent: Node, hit_position: Vector3, damage: int) -> void:
	var number := Label3D.new()
	number.name = "MeleeDamageNumber"
	number.set_script(DamageNumber)
	parent.add_child(number)
	number.start(damage, hit_position + Vector3.UP * 0.12, _melee_damage_color(damage))


func _melee_damage_color(damage: int) -> Color:
	var red_weight := clampf(float(damage) / MELEE_DAMAGE_FULL_RED, 0.0, 1.0)
	return Color("#fff2a8").lerp(Color("#ff321f"), red_weight)


func _die() -> void:
	_broadcast_death_morale()
	_unregister_from_combat()
	_active_target = null
	died.emit(faction)
	remove_from_group(SOLDIER_GROUP)
	remove_from_group(_faction_group(faction))
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	if _label != null:
		_label.visible = false
	if _uses_imported_visuals and _imported_visual != null and _imported_visual.has_method("play_death"):
		_imported_visual.call("play_death")
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.0, 0.15, 1.0), 0.18)
	tween.tween_callback(Callable(self, "queue_free"))


func _base_morale() -> float:
	var shield_bonus := 2.0 if has_shield else 0.0
	return clampf(BASE_MORALE + float(power) * MORALE_POWER_BONUS + shield_bonus, 0.0, MORALE_MAX)


func _change_morale(amount: float) -> void:
	_morale = clampf(_morale + amount, 0.0, MORALE_MAX)
	if _morale <= MORALE_ROUT_THRESHOLD:
		_start_rout()


func _broadcast_death_morale() -> void:
	for node in _nearby_combat_soldiers(global_position, MORALE_DEATH_EVENT_RADIUS):
		if node == self:
			continue
		if node.has_method("receive_morale_event"):
			node.call("receive_morale_event", faction, global_position)


func _update_morale(delta: float) -> void:
	if _is_routing():
		_rout_time = maxf(0.0, _rout_time - delta)

	_morale_check_time = maxf(0.0, _morale_check_time - delta)
	if _morale_check_time > 0.0:
		return

	_morale_check_time = _morale_check_interval() + randf_range(0.0, 0.08)
	var counts := _nearby_morale_counts()
	var target_morale := _morale_target(counts)
	var rate := MORALE_RECOVERY_PER_SECOND if target_morale > _morale else MORALE_PRESSURE_LOSS_PER_SECOND
	_morale = move_toward(_morale, target_morale, rate * _morale_check_interval())
	_update_morale_state(counts)


func _nearby_morale_counts() -> Dictionary:
	var counts := {
		"allies": 0,
		"enemies": 0,
	}
	var radius_squared := MORALE_NEARBY_RADIUS * MORALE_NEARBY_RADIUS
	for node in _nearby_combat_soldiers(global_position, MORALE_NEARBY_RADIUS):
		if node == self:
			continue
		var soldier := node as Node3D
		if soldier == null or soldier.global_position.distance_squared_to(global_position) > radius_squared:
			continue
		if not soldier.has_method("is_alive") or not soldier.is_alive():
			continue
		if soldier.has_method("get_faction") and soldier.get_faction() == faction:
			counts["allies"] += 1
		else:
			counts["enemies"] += 1

	if faction == FACTION_ENEMY and player_target != null and player_target.global_position.distance_squared_to(global_position) <= radius_squared:
		counts["enemies"] += 1

	return counts


func _morale_target(counts: Dictionary) -> float:
	var health_ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	var allies := int(counts.get("allies", 0))
	var enemies := int(counts.get("enemies", 0))
	var target := _base_morale()
	target -= (1.0 - health_ratio) * MORALE_WOUND_LOSS
	target -= _fatigue_ratio() * MORALE_FATIGUE_LOSS
	target += float(mini(allies, 5)) * MORALE_ALLY_SUPPORT
	target -= float(mini(enemies, 5)) * MORALE_ENEMY_PRESSURE
	if enemies > allies + 1:
		target -= float(enemies - allies - 1) * MORALE_OUTNUMBERED_LOSS
	if _should_hold_position():
		target += 3.0
	return clampf(target, 0.0, MORALE_MAX)


func _update_morale_state(counts: Dictionary) -> void:
	if _morale <= MORALE_ROUT_THRESHOLD:
		_start_rout()
		return

	if _is_routing():
		var allies := int(counts.get("allies", 0))
		var enemies := int(counts.get("enemies", 0))
		if _rout_time <= 0.0 and _morale >= MORALE_RALLY_THRESHOLD and allies >= enemies:
			_morale_state = MORALE_WAVERING
		return

	if _morale <= MORALE_WAVERING_THRESHOLD:
		_morale_state = MORALE_WAVERING
	elif _morale <= MORALE_SHAKEN_THRESHOLD:
		_morale_state = MORALE_SHAKEN
	else:
		_morale_state = MORALE_STEADY


func _start_rout() -> void:
	if _morale_state == MORALE_ROUTING:
		return

	_morale_state = MORALE_ROUTING
	_rout_time = MORALE_ROUT_MIN_SECONDS + randf_range(0.0, 1.6)
	_rout_direction = _calculate_rout_direction()
	_active_target = null
	_attack_time = 0.0
	_has_struck = false


func _is_routing() -> bool:
	return _morale_state == MORALE_ROUTING


func _calculate_rout_direction() -> Vector3:
	var direction := Vector3.ZERO
	var radius_squared := MORALE_ROUT_SEARCH_RADIUS * MORALE_ROUT_SEARCH_RADIUS
	for node in _nearby_combat_soldiers(global_position, MORALE_ROUT_SEARCH_RADIUS, _opposing_faction()):
		var enemy := node as Node3D
		if enemy == null or enemy.global_position.distance_squared_to(global_position) > radius_squared:
			continue
		if enemy.has_method("is_alive") and not enemy.is_alive():
			continue
		var away := global_position - enemy.global_position
		away.y = 0.0
		if away.length() > 0.01:
			direction += away.normalized()

	if faction == FACTION_ENEMY and player_target != null and player_target.global_position.distance_squared_to(global_position) <= radius_squared:
		var away_from_player := global_position - player_target.global_position
		away_from_player.y = 0.0
		if away_from_player.length() > 0.01:
			direction += away_from_player.normalized()

	if direction.length() <= 0.01:
		direction = global_transform.basis.z
		direction.y = 0.0
	if direction.length() <= 0.01:
		direction = Vector3.BACK
	return direction.normalized()


func _move_routing(delta: float) -> float:
	_ai_action = AI_ACTION_ROUT
	if _rout_direction.length() <= 0.01:
		_rout_direction = _calculate_rout_direction()
	_face_direction(_rout_direction, delta)
	_set_flat_velocity(_rout_direction, move_speed * MORALE_ROUT_SPEED_MULTIPLIER, delta, 0.25, _rout_direction)
	return Vector3(velocity.x, 0.0, velocity.z).length()


func _update_fatigue(delta: float, flat_speed: float) -> void:
	var gain := 0.0
	var speed_ratio := clampf(flat_speed / maxf(move_speed, 0.01), 0.0, 1.5)
	if speed_ratio > 0.25:
		gain += FATIGUE_MOVE_GAIN_PER_SECOND * speed_ratio
	if _attack_time > 0.0:
		if weapon_type == WEAPON_BOW:
			gain += FATIGUE_BOW_DRAW_GAIN_PER_SECOND
		else:
			gain += FATIGUE_ATTACK_GAIN_PER_SECOND
	if _is_routing():
		gain += FATIGUE_ROUT_GAIN_PER_SECOND

	if gain > 0.0:
		_fatigue = clampf(_fatigue + gain * delta, 0.0, FATIGUE_MAX)
	else:
		_fatigue = clampf(_fatigue - FATIGUE_RECOVERY_PER_SECOND * delta, 0.0, FATIGUE_MAX)


func _fatigue_ratio() -> float:
	return clampf(_fatigue / FATIGUE_MAX, 0.0, 1.0)


func _movement_efficiency() -> float:
	var efficiency := 1.0 - _fatigue_ratio() * FATIGUE_SPEED_PENALTY
	if _morale_state == MORALE_SHAKEN:
		efficiency -= 0.04
	elif _morale_state == MORALE_WAVERING:
		efficiency -= 0.08
	return clampf(efficiency, 0.62, 1.05)


func _morale_attack_penalty() -> float:
	if _morale_state == MORALE_WAVERING:
		return 0.16
	if _morale_state == MORALE_SHAKEN:
		return 0.08
	return 0.0


func _update_active_target(delta: float) -> void:
	_target_refresh_time = maxf(0.0, _target_refresh_time - delta)
	if _target_refresh_time > 0.0 and _is_attack_target_valid(_active_target):
		return

	_active_target = _choose_target()
	_target_refresh_time = _target_refresh_interval()


func _target_refresh_interval() -> float:
	var multiplier := LARGE_BATTLE_TARGET_REFRESH_MULTIPLIER if _is_large_battle() else 1.0
	if weapon_type == WEAPON_BOW:
		return randf_range(BOW_TARGET_REFRESH_MIN_SECONDS, BOW_TARGET_REFRESH_MAX_SECONDS) * multiplier
	return randf_range(MELEE_TARGET_REFRESH_MIN_SECONDS, MELEE_TARGET_REFRESH_MAX_SECONDS) * multiplier


func _valid_node3d(value) -> Node3D:
	if value == null or not is_instance_valid(value):
		return null
	return value as Node3D


func _is_attack_target_valid(attack_target) -> bool:
	var target := _valid_node3d(attack_target)
	if target == null:
		return false
	if target.has_method("is_alive") and not target.is_alive():
		return false
	if target.has_method("get_faction") and target.get_faction() == faction:
		return false

	var distance_squared := global_position.distance_squared_to(target.global_position)
	if _should_hold_position():
		if weapon_type == WEAPON_BOW:
			var bow_hold_range := BOW_ATTACK_RANGE + TARGET_LEASH_EXTRA
			return distance_squared <= bow_hold_range * bow_hold_range
		var defend_range := HOLD_DEFEND_RADIUS + TARGET_LEASH_EXTRA
		return target.global_position.distance_squared_to(_order_position) <= defend_range * defend_range

	var leash_range := aggro_range + TARGET_LEASH_EXTRA
	return distance_squared <= leash_range * leash_range


func _faction_group(group_faction: String) -> String:
	return "%s_%s" % [SOLDIER_GROUP, group_faction]


func _opposing_faction() -> String:
	if faction == FACTION_ENEMY:
		return FACTION_FRIENDLY
	return FACTION_ENEMY


func _all_combat_soldiers() -> Array:
	if terrain_owner != null and is_instance_valid(terrain_owner) and terrain_owner.has_method("get_combat_soldiers"):
		return Array(terrain_owner.call("get_combat_soldiers"))
	return get_tree().get_nodes_in_group(SOLDIER_GROUP)


func _combat_soldiers_for_faction(soldier_faction: String) -> Array:
	if terrain_owner != null and is_instance_valid(terrain_owner) and terrain_owner.has_method("get_combat_soldiers_for_faction"):
		return Array(terrain_owner.call("get_combat_soldiers_for_faction", soldier_faction))
	return get_tree().get_nodes_in_group(_faction_group(soldier_faction))


func _nearby_combat_soldiers(center: Vector3, radius: float, soldier_faction := "") -> Array:
	if terrain_owner != null and is_instance_valid(terrain_owner) and terrain_owner.has_method("get_nearby_combat_soldiers"):
		return Array(terrain_owner.call("get_nearby_combat_soldiers", center, radius, soldier_faction))

	var source := _all_combat_soldiers()
	if soldier_faction != "":
		source = _combat_soldiers_for_faction(soldier_faction)

	var result: Array[Node3D] = []
	var radius_squared := radius * radius
	for node in source:
		var soldier := node as Node3D
		if soldier == null or not is_instance_valid(soldier):
			continue
		if soldier.global_position.distance_squared_to(center) <= radius_squared:
			result.append(soldier)
	return result


func _battle_soldier_count() -> int:
	if terrain_owner != null and is_instance_valid(terrain_owner) and terrain_owner.has_method("get_combat_soldier_count"):
		return int(terrain_owner.call("get_combat_soldier_count"))
	return get_tree().get_nodes_in_group(SOLDIER_GROUP).size()


func _is_large_battle() -> bool:
	return _battle_soldier_count() >= LARGE_BATTLE_SOLDIER_COUNT


func _morale_check_interval() -> float:
	if _is_large_battle():
		return MORALE_CHECK_INTERVAL * LARGE_BATTLE_MORALE_CHECK_MULTIPLIER
	return MORALE_CHECK_INTERVAL


func _separation_refresh_seconds() -> float:
	if _is_large_battle():
		return LARGE_BATTLE_SEPARATION_REFRESH_SECONDS
	return SMALL_BATTLE_SEPARATION_REFRESH_SECONDS


func _choose_target() -> Node3D:
	if _should_hold_position():
		return _choose_hold_defense_target()
	if weapon_type == WEAPON_BOW:
		return _choose_bow_target()

	var best_target: Node3D
	var best_distance_squared := aggro_range * aggro_range

	if faction == FACTION_ENEMY and _is_attack_target_valid(player_target):
		best_target = _nearest_target(best_target, best_distance_squared, player_target)
		if best_target != null:
			best_distance_squared = global_position.distance_squared_to(best_target.global_position)

	for node in _combat_soldiers_for_faction(_opposing_faction()):
		var candidate := node as Node3D
		if candidate == null or not _is_attack_target_valid(candidate):
			continue
		best_target = _nearest_target(best_target, best_distance_squared, candidate)
		if best_target != null:
			best_distance_squared = global_position.distance_squared_to(best_target.global_position)

	return best_target


func _choose_hold_defense_target() -> Node3D:
	var best_target: Node3D
	var best_score := 999999.0
	var bow_candidates: Array[Node3D] = []
	var bow_distances: Array[float] = []

	for node in _combat_soldiers_for_faction(_opposing_faction()):
		var candidate := node as Node3D
		if candidate == null or not _is_attack_target_valid(candidate):
			continue
		var distance_squared := global_position.distance_squared_to(candidate.global_position)
		if weapon_type == WEAPON_BOW:
			if distance_squared > BOW_ATTACK_RANGE * BOW_ATTACK_RANGE:
				continue
			_remember_bow_candidate(bow_candidates, bow_distances, candidate, distance_squared)
			continue
		elif candidate.global_position.distance_squared_to(_order_position) > HOLD_DEFEND_RADIUS * HOLD_DEFEND_RADIUS:
			continue
		var distance := sqrt(distance_squared)
		var score := distance
		if score < best_score:
			best_score = score
			best_target = candidate

	if weapon_type == WEAPON_BOW:
		best_target = _lowest_risk_bow_candidate(bow_candidates, bow_distances)

	return best_target


func _choose_bow_target() -> Node3D:
	var candidates: Array[Node3D] = []
	var distances: Array[float] = []
	if faction == FACTION_ENEMY and _is_attack_target_valid(player_target):
		_remember_bow_candidate(candidates, distances, player_target, global_position.distance_squared_to(player_target.global_position))

	for node in _combat_soldiers_for_faction(_opposing_faction()):
		var candidate := node as Node3D
		if candidate == null or not _is_attack_target_valid(candidate):
			continue
		var distance_squared := global_position.distance_squared_to(candidate.global_position)
		if distance_squared > aggro_range * aggro_range:
			continue
		_remember_bow_candidate(candidates, distances, candidate, distance_squared)

	return _lowest_risk_bow_candidate(candidates, distances)


func _lowest_risk_bow_candidate(candidates: Array[Node3D], distances: Array[float]) -> Node3D:
	var best_target: Node3D
	var best_score := 999999.0
	for index in range(candidates.size()):
		var candidate := candidates[index]
		if not _is_attack_target_valid(candidate):
			continue
		var distance := sqrt(distances[index])
		var friendly_fire_risk := _friendly_fire_risk_for_target(candidate)
		var score := distance + friendly_fire_risk * FRIENDLY_FIRE_SCORE_PENALTY - _bow_target_priority_bonus(candidate, distance, friendly_fire_risk)
		if score < best_score:
			best_score = score
			best_target = candidate

	return best_target


func _bow_target_priority_bonus(candidate: Node3D, distance: float, friendly_fire_risk: float) -> float:
	var bonus := 0.0
	if faction == FACTION_ENEMY and candidate == player_target:
		bonus += 5.0
	if distance < BOW_BACK_UP_DISTANCE:
		bonus += (BOW_BACK_UP_DISTANCE - distance) * 1.25
	if friendly_fire_risk <= 0.0:
		bonus += 2.0
	return bonus


func _remember_bow_candidate(candidates: Array[Node3D], distances: Array[float], candidate: Node3D, distance_squared: float) -> void:
	var insert_index := distances.size()
	for index in range(distances.size()):
		if distance_squared < distances[index]:
			insert_index = index
			break

	if insert_index >= MAX_BOW_TARGET_CANDIDATES and distances.size() >= MAX_BOW_TARGET_CANDIDATES:
		return

	candidates.insert(insert_index, candidate)
	distances.insert(insert_index, distance_squared)
	if candidates.size() > MAX_BOW_TARGET_CANDIDATES:
		candidates.remove_at(candidates.size() - 1)
		distances.remove_at(distances.size() - 1)


func _nearest_target(current_best: Node3D, current_best_distance_squared: float, candidate: Node3D) -> Node3D:
	var distance_squared := global_position.distance_squared_to(candidate.global_position)
	if distance_squared <= current_best_distance_squared:
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
	return SWORD_ATTACK_COOLDOWN * (1.0 + _fatigue_ratio() * FATIGUE_ATTACK_COOLDOWN_PENALTY + _morale_attack_penalty())


func _move_while_charging_bow(delta: float, direction: Vector3, distance: float) -> void:
	if _should_hold_position():
		_move_to_order_position(delta, BOW_CHARGING_MOVE_MULTIPLIER)
		return

	if direction == Vector3.ZERO:
		_brake_flat_velocity(delta)
		return

	var move_direction := Vector3.ZERO
	if distance < BOW_BACK_UP_DISTANCE:
		move_direction = -direction
	elif distance > BOW_ADVANCE_DISTANCE:
		move_direction = direction
	else:
		_brake_flat_velocity(delta)
		return
	var charge_speed := move_speed * BOW_CHARGING_MOVE_MULTIPLIER
	_set_flat_velocity(move_direction, charge_speed, delta, 1.0, direction)


func _should_hold_position() -> bool:
	return faction == FACTION_FRIENDLY and _order_mode == ORDER_HOLD and _has_order_position


func _should_move_to_order_position() -> bool:
	return _should_hold_position() and _flat_distance_to(_order_position) > HOLD_POSITION_ARRIVAL_DISTANCE


func _move_to_order_position(delta: float, speed_multiplier := 1.0) -> float:
	var to_position := _order_position - global_position
	var flat_to_position := Vector3(to_position.x, 0.0, to_position.z)
	var distance := flat_to_position.length()
	_ai_action = AI_ACTION_HOLD
	if distance <= HOLD_POSITION_ARRIVAL_DISTANCE:
		return _brake_and_report(delta)

	var direction := flat_to_position / distance
	_face_direction(direction, delta)
	var order_speed := move_speed * speed_multiplier
	_set_flat_velocity(direction, order_speed, delta, 1.0, direction)
	return Vector3(velocity.x, 0.0, velocity.z).length()


func _should_use_battle_slot(delta: float, target_distance: float) -> bool:
	if not _has_battle_slot or _battle_slot_released or _should_hold_position():
		return false

	var release_distance := BATTLE_SLOT_ARCHER_RELEASE_DISTANCE if weapon_type == WEAPON_BOW else BATTLE_SLOT_RELEASE_DISTANCE
	if target_distance <= release_distance:
		_battle_slot_released = true
		return false

	var slot_distance := _flat_distance_to(_battle_slot_position)
	if slot_distance <= BATTLE_SLOT_SOFT_RELEASE_DISTANCE:
		_battle_slot_released = true
		return false

	_battle_slot_stage_time = maxf(0.0, _battle_slot_stage_time - delta)
	if _battle_slot_stage_time <= 0.0:
		_battle_slot_released = true
		return false

	return slot_distance > BATTLE_SLOT_ARRIVAL_DISTANCE


func _move_to_battle_slot(delta: float, speed_multiplier := 1.0) -> float:
	var to_position := _battle_slot_position - global_position
	var flat_to_position := Vector3(to_position.x, 0.0, to_position.z)
	var distance := flat_to_position.length()
	_ai_action = AI_ACTION_ADVANCE
	if distance <= BATTLE_SLOT_ARRIVAL_DISTANCE:
		_battle_slot_released = true
		return _brake_and_report(delta)

	var direction := flat_to_position / distance
	_face_direction(direction, delta)
	_set_flat_velocity(direction, move_speed * speed_multiplier, delta, 1.0, direction)
	return Vector3(velocity.x, 0.0, velocity.z).length()


func _move_to_bow_lane(delta: float, attack_target: Node3D, direction: Vector3) -> float:
	if direction == Vector3.ZERO:
		return _brake_and_report(delta)

	_ai_action = AI_ACTION_LANE
	_face_direction(direction, delta)
	var lane_direction := _best_bow_lane_direction(attack_target, direction)
	_set_flat_velocity(lane_direction, move_speed * BOW_LANE_MOVE_MULTIPLIER, delta, 1.0, direction)
	return Vector3(velocity.x, 0.0, velocity.z).length()


func _move_for_combat_range(delta: float, direction: Vector3, distance: float) -> float:
	if direction == Vector3.ZERO:
		return _settle_or_separate(delta)

	var move_direction := Vector3.ZERO
	var speed_multiplier := 1.0
	if weapon_type == WEAPON_BOW:
		if distance < BOW_BACK_UP_DISTANCE:
			move_direction = -direction
			speed_multiplier = 0.62
		elif distance > BOW_ADVANCE_DISTANCE:
			move_direction = direction
		else:
			return _brake_and_report(delta)
	else:
		if distance < MELEE_BACK_UP_DISTANCE:
			move_direction = -direction
			speed_multiplier = 0.45
		elif distance > MELEE_ADVANCE_DISTANCE:
			move_direction = direction
		else:
			return _brake_and_report(delta)

	_set_flat_velocity(move_direction, move_speed * speed_multiplier, delta, 1.0, direction)
	return Vector3(velocity.x, 0.0, velocity.z).length()


func _best_bow_lane_direction(attack_target: Node3D, direction: Vector3) -> Vector3:
	if _bow_lane_commit_time > 0.0 and _bow_lane_direction != Vector3.ZERO:
		return _bow_lane_direction

	var side := Vector3(-direction.z, 0.0, direction.x)
	if side.length() <= 0.01:
		side = Vector3.RIGHT
	side = side.normalized()

	var current_risk := _friendly_fire_risk_for_target(attack_target)
	var best_risk := current_risk
	var best_direction := side if (_formation_index + _battle_slot_index) % 2 == 0 else -side
	var best_score := _score_bow_position(global_position, attack_target, current_risk)
	var candidates: Array[Vector3] = [
		side,
		-side,
		(side - direction * 0.35).normalized(),
		(-side - direction * 0.35).normalized(),
		-direction,
	]

	for candidate_direction in candidates:
		if candidate_direction == Vector3.ZERO:
			continue
		var normalized_direction := candidate_direction.normalized()
		var candidate_position := global_position + normalized_direction * BOW_LANE_STEP_DISTANCE
		var candidate_forward := attack_target.global_position - candidate_position
		candidate_forward.y = 0.0
		if candidate_forward.length() <= 0.01:
			candidate_forward = direction
		else:
			candidate_forward = candidate_forward.normalized()
		var candidate_origin := _bow_arrow_origin_from_position(candidate_position, candidate_forward)
		var risk := _friendly_fire_risk_for_target_from_origin(attack_target, candidate_origin)
		var score := _score_bow_position(candidate_position, attack_target, risk)
		if score > best_score:
			best_score = score
			best_risk = risk
			best_direction = normalized_direction

	if current_risk - best_risk < BOW_LANE_MIN_RISK_IMPROVEMENT:
		if (_formation_index + _battle_slot_index) % 2 == 0:
			best_direction = side
		else:
			best_direction = -side

	_bow_lane_direction = best_direction.normalized()
	_bow_lane_commit_time = BOW_LANE_COMMIT_SECONDS + randf_range(0.0, 0.18)
	return _bow_lane_direction


func _score_bow_position(position: Vector3, attack_target: Node3D, friendly_fire_risk: float) -> float:
	var flat_distance := Vector2(position.x, position.z).distance_to(Vector2(attack_target.global_position.x, attack_target.global_position.z))
	var ideal_distance := (BOW_BACK_UP_DISTANCE + BOW_ADVANCE_DISTANCE) * 0.5
	var score := -friendly_fire_risk * BOW_POSITION_RISK_PENALTY
	score -= absf(flat_distance - ideal_distance) * BOW_POSITION_RANGE_WEIGHT

	if _has_battle_slot:
		score -= Vector2(position.x, position.z).distance_to(Vector2(_battle_slot_position.x, _battle_slot_position.z)) * BOW_POSITION_SLOT_WEIGHT

	if _should_score_bow_terrain():
		var height_delta := _terrain_height_at(position) - attack_target.global_position.y
		score += clampf(height_delta, -2.0, 4.0) * BOW_POSITION_HEIGHT_WEIGHT
		score -= _terrain_slope_at(position) * BOW_POSITION_SLOPE_PENALTY

	return score


func _should_score_bow_terrain() -> bool:
	return _battle_soldier_count() <= BOW_TERRAIN_SCORE_MAX_SOLDIERS


func _terrain_height_at(position: Vector3) -> float:
	if terrain_owner != null and is_instance_valid(terrain_owner) and terrain_owner.has_method("get_combat_terrain_height"):
		return float(terrain_owner.call("get_combat_terrain_height", position))
	return position.y


func _terrain_slope_at(position: Vector3) -> float:
	if terrain_owner != null and is_instance_valid(terrain_owner) and terrain_owner.has_method("get_combat_terrain_slope"):
		return float(terrain_owner.call("get_combat_terrain_slope", position))
	return 0.0


func _set_flat_velocity(move_direction: Vector3, desired_speed: float, delta: float, separation_weight := 1.0, facing_direction := Vector3.ZERO) -> void:
	var flat_direction := Vector3(move_direction.x, 0.0, move_direction.z)
	if flat_direction.length() > 0.01:
		flat_direction = flat_direction.normalized()
	else:
		flat_direction = Vector3.ZERO

	if separation_weight > 0.0:
		var separation := _ally_separation_direction(delta)
		if separation != Vector3.ZERO:
			flat_direction += separation * ALLY_SEPARATION_STRENGTH * separation_weight

	if flat_direction.length() <= 0.01:
		_brake_flat_velocity(delta)
		return

	flat_direction = flat_direction.normalized()
	var adjusted_desired_speed := desired_speed * _movement_efficiency() * _directional_speed_multiplier(flat_direction, facing_direction)
	var acceleration := move_speed * _movement_efficiency() * FLAT_ACCELERATION_MULTIPLIER * delta
	velocity.x = move_toward(velocity.x, flat_direction.x * adjusted_desired_speed, acceleration)
	velocity.z = move_toward(velocity.z, flat_direction.z * adjusted_desired_speed, acceleration)


func _directional_speed_multiplier(flat_direction: Vector3, facing_direction := Vector3.ZERO) -> float:
	var forward := Vector3(facing_direction.x, 0.0, facing_direction.z)
	if forward.length_squared() <= 0.0001:
		forward = -global_transform.basis.z
		forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		return 1.0

	forward = forward.normalized()
	var right := Vector3(-forward.z, 0.0, forward.x)
	var local_x := flat_direction.dot(right) / STRAFE_SPEED_DIVISOR
	var local_y := flat_direction.dot(forward)
	if local_y < 0.0:
		local_y /= BACKPEDAL_SPEED_DIVISOR
	return clampf(Vector2(local_x, local_y).length(), 0.0, 1.0)


func _settle_or_separate(delta: float) -> float:
	var separation := _ally_separation_direction(delta)
	if separation != Vector3.ZERO:
		_set_flat_velocity(separation, move_speed * ALLY_SEPARATION_IDLE_MOVE_MULTIPLIER, delta, 0.0, separation)
	else:
		_brake_flat_velocity(delta)
	return Vector3(velocity.x, 0.0, velocity.z).length()


func _brake_and_report(delta: float) -> float:
	_brake_flat_velocity(delta)
	return Vector3(velocity.x, 0.0, velocity.z).length()


func _brake_flat_velocity(delta: float) -> void:
	var brake := move_speed * _movement_efficiency() * FLAT_BRAKE_MULTIPLIER * delta
	velocity.x = move_toward(velocity.x, 0.0, brake)
	velocity.z = move_toward(velocity.z, 0.0, brake)


func _ally_separation_direction(delta: float) -> Vector3:
	_separation_refresh_time = maxf(0.0, _separation_refresh_time - delta)
	if _separation_refresh_time > 0.0:
		return _cached_separation_direction

	_separation_refresh_time = _separation_refresh_seconds() + randf_range(0.0, 0.025)
	var steering := Vector3.ZERO
	var checked := 0
	for node in _nearby_combat_soldiers(global_position, ALLY_SEPARATION_RADIUS, faction):
		if node == self:
			continue
		var ally := node as Node3D
		if ally == null or not _is_attack_target_valid_for_friendly_fire(ally):
			continue

		var offset := global_position - ally.global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance > ALLY_SEPARATION_RADIUS:
			continue
		if distance <= 0.01:
			var angle := float(_formation_index + _battle_slot_index + checked * 11) * 2.399963
			offset = Vector3(cos(angle), 0.0, sin(angle))
			distance = 0.01

		var weight := (ALLY_SEPARATION_RADIUS - distance) / ALLY_SEPARATION_RADIUS
		steering += offset.normalized() * weight
		checked += 1
		if checked >= ALLY_SEPARATION_MAX_NEIGHBORS:
			break

	if steering.length() <= 0.01:
		_cached_separation_direction = Vector3.ZERO
	else:
		_cached_separation_direction = steering.normalized()
	return _cached_separation_direction


func _flat_distance_to(position: Vector3) -> float:
	return Vector2(global_position.x, global_position.z).distance_to(Vector2(position.x, position.z))


func _flat_direction_to(position: Vector3) -> Vector3:
	var to_position := position - global_position
	var flat_to_position := Vector3(to_position.x, 0.0, to_position.z)
	if flat_to_position.length() <= 0.05:
		return Vector3.ZERO
	return flat_to_position.normalized()


func _aim_spread_radians() -> float:
	var dexterity_ratio := clampf(float(dexterity) / float(MAX_STAT), 0.0, 1.0)
	var morale_spread := 0.0
	if _morale_state == MORALE_WAVERING:
		morale_spread = deg_to_rad(2.4)
	elif _morale_state == MORALE_SHAKEN:
		morale_spread = deg_to_rad(1.2)
	return lerpf(deg_to_rad(5.0), 0.0, dexterity_ratio) + deg_to_rad(FATIGUE_AIM_SPREAD_DEGREES) * _fatigue_ratio() + morale_spread


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
	_aim_confidence = maxf(0.0, _aim_confidence - AIM_CONFIDENCE_SHOT_COST)


func _bow_arrow_origin() -> Vector3:
	return global_position + Vector3(0.0, ARROW_RELEASE_HEIGHT, 0.0) - global_transform.basis.z * ARROW_FORWARD_OFFSET


func _bow_arrow_origin_from_position(origin_position: Vector3, forward_direction: Vector3) -> Vector3:
	var flat_forward := Vector3(forward_direction.x, 0.0, forward_direction.z)
	if flat_forward.length() <= 0.01:
		flat_forward = -global_transform.basis.z
	flat_forward = flat_forward.normalized()
	return origin_position + Vector3(0.0, ARROW_RELEASE_HEIGHT, 0.0) + flat_forward * ARROW_FORWARD_OFFSET


func _shot_has_friendly_fire_risk(attack_target: Node3D) -> bool:
	return _friendly_fire_risk_for_target(attack_target) > 0.0


func _friendly_fire_risk_for_target(attack_target: Node3D) -> float:
	var arrow_origin := _bow_arrow_origin()
	return _friendly_fire_risk_for_target_from_origin(attack_target, arrow_origin)


func _friendly_fire_risk_for_target_from_origin(attack_target: Node3D, arrow_origin: Vector3) -> float:
	var aim_point := _predicted_bow_aim_point(arrow_origin, attack_target)
	var risk := 0.0
	var lane_center := (arrow_origin + aim_point) * 0.5
	var lane_query_radius := arrow_origin.distance_to(aim_point) * 0.5 + FRIENDLY_FIRE_LANE_RADIUS

	for node in _nearby_combat_soldiers(lane_center, lane_query_radius, faction):
		if node == self or node == attack_target:
			continue
		var blocker := node as Node3D
		if blocker == null or not _is_attack_target_valid_for_friendly_fire(blocker):
			continue
		risk += _friendly_fire_risk_for_position(arrow_origin, aim_point, blocker.global_position + Vector3(0.0, BOW_AIM_HEIGHT, 0.0))

	if faction == FACTION_FRIENDLY and player_target != null and player_target != attack_target:
		risk += _friendly_fire_risk_for_position(arrow_origin, aim_point, player_target.global_position + Vector3(0.0, BOW_AIM_HEIGHT, 0.0))

	return risk


func _is_attack_target_valid_for_friendly_fire(blocker: Node3D) -> bool:
	if blocker == null or not is_instance_valid(blocker):
		return false
	if blocker.has_method("is_alive") and not blocker.is_alive():
		return false
	if blocker.has_method("get_faction") and blocker.get_faction() != faction:
		return false
	return true


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

	if _try_build_imported_visual():
		return

	_body_mesh = _add_capsule("Body", Vector3(0.0, 0.86, 0.0), 0.29, 1.05, _cloth_material)
	_head_mesh = _add_sphere("Head", HEAD_CENTER, Vector3(0.4, 0.37, 0.4), _base_material)
	_add_capsule("Helmet", Vector3(0.0, 1.75, 0.0), 0.42, 0.24, _metal_material, true)
	_add_box("NoseGuard", Vector3(0.0, 1.6, -0.36), Vector3(0.045, 0.25, 0.035), _metal_material, true)
	_add_box("Belt", Vector3(0.0, 0.86, -0.01), Vector3(0.39, 0.08, 0.33), _leather_material, true)

	_left_arm_mesh = _add_limb("LeftArm", Vector3(-0.35, 1.04, -0.03), -8.0)
	_right_arm_mesh = _add_limb("RightArm", Vector3(0.35, 1.04, -0.03), 8.0)
	_left_leg_mesh = _add_limb("LeftLeg", Vector3(-0.16, 0.28, 0.0), 4.0, 1.12)
	_right_leg_mesh = _add_limb("RightLeg", Vector3(0.16, 0.28, 0.0), -4.0, 1.12)


func _try_build_imported_visual() -> bool:
	if not use_imported_visuals:
		return false

	var visual := QuaterniusSoldierVisualScene.instantiate() as Node3D
	if visual == null:
		return false
	visual.name = "QuaterniusSoldierVisual"

	if not visual.has_method("setup_visual"):
		visual.free()
		return false

	var loaded := bool(visual.call("setup_visual", faction, weapon_type, has_shield))
	if not loaded:
		visual.free()
		return false

	_imported_visual = visual
	_uses_imported_visuals = true
	add_child(_imported_visual)
	return true


func _build_equipment() -> void:
	if _uses_imported_visuals:
		return

	if weapon_type == WEAPON_SWORD:
		_build_sword()
	elif weapon_type == WEAPON_BOW:
		_build_bow()
	else:
		_build_sword()

	if has_shield:
		_build_round_shield()


func _build_sword() -> void:
	_sword_pivot = Node3D.new()
	_sword_pivot.name = "SwordPivot"
	_sword_pivot.position = Vector3(0.46, 1.0, -0.2)
	add_child(_sword_pivot)

	var blade = _add_box("SwordBlade", Vector3(0.0, 0.05, -0.38), Vector3(0.055, 0.035, 0.58), _metal_material, true)
	var handle = _add_capsule("SwordGrip", Vector3.ZERO, 0.035, 0.22, _leather_material, true)
	handle.rotation_degrees.x = 90.0
	var guard = _add_box("SwordGuard", Vector3(0.0, 0.01, -0.11), Vector3(0.24, 0.045, 0.045), _metal_material, true)

	remove_child(blade)
	remove_child(handle)
	remove_child(guard)

	_sword_pivot.add_child(blade)
	_sword_pivot.add_child(handle)
	_sword_pivot.add_child(guard)

	_remember_animation_node(_sword_pivot)


func _build_round_shield() -> void:
	var shield := _add_capsule("RoundShield", Vector3(-0.5, 1.0, -0.2), 0.34, 0.08, _leather_material, true)
	shield.rotation_degrees.x = 90.0


func _build_bow() -> void:
	_bow_pivot = Node3D.new()
	_bow_pivot.name = "BowPivot"
	_bow_pivot.position = Vector3(-0.35, 0.8, -0.15)
	add_child(_bow_pivot)

	var bow = _add_capsule("Bow", Vector3.ZERO, 0.025, 1.05, _leather_material, true)
	bow.rotation_degrees = Vector3(0.0, 0.0, 16.0)

	_bow_string_top = _add_box("BowStringTop", Vector3.ZERO, Vector3(0.008, 0.008, 1.0), _make_material(Color("#d8c58d"), 0.95), true)
	_bow_string_bottom = _add_box("BowStringBottom", Vector3.ZERO, Vector3(0.008, 0.008, 1.0), _make_material(Color("#d8c58d"), 0.95), true)
	_loaded_arrow_mesh = _add_box("LoadedArrow", Vector3.ZERO, Vector3(0.025, 0.025, 0.68), _make_material(Color("#6b4328"), 0.88), true)

	remove_child(bow)
	remove_child(_bow_string_top)
	remove_child(_bow_string_bottom)
	remove_child(_loaded_arrow_mesh)

	_bow_pivot.add_child(bow)
	_bow_pivot.add_child(_bow_string_top)
	_bow_pivot.add_child(_bow_string_bottom)
	_bow_pivot.add_child(_loaded_arrow_mesh)

	var top_tip_local = Vector3(-0.14, 0.5, 0)
	var bottom_tip_local = Vector3(0.14, -0.5, 0)
	var nock_local = Vector3(0, 0, 0)
	
	var top_tip_global = _bow_pivot.to_global(top_tip_local)
	var nock_global = _bow_pivot.to_global(nock_local)
	var bottom_tip_global = _bow_pivot.to_global(bottom_tip_local)
	
	_bow_string_top.global_position = (top_tip_global + nock_global) / 2.0
	if top_tip_global.distance_squared_to(nock_global) > 0.001:
		_bow_string_top.look_at(nock_global, Vector3.UP)
	_bow_string_top.scale.z = top_tip_local.distance_to(nock_local)
	
	_bow_string_bottom.global_position = (bottom_tip_global + nock_global) / 2.0
	if bottom_tip_global.distance_squared_to(nock_global) > 0.001:
		_bow_string_bottom.look_at(nock_global, Vector3.UP)
	_bow_string_bottom.scale.z = bottom_tip_local.distance_to(nock_local)

	_loaded_arrow_mesh.position = Vector3(0, 0, -0.34)

	_remember_animation_node(_bow_pivot)
	_remember_animation_node(_bow_string_top)
	_remember_animation_node(_bow_string_bottom)
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


func _update_health_label(delta := 0.0, force := false) -> void:
	if _label == null:
		return

	_label_update_time = maxf(0.0, _label_update_time - delta)
	var should_show := _should_show_health_label()
	if _label.visible != should_show:
		_label.visible = should_show
	if not should_show:
		return
	if not force and _label_update_time > 0.0:
		return

	_label_update_time = LABEL_UPDATE_SECONDS + randf_range(0.0, 0.06)
	var role := "Archer" if weapon_type == WEAPON_BOW else "Swordsman"
	var name_text := "Enemy %s" % role
	if faction == FACTION_FRIENDLY:
		name_text = "Ally %s" % role
	var label_text := "%s\n%d/%d\n%s | %s\nM %.0f F %.0f" % [name_text, health, max_health, _ai_action, _morale_state, _morale, _fatigue]
	if label_text != _last_label_text:
		_label.text = label_text
		_last_label_text = label_text


func _should_show_health_label() -> bool:
	if _battle_soldier_count() <= LABEL_VISIBLE_MAX_SOLDIERS:
		return true
	if _flash_time <= 0.0 or player_target == null:
		return false
	var close_to_player := player_target.global_position.distance_squared_to(global_position) <= 100.0
	return close_to_player


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
	mesh_instance.mesh = _cached_capsule_mesh(radius, height, 10)
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
	mesh_instance.mesh = _cached_sphere_mesh()
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
	mesh_instance.mesh = _cached_box_mesh(size)
	mesh_instance.position = position
	mesh_instance.material_override = material
	if is_detail:
		mesh_instance.add_to_group(DETAIL_MESH_GROUP)
	add_child(mesh_instance)
	return mesh_instance


func _cached_capsule_mesh(radius: float, height: float, radial_segments: int) -> CapsuleMesh:
	var key := "%.3f:%.3f:%d" % [radius, height, radial_segments]
	if _capsule_mesh_cache.has(key):
		return _capsule_mesh_cache[key] as CapsuleMesh

	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = radial_segments
	_capsule_mesh_cache[key] = mesh
	return mesh


func _cached_sphere_mesh() -> SphereMesh:
	if _sphere_mesh != null:
		return _sphere_mesh

	_sphere_mesh = SphereMesh.new()
	_sphere_mesh.radius = 0.5
	_sphere_mesh.height = 1.0
	return _sphere_mesh


func _cached_box_mesh(size: Vector3) -> BoxMesh:
	var key := "%.3f:%.3f:%.3f" % [size.x, size.y, size.z]
	if _box_mesh_cache.has(key):
		return _box_mesh_cache[key] as BoxMesh

	var mesh := BoxMesh.new()
	mesh.size = size
	_box_mesh_cache[key] = mesh
	return mesh


func _remember_animation_node(node: Node3D) -> void:
	_animated_meshes.append(node)
	_base_positions.append(node.position)
	_base_rotations.append(node.rotation_degrees)
	_base_scales.append(node.scale)


func _update_soldier_visuals(delta: float, flat_speed: float) -> void:
	if not _is_large_battle():
		_animate_soldier(delta, flat_speed)
		return

	_visual_update_time = maxf(0.0, _visual_update_time - delta)
	if _visual_update_time > 0.0:
		return

	_visual_update_time = LARGE_BATTLE_VISUAL_UPDATE_SECONDS + randf_range(0.0, 0.014)
	_animate_soldier(LARGE_BATTLE_VISUAL_UPDATE_SECONDS, flat_speed)


func _animate_soldier(delta: float, flat_speed: float) -> void:
	if _uses_imported_visuals:
		if _imported_visual != null and _imported_visual.has_method("update_combat_state"):
			_imported_visual.call("update_combat_state", delta, flat_speed, _attack_time > 0.0, weapon_type, _is_moving_backward(flat_speed))
		return

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


func _is_moving_backward(flat_speed: float) -> bool:
	if weapon_type != WEAPON_BOW or flat_speed <= 0.05:
		return false

	var flat_velocity := Vector3(velocity.x, 0.0, velocity.z)
	if flat_velocity.length_squared() <= 0.0025:
		return false

	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		return false

	return flat_velocity.normalized().dot(forward.normalized()) < -0.25


func _restore_animation_pose() -> void:
	for index in range(_animated_meshes.size()):
		var mesh := _animated_meshes[index]
		if mesh == null:
			continue
		mesh.position = _base_positions[index]
		mesh.rotation_degrees = _base_rotations[index]
		mesh.scale = _base_scales[index]


func _animate_walk(flat_speed: float) -> void:
	var weight := clampf(flat_speed / maxf(move_speed * _movement_efficiency(), 0.01), 0.0, 1.0)
	var phase := _animation_time * 8.0
	var bob := absf(sin(phase)) * 0.045 * weight
	_body_mesh.position.y += bob
	_head_mesh.position.y += bob * 0.6
	_left_arm_mesh.rotation_degrees.x += sin(phase) * 20.0 * weight
	_right_arm_mesh.rotation_degrees.x += sin(phase + PI) * 12.0 * weight
	_left_leg_mesh.rotation_degrees.x += sin(phase + PI) * 22.0 * weight
	_right_leg_mesh.rotation_degrees.x += sin(phase) * 22.0 * weight


func _animate_sword_attack() -> void:
	var attack_seconds := _attack_duration_seconds()
	var elapsed := attack_seconds - _attack_time
	var t := clampf(elapsed / attack_seconds, 0.0, 1.0)

	var windup := 0.0
	var strike := 0.0
	var recover := 0.0

	if t < 0.32:
		windup = smoothstep(0.0, 1.0, t / 0.32)
	elif t < 0.50:
		var st := (t - 0.32) / 0.18
		windup = 1.0 - st
		strike = smoothstep(0.0, 1.0, st)
	else:
		var rt := (t - 0.50) / 0.50
		strike = 1.0 - smoothstep(0.0, 1.0, rt)
		recover = smoothstep(0.0, 1.0, rt)

	var lunge_z := 0.30 * strike - 0.08 * windup - 0.03 * recover
	var shoulder_twist := 18.0 * windup - 26.0 * strike + 5.0 * recover

	_body_mesh.position.z -= lunge_z
	_head_mesh.position.z -= lunge_z * 0.8
	_left_arm_mesh.position.z -= lunge_z
	_right_arm_mesh.position.z -= lunge_z
	_left_leg_mesh.position.z -= lunge_z
	_right_leg_mesh.position.z -= lunge_z

	_sword_pivot.position.x += -0.16 * windup + 0.34 * strike
	_sword_pivot.position.y += 0.20 * windup + 0.06 * strike - 0.08 * recover
	_sword_pivot.position.z -= lunge_z + 0.14 * strike

	_body_mesh.rotation_degrees.x += 10.0 * strike - 4.0 * windup
	_body_mesh.rotation_degrees.y += shoulder_twist
	_head_mesh.rotation_degrees.x += 5.0 * strike - 2.0 * windup
	_head_mesh.rotation_degrees.y += shoulder_twist * 0.35

	_left_arm_mesh.rotation_degrees.x -= 18.0 * windup + 20.0 * strike
	_left_arm_mesh.rotation_degrees.y += 18.0 * strike

	_right_arm_mesh.rotation_degrees.x += 62.0 * windup - 82.0 * strike + 18.0 * recover
	_right_arm_mesh.rotation_degrees.y += 42.0 * windup - 72.0 * strike
	_right_arm_mesh.rotation_degrees.z -= 38.0 * windup - 92.0 * strike + 22.0 * recover

	_sword_pivot.rotation_degrees.x += 74.0 * windup - 118.0 * strike + 24.0 * recover
	_sword_pivot.rotation_degrees.y += 52.0 * windup - 104.0 * strike + 18.0 * recover
	_sword_pivot.rotation_degrees.z -= 64.0 * windup - 128.0 * strike + 32.0 * recover

	_left_leg_mesh.rotation_degrees.x -= 30.0 * strike - 10.0 * windup
	_right_leg_mesh.rotation_degrees.x += 20.0 * strike + 10.0 * windup


func _animate_bow_attack() -> void:
	var elapsed := _attack_duration_seconds() - _attack_time
	var draw := smoothstep(0.0, 1.0, clampf(elapsed / _attack_duration_seconds(), 0.0, 1.0))
	
	_left_arm_mesh.rotation_degrees.x -= 70.0 * draw
	_right_arm_mesh.rotation_degrees.x -= 65.0 * draw
	_right_arm_mesh.rotation_degrees.y -= 45.0 * draw
	
	_bow_pivot.position.y += 0.25 * draw
	_bow_pivot.position.z -= 0.35 * draw
	_bow_pivot.rotation_degrees.y -= 15.0 * draw
	
	var nock_z = 0.45 * draw
	var top_tip_local = Vector3(-0.14, 0.5, 0)
	var bottom_tip_local = Vector3(0.14, -0.5, 0)
	var nock_local = Vector3(0, 0, nock_z)
	
	var top_tip_global = _bow_pivot.to_global(top_tip_local)
	var nock_global = _bow_pivot.to_global(nock_local)
	var bottom_tip_global = _bow_pivot.to_global(bottom_tip_local)
	
	_bow_string_top.global_position = (top_tip_global + nock_global) / 2.0
	if top_tip_global.distance_squared_to(nock_global) > 0.001:
		_bow_string_top.look_at(nock_global, Vector3.UP)
	_bow_string_top.scale.z = top_tip_local.distance_to(nock_local)
	
	_bow_string_bottom.global_position = (bottom_tip_global + nock_global) / 2.0
	if bottom_tip_global.distance_squared_to(nock_global) > 0.001:
		_bow_string_bottom.look_at(nock_global, Vector3.UP)
	_bow_string_bottom.scale.z = bottom_tip_local.distance_to(nock_local)
	
	_loaded_arrow_mesh.position = Vector3(0, 0, nock_z - 0.34)


func _animate_idle() -> void:
	var breath := sin(_animation_time * 1.8) * 0.018
	_body_mesh.scale.y += breath
	_head_mesh.position.y += breath * 0.35


func _update_hit_flash() -> void:
	var should_flash := _flash_time > 0.0
	if should_flash == _flash_visible:
		return

	_flash_visible = should_flash
	if _uses_imported_visuals:
		if _imported_visual != null and _imported_visual.has_method("set_hit_flash"):
			_imported_visual.call("set_hit_flash", _flash_visible)
		return

	var cloth_material := _hit_material if _flash_visible else _cloth_material
	var skin_material := _hit_material if _flash_visible else _base_material
	if _body_mesh != null:
		_body_mesh.material_override = cloth_material
	for mesh in [_head_mesh, _left_arm_mesh, _right_arm_mesh, _left_leg_mesh, _right_leg_mesh]:
		if mesh != null:
			mesh.material_override = skin_material


func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var key := "%.3f:%.3f:%.3f:%.3f:%.3f" % [color.r, color.g, color.b, color.a, roughness]
	if _material_cache.has(key):
		return _material_cache[key] as StandardMaterial3D

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	_material_cache[key] = material
	return material
