extends CharacterBody3D

signal died(faction: String)

const SOLDIER_GROUP := "combat_soldiers"
const WORLD_COLLISION_MASK := 1
const SOLDIER_COLLISION_LAYER := 2
const GRAVITY := 22.0
const GROUND_STICK_VELOCITY := -0.25
const HEADSHOT_MULTIPLIER := 2
const HIT_FLASH_SECONDS := 0.16

var terrain_owner: Node
var max_health := 32
var health := max_health

var _dead := false
var _registered_with_combat := false
var _visual_root: Node3D
var _animation_player: AnimationPlayer
var _current_animation := ""
var _health_label: Label3D
var _hit_flash_time := 0.0
var _hit_flash_meshes: Array[MeshInstance3D] = []
var _hit_flash_original_overrides: Array = []
var _hit_flash_material: StandardMaterial3D


func setup(first_node: Node, second_node: Node = null) -> void:
	if second_node == null:
		terrain_owner = first_node
	else:
		terrain_owner = second_node
	_on_setup(first_node, second_node)


func _ready() -> void:
	collision_layer = SOLDIER_COLLISION_LAYER
	collision_mask = WORLD_COLLISION_MASK
	max_slides = 2
	safe_margin = 0.035
	max_health = _actor_max_health()
	health = max_health

	add_to_group(SOLDIER_GROUP)
	add_to_group(_faction_group())
	_register_with_combat()
	_add_collision()
	_add_visual()
	_add_health_label()
	_update_health_label()
	_on_actor_ready()


func _exit_tree() -> void:
	_unregister_from_combat()


func _physics_process(delta: float) -> void:
	if _dead:
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = GROUND_STICK_VELOCITY

	_update_hit_flash(delta)
	_tick_actor(delta)
	move_and_slide()
	_after_actor_move(delta)


func take_hit(damage: int) -> void:
	_apply_damage(damage)


func take_damage(damage: int, _source_position := Vector3.ZERO) -> void:
	_apply_damage(damage)


func take_projectile_hit(damage: int, hit_position: Vector3) -> int:
	var final_damage := damage
	if is_projectile_headshot(hit_position):
		final_damage *= HEADSHOT_MULTIPLIER
	_apply_damage(final_damage)
	return final_damage


func take_projectile_hit_shape(damage: int, hit_position: Vector3, hit_shape_name: String) -> int:
	var final_damage := damage
	if is_projectile_headshot(hit_position, hit_shape_name):
		final_damage *= HEADSHOT_MULTIPLIER
	_apply_damage(final_damage)
	return final_damage


func is_projectile_headshot(hit_position: Vector3, hit_shape_name := "") -> bool:
	if hit_shape_name == "HeadHitShape":
		return true

	var head_radius := _head_radius()
	if head_radius.x <= 0.0 or head_radius.y <= 0.0 or head_radius.z <= 0.0:
		return false

	var head_center := _head_center()
	var local_hit := to_local(hit_position)
	var normalized_offset := Vector3(
		(local_hit.x - head_center.x) / head_radius.x,
		(local_hit.y - head_center.y) / head_radius.y,
		(local_hit.z - head_center.z) / head_radius.z
	)
	return normalized_offset.length() <= 1.0


func get_faction() -> String:
	return _actor_faction()


func is_alive() -> bool:
	return not _dead and health > 0


func _actor_max_health() -> int:
	return 32


func _actor_faction() -> String:
	return "neutral"


func _actor_display_name() -> String:
	return "Animal"


func _actor_scene() -> PackedScene:
	return null


func _visual_scale() -> float:
	return 1.0


func _visual_offset() -> Vector3:
	return Vector3.ZERO


func _body_radius() -> float:
	return 0.16


func _body_height() -> float:
	return 0.52


func _body_center_y() -> float:
	return 0.28


func _head_center() -> Vector3:
	return Vector3(0.0, 0.38, -0.3)


func _head_radius() -> Vector3:
	return Vector3(0.12, 0.12, 0.12)


func _label_position() -> Vector3:
	return Vector3(0.0, 0.7, 0.0)


func _label_color() -> Color:
	return Color("#f3e7bb")


func _label_outline_color() -> Color:
	return Color("#151008")


func _on_actor_ready() -> void:
	pass


func _on_setup(_first_node: Node, _second_node: Node) -> void:
	pass


func _tick_actor(_delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func _after_actor_move(_delta: float) -> void:
	pass


func _on_actor_died() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.0, 0.18, 1.0), 0.18)
	tween.tween_callback(Callable(self, "queue_free"))


func _play_animation(animation_name: String) -> void:
	if _animation_player == null or _current_animation == animation_name:
		return
	if not _animation_player.has_animation(animation_name):
		return
	_current_animation = animation_name
	_animation_player.play(animation_name)


