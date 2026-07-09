extends CharacterBody3D

const SlingStone := preload("res://scripts/sling_stone.gd")

const LOOK_GROUND_LIMIT := deg_to_rad(-84.0)
const LOOK_SKY_LIMIT := deg_to_rad(84.0)
const FULL_CHARGE_RATIO := 1.0
const SLING_RELEASE_SECONDS := 0.22
const SLING_REST_POSITION := Vector3(0.34, -0.34, -0.76)
const SLING_OVERHEAD_POSITION := Vector3(0.42, 0.34, -0.16)
const SLING_WRIST_LOCAL := Vector3.ZERO
const SLING_HEAD_SWING_CENTER := Vector3(0.0, -0.08, -0.10)
const SLING_HEAD_SWING_RADIUS := 0.46
const SLING_FULL_ROTATION_RELEASE_PHASE := TAU
const SLING_CHARGE_ROTATIONS := 2.0
const SLING_FULL_CHARGE_PHASE := TAU * SLING_CHARGE_ROTATIONS
const SLING_FULL_SPEED := 14.0
const SLING_RELEASE_WINDOW_SECONDS := 0.25
const BASE_CAMERA_FOV := 70.0
const AIM_ZOOM_MULTIPLIER := 1.5
const CAMERA_ZOOM_LERP_SPEED := 14.0
const BACKPEDAL_SPEED_DIVISOR := 2.0
const STRAFE_SPEED_DIVISOR := 1.3
const CROUCH_TOGGLE_KEY := KEY_C
const CROUCH_HOLD_KEY := KEY_CTRL

@export var move_speed := 6.0
@export var sprint_multiplier := 1.45
@export var jump_velocity := 6.8
@export var gravity := 20.0
@export var air_control_acceleration := 2.2
@export var charging_move_multiplier := 0.45
@export var crouch_move_multiplier := 0.52
@export var crouch_collision_height := 1.15
@export var crouch_camera_height := 1.05
@export var crouch_transition_speed := 11.0
@export var crouch_slide_min_slope := 0.035
@export var crouch_slide_full_slope := 0.18
@export var crouch_slide_acceleration := 32.0
@export var crouch_slide_max_speed := 14.0
@export var crouch_slide_brake := 10.0
@export var crouch_slide_steering_multiplier := 0.22
@export var mouse_sensitivity := 0.0025
@export var min_throw_speed := 13.0
@export var max_throw_speed := 45.0
@export var max_charge_time := 1.35
@export var max_health := 50
@export var damage_knockback := 3.2

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var sling_hand: Marker3D = $SlingHand
@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var aiming := false
var charging := false
var charge_time := 0.0
var yaw := 0.0
var pitch := -0.18
var sling_view_root: Node3D
var sling_arm: MeshInstance3D
var sling_hand_mesh: MeshInstance3D
var sling_cord_left: MeshInstance3D
var sling_cord_right: MeshInstance3D
var sling_pouch: MeshInstance3D
var sling_loaded_stone: MeshInstance3D
var sling_pouch_marker: Marker3D
var sling_phase := 0.0
var sling_previous_phase := 0.0
var sling_release_time := 0.0
var sling_release_power := 0.0
var sling_release_queued := false
var health := max_health
var last_damage_taken := 0
var damage_flash_time := 0.0
var _damage_invulnerability_time := 0.0
var _crouch_toggled := false
var _sliding := false
var _crouch_slide_velocity := Vector3.ZERO
var _crouch_slide_direction := Vector3.ZERO
var _body_shape: CapsuleShape3D
var _body_mesh_shape: CapsuleMesh
var _standing_collision_height := 1.8
var _standing_collision_y := 0.9
var _standing_camera_position := Vector3.ZERO
var _standing_sling_hand_position := Vector3.ZERO
var _standing_body_mesh_y := 0.9


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.fov = BASE_CAMERA_FOV
	body_mesh.visible = false
	health = max_health
	_capture_standing_height()
	_build_sling_view_model()
	_apply_camera_rotation()
	_update_sling_view_model(0.0)


