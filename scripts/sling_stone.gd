extends RigidBody3D

const ImpactSparks := preload("res://scripts/impact_sparks.gd")
const LIFE_SECONDS := 8.0

var _age := 0.0
var _has_impacted := false
var _previous_position := Vector3.ZERO


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	_previous_position = global_position


func launch(origin: Vector3, direction: Vector3, speed: float) -> void:
	global_position = origin
	_previous_position = origin
	linear_velocity = direction.normalized() * speed
	angular_velocity = Vector3(10.0, 3.0, -6.0)


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
	_spawn_impact_sparks()

	if body.has_method("take_hit"):
		body.take_hit(linear_velocity.length())

	queue_free()


func _spawn_impact_sparks() -> void:
	var parent := get_tree().current_scene
	if parent == null:
		return

	var impact := _find_impact_surface()
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
		return {"position": fallback_position, "normal": fallback_normal}

	var travel_direction := global_position - _previous_position
	if travel_direction.length() < 0.01 and linear_velocity.length() > 0.01:
		travel_direction = linear_velocity.normalized()

	var ray_start := _previous_position - travel_direction.normalized() * 0.2
	var ray_end := global_position + travel_direction.normalized() * 0.65
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = [self]

	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {"position": fallback_position, "normal": fallback_normal}

	var hit_normal: Vector3 = hit["normal"]
	var hit_position: Vector3 = hit["position"]
	return {
		"position": hit_position + hit_normal * 0.055,
		"normal": hit_normal
	}
