extends CharacterBody3D

const SIZE_SCALE := 1.75
const GRAVITY := 22.0
const GROUND_STICK_VELOCITY := -0.25
const BODY_LENGTH := 1.45
const ATTACK_DAMAGE := 18
const HEADSHOT_MULTIPLIER := 2
const HEAD_CENTER := Vector3(1.04, 0.7, 0.0)
const HEAD_RADIUS := Vector3(0.5, 0.42, 0.42)
const DETAIL_MESH_GROUP := "lion_detail_mesh"
const WALK_CYCLE_SPEED := 8.5
const WALK_BOB_HEIGHT := 0.075
const WALK_HEAD_BOB := 0.012
const WALK_HEAD_CYCLE_SCALE := 0.45
const ATTACK_STRETCH := 0.24

@export var chase_speed := 5.3
@export var leap_speed := 15.75
@export var leap_up_velocity := 5.6
@export var attack_range := 7.2
@export var bite_range := 2.05
@export var max_health := 72

var target: Node3D
var terrain_owner: Node
var health := max_health

var _leaping := false
var _attack_cooldown := 1.0
var _recovery_time := 0.0
var _has_hit_this_leap := false
var _flash_time := 0.0
var _base_material: StandardMaterial3D
var _hit_material: StandardMaterial3D
var _animation_time := 0.0
var _body_mesh: MeshInstance3D
var _chest_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D
var _muzzle_mesh: MeshInstance3D
var _tail_mesh: MeshInstance3D
var _tail_tuft_mesh: MeshInstance3D
var _leg_meshes: Array[MeshInstance3D] = []
var _animated_meshes: Array[MeshInstance3D] = []
var _base_positions: Array[Vector3] = []
var _base_scales: Array[Vector3] = []
var _base_rotations: Array[Vector3] = []


func setup(new_target: Node3D, new_terrain_owner: Node) -> void:
	target = new_target
	terrain_owner = new_terrain_owner


func _ready() -> void:
	health = max_health
	_base_material = _make_material(Color("#b98743"), 0.88)
	_hit_material = _make_material(Color("#7c241c"), 0.72)
	_build_body()


func _physics_process(delta: float) -> void:
	if health <= 0:
		return

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_recovery_time = maxf(0.0, _recovery_time - delta)
	_flash_time = maxf(0.0, _flash_time - delta)
	_update_hit_flash()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif not _leaping:
		velocity.y = GROUND_STICK_VELOCITY

	if target == null:
		move_and_slide()
		_animate_body(delta, Vector3(velocity.x, 0.0, velocity.z).length())
		return

	var to_target := target.global_position - global_position
	var flat_to_target := Vector3(to_target.x, 0.0, to_target.z)
	var distance := flat_to_target.length()
	var direction := Vector3.ZERO
	if distance > 0.05:
		direction = flat_to_target / distance
		_face_direction(direction, delta)

	if _leaping:
		_check_leap_hit(distance)
		if is_on_floor() and velocity.y <= 0.0:
			_leaping = false
			_recovery_time = 0.55
			_attack_cooldown = 1.25
	elif _recovery_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, chase_speed * delta * 3.0)
		velocity.z = move_toward(velocity.z, 0.0, chase_speed * delta * 3.0)
	elif distance <= attack_range and _attack_cooldown <= 0.0 and is_on_floor():
		_start_leap(direction)
	elif direction != Vector3.ZERO:
		velocity.x = direction.x * chase_speed
		velocity.z = direction.z * chase_speed

	move_and_slide()
	_check_slide_hit()
	_animate_body(delta, Vector3(velocity.x, 0.0, velocity.z).length())


func take_hit(damage: int) -> void:
	_apply_damage(damage)


func take_projectile_hit(damage: int, hit_position: Vector3) -> int:
	var final_damage := damage
	if is_projectile_headshot(hit_position):
		final_damage *= HEADSHOT_MULTIPLIER
	_apply_damage(final_damage)
	return final_damage


func is_projectile_headshot(hit_position: Vector3, hit_shape_name := "") -> bool:
	return hit_shape_name == "HeadHitShape" or _is_headshot(hit_position)