func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _unhandled_input(event: InputEvent) -> void:
	var mouse_motion := event as InputEventMouseMotion
	if mouse_motion != null:
		yaw -= mouse_motion.relative.x * mouse_sensitivity
		pitch = clampf(pitch - mouse_motion.relative.y * mouse_sensitivity, LOOK_GROUND_LIMIT, LOOK_SKY_LIMIT)
		_apply_camera_rotation()
		return

	var key_event := event as InputEventKey
	if key_event != null:
		if key_event.pressed and not key_event.echo and _is_crouch_toggle_event(key_event):
			_crouch_toggled = not _crouch_toggled
		return

	var mouse_button := event as InputEventMouseButton
	if mouse_button == null:
		return

	if mouse_button.button_index == MOUSE_BUTTON_RIGHT:
		aiming = mouse_button.pressed
		return

	if mouse_button.button_index == MOUSE_BUTTON_LEFT:
		if mouse_button.pressed:
			if sling_release_queued:
				return
			charging = true
			charge_time = 0.0
			sling_phase = 0.0
			sling_previous_phase = 0.0
			sling_release_time = 0.0
		elif charging:
			if _is_fully_charged():
				_try_full_charge_release()
			else:
				_cancel_sling_charge()


func _process(delta: float) -> void:
	damage_flash_time = maxf(0.0, damage_flash_time - delta)
	_damage_invulnerability_time = maxf(0.0, _damage_invulnerability_time - delta)
	_update_camera_zoom(delta)
	_update_sling_view_model(delta)


func _physics_process(delta: float) -> void:
	if charging:
		charge_time = minf(charge_time + delta, max_charge_time)

	var grounded := is_on_floor()
	var jump_pressed := grounded and Input.is_key_pressed(KEY_SPACE)
	if jump_pressed:
		_crouch_toggled = false
	var crouching := is_crouching()
	var was_sliding := _sliding
	var previous_flat_velocity := Vector3(velocity.x, 0.0, velocity.z)
	_update_crouch_height(delta, crouching)
	var input_vector := _movement_input()
	var adjusted_input := _adjusted_local_movement(input_vector)
	var forward := -global_transform.basis.z
	var right := global_transform.basis.x
	var direction := forward * adjusted_input.y + right * adjusted_input.x
	var speed := move_speed
	if charging or sling_release_queued:
		speed *= charging_move_multiplier
	if crouching:
		speed *= crouch_move_multiplier
	elif grounded and not was_sliding and Input.is_key_pressed(KEY_SHIFT):
		speed *= sprint_multiplier

	if grounded:
		var drive_velocity := direction * speed
		_update_crouch_slide_velocity(delta, crouching, previous_flat_velocity)
		if crouching and _crouch_slide_direction != Vector3.ZERO:
			drive_velocity = _slide_limited_drive_velocity(drive_velocity)
		var flat_velocity := drive_velocity + _crouch_slide_velocity
		velocity.x = flat_velocity.x
		velocity.z = flat_velocity.z
		if jump_pressed:
			velocity.y = jump_velocity
		else:
			velocity.y = -0.1
	else:
		_sliding = false
		velocity.x = move_toward(velocity.x, direction.x * speed, air_control_acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, air_control_acceleration * delta)
		velocity.y -= gravity * delta

	move_and_slide()


func get_charge_ratio() -> float:
	if sling_release_queued:
		return FULL_CHARGE_RATIO
	if not charging:
		return 0.0
	return charge_time / max_charge_time


func is_release_queued() -> bool:
	return sling_release_queued


func is_crouching() -> bool:
	return _crouch_toggled or Input.is_key_pressed(CROUCH_HOLD_KEY)


func is_sliding() -> bool:
	return _sliding


func take_damage(damage: int, source_position := Vector3.ZERO) -> void:
	if damage <= 0 or _damage_invulnerability_time > 0.0:
		return

	health = maxi(0, health - damage)
	last_damage_taken = damage
	damage_flash_time = 0.35
	_damage_invulnerability_time = 0.45

	var knockback := global_position - source_position
	knockback.y = 0.0
	if knockback.length() > 0.01:
		knockback = knockback.normalized()
		velocity.x += knockback.x * damage_knockback
		velocity.z += knockback.z * damage_knockback
		velocity.y = maxf(velocity.y, 2.0)


func get_health_text() -> String:
	return "Health: %d/%d" % [health, max_health]


func is_recently_damaged() -> bool:
	return damage_flash_time > 0.0


func _movement_input() -> Vector2:
	var input_vector := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_vector.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_vector.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_vector.y -= 1.0
	return input_vector.normalized()


func _adjusted_local_movement(input_vector: Vector2) -> Vector2:
	var adjusted := input_vector
	adjusted.x /= STRAFE_SPEED_DIVISOR
	if adjusted.y < 0.0:
		adjusted.y /= BACKPEDAL_SPEED_DIVISOR
	return adjusted


