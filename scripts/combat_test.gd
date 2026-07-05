extends Node3D

const CombatPlayer := preload("res://scripts/combat_player.gd")
const TargetDummy := preload("res://scripts/target_dummy.gd")
const SoldierEnemy := preload("res://scripts/soldier_enemy.gd")
const TerrainGrassAlbedo := preload("res://assets/textures/terrain/rocky_grass/rocky_terrain_02_diff_1k.jpg")
const TerrainGrassHeight := preload("res://assets/textures/terrain/rocky_grass/rocky_terrain_02_disp_1k.png")
const TerrainDirtAlbedo := preload("res://assets/textures/terrain/rocky_gravel/gravelly_sand_diff_1k.jpg")
const TerrainDirtHeight := preload("res://assets/textures/terrain/rocky_gravel/gravelly_sand_disp_1k.png")
const StoneAlbedo := preload("res://assets/textures/terrain/marble/marble_rock_02_diff_1k.jpg")
const StoneHeight := preload("res://assets/textures/terrain/marble/marble_rock_02_disp_1k.png")

const TERRAIN_SIZE := 88.0
const TERRAIN_STEPS := 72
const TERRAIN_HALF := TERRAIN_SIZE * 0.5
const TERRAIN_FALL_LIMIT := -5.0
const PLAYER_SPAWN := Vector3(0.0, 0.0, 8.0)
const PLAYER_FOOT_CLEARANCE := 0.12
const TERRAIN_COLOR_LOW := Color("#566f38")
const TERRAIN_COLOR_HIGH := Color("#8a9a59")
const PATH_COLOR := Color("#c0a56d")
const COMMAND_RAY_LENGTH := 95.0
const COMMAND_RAY_STEP := 0.45
const COMMAND_INVALID_POSITION := Vector3(999999.0, 999999.0, 999999.0)
const FORMATION_SPACING := 1.65

@onready var player: CharacterBody3D = $Player
@onready var player_camera: Camera3D = $Player/CameraPivot/Camera3D
@onready var aim_label: Label = $HUD/AimLabel
@onready var charge_bar: ProgressBar = $HUD/ChargeBar
@onready var reticle: Label = $HUD/Reticle
@onready var velocity_label: Label = $HUD/VelocityLabel
@onready var health_label: Label = $HUD/HealthLabel

var _decoration_exclusions: Array[Dictionary] = []
var _stone_material: ShaderMaterial
var _last_sling_impact_speed := 0.0
var _last_sling_damage := 0
var _command_mode := false
var _command_position := Vector3.ZERO
var _command_marker: Node3D
var _command_menu_label: Label


func _ready() -> void:
	_setup_environment()
	_setup_command_ui()
	_place_player_on_terrain(PLAYER_SPAWN)


func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return

	if player.global_position.y < TERRAIN_FALL_LIMIT:
		_place_player_on_terrain(PLAYER_SPAWN)

	_update_command_marker()
	charge_bar.value = player.get_charge_ratio() * 100.0
	reticle.modulate = Color("#56ff8d") if _command_mode else Color("#f3d67d") if player.aiming else Color("#f4efe0")
	health_label.text = player.get_health_text()
	health_label.modulate = Color("#ff6c4f") if player.is_recently_damaged() else Color("#f4d27a")
	aim_label.text = "Space: jump | Hold left mouse to spin faster, release on full charge | Esc: map"
	if player.is_release_queued():
		aim_label.text = "Release mistimed: stone goes on the next full rotation | Esc: map"
	elif player.aiming:
		aim_label.text = "Aiming: no zoom | Early release cancels, full charge is the first firing window | Esc: map"

	_update_velocity_label()


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_F1:
		if _command_mode:
			_issue_hold_position_order()
		else:
			_set_command_mode(true)
		var viewport := get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()
	elif key_event.keycode == KEY_F3:
		_issue_charge_order()
		_set_command_mode(false)
		var viewport := get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()


func set_last_sling_impact(impact_speed: float, damage: int) -> void:
	_last_sling_impact_speed = impact_speed
	_last_sling_damage = damage