func _apply_damage(damage: int) -> void:
	if health <= 0:
		return

	health = maxi(0, health - damage)
	_flash_time = 0.18
	if health <= 0:
		_die()


func _start_leap(direction: Vector3) -> void:
	if direction == Vector3.ZERO:
		return

	_leaping = true
	_has_hit_this_leap = false
	velocity = direction * leap_speed
	velocity.y = leap_up_velocity


func _check_leap_hit(distance: float) -> void:
	if _has_hit_this_leap or target == null:
		return
	if distance > bite_range:
		return
	if target.has_method("take_damage"):
		target.take_damage(ATTACK_DAMAGE, global_position)
		_has_hit_this_leap = true


func _check_slide_hit() -> void:
	if not _leaping or _has_hit_this_leap:
		return

	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider != null and collider == target and collider.has_method("take_damage"):
			collider.take_damage(ATTACK_DAMAGE, global_position)
			_has_hit_this_leap = true
			return


func _die() -> void:
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.0, 0.18, 1.0), 0.18)
	tween.tween_callback(Callable(self, "queue_free"))


func _face_direction(direction: Vector3, delta: float) -> void:
	var desired_yaw := atan2(direction.x, direction.z) - PI * 0.5
	rotation.y = lerp_angle(rotation.y, desired_yaw, minf(delta * 9.0, 1.0))


func _update_hit_flash() -> void:
	var material := _hit_material if _flash_time > 0.0 else _base_material
	for child in get_children():
		var mesh := child as MeshInstance3D
		if mesh != null and not child.is_in_group(DETAIL_MESH_GROUP):
			mesh.material_override = material


func _is_headshot(hit_position: Vector3) -> bool:
	var local_hit := to_local(hit_position)
	var head_center := _scaled(HEAD_CENTER)
	var head_radius := _scaled(HEAD_RADIUS)
	var normalized_offset := Vector3(
		(local_hit.x - head_center.x) / head_radius.x,
		(local_hit.y - head_center.y) / head_radius.y,
		(local_hit.z - head_center.z) / head_radius.z
	)
	return normalized_offset.length() <= 1.0


func _build_body() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34 * SIZE_SCALE
	capsule.height = BODY_LENGTH * SIZE_SCALE
	shape.shape = capsule
	shape.rotation_degrees.z = 90.0
	shape.position.y = capsule.radius
	add_child(shape)

	var head_shape := CollisionShape3D.new()
	head_shape.name = "HeadHitShape"
	var head_sphere := SphereShape3D.new()
	head_sphere.radius = 0.42 * SIZE_SCALE
	head_shape.shape = head_sphere
	head_shape.position = _scaled(HEAD_CENTER)
	add_child(head_shape)

	_body_mesh = _add_ellipsoid("Body", _scaled(Vector3(0.0, 0.52, 0.0)), _scaled(Vector3(1.35, 0.48, 0.58)), Color("#b98743"))
	_chest_mesh = _add_ellipsoid("Chest", _scaled(Vector3(0.52, 0.58, 0.0)), _scaled(Vector3(0.62, 0.54, 0.62)), Color("#b98743"))
	_head_mesh = _add_ellipsoid("Head", _scaled(Vector3(1.04, 0.7, 0.0)), _scaled(Vector3(0.42, 0.34, 0.34)), Color("#b98743"))
	_muzzle_mesh = _add_ellipsoid("Muzzle", _scaled(Vector3(1.32, 0.66, 0.0)), _scaled(Vector3(0.24, 0.16, 0.2)), Color("#d6bd80"), true)
	_tail_mesh = _add_ellipsoid("Tail", _scaled(Vector3(-0.9, 0.72, 0.0)), _scaled(Vector3(0.58, 0.12, 0.12)), Color("#b98743"))
	_tail_tuft_mesh = _add_ellipsoid("TailTuft", _scaled(Vector3(-1.34, 0.75, 0.0)), _scaled(Vector3(0.22, 0.2, 0.18)), Color("#3a2417"), true)
	_add_ellipsoid("ManeChest", _scaled(Vector3(0.68, 0.72, 0.0)), _scaled(Vector3(0.48, 0.62, 0.68)), Color("#4c2f1b"), true)
	_add_ellipsoid("ManeCrown", _scaled(Vector3(0.96, 0.9, 0.0)), _scaled(Vector3(0.45, 0.28, 0.42)), Color("#3b2416"), true)
	_add_ellipsoid("ManeThroat", _scaled(Vector3(0.88, 0.45, 0.0)), _scaled(Vector3(0.38, 0.3, 0.46)), Color("#4a2d19"), true)
	_add_ellipsoid("LeftManeCheek", _scaled(Vector3(0.92, 0.66, -0.28)), _scaled(Vector3(0.3, 0.32, 0.18)), Color("#3f2818"), true)
	_add_ellipsoid("RightManeCheek", _scaled(Vector3(0.92, 0.66, 0.28)), _scaled(Vector3(0.3, 0.32, 0.18)), Color("#3f2818"), true)
	_add_ellipsoid("LeftEar", _scaled(Vector3(0.92, 1.0, -0.22)), _scaled(Vector3(0.13, 0.19, 0.09)), Color("#5d351c"), true)
	_add_ellipsoid("RightEar", _scaled(Vector3(0.92, 1.0, 0.22)), _scaled(Vector3(0.13, 0.19, 0.09)), Color("#5d351c"), true)
	_add_eye(Vector3(1.25, 0.78, -0.16))
	_add_eye(Vector3(1.25, 0.78, 0.16))

	for x in [-0.48, 0.48]:
		for z in [-0.22, 0.22]:
			_add_leg(_scaled(Vector3(x, 0.25, z)))