func _is_crouch_toggle_event(key_event: InputEventKey) -> bool:
	return key_event.keycode == CROUCH_TOGGLE_KEY or key_event.physical_keycode == CROUCH_TOGGLE_KEY


func _capture_standing_height() -> void:
	_standing_camera_position = camera_pivot.position
	_standing_sling_hand_position = sling_hand.position
	if collision_shape != null:
		_standing_collision_y = collision_shape.position.y
		_body_shape = collision_shape.shape as CapsuleShape3D
		if _body_shape != null:
			_body_shape = _body_shape.duplicate() as CapsuleShape3D
			collision_shape.shape = _body_shape
			_standing_collision_height = _body_shape.height
	if body_mesh != null:
		_standing_body_mesh_y = body_mesh.position.y
		_body_mesh_shape = body_mesh.mesh as CapsuleMesh
		if _body_mesh_shape != null:
			_body_mesh_shape = _body_mesh_shape.duplicate() as CapsuleMesh
			body_mesh.mesh = _body_mesh_shape


func _update_crouch_height(delta: float, crouching: bool) -> void:
	if collision_shape == null or camera_pivot == null:
		return

	var target_collision_height := _standing_collision_height
	var target_camera_y := _standing_camera_position.y
	if crouching:
		target_collision_height = minf(crouch_collision_height, _standing_collision_height)
		target_camera_y = minf(crouch_camera_height, _standing_camera_position.y)

	var weight := clampf(crouch_transition_speed * delta, 0.0, 1.0)
	var current_collision_height := _standing_collision_height
	if _body_shape != null:
		current_collision_height = _body_shape.height
	var new_collision_height := lerpf(current_collision_height, target_collision_height, weight)
	var height_ratio := new_collision_height / maxf(_standing_collision_height, 0.01)
	var target_collision_y := _standing_collision_y * height_ratio

	if _body_shape != null:
		_body_shape.height = new_collision_height
	collision_shape.position.y = lerpf(collision_shape.position.y, target_collision_y, weight)

	var camera_position := camera_pivot.position
	camera_position.y = lerpf(camera_position.y, target_camera_y, weight)
	camera_pivot.position = camera_position

	var camera_drop := _standing_camera_position.y - camera_pivot.position.y
	sling_hand.position = _standing_sling_hand_position - Vector3(0.0, camera_drop, 0.0)
	if body_mesh != null:
		var body_position := body_mesh.position
		body_position.y = lerpf(body_position.y, _standing_body_mesh_y * height_ratio, weight)
		body_mesh.position = body_position
	if _body_mesh_shape != null:
		_body_mesh_shape.height = new_collision_height


func _update_crouch_slide_velocity(delta: float, crouching: bool, previous_flat_velocity: Vector3) -> void:
	var was_sliding := _sliding
	_sliding = false
	if not crouching:
		_brake_crouch_slide(delta)
		return

	var ground_normal := _combat_terrain_normal()
	if ground_normal == Vector3.ZERO:
		_brake_crouch_slide(delta)
		return

	var slope := 1.0 - clampf(ground_normal.dot(Vector3.UP), 0.0, 1.0)
	if slope < crouch_slide_min_slope:
		_brake_crouch_slide(delta)
		return

	var downhill := Vector3.DOWN.slide(ground_normal)
	downhill.y = 0.0
	if downhill.length_squared() <= 0.0001:
		_brake_crouch_slide(delta)
		return

	downhill = downhill.normalized()
	_crouch_slide_direction = downhill
	var slide_weight := smoothstep(crouch_slide_min_slope, crouch_slide_full_slope, slope)
	var downhill_speed := maxf(_crouch_slide_velocity.dot(downhill), 0.0)
	if not was_sliding:
		downhill_speed = maxf(downhill_speed, _slide_entry_downhill_speed(previous_flat_velocity, downhill))
	var slide_acceleration := crouch_slide_acceleration * slide_weight
	downhill_speed += slide_acceleration * delta

	var max_flat_speed := maxf(crouch_slide_max_speed, _slide_entry_downhill_speed(previous_flat_velocity, downhill))
	downhill_speed = minf(downhill_speed, max_flat_speed)
	_crouch_slide_velocity = downhill * downhill_speed

	_sliding = slide_weight > 0.05 and downhill_speed > move_speed * crouch_move_multiplier * 0.35