func _update_velocity_label() -> void:
	var live_speed := _current_sling_speed()
	if _last_sling_impact_speed <= 0.0:
		velocity_label.text = "Stone velocity: %.1f\nLast hit: --" % live_speed
	else:
		velocity_label.text = "Stone velocity: %.1f\nLast hit: %.1f -> %d dmg" % [live_speed, _last_sling_impact_speed, _last_sling_damage]


func _current_sling_speed() -> float:
	for child in get_children():
		var stone := child as RigidBody3D
		if stone != null and stone.name == "SlingStone":
			return stone.linear_velocity.length()
	return 0.0


func _setup_command_ui() -> void:
	_command_marker = Node3D.new()
	_command_marker.name = "CommandGroundReticle"
	_command_marker.visible = false
	add_child(_command_marker)

	var material := _make_material(Color("#4dff7a"), 0.55, 1.4)
	_add_command_reticle_bar(Vector3(0.0, 0.035, 0.0), Vector3(1.65, 0.035, 0.08), material)
	_add_command_reticle_bar(Vector3(0.0, 0.035, 0.0), Vector3(0.08, 0.035, 1.65), material)
	_add_command_reticle_bar(Vector3(0.0, 0.055, 0.0), Vector3(0.34, 0.05, 0.34), material)

	_command_menu_label = Label.new()
	_command_menu_label.name = "CommandMenuLabel"
	_command_menu_label.offset_left = 22.0
	_command_menu_label.offset_top = 116.0
	_command_menu_label.offset_right = 430.0
	_command_menu_label.offset_bottom = 176.0
	_command_menu_label.add_theme_color_override("font_color", Color("#73ff94"))
	_command_menu_label.add_theme_font_size_override("font_size", 18)
	_command_menu_label.text = "F1: hold position\nF3: charge"
	_command_menu_label.visible = false
	$HUD.add_child(_command_menu_label)