func _add_ellipsoid(node_name: String, position: Vector3, node_scale: Vector3, color: Color, is_detail := false) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.scale = node_scale
	mesh_instance.material_override = _make_material(color, 0.9)
	if is_detail:
		mesh_instance.add_to_group(DETAIL_MESH_GROUP)
	add_child(mesh_instance)
	_remember_animation_node(mesh_instance)
	return mesh_instance


func _add_eye(position: Vector3) -> void:
	var eye := MeshInstance3D.new()
	eye.name = "AmberEye"
	var mesh := SphereMesh.new()
	mesh.radius = 0.045 * SIZE_SCALE
	mesh.height = 0.09 * SIZE_SCALE
	eye.mesh = mesh
	eye.position = _scaled(position)
	eye.scale = Vector3(1.0, 0.72, 0.72)
	eye.material_override = _make_material(Color("#d39a22"), 0.42)
	eye.add_to_group(DETAIL_MESH_GROUP)
	add_child(eye)
	_remember_animation_node(eye)


func _add_leg(position: Vector3) -> void:
	var leg := MeshInstance3D.new()
	leg.name = "Leg"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.07 * SIZE_SCALE
	mesh.bottom_radius = 0.09 * SIZE_SCALE
	mesh.height = 0.56 * SIZE_SCALE
	mesh.radial_segments = 8
	leg.mesh = mesh
	leg.position = position
	leg.rotation_degrees.z = 7.0 if position.x > 0.0 else -7.0
	leg.material_override = _base_material
	add_child(leg)
	_leg_meshes.append(leg)
	_remember_animation_node(leg)


func _remember_animation_node(mesh: MeshInstance3D) -> void:
	_animated_meshes.append(mesh)
	_base_positions.append(mesh.position)
	_base_scales.append(mesh.scale)
	_base_rotations.append(mesh.rotation_degrees)


func _animate_body(delta: float, flat_speed: float) -> void:
	_animation_time += delta * maxf(flat_speed, 0.5)
	_restore_animation_pose()

	if _leaping:
		_animate_leap_attack()
		return

	var walk_weight := clampf(flat_speed / chase_speed, 0.0, 1.0)
	if _recovery_time > 0.0:
		_animate_attack_recovery()
	elif walk_weight > 0.05:
		_animate_walk(walk_weight)
	else:
		_animate_idle(delta)