func _brake_crouch_slide(delta: float) -> void:
	_crouch_slide_velocity = _crouch_slide_velocity.move_toward(Vector3.ZERO, crouch_slide_brake * delta)
	if _crouch_slide_velocity.length_squared() <= 0.0001:
		_crouch_slide_velocity = Vector3.ZERO
		_crouch_slide_direction = Vector3.ZERO


func _entry_downhill_speed(previous_flat_velocity: Vector3, downhill: Vector3) -> float:
	return maxf(previous_flat_velocity.dot(downhill), 0.0)


func _slide_entry_downhill_speed(previous_flat_velocity: Vector3, downhill: Vector3) -> float:
	return minf(_entry_downhill_speed(previous_flat_velocity, downhill), move_speed)


func _slide_limited_drive_velocity(drive_velocity: Vector3) -> Vector3:
	var downhill_amount := drive_velocity.dot(_crouch_slide_direction)
	var lateral_velocity := drive_velocity - _crouch_slide_direction * downhill_amount
	return _crouch_slide_direction * maxf(downhill_amount, 0.0) + lateral_velocity * crouch_slide_steering_multiplier


func _combat_terrain_normal() -> Vector3:
	var terrain_owner := get_tree().current_scene
	if terrain_owner != null and terrain_owner.has_method("get_combat_terrain_normal"):
		var terrain_normal = terrain_owner.call("get_combat_terrain_normal", global_position)
		if terrain_normal is Vector3:
			return terrain_normal

	var floor_normal := get_floor_normal()
	if floor_normal.length_squared() > 0.0001:
		return floor_normal
	return Vector3.UP


func _apply_camera_rotation() -> void:
	rotation.y = yaw
	camera_pivot.rotation.x = pitch


func _update_camera_zoom(delta: float) -> void:
	if camera == null:
		return
	var target_fov := BASE_CAMERA_FOV
	if aiming:
		target_fov = _fov_for_zoom_multiplier(BASE_CAMERA_FOV, AIM_ZOOM_MULTIPLIER)
	camera.fov = lerpf(camera.fov, target_fov, clampf(CAMERA_ZOOM_LERP_SPEED * delta, 0.0, 1.0))


func _fov_for_zoom_multiplier(base_fov: float, zoom_multiplier: float) -> float:
	return rad_to_deg(atan(tan(deg_to_rad(base_fov) * 0.5) / zoom_multiplier) * 2.0)


func _throw_stone(charge_ratio: float) -> void:
	var stone := RigidBody3D.new()
	stone.name = "SlingStone"
	stone.set_script(SlingStone)
	stone.mass = 0.18
	stone.gravity_scale = 1.0

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.09
	sphere.height = 0.18
	mesh.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#7a7469")
	mesh.material_override = material
	stone.add_child(mesh)

	var shape := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 0.09
	shape.shape = sphere_shape
	stone.add_child(shape)

	get_tree().current_scene.add_child(stone)
	stone.add_collision_exception_with(self)

	var throw_direction := -camera.global_transform.basis.z
	var launch_origin := sling_hand.global_position
	if sling_pouch_marker != null:
		launch_origin = sling_pouch_marker.global_position
	var speed := lerpf(min_throw_speed, max_throw_speed, charge_ratio)
	stone.launch(launch_origin, throw_direction, speed)