func _add_command_reticle_bar(local_position: Vector3, size: Vector3, material: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "CommandReticleBar"
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.material_override = material
	_command_marker.add_child(mesh_instance)


func _set_command_mode(enabled: bool) -> void:
	_command_mode = enabled
	if _command_marker != null:
		_command_marker.visible = enabled
	if _command_menu_label != null:
		_command_menu_label.visible = enabled


func _update_command_marker() -> void:
	if not _command_mode or _command_marker == null:
		return

	var ground_point: Vector3 = _find_command_ground_point()
	if ground_point == COMMAND_INVALID_POSITION:
		_command_marker.visible = false
		return

	_command_position = ground_point
	_command_marker.visible = true
	_command_marker.global_position = ground_point
	_command_marker.rotation.y = player.rotation.y


func _find_command_ground_point() -> Vector3:
	if player_camera == null:
		return COMMAND_INVALID_POSITION

	var origin := player_camera.global_position
	var direction := -player_camera.global_transform.basis.z.normalized()
	var previous_point := origin
	var steps := int(COMMAND_RAY_LENGTH / COMMAND_RAY_STEP)

	for step_index in range(1, steps + 1):
		var point := origin + direction * COMMAND_RAY_STEP * float(step_index)
		if point.x < -TERRAIN_HALF or point.x > TERRAIN_HALF or point.z < -TERRAIN_HALF or point.z > TERRAIN_HALF:
			previous_point = point
			continue

		var ground_y := _terrain_height(point.x, point.z)
		if point.y <= ground_y + 0.08:
			var previous_ground_y := _terrain_height(previous_point.x, previous_point.z)
			var previous_gap := previous_point.y - previous_ground_y
			var current_gap := point.y - ground_y
			var t := 1.0
			var gap_delta := previous_gap - current_gap
			if absf(gap_delta) > 0.001:
				t = clampf(previous_gap / gap_delta, 0.0, 1.0)
			var hit_point := previous_point.lerp(point, t)
			hit_point.y = _terrain_height(hit_point.x, hit_point.z) + 0.12
			return hit_point
		previous_point = point

	return COMMAND_INVALID_POSITION


func _issue_hold_position_order() -> void:
	if not _command_marker.visible:
		return

	var soldiers := _friendly_soldiers()
	var count := soldiers.size()
	for index in range(count):
		var soldier := soldiers[index]
		if soldier.has_method("receive_order"):
			soldier.call("receive_order", "hold", _formation_slot_position(_command_position, index, count), index)
	_set_command_mode(false)


func _issue_charge_order() -> void:
	var soldiers := _friendly_soldiers()
	for index in range(soldiers.size()):
		var soldier := soldiers[index]
		if soldier.has_method("receive_order"):
			soldier.call("receive_order", "charge", Vector3.ZERO, index)


func _friendly_soldiers() -> Array[Node3D]:
	var soldiers: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group("combat_soldiers"):
		if not node.has_method("get_faction") or not node.has_method("is_alive"):
			continue
		if node.get_faction() != "friendly" or not node.is_alive():
			continue
		var soldier := node as Node3D
		if soldier != null:
			soldiers.append(soldier)
	return soldiers


func _formation_slot_position(center: Vector3, index: int, count: int) -> Vector3:
	var side := player.global_transform.basis.x
	side.y = 0.0
	if side.length() <= 0.01:
		side = Vector3.RIGHT
	side = side.normalized()

	var offset := (float(index) - float(count - 1) * 0.5) * FORMATION_SPACING
	var slot := center + side * offset
	slot.x = clampf(slot.x, -TERRAIN_HALF + 1.0, TERRAIN_HALF - 1.0)
	slot.z = clampf(slot.z, -TERRAIN_HALF + 1.0, TERRAIN_HALF - 1.0)
	slot.y = _terrain_height(slot.x, slot.z) + PLAYER_FOOT_CLEARANCE
	return slot


func _setup_environment() -> void:
	_add_world_environment()
	_add_sun()
	_add_terrain()
	_add_ground_visibility_underlay()
	_add_path()
	_add_small_rocks()
	_add_target(Vector3(0.0, _terrain_height(0.0, -20.0), -20.0))
	_add_target(Vector3(8.5, _terrain_height(8.5, -30.0), -30.0))
	_add_target(Vector3(-13.0, _terrain_height(-13.0, -26.0), -26.0))
	_add_soldier(Vector3(-9.0, _terrain_height(-9.0, -12.0), -12.0), "enemy", "sword", 5, 5, 3)
	_add_soldier(Vector3(-5.5, _terrain_height(-5.5, -15.0), -15.0), "enemy", "sword", 5, 5, 3)
	_add_soldier(Vector3(-13.5, _terrain_height(-13.5, -9.0), -9.0), "enemy", "bow", 3, 5, 4)
	_add_soldier(Vector3(4.0, _terrain_height(4.0, -5.0), -5.0), "friendly", "sword", 5, 5, 3)
	_add_soldier(Vector3(7.0, _terrain_height(7.0, -8.0), -8.0), "friendly", "sword", 5, 5, 3)
	_add_soldier(Vector3(10.5, _terrain_height(10.5, -3.5), -3.5), "friendly", "bow", 3, 5, 4)


func _add_world_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "HillCountryWorld"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#64b7f0")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#e8e0c5")
	environment.ambient_light_energy = 0.58
	environment.fog_enabled = true
	environment.fog_light_color = Color("#c2d8e6")
	environment.fog_density = 0.0045
	world.environment = environment
	add_child(world)


func _add_sun() -> void:
	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-38.0, 38.0, 0.0)
	light.light_energy = 2.9
	light.shadow_enabled = true
	add_child(light)

	var fill := DirectionalLight3D.new()
	fill.name = "SoftSkyFill"
	fill.rotation_degrees = Vector3(-68.0, -128.0, 0.0)
	fill.light_color = Color("#9ec7ef")
	fill.light_energy = 0.32
	add_child(fill)


func _add_terrain() -> void:
	var terrain := StaticBody3D.new()
	terrain.name = "JudeanHillCountry"
	add_child(terrain)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "TerrainMesh"
	var mesh := _build_terrain_mesh()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_terrain_material()
	terrain.add_child(mesh_instance)

	_add_terrain_heightmap_collision(terrain)


func _add_ground_visibility_underlay() -> void:
	var underlay := MeshInstance3D.new()
	underlay.name = "GroundVisibilityUnderlay"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(TERRAIN_SIZE, TERRAIN_SIZE)
	underlay.mesh = mesh
	underlay.position.y = -0.48
	underlay.material_override = _make_material(Color("#596f3c"), 1.0, 0.0)
	add_child(underlay)