func _find_animation_player(root: Node) -> AnimationPlayer:
	var player := root as AnimationPlayer
	if player != null:
		return player

	for child in root.get_children():
		var child_player := _find_animation_player(child)
		if child_player != null:
			return child_player
	return null


func _register_with_combat() -> void:
	if _registered_with_combat:
		return
	if terrain_owner != null and is_instance_valid(terrain_owner) and terrain_owner.has_method("register_combat_soldier"):
		terrain_owner.call("register_combat_soldier", self, _actor_faction())
		_registered_with_combat = true


func _unregister_from_combat() -> void:
	if not _registered_with_combat:
		return
	if terrain_owner != null and is_instance_valid(terrain_owner) and terrain_owner.has_method("unregister_combat_soldier"):
		terrain_owner.call("unregister_combat_soldier", self, _actor_faction())
	_registered_with_combat = false


func _apply_damage(damage: int) -> void:
	if _dead:
		return

	health = maxi(0, health - maxi(1, damage))
	_update_health_label()
	if health <= 0:
		_die()
	else:
		_start_hit_flash()


func _die() -> void:
	_dead = true
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	_unregister_from_combat()
	remove_from_group(SOLDIER_GROUP)
	remove_from_group(_faction_group())
	if _health_label != null:
		_health_label.visible = false
	_clear_hit_flash()
	died.emit(_actor_faction())
	_on_actor_died()


func _add_collision() -> void:
	var body_shape := CollisionShape3D.new()
	body_shape.name = "BodyHitShape"
	var capsule := CapsuleShape3D.new()
	capsule.radius = _body_radius()
	capsule.height = _body_height()
	body_shape.shape = capsule
	body_shape.position = Vector3(0.0, _body_center_y(), 0.0)
	add_child(body_shape)

	var head_shape := CollisionShape3D.new()
	head_shape.name = "HeadHitShape"
	var head_sphere := SphereShape3D.new()
	head_sphere.radius = _head_radius().x
	head_shape.shape = head_sphere
	head_shape.position = _head_center()
	add_child(head_shape)


func _add_visual() -> void:
	var scene := _actor_scene()
	if scene == null:
		return

	_visual_root = scene.instantiate() as Node3D
	if _visual_root == null:
		return

	_visual_root.name = "%sVisual" % _actor_display_name().replace(" ", "")
	_visual_root.scale = Vector3.ONE * _visual_scale()
	_visual_root.position = _visual_offset()
	add_child(_visual_root)
	_animation_player = _find_animation_player(_visual_root)
	_remember_hit_flash_meshes(_visual_root)


func _add_health_label() -> void:
	_health_label = Label3D.new()
	_health_label.name = "AnimalHealthLabel"
	_health_label.position = _label_position()
	_health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_health_label.font_size = 22
	_health_label.outline_size = 5
	_health_label.outline_modulate = _label_outline_color()
	_health_label.modulate = _label_color()
	_health_label.no_depth_test = true
	add_child(_health_label)


func _update_health_label() -> void:
	if _health_label != null:
		_health_label.text = "%s %d/%d" % [_actor_display_name(), maxi(0, health), max_health]


func _faction_group() -> String:
	return "%s_%s" % [SOLDIER_GROUP, _actor_faction()]


func _start_hit_flash() -> void:
	if _hit_flash_meshes.is_empty():
		return
	_hit_flash_time = HIT_FLASH_SECONDS
	_set_hit_flash_enabled(true)


func _update_hit_flash(delta: float) -> void:
	if _hit_flash_time <= 0.0:
		return

	_hit_flash_time = maxf(0.0, _hit_flash_time - delta)
	if _hit_flash_time <= 0.0:
		_clear_hit_flash()


func _clear_hit_flash() -> void:
	_hit_flash_time = 0.0
	_set_hit_flash_enabled(false)


func _set_hit_flash_enabled(enabled: bool) -> void:
	if _hit_flash_material == null:
		_hit_flash_material = _make_hit_flash_material()

	for index in range(_hit_flash_meshes.size()):
		var mesh := _hit_flash_meshes[index]
		if mesh == null or not is_instance_valid(mesh):
			continue
		if enabled:
			mesh.material_override = _hit_flash_material
		else:
			mesh.material_override = _hit_flash_original_overrides[index]


func _remember_hit_flash_meshes(root: Node) -> void:
	var mesh := root as MeshInstance3D
	if mesh != null:
		_hit_flash_meshes.append(mesh)
		_hit_flash_original_overrides.append(mesh.material_override)

	for child in root.get_children():
		_remember_hit_flash_meshes(child)


func _make_hit_flash_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#ff463a")
	material.roughness = 0.7
	return material