func _restore_animation_pose() -> void:
	for index in range(_animated_meshes.size()):
		var mesh := _animated_meshes[index]
		if mesh == null:
			continue
		mesh.position = _base_positions[index]
		mesh.scale = _base_scales[index]
		mesh.rotation_degrees = _base_rotations[index]


func _animate_walk(weight: float) -> void:
	var phase := _animation_time * WALK_CYCLE_SPEED
	var bob := sin(phase * 2.0) * WALK_BOB_HEIGHT * SIZE_SCALE * weight
	var shoulder_roll := sin(phase) * 3.0 * weight

	_body_mesh.position.y += bob
	_body_mesh.rotation_degrees.z += shoulder_roll
	_chest_mesh.position.y += bob * 1.25
	_head_mesh.position.y += sin(phase * WALK_HEAD_CYCLE_SCALE + 0.8) * WALK_HEAD_BOB * SIZE_SCALE * weight
	_muzzle_mesh.position = _head_mesh.position + _scaled(Vector3(0.28, -0.04, 0.0))

	_tail_mesh.rotation_degrees.y += sin(phase + 1.2) * 12.0 * weight
	_tail_mesh.rotation_degrees.z += sin(phase * 0.5) * 8.0 * weight
	_tail_tuft_mesh.position.z += sin(phase + 1.2) * 0.08 * SIZE_SCALE * weight

	for index in range(_leg_meshes.size()):
		var leg := _leg_meshes[index]
		var side_phase := phase + PI if index % 2 == 0 else phase
		var front_weight := 1.0 if leg.position.x > 0.0 else -0.65
		leg.rotation_degrees.z += sin(side_phase) * 22.0 * weight
		leg.position.x += sin(side_phase) * 0.08 * SIZE_SCALE * front_weight * weight
		leg.position.y += maxf(0.0, cos(side_phase)) * 0.08 * SIZE_SCALE * weight


func _animate_leap_attack() -> void:
	var airborne_weight := 1.0
	if is_on_floor():
		airborne_weight = 0.45

	_body_mesh.scale.x *= 1.0 + ATTACK_STRETCH * airborne_weight
	_body_mesh.scale.y *= 0.92
	_chest_mesh.position.x += 0.18 * SIZE_SCALE * airborne_weight
	_head_mesh.position.x += 0.26 * SIZE_SCALE * airborne_weight
	_head_mesh.position.y += 0.08 * SIZE_SCALE * airborne_weight
	_muzzle_mesh.position = _head_mesh.position + _scaled(Vector3(0.31, -0.04, 0.0))
	_tail_mesh.rotation_degrees.z -= 22.0 * airborne_weight
	_tail_tuft_mesh.position.y -= 0.14 * SIZE_SCALE * airborne_weight

	for index in range(_leg_meshes.size()):
		var leg := _leg_meshes[index]
		var is_front := leg.position.x > 0.0
		leg.rotation_degrees.z += -36.0 if is_front else 34.0
		leg.position.x += (0.18 if is_front else -0.12) * SIZE_SCALE


func _animate_attack_recovery() -> void:
	var crouch := clampf(_recovery_time / 0.55, 0.0, 1.0)
	_body_mesh.position.y -= 0.1 * SIZE_SCALE * crouch
	_body_mesh.scale.y *= 1.0 - 0.12 * crouch
	_head_mesh.position.y -= 0.08 * SIZE_SCALE * crouch
	_muzzle_mesh.position = _head_mesh.position + _scaled(Vector3(0.28, -0.04, 0.0))
	for leg in _leg_meshes:
		leg.rotation_degrees.z *= 0.65


func _animate_idle(delta: float) -> void:
	var breath := sin(_animation_time * 1.8) * 0.025 * SIZE_SCALE
	_body_mesh.scale.y += breath
	_chest_mesh.scale.y += breath * 1.25
	_tail_mesh.rotation_degrees.y += sin(_animation_time * 1.4) * 4.0


func _scaled(value: Vector3) -> Vector3:
	return value * SIZE_SCALE


func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