func _add_terrain_heightmap_collision(terrain: StaticBody3D) -> void:
	var sample_count := TERRAIN_STEPS + 1
	var step_size := TERRAIN_SIZE / float(TERRAIN_STEPS)
	var map_data := PackedFloat32Array()
	map_data.resize(sample_count * sample_count)

	for z_index in range(sample_count):
		var z := -TERRAIN_HALF + float(z_index) * step_size
		for x_index in range(sample_count):
			var x := -TERRAIN_HALF + float(x_index) * step_size
			map_data[z_index * sample_count + x_index] = _terrain_height(x, z) / step_size

	var heightmap := HeightMapShape3D.new()
	heightmap.map_width = sample_count
	heightmap.map_depth = sample_count
	heightmap.map_data = map_data

	var collision := CollisionShape3D.new()
	collision.name = "TerrainHeightmapCollision"
	collision.shape = heightmap
	collision.scale = Vector3.ONE * step_size
	terrain.add_child(collision)


func _place_player_on_terrain(target_position: Vector3) -> void:
	var x := clampf(target_position.x, -TERRAIN_HALF + 2.0, TERRAIN_HALF - 2.0)
	var z := clampf(target_position.z, -TERRAIN_HALF + 2.0, TERRAIN_HALF - 2.0)
	var ground_y := _terrain_height(x, z)
	player.global_position = Vector3(x, ground_y + PLAYER_FOOT_CLEARANCE, z)
	player.velocity = Vector3.ZERO


func _build_terrain_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var step_size := TERRAIN_SIZE / float(TERRAIN_STEPS)

	for z_index in range(TERRAIN_STEPS + 1):
		var z := -TERRAIN_HALF + float(z_index) * step_size
		for x_index in range(TERRAIN_STEPS + 1):
			var x := -TERRAIN_HALF + float(x_index) * step_size
			var y := _terrain_height(x, z)
			vertices.append(Vector3(x, y, z))
			normals.append(_terrain_normal(x, z))
			var color_blend := clampf((y + 0.8) / 3.7, 0.0, 1.0)
			colors.append(TERRAIN_COLOR_LOW.lerp(TERRAIN_COLOR_HIGH, color_blend))
			uvs.append(Vector2((x + TERRAIN_HALF) / TERRAIN_SIZE, (z + TERRAIN_HALF) / TERRAIN_SIZE))

	for z_index in range(TERRAIN_STEPS):
		for x_index in range(TERRAIN_STEPS):
			var row := TERRAIN_STEPS + 1
			var a := z_index * row + x_index
			var b := a + 1
			var c := a + row
			var d := c + 1
			indices.append_array([a, c, b, b, c, d])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _terrain_height(x: float, z: float) -> float:
	var north_ridge := 1.55 * exp(-pow((z + 19.0) / 16.0, 2.0))
	var west_swell := 1.15 * exp(-(pow((x + 24.0) / 18.0, 2.0) + pow((z - 2.0) / 24.0, 2.0)))
	var east_swell := 0.85 * exp(-(pow((x - 22.0) / 23.0, 2.0) + pow((z + 11.0) / 20.0, 2.0)))
	var shallow_wadi := -0.85 * exp(-(pow((x - 1.5) / 9.0, 2.0) + pow((z + 1.0) / 32.0, 2.0)))
	var ripple := 0.22 * sin(x * 0.22) + 0.14 * cos((x + z) * 0.17)
	var spawn_flatten := 0.45 * exp(-(pow(x / 10.0, 2.0) + pow((z - 8.0) / 8.0, 2.0)))
	var base_height := maxf(-0.35, north_ridge + west_swell + east_swell + shallow_wadi + ripple - spawn_flatten)
	return base_height + _terrain_surface_relief(x, z)


func _terrain_surface_relief(x: float, z: float) -> float:
	var uv := _terrain_uv(x, z)
	var dirt := _terrain_dirt_mask_at(uv)
	var rough_grass := (_value_noise(uv * 42.0 + Vector2(3.0, -7.0)) - 0.5) * 0.035
	return -dirt * 0.09 + rough_grass * (1.0 - dirt)


func _terrain_uv(x: float, z: float) -> Vector2:
	return Vector2((x + TERRAIN_HALF) / TERRAIN_SIZE, (z + TERRAIN_HALF) / TERRAIN_SIZE)