func _build_sling_view_model() -> void:
	var skin_material := _make_view_material(Color("#9d6f48"), 0.82)
	var leather_material := _make_view_material(Color("#5f3a24"), 0.9)
	var cord_material := _make_view_material(Color("#d6be87"), 0.96)
	var stone_material := _make_view_material(Color("#7a7469"), 0.98)

	sling_view_root = Node3D.new()
	sling_view_root.name = "SlingViewModel"
	camera.add_child(sling_view_root)

	sling_arm = _add_view_cylinder(sling_view_root, "SlingForearm", 0.055, 0.56, skin_material)
	sling_arm.position = Vector3(0.02, -0.10, 0.17)
	sling_arm.rotation_degrees = Vector3(83.0, -4.0, -9.0)

	sling_hand_mesh = MeshInstance3D.new()
	sling_hand_mesh.name = "SlingHandMesh"
	var hand_mesh := SphereMesh.new()
	hand_mesh.radius = 0.075
	hand_mesh.height = 0.12
	sling_hand_mesh.mesh = hand_mesh
	sling_hand_mesh.scale = Vector3(1.12, 0.82, 0.72)
	sling_hand_mesh.material_override = skin_material
	sling_view_root.add_child(sling_hand_mesh)

	sling_cord_left = _add_view_cylinder(sling_view_root, "SlingCordLeft", 0.006, 1.0, cord_material)
	sling_cord_right = _add_view_cylinder(sling_view_root, "SlingCordRight", 0.006, 1.0, cord_material)

	sling_pouch = MeshInstance3D.new()
	sling_pouch.name = "SlingLeatherPouch"
	var pouch_mesh := SphereMesh.new()
	pouch_mesh.radius = 0.09
	pouch_mesh.height = 0.05
	sling_pouch.mesh = pouch_mesh
	sling_pouch.scale = Vector3(1.45, 0.42, 0.82)
	sling_pouch.material_override = leather_material
	sling_view_root.add_child(sling_pouch)

	sling_loaded_stone = MeshInstance3D.new()
	sling_loaded_stone.name = "LoadedSlingStone"
	var loaded_stone_mesh := SphereMesh.new()
	loaded_stone_mesh.radius = 0.035
	loaded_stone_mesh.height = 0.07
	sling_loaded_stone.mesh = loaded_stone_mesh
	sling_loaded_stone.material_override = stone_material
	sling_view_root.add_child(sling_loaded_stone)

	sling_pouch_marker = Marker3D.new()
	sling_pouch_marker.name = "SlingPouchMarker"
	sling_view_root.add_child(sling_pouch_marker)


func _make_view_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.no_depth_test = true
	return material


