extends Area3D

const LIFE_SECONDS := 4.0
const FRIENDLY_BLOCKS_ARROW := true
const WORLD_COLLISION_MASK := 1
const SOLDIER_COLLISION_LAYER := 2

var velocity := Vector3.ZERO
var damage := 1
var faction := ""
var source: Node
var _age := 0.0
var _previous_position := Vector3.ZERO


func start(origin: Vector3, direction: Vector3, speed: float, new_damage: int, new_faction: String, new_source: Node) -> void:
	global_position = origin
	_previous_position = origin
	velocity = direction.normalized() * speed
	damage = maxi(1, new_damage)
	faction = new_faction
	source = new_source
	look_at(global_position + direction.normalized(), Vector3.UP)
	_build_arrow()


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFE_SECONDS:
		queue_free()
		return

	_previous_position = global_position
	global_position += velocity * delta
	_check_hit()


func _check_hit() -> void:
	var world := get_world_3d()
	if world == null:
		return

	var query := PhysicsRayQueryParameters3D.create(_previous_position, global_position)
	query.exclude = [self]
	query.collision_mask = WORLD_COLLISION_MASK | SOLDIER_COLLISION_LAYER
	if source != null:
		query.exclude.append(source)

	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	var collider := hit["collider"] as Node
	if collider == null:
		queue_free()
		return

	if collider.has_method("get_faction") and collider.get_faction() == faction:
		if FRIENDLY_BLOCKS_ARROW:
			queue_free()
		return

	var shape_name := _hit_shape_name(hit)
	if collider.has_method("take_projectile_hit_shape"):
		collider.call("take_projectile_hit_shape", damage, hit["position"], shape_name)
	elif collider.has_method("take_projectile_hit"):
		collider.call("take_projectile_hit", damage, hit["position"])
	elif collider.has_method("take_damage"):
		collider.take_damage(damage, global_position)
	elif collider.has_method("take_hit"):
		collider.take_hit(damage)

	queue_free()


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


func _build_arrow() -> void:
	var shaft := MeshInstance3D.new()
	shaft.name = "ArrowShaft"
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.012
	shaft_mesh.bottom_radius = 0.012
	shaft_mesh.height = 0.72
	shaft_mesh.radial_segments = 6
	shaft.mesh = shaft_mesh
	shaft.rotation_degrees.x = 90.0
	shaft.material_override = _make_material(Color("#6b4328"), 0.88)
	add_child(shaft)

	var head := MeshInstance3D.new()
	head.name = "ArrowHead"
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.045
	head_mesh.height = 0.12
	head_mesh.radial_segments = 6
	head.mesh = head_mesh
	head.position.z = -0.42
	head.rotation_degrees.x = 90.0
	head.material_override = _make_material(Color("#aeb7b5"), 0.42)
	add_child(head)

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.055
	shape.shape = sphere
	add_child(shape)


func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