func _terrain_dirt_mask_at(uv: Vector2) -> float:
	var dirt_mask := 0.0
	dirt_mask = maxf(dirt_mask, _terrain_patch(uv, Vector2(0.25, 0.50), Vector2(0.12, 0.08), 0.95))
	dirt_mask = maxf(dirt_mask, _terrain_patch(uv, Vector2(0.70, 0.24), Vector2(0.15, 0.10), 0.90))
	dirt_mask = maxf(dirt_mask, _terrain_patch(uv, Vector2(0.28, 0.72), Vector2(0.09, 0.12), 0.82))
	dirt_mask = maxf(dirt_mask, _terrain_patch(uv, Vector2(0.47, 0.22), Vector2(0.12, 0.08), 0.72))
	dirt_mask = maxf(dirt_mask, _terrain_patch(uv, Vector2(0.60, 0.63), Vector2(0.10, 0.13), 0.78))
	dirt_mask = maxf(dirt_mask, _terrain_patch(uv, Vector2(0.80, 0.55), Vector2(0.08, 0.11), 0.62))
	return smoothstep(0.08, 0.85, dirt_mask)


func _terrain_patch(uv: Vector2, center: Vector2, radius: Vector2, strength: float) -> float:
	var offset := Vector2((uv.x - center.x) / radius.x, (uv.y - center.y) / radius.y)
	var edge := _value_noise(uv * 24.0 + center * 17.0) * 0.22
	return (1.0 - smoothstep(0.38 + edge, 1.0 + edge, offset.length())) * strength


func _value_noise(point: Vector2) -> float:
	var cell := point.floor()
	var fraction := point - cell
	var u := fraction * fraction * (Vector2.ONE * 3.0 - fraction * 2.0)
	var a := _hash21(cell)
	var b := _hash21(cell + Vector2(1.0, 0.0))
	var c := _hash21(cell + Vector2(0.0, 1.0))
	var d := _hash21(cell + Vector2(1.0, 1.0))
	return lerpf(lerpf(a, b, u.x), lerpf(c, d, u.x), u.y)


func _hash21(point: Vector2) -> float:
	return fmod(absf(sin(point.dot(Vector2(127.1, 311.7))) * 43758.5453123), 1.0)


func _terrain_normal(x: float, z: float) -> Vector3:
	var sample := 0.45
	var left := _terrain_height(x - sample, z)
	var right := _terrain_height(x + sample, z)
	var back := _terrain_height(x, z - sample)
	var front := _terrain_height(x, z + sample)
	return Vector3(left - right, sample * 2.0, back - front).normalized()


func _add_path() -> void:
	var path_points := [
		Vector3(-30.0, 0.0, 18.0),
		Vector3(-17.0, 0.0, 10.0),
		Vector3(-6.0, 0.0, 5.0),
		Vector3(6.0, 0.0, -6.0),
		Vector3(18.0, 0.0, -18.0),
		Vector3(31.0, 0.0, -29.0),
	]
	var sampled_points := _sample_path_points(path_points, 1.35)
	var path_width := 2.4
	_register_decoration_exclusion_corridor(sampled_points, path_width * 0.5 + 0.45)
	_add_path_ribbon(sampled_points, path_width)


func _sample_path_points(path_points: Array, spacing: float) -> Array[Vector3]:
	var sampled: Array[Vector3] = []
	for index in range(path_points.size() - 1):
		var start: Vector3 = path_points[index]
		var finish: Vector3 = path_points[index + 1]
		var distance := start.distance_to(finish)
		var steps := maxi(2, int(ceil(distance / spacing)))
		for step_index in range(steps):
			if index > 0 and step_index == 0:
				continue
			var t := float(step_index) / float(steps)
			var point := start.lerp(finish, t)
			point.y = _terrain_height(point.x, point.z) + 0.095
			sampled.append(point)

	var final_point: Vector3 = path_points[path_points.size() - 1]
	final_point.y = _terrain_height(final_point.x, final_point.z) + 0.095
	sampled.append(final_point)
	return sampled


