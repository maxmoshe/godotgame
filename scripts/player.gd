extends CharacterBody2D

@export var speed := 135.0
@export var world_bounds := Rect2(Vector2(-2662.0, -3712.0), Vector2(5324.0, 7424.0))

var movement_constraint: Callable
var campaign_speed_multiplier := 1.0
var _facing := Vector2.RIGHT
var _travel_target := Vector2.ZERO
var _has_travel_target := false
var _arrival_radius := 20.0


func _physics_process(_delta: float) -> void:
	var previous_position := global_position
	var input_vector := _get_keyboard_vector()

	if input_vector != Vector2.ZERO:
		_has_travel_target = false
	elif _has_travel_target:
		var to_target := _travel_target - global_position
		if to_target.length() <= _arrival_radius:
			_has_travel_target = false
			input_vector = Vector2.ZERO
		else:
			input_vector = to_target.normalized()

	var sprint := 1.55 if Input.is_key_pressed(KEY_SHIFT) else 1.0
	velocity = input_vector.normalized() * speed * campaign_speed_multiplier * sprint
	move_and_slide()

	var intended_position := _clamped_position(global_position)
	var constrained_position := _constrained_position(intended_position, previous_position)
	var movement_was_blocked := intended_position.distance_to(constrained_position) > 0.5
	global_position = constrained_position
	if movement_was_blocked:
		velocity = Vector2.ZERO
		if _has_travel_target:
			_has_travel_target = false

	if velocity.length() > 0.1:
		_facing = velocity.normalized()
		queue_redraw()


func travel_to(target_position: Vector2) -> void:
	_travel_target = _clamped_position(target_position)
	_has_travel_target = true


func stop_travel() -> void:
	_has_travel_target = false
	velocity = Vector2.ZERO


func is_traveling() -> bool:
	return _has_travel_target


func _clamped_position(position: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, world_bounds.position.x, world_bounds.end.x),
		clampf(position.y, world_bounds.position.y, world_bounds.end.y)
	)


func _constrained_position(position: Vector2, fallback_position: Vector2) -> Vector2:
	if not movement_constraint.is_valid():
		return position

	var constrained = movement_constraint.call(position, fallback_position)
	if constrained is Vector2:
		return Vector2(constrained)
	return position


func _draw() -> void:
	var side := Vector2(-_facing.y, _facing.x)
	var shadow := Color(0.05, 0.03, 0.02, 0.28)

	draw_circle(Vector2(3.0, 5.0), 19.0, shadow)
	draw_circle(Vector2.ZERO, 16.0, Color("#f1d28a"))
	draw_circle(Vector2.ZERO, 11.0, Color("#1f596f"))

	var arrow := PackedVector2Array([
		_facing * 26.0,
		-_facing * 7.0 + side * 8.0,
		-_facing * 7.0 - side * 8.0
	])
	draw_colored_polygon(arrow, Color("#f7e8bd"))
	draw_polyline(PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[0]]), Color("#5f3f23"), 2.0, true)


func _get_keyboard_vector() -> Vector2:
	var input_vector := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_vector.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_vector.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_vector.y += 1.0
	return input_vector
