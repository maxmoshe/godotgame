extends Node3D

const CombatPlayer := preload("res://scripts/combat_player.gd")
const TargetDummy := preload("res://scripts/target_dummy.gd")

const TERRAIN_SIZE := 88.0
const TERRAIN_STEPS := 72
const TERRAIN_HALF := TERRAIN_SIZE * 0.5
const TERRAIN_FALL_LIMIT := -5.0
const PLAYER_SPAWN := Vector3(0.0, 0.0, 8.0)
const PLAYER_FOOT_CLEARANCE := 0.12
const TERRAIN_COLOR_LOW := Color("#8f7747")
const TERRAIN_COLOR_HIGH := Color("#b99f5e")
const PATH_COLOR := Color("#c0a56d")
const STONE_COLOR := Color("#776f60")
const DRY_GRASS_COLOR := Color("#c5ad6e")
const OLIVE_LEAF_COLOR := Color("#5f7147")
const OLIVE_TRUNK_COLOR := Color("#6c4f36")

@onready var player: CharacterBody3D = $Player
@onready var aim_label: Label = $HUD/AimLabel
@onready var charge_bar: ProgressBar = $HUD/ChargeBar
@onready var reticle: Label = $HUD/Reticle


func _ready() -> void:
	_setup_environment()
	_place_player_on_terrain(PLAYER_SPAWN)


func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return

	if player.global_position.y < TERRAIN_FALL_LIMIT:
		_place_player_on_terrain(PLAYER_SPAWN)

	charge_bar.value = player.get_charge_ratio() * 100.0
	reticle.modulate = Color("#f3d67d") if player.aiming else Color("#f4efe0")
	aim_label.text = "Right mouse: aim, no zoom | Hold/release left mouse: sling | Esc: map"
	if player.aiming:
		aim_label.text = "Aiming: camera FOV stays fixed | Hold/release left mouse: sling | Esc: map"


func _setup_environment() -> void:
	_add_world_environment()
	_add_sun()
	_add_terrain()
	_add_ground_visibility_underlay()
	_add_terrace_wall(Vector3(-17.0, _terrain_height(-17.0, -10.0) + 0.1, -10.0), 20.0, 0.0)
	_add_terrace_wall(Vector3(11.0, _terrain_height(11.0, -17.0) + 0.1, -17.0), 23.0, -12.0)
	_add_terrace_wall(Vector3(-4.0, _terrain_height(-4.0, 8.0) + 0.1, 8.0), 17.0, 8.0)
	_add_sheepfold(Vector3(-24.0, _terrain_height(-24.0, 7.5), 7.5))
	_add_path()
	_add_olive_grove()
	_add_grass_tufts()
	_add_scattered_rocks()
	_add_sheep(Vector3(-27.0, _terrain_height(-27.0, 10.0), 10.0), 30.0)
	_add_sheep(Vector3(-21.0, _terrain_height(-21.0, 5.0), 5.0), -8.0)
	_add_sheep(Vector3(-18.0, _terrain_height(-18.0, 12.5), 12.5), 18.0)
	_add_target(Vector3(0.0, _terrain_height(0.0, -20.0), -20.0))
	_add_target(Vector3(8.5, _terrain_height(8.5, -30.0), -30.0))
	_add_target(Vector3(-13.0, _terrain_height(-13.0, -26.0), -26.0))


func _add_world_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "HillCountryWorld"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#72b9ed")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d9e8ee")
	environment.ambient_light_energy = 0.62
	environment.fog_enabled = true
	environment.fog_light_color = Color("#b9d7e8")
	environment.fog_density = 0.006
	world.environment = environment
	add_child(world)


func _add_sun() -> void:
	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-42.0, 31.0, 0.0)
	light.light_energy = 2.6
	light.shadow_enabled = true
	add_child(light)


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
	underlay.material_override = _make_material(Color("#7f6d43"), 1.0, 0.0)
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
	return maxf(-0.35, north_ridge + west_swell + east_swell + shallow_wadi + ripple - spawn_flatten)


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
	_add_path_ribbon(sampled_points, 2.4)


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


func _add_terrace_wall(position: Vector3, length: float, yaw_degrees: float) -> void:
	var wall := Node3D.new()
	wall.name = "StoneTerraceWall"
	wall.position = position
	wall.rotation_degrees.y = yaw_degrees
	add_child(wall)

	var block_count := int(length / 1.45)
	for index in range(block_count):
		var x := (float(index) - float(block_count - 1) * 0.5) * 1.45
		var local_position := Vector3(x, 0.0, 0.0)
		var world_position := wall.global_transform * local_position
		local_position.y = _terrain_height(world_position.x, world_position.z) - position.y + 0.28
		var size := Vector3(1.25, 0.52, 0.55)
		_add_static_box(wall, "TerraceStone", local_position, size, STONE_COLOR.darkened(0.04 + float(index % 3) * 0.04), 0.98)


func _add_sheepfold(center: Vector3) -> void:
	var wall_length := 8.5
	_add_terrace_wall(center + Vector3(0.0, 0.08, -3.5), wall_length, 0.0)
	_add_terrace_wall(center + Vector3(0.0, 0.08, 3.5), wall_length, 0.0)
	_add_terrace_wall(center + Vector3(-4.3, 0.08, 0.0), 6.6, 90.0)
	_add_terrace_wall(center + Vector3(4.3, 0.08, 0.0), 3.8, 90.0)