func _add_path_ribbon(path_points: Array[Vector3], width: float) -> void:
	if path_points.size() < 2:
		return

	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var half_width := width * 0.5

	for index in range(path_points.size()):
		var previous: Vector3 = path_points[maxi(index - 1, 0)]
		var next: Vector3 = path_points[mini(index + 1, path_points.size() - 1)]
		var tangent := Vector3(next.x - previous.x, 0.0, next.z - previous.z).normalized()
		if tangent == Vector3.ZERO:
			tangent = Vector3.FORWARD
		var side := Vector3(-tangent.z, 0.0, tangent.x).normalized()
		var point: Vector3 = path_points[index]
		vertices.append(point + side * half_width)
		vertices.append(point - side * half_width)
		colors.append(PATH_COLOR)
		colors.append(PATH_COLOR.darkened(0.04))

	for index in range(path_points.size() - 1):
		var a := index * 2
		var b := a + 1
		var c := a + 2
		var d := a + 3
		indices.append_array([a, c, b, b, c, d])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "TerrainFollowingPath"
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(PATH_COLOR, 0.98, 0.0, true, true)
	add_child(mesh_instance)


func _register_decoration_exclusion_corridor(points: Array[Vector3], radius: float) -> void:
	var path_points: Array[Vector2] = []
	for point in points:
		path_points.append(Vector2(point.x, point.z))
	_decoration_exclusions.append({
		"type": "corridor",
		"points": path_points,
		"radius": radius,
	})


func _register_decoration_exclusion_circle(center: Vector3, radius: float) -> void:
	_decoration_exclusions.append({
		"type": "circle",
		"center": Vector2(center.x, center.z),
		"radius": radius,
	})


func _is_decoration_excluded(position: Vector3, object_radius := 0.0) -> bool:
	var point := Vector2(position.x, position.z)
	for exclusion in _decoration_exclusions:
		var radius := float(exclusion["radius"]) + object_radius
		match String(exclusion["type"]):
			"circle":
				if point.distance_to(exclusion["center"]) <= radius:
					return true
			"corridor":
				var path_points: Array[Vector2] = exclusion["points"]
				for index in range(path_points.size() - 1):
					if _distance_to_segment_2d(point, path_points[index], path_points[index + 1]) <= radius:
						return true
	return false


func _distance_to_segment_2d(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)


func _add_small_rocks() -> void:
	for index in range(86):
		var angle := float(index) * 2.371
		var radius := 4.0 + fmod(float(index) * 5.23, 40.0)
		var x := cos(angle) * radius + sin(float(index) * 0.55) * 2.8
		var z := sin(angle) * radius + cos(float(index) * 0.37) * 2.8
		if Vector2(x, z).distance_to(Vector2(PLAYER_SPAWN.x, PLAYER_SPAWN.z)) < 3.5:
			continue

		var size_roll := pow(_deterministic_unit(index, 222), 1.9)
		var rock_radius := 0.16 + size_roll * 0.86
		var rock_position := Vector3(x, _terrain_height(x, z), z)
		if _is_decoration_excluded(rock_position, rock_radius * 1.8):
			continue
		_add_small_rock(rock_position, rock_radius, index)


func _add_small_rock(position: Vector3, radius: float, index: int) -> void:
	var rock := MeshInstance3D.new()
	rock.name = "SmallTerrainRock"
	rock.mesh = _make_small_rock_mesh(radius, index)
	rock.position = position + Vector3(0.0, 0.035 + radius * 0.025, 0.0)
	rock.rotation_degrees = Vector3(0.0, fmod(float(index) * 43.0, 360.0), 0.0)
	rock.material_override = _make_stone_material()
	add_child(rock)


