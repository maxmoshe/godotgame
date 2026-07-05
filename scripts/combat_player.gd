extends CharacterBody3D

const SlingStone := preload("res://scripts/sling_stone.gd")

const LOOK_GROUND_LIMIT := deg_to_rad(-84.0)
const LOOK_SKY_LIMIT := deg_to_rad(84.0)

@export var move_speed := 6.0
@export var sprint_multiplier := 1.45
@export var mouse_sensitivity := 0.0025
@export var min_throw_speed := 13.0
@export var max_throw_speed := 45.0
@export var max_charge_time := 1.35

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var sling_hand: Marker3D = $SlingHand
@onready var body_mesh: MeshInstance3D = $BodyMesh

var aiming := false
var charging := false
var charge_time := 0.0
var yaw := 0.0
var pitch := -0.18


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.fov = 70.0
	body_mesh.visible = false
	_apply_camera_rotation()


func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _unhandled_input(event: InputEvent) -> void:
	var mouse_motion := event as InputEventMouseMotion
	if mouse_motion != null:
		yaw -= mouse_motion.relative.x * mouse_sensitivity
		pitch = clampf(pitch - mouse_motion.relative.y * mouse_sensitivity, LOOK_GROUND_LIMIT, LOOK_SKY_LIMIT)
		_apply_camera_rotation()
		return

	var mouse_button := event as InputEventMouseButton
	if mouse_button == null:
		return

	if mouse_button.button_index == MOUSE_BUTTON_RIGHT:
		aiming = mouse_button.pressed
		return

	if mouse_button.button_index == MOUSE_BUTTON_LEFT:
		if mouse_button.pressed:
			charging = true
			charge_time = 0.0
		elif charging:
			_throw_stone()
			charging = false


func _physics_process(delta: float) -> void:
	if charging:
		charge_time = minf(charge_time + delta, max_charge_time)

	var input_vector := _movement_input()
	var forward := -global_transform.basis.z
	var right := global_transform.basis.x
	var direction := (forward * input_vector.y + right * input_vector.x).normalized()
	var speed := move_speed
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= sprint_multiplier

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = -0.1

	move_and_slide()


func get_charge_ratio() -> float:
	if not charging:
		return 0.0
	return charge_time / max_charge_time


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


func _apply_camera_rotation() -> void:
	rotation.y = yaw
	camera_pivot.rotation.x = pitch


func _throw_stone() -> void:
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
	var speed := lerpf(min_throw_speed, max_throw_speed, get_charge_ratio())
	stone.launch(sling_hand.global_position, throw_direction, speed)