func _add_olive_grove() -> void:
	var trees := [
		Vector3(17.0, 0.0, 8.0),
		Vector3(22.0, 0.0, 13.0),
		Vector3(29.0, 0.0, 4.0),
		Vector3(16.0, 0.0, -2.0),
		Vector3(27.0, 0.0, -6.0),
		Vector3(-31.0, 0.0, -8.0),
		Vector3(-25.0, 0.0, -16.0),
	]
	for tree_position in trees:
		tree_position.y = _terrain_height(tree_position.x, tree_position.z)
		_add_olive_tree(tree_position)


func _add_olive_tree(position: Vector3) -> void:
	var tree := Node3D.new()
	tree.name = "OliveTree"
	tree.position = position
	add_child(tree)

	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18
	trunk_mesh.bottom_radius = 0.28
	trunk_mesh.height = 2.2
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.1
	trunk.rotation_degrees.z = 5.0
	trunk.material_override = _make_material(OLIVE_TRUNK_COLOR, 0.9, 0.0)
	tree.add_child(trunk)

	var canopy_offsets := [
		Vector3(0.0, 2.45, 0.0),
		Vector3(0.55, 2.2, 0.18),
		Vector3(-0.45, 2.16, -0.18),
	]
	for offset in canopy_offsets:
		var canopy := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 1.05
		mesh.height = 1.15
		canopy.mesh = mesh
		canopy.position = offset
		canopy.scale = Vector3(1.35, 0.55, 1.05)
		canopy.material_override = _make_material(OLIVE_LEAF_COLOR, 0.95, 0.0)
		tree.add_child(canopy)


func _add_grass_tufts() -> void:
	for index in range(75):
		var angle := float(index) * 2.39996
		var radius := 7.0 + fmod(float(index) * 4.65, 34.0)
		var x := cos(angle) * radius + sin(float(index) * 0.74) * 3.0
		var z := sin(angle) * radius + cos(float(index) * 0.41) * 3.0
		if absf(x) < 3.0 and z > 4.0 and z < 12.0:
			continue
		_add_grass_tuft(Vector3(x, _terrain_height(x, z), z), 0.65 + fmod(float(index), 5.0) * 0.08)


func _add_grass_tuft(position: Vector3, height: float) -> void:
	var tuft := Node3D.new()
	tuft.name = "DryGrassTuft"
	tuft.position = position + Vector3(0.0, 0.02, 0.0)
	add_child(tuft)

	for blade_index in range(4):
		var blade := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.045, height, 0.045)
		blade.mesh = mesh
		blade.position.y = height * 0.5
		blade.rotation_degrees = Vector3(8.0 + float(blade_index) * 3.0, float(blade_index) * 56.0, 12.0)
		blade.material_override = _make_material(DRY_GRASS_COLOR.darkened(float(blade_index) * 0.035), 1.0, 0.0)
		tuft.add_child(blade)


func _add_scattered_rocks() -> void:
	var rock_positions := [
		Vector3(-8.0, 0.0, -12.0),
		Vector3(-4.0, 0.0, -15.0),
		Vector3(3.0, 0.0, -13.0),
		Vector3(14.0, 0.0, -23.0),
		Vector3(23.0, 0.0, -13.0),
		Vector3(-29.0, 0.0, 22.0),
		Vector3(30.0, 0.0, 20.0),
		Vector3(6.0, 0.0, 20.0),
	]
	for index in range(rock_positions.size()):
		var rock_position: Vector3 = rock_positions[index]
		rock_position.y = _terrain_height(rock_position.x, rock_position.z) + 0.18
		_add_rock(rock_position, 0.65 + float(index % 4) * 0.16)


func _add_rock(position: Vector3, radius: float) -> void:
	var rock := StaticBody3D.new()
	rock.name = "LimestoneRock"
	rock.position = position
	rock.rotation_degrees = Vector3(0.0, fmod(position.x * 17.0, 360.0), 0.0)
	add_child(rock)

	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 1.15
	mesh_instance.mesh = mesh
	mesh_instance.scale = Vector3(1.25, 0.55, 0.8)
	mesh_instance.material_override = _make_material(STONE_COLOR.lightened(0.06), 0.96, 0.0)
	rock.add_child(mesh_instance)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(radius * 1.85, radius * 0.72, radius * 1.25)
	shape.shape = box
	rock.add_child(shape)


func _add_sheep(position: Vector3, yaw_degrees: float) -> void:
	var sheep := StaticBody3D.new()
	sheep.name = "Sheep"
	sheep.position = position + Vector3(0.0, 0.34, 0.0)
	sheep.rotation_degrees.y = yaw_degrees
	add_child(sheep)

	var body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.52
	body_mesh.height = 0.75
	body.mesh = body_mesh
	body.scale = Vector3(1.35, 0.72, 0.82)
	body.material_override = _make_material(Color("#e1d8c7"), 0.82, 0.0)
	sheep.add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.32
	head.mesh = head_mesh
	head.position = Vector3(0.64, 0.05, 0.0)
	head.scale = Vector3(0.85, 0.95, 0.75)
	head.material_override = _make_material(Color("#4b4036"), 0.95, 0.0)
	sheep.add_child(head)

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 0.9
	shape.rotation_degrees.z = 90.0
	shape.shape = capsule
	sheep.add_child(shape)


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


func _add_static_box(parent: Node, node_name: String, position: Vector3, size: Vector3, color: Color, roughness: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	parent.add_child(body)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(color, roughness, 0.0)
	body.add_child(mesh_instance)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	return body


func _make_terrain_material() -> StandardMaterial3D:
	var material := _make_material(Color("#927b49"), 0.96, 0.0, false, true)
	material.albedo_color = Color("#927b49")
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