func _make_small_rock_mesh(radius: float, seed: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var segments := 8
	var height := radius * (0.62 + _deterministic_unit(seed, 91) * 0.42) / 3.0
	var squash_x := 1.15 + _deterministic_unit(seed, 12) * 0.65
	var squash_z := 0.78 + _deterministic_unit(seed, 41) * 0.42
	var bottom: Array[Vector3] = []
	var middle: Array[Vector3] = []
	var top: Array[Vector3] = []

	for segment in range(segments):
		var angle := float(segment) * TAU / float(segments)
		var ring_noise := 0.78 + _deterministic_unit(seed, segment) * 0.38
		var top_noise := 0.52 + _deterministic_unit(seed + 13, segment) * 0.28
		var direction := Vector3(cos(angle) * squash_x, 0.0, sin(angle) * squash_z)
		bottom.append(direction * radius * ring_noise)
		middle.append(direction * radius * ring_noise * 0.86 + Vector3(0.0, height * (0.38 + _deterministic_unit(seed, segment + 30) * 0.14), 0.0))
		top.append(direction * radius * top_noise + Vector3(0.0, height * (0.84 + _deterministic_unit(seed, segment + 60) * 0.18), 0.0))

	var bottom_center := Vector3.ZERO
	var top_center := Vector3(0.0, height * (1.02 + _deterministic_unit(seed, 99) * 0.16), 0.0)
	for segment in range(segments):
		var next := (segment + 1) % segments
		_append_rock_triangle(vertices, normals, indices, bottom[segment], bottom[next], middle[segment])
		_append_rock_triangle(vertices, normals, indices, middle[segment], bottom[next], middle[next])
		_append_rock_triangle(vertices, normals, indices, middle[segment], middle[next], top[segment])
		_append_rock_triangle(vertices, normals, indices, top[segment], middle[next], top[next])
		_append_rock_triangle(vertices, normals, indices, top_center, top[segment], top[next])
		_append_rock_triangle(vertices, normals, indices, bottom_center, bottom[next], bottom[segment])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _append_rock_triangle(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal == Vector3.ZERO:
		normal = Vector3.UP
	var start_index := vertices.size()
	vertices.append(a)
	vertices.append(b)
	vertices.append(c)
	normals.append(normal)
	normals.append(normal)
	normals.append(normal)
	indices.append(start_index)
	indices.append(start_index + 1)
	indices.append(start_index + 2)


func _deterministic_unit(seed: int, salt: int) -> float:
	return fmod(absf(sin(float(seed) * 12.9898 + float(salt) * 78.233) * 43758.5453), 1.0)


func _add_target(position: Vector3) -> void:
	var target := StaticBody3D.new()
	target.name = "TargetDummy"
	target.set_script(TargetDummy)
	target.position = position

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.45
	mesh.height = 1.8
	mesh_instance.mesh = mesh
	mesh_instance.position.y = 0.9
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#6c3f2d")
	mesh_instance.material_override = material
	target.add_child(mesh_instance)

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	shape.position.y = 0.9
	shape.shape = capsule
	target.add_child(shape)

	var label := Label3D.new()
	label.name = "Label3D"
	label.position = Vector3(0.0, 2.2, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#f7e6b5")
	target.add_child(label)

	add_child(target)


func _add_soldier(position: Vector3, faction: String, weapon_type: String, power: int, speed: int, dexterity: int) -> void:
	var soldier := CharacterBody3D.new()
	var side := "Friendly" if faction == "friendly" else "Enemy"
	var role := "Archer" if weapon_type == "bow" else "Swordsman"
	soldier.name = "%s%s" % [side, role]
	soldier.set_script(SoldierEnemy)
	soldier.position = position
	soldier.call("setup", player, self, weapon_type, false, faction, power, speed, dexterity)
	add_child(soldier)


func _make_stone_material() -> ShaderMaterial:
	if _stone_material != null:
		return _stone_material

	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform sampler2D stone_albedo : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D stone_height : repeat_enable, filter_linear_mipmap;
uniform float stone_tile = 0.215;

varying vec3 stone_pos;
varying vec3 stone_normal;

void vertex() {
	stone_pos = VERTEX;
	stone_normal = NORMAL;
}

float hash31(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453123);
}

void fragment() {
	vec3 weights = pow(abs(normalize(stone_normal)), vec3(2.0));
	weights /= max(weights.x + weights.y + weights.z, 0.001);

	vec3 p = stone_pos * stone_tile;
	vec3 color_x = texture(stone_albedo, p.zy).rgb;
	vec3 color_y = texture(stone_albedo, p.xz).rgb;
	vec3 color_z = texture(stone_albedo, p.xy).rgb;
	vec3 color = color_x * weights.x + color_y * weights.y + color_z * weights.z;

	float height_x = texture(stone_height, p.zy).r;
	float height_y = texture(stone_height, p.xz).r;
	float height_z = texture(stone_height, p.xy).r;
	float height_mix = height_x * weights.x + height_y * weights.y + height_z * weights.z;
	float object_variation = hash31(floor(stone_pos * 3.0));

	ALBEDO = color * (0.78 + height_mix * 0.28 + object_variation * 0.04);
	ROUGHNESS = 0.96;
}
"""

	_stone_material = ShaderMaterial.new()
	_stone_material.shader = shader
	_stone_material.set_shader_parameter("stone_albedo", StoneAlbedo)
	_stone_material.set_shader_parameter("stone_height", StoneHeight)
	_stone_material.set_shader_parameter("stone_tile", 0.215)
	return _stone_material


func _make_terrain_material() -> Material:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D grass_albedo : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D grass_height : repeat_enable, filter_linear_mipmap;
uniform sampler2D dirt_albedo : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D dirt_height : repeat_enable, filter_linear_mipmap;
uniform float detail_tile = 7.33;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float patch(vec2 uv, vec2 center, vec2 radius, float strength) {
	vec2 p = (uv - center) / radius;
	float d = length(p);
	float edge = value_noise(uv * 24.0 + center * 17.0) * 0.22;
	return (1.0 - smoothstep(0.38 + edge, 1.0 + edge, d)) * strength;
}

float dirt_mask_at(vec2 map_uv) {
	float dirt_mask = 0.0;
	dirt_mask = max(dirt_mask, patch(map_uv, vec2(0.25, 0.50), vec2(0.12, 0.08), 0.95));
	dirt_mask = max(dirt_mask, patch(map_uv, vec2(0.70, 0.24), vec2(0.15, 0.10), 0.90));
	dirt_mask = max(dirt_mask, patch(map_uv, vec2(0.28, 0.72), vec2(0.09, 0.12), 0.82));
	dirt_mask = max(dirt_mask, patch(map_uv, vec2(0.47, 0.22), vec2(0.12, 0.08), 0.72));
	dirt_mask = max(dirt_mask, patch(map_uv, vec2(0.60, 0.63), vec2(0.10, 0.13), 0.78));
	dirt_mask = max(dirt_mask, patch(map_uv, vec2(0.80, 0.55), vec2(0.08, 0.11), 0.62));
	return smoothstep(0.08, 0.85, dirt_mask);
}

void fragment() {
	vec2 map_uv = UV;
	vec2 detail_uv = UV * detail_tile;

	float dirt_mask = dirt_mask_at(map_uv);
	vec3 grass = texture(grass_albedo, detail_uv).rgb;
	vec3 dirt = texture(dirt_albedo, detail_uv * 1.2).rgb;

	vec3 color = mix(grass, dirt, dirt_mask * 0.92);
	color *= 0.97 + value_noise(detail_uv * 26.0) * 0.06;

	vec2 bump_step = vec2(0.018, 0.0);
	float grass_h = texture(grass_height, detail_uv).r;
	float dirt_h = texture(dirt_height, detail_uv * 1.2).r;
	float h = mix(grass_h, dirt_h, dirt_mask);
	float hx = mix(texture(grass_height, detail_uv + bump_step.xy).r, texture(dirt_height, detail_uv * 1.2 + bump_step.xy).r, dirt_mask);
	float hy = mix(texture(grass_height, detail_uv + bump_step.yx).r, texture(dirt_height, detail_uv * 1.2 + bump_step.yx).r, dirt_mask);
	vec3 normal_sample = normalize(vec3((h - hx) * 2.2, (h - hy) * 2.2, 1.0));

	ALBEDO = color;
	NORMAL_MAP = normal_sample * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.55;
	ROUGHNESS = mix(0.94, 0.98, dirt_mask);
}
"""

	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("grass_albedo", TerrainGrassAlbedo)
	material.set_shader_parameter("grass_height", TerrainGrassHeight)
	material.set_shader_parameter("dirt_albedo", TerrainDirtAlbedo)
	material.set_shader_parameter("dirt_height", TerrainDirtHeight)
	material.set_shader_parameter("detail_tile", 7.33)
	return material


func _make_material(albedo: Color, roughness: float, emission_energy: float, use_vertex_color := false, disable_cull := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = roughness
	material.vertex_color_use_as_albedo = use_vertex_color
	if disable_cull:
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = albedo
		material.emission_energy_multiplier = emission_energy
	return material