func _add_view_cylinder(parent: Node, node_name: String, radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance


func _start_sling_release(charge_ratio: float) -> void:
	sling_release_time = SLING_RELEASE_SECONDS
	sling_release_power = maxf(charge_ratio, 0.18)


func _update_sling_view_model(delta: float) -> void:
	if sling_view_root == null:
		return

	var charge_ratio := get_charge_ratio()
	var was_ready_to_release := _is_fully_charged() or sling_release_queued
	if was_ready_to_release:
		sling_previous_phase = sling_phase
		if charging and sling_phase < SLING_FULL_CHARGE_PHASE:
			sling_phase = SLING_FULL_CHARGE_PHASE
			sling_previous_phase = sling_phase
		else:
			sling_phase += delta * _full_sling_speed()
		if sling_release_queued and _crossed_full_rotation_release_point(sling_previous_phase, sling_phase):
			_finish_timed_release()
			charge_ratio = FULL_CHARGE_RATIO
	elif charging:
		sling_previous_phase = sling_phase
		sling_phase = _charging_phase_for_ratio(charge_ratio)
	else:
		sling_phase = lerpf(sling_phase, -0.65, minf(delta * 7.0, 1.0))
		sling_previous_phase = sling_phase

	if sling_release_time > 0.0:
		sling_release_time = maxf(0.0, sling_release_time - delta)

	var aim_weight := 1.0 if aiming else 0.0
	var spin_weight := 1.0 if charging or sling_release_queued or sling_release_time > 0.0 else 0.0
	sling_view_root.position = SLING_REST_POSITION.lerp(SLING_OVERHEAD_POSITION, smoothstep(0.0, 1.0, spin_weight))
	if aiming:
		sling_view_root.position.z -= 0.05
	sling_view_root.rotation_degrees = Vector3(
		0.0,
		-8.0 + aim_weight * 6.0,
		0.0
	)

	var pouch_local := _sling_pouch_position(charge_ratio, was_ready_to_release)

	if sling_release_time > 0.0:
		var release_ratio := 1.0 - sling_release_time / SLING_RELEASE_SECONDS
		var release_curve := sin(release_ratio * PI)
		pouch_local = pouch_local.lerp(
			Vector3(0.02, 0.12 + sling_release_power * 0.05, -0.58 - sling_release_power * 0.18),
			release_curve
		)

	sling_hand_mesh.position = SLING_WRIST_LOCAL
	sling_hand_mesh.rotation_degrees = Vector3(8.0 + charge_ratio * 12.0, -12.0, 7.0)

	sling_arm.rotation_degrees = Vector3(83.0 - spin_weight * 38.0, -4.0 + aim_weight * 7.0, -9.0 - spin_weight * 20.0)
	sling_arm.position = Vector3(0.02, -0.10 + spin_weight * 0.03, 0.17 - spin_weight * 0.08)

	var left_anchor := SLING_WRIST_LOCAL + Vector3(-0.024, 0.006, -0.012)
	var right_anchor := SLING_WRIST_LOCAL + Vector3(0.028, -0.008, -0.012)
	var pouch_left := pouch_local + Vector3(-0.045, 0.0, 0.01)
	var pouch_right := pouch_local + Vector3(0.045, 0.0, 0.01)
	_set_cylinder_between(sling_cord_left, left_anchor, pouch_left)
	_set_cylinder_between(sling_cord_right, right_anchor, pouch_right)

	sling_pouch.position = pouch_local
	sling_pouch.rotation_degrees = Vector3(0.0, -rad_to_deg(sling_phase), 0.0)
	sling_loaded_stone.position = pouch_local + Vector3(0.0, 0.02, 0.0)
	sling_loaded_stone.visible = charging or sling_release_queued or sling_release_time <= 0.0
	sling_pouch_marker.position = pouch_local


func _is_fully_charged() -> bool:
	return charging and charge_time >= max_charge_time


func _cancel_sling_charge() -> void:
	charging = false
	charge_time = 0.0
	sling_release_queued = false
	sling_release_power = 0.0


func _queue_timed_release() -> void:
	charging = false
	charge_time = max_charge_time
	sling_release_queued = true
	sling_release_power = FULL_CHARGE_RATIO


func _try_full_charge_release() -> void:
	if sling_phase < SLING_FULL_CHARGE_PHASE:
		sling_phase = SLING_FULL_CHARGE_PHASE
		sling_previous_phase = sling_phase

	if _is_sling_in_release_window():
		_finish_timed_release()
	else:
		_queue_timed_release()


func _is_sling_in_release_window() -> bool:
	var wrapped_phase := fposmod(sling_phase, TAU)
	var half_window_phase := _release_window_half_phase()
	return wrapped_phase <= half_window_phase or wrapped_phase >= TAU - half_window_phase


func _crossed_full_rotation_release_point(previous_phase: float, current_phase: float) -> bool:
	return floor(previous_phase / SLING_FULL_ROTATION_RELEASE_PHASE) < floor(current_phase / SLING_FULL_ROTATION_RELEASE_PHASE)


func _finish_timed_release() -> void:
	charging = false
	sling_release_queued = false
	_throw_stone(FULL_CHARGE_RATIO)
	_start_sling_release(FULL_CHARGE_RATIO)
	charge_time = 0.0
	sling_phase = fmod(sling_phase, TAU)
	sling_previous_phase = sling_phase


func _sling_pouch_position(charge_ratio: float, is_ready_to_release: bool) -> Vector3:
	if charging or is_ready_to_release:
		return SLING_HEAD_SWING_CENTER + Vector3(
			SLING_HEAD_SWING_RADIUS * cos(sling_phase),
			0.0,
			-SLING_HEAD_SWING_RADIUS * sin(sling_phase)
		)

	var low_position := Vector3(-0.02, -0.12, -0.28)
	var rest_position := Vector3(0.0, -0.15, -0.12)
	return low_position.lerp(rest_position, smoothstep(0.0, 1.0, charge_ratio))


func _charging_phase_for_ratio(charge_ratio: float) -> float:
	var target_slope := clampf(_full_sling_speed() * max_charge_time / SLING_FULL_CHARGE_PHASE, 1.05, 1.95)
	var cubic_weight := target_slope - 2.0
	var square_weight := 3.0 - target_slope
	var eased_ratio := cubic_weight * charge_ratio * charge_ratio * charge_ratio + square_weight * charge_ratio * charge_ratio
	return SLING_FULL_CHARGE_PHASE * eased_ratio


func _full_sling_speed() -> float:
	return SLING_FULL_SPEED


func _release_window_half_phase() -> float:
	return minf(PI - 0.05, _full_sling_speed() * SLING_RELEASE_WINDOW_SECONDS * 0.5)


func _set_cylinder_between(cylinder: MeshInstance3D, start: Vector3, finish: Vector3) -> void:
	var direction := finish - start
	var length := direction.length()
	if length <= 0.001:
		cylinder.visible = false
		return

	cylinder.visible = true
	var local_y := direction / length
	var local_x := local_y.cross(Vector3.FORWARD)
	if local_x.length() <= 0.001:
		local_x = local_y.cross(Vector3.RIGHT)
	local_x = local_x.normalized()
	var local_z := local_x.cross(local_y).normalized()
	cylinder.transform = Transform3D(Basis(local_x, local_y, local_z), start.lerp(finish, 0.5))
	cylinder.scale = Vector3(1.0, length, 1.0)
