extends Node3D

const CombatPlayer := preload("res://scripts/combat_player.gd")
const TargetDummy := preload("res://scripts/target_dummy.gd")
const SoldierEnemy := preload("res://scripts/soldier_enemy.gd")
const CombatBiomeProfiles := preload("res://scripts/combat_biome_profiles.gd")
const TerrainGrassAlbedo := preload("res://assets/textures/terrain/rocky_grass/rocky_terrain_02_diff_1k.jpg")
const TerrainGrassHeight := preload("res://assets/textures/terrain/rocky_grass/rocky_terrain_02_disp_1k.png")
const TerrainDirtAlbedo := preload("res://assets/textures/terrain/rocky_gravel/gravelly_sand_diff_1k.jpg")
const TerrainDirtHeight := preload("res://assets/textures/terrain/rocky_gravel/gravelly_sand_disp_1k.png")
const StoneAlbedo := preload("res://assets/textures/terrain/marble/marble_rock_02_diff_1k.jpg")
const StoneHeight := preload("res://assets/textures/terrain/marble/marble_rock_02_disp_1k.png")

const TERRAIN_SIZE := 176.0
const TERRAIN_STEPS := 144
const TERRAIN_HALF := TERRAIN_SIZE * 0.5
const TERRAIN_FALL_LIMIT := -5.0
const GROUND_UNDERLAY_Y := -2.0
const PLAYER_SPAWN := Vector3(0.0, 0.0, 8.0)
const PLAYER_FOOT_CLEARANCE := 0.12
const SMALL_ROCK_COUNT := 240
const SMALL_ROCK_MESH_VARIANTS := 24
const TERRAIN_COLOR_LOW := Color("#566f38")
const TERRAIN_COLOR_HIGH := Color("#8a9a59")
const PATH_COLOR := Color("#c0a56d")
const COMMAND_RAY_LENGTH := 185.0
const COMMAND_RAY_STEP := 0.45
const COMMAND_INVALID_POSITION := Vector3(999999.0, 999999.0, 999999.0)
const FORMATION_SPACING := 1.65
const BATTLE_FORMATION_SPACING := 2.25
const BATTLE_FORMATION_COLUMNS := 15
const BATTLE_ARCHER_REAR_OFFSET := 5.0
const BATTLE_ARCHER_SIDE_OFFSET := 1.45
const CAMPAIGN_CHUNK_SIZE := 220.0
const CAMPAIGN_TO_TERRAIN_SCALE := 8.0
const COMBAT_SPATIAL_CELL_SIZE := 6.0
const COMBAT_SPATIAL_REFRESH_SECONDS := 0.16
const COMMAND_GROUP_ALL := "all"
const COMMAND_GROUP_MELEE := "melee"
const COMMAND_GROUP_ARCHERS := "archers"
const BATTLEFIELD_EDGE_MARGIN := 6.0
const BATTLEFIELD_WALL_HALF := TERRAIN_HALF - BATTLEFIELD_EDGE_MARGIN
const BATTLEFIELD_WALL_COLLISION_LAYER := 8
const BATTLEFIELD_WALL_THICKNESS := 0.72
const BATTLEFIELD_WALL_HEIGHT := 20.0
const BATTLEFIELD_WALL_FADE_NEAR := 1.4
const BATTLEFIELD_WALL_FADE_FAR := 19.0
const BATTLEFIELD_FLEE_PROMPT_DISTANCE := 5.5
const BATTLEFIELD_NPC_EXIT_MARGIN := 0.35

@onready var player: CharacterBody3D = $Player
@onready var player_camera: Camera3D = $Player/CameraPivot/Camera3D
@onready var aim_label: Label = $HUD/AimLabel
@onready var charge_bar: ProgressBar = $HUD/ChargeBar
@onready var reticle: Label = $HUD/Reticle
@onready var velocity_label: Label = $HUD/VelocityLabel
@onready var health_label: Label = $HUD/HealthLabel

var _decoration_exclusions: Array[Dictionary] = []
var _stone_material: ShaderMaterial
var _clump_material: StandardMaterial3D
var _clump_mesh: CylinderMesh
var _battlefield_wall_material: ShaderMaterial
var _small_rock_mesh_cache: Dictionary = {}
var _last_sling_impact_speed := 0.0
var _last_sling_damage := 0
var _last_sling_xp_gain := 0
var _last_sling_xp_multiplier := 1.0
var _last_sling_headshot := false
var _last_sling_flight_distance := 0.0
var _command_mode := false
var _group_selection_mode := false
var _selected_command_group := COMMAND_GROUP_ALL
var _command_position := Vector3.ZERO
var _command_marker: Node3D
var _command_menu_label: Label
var _combat_campaign_position := Vector2.ZERO
var _combat_chunk := Vector2i.ZERO
var _combat_seed := 1
var _combat_local_terrain_offset := Vector2.ZERO
var _combat_decoration_offset := Vector2.ZERO
var _combat_uv_offset := Vector2.ZERO
var _combat_context: Dictionary = {}
var _combat_map_context: Dictionary = {}
var _biome_profile: Dictionary = {}
var _combat_result_applied := false
var _lord_enemy_start_count := 0
var _lord_friendly_start_count := 0
var _lord_enemy_dead_count := 0
var _lord_friendly_dead_count := 0
var _lord_enemy_fled_count := 0
var _lord_friendly_fled_count := 0
var _enemy_source_start_counts: Dictionary = {}
var _enemy_source_dead_counts: Dictionary = {}
var _enemy_source_fled_counts: Dictionary = {}
var _enemy_source_details: Dictionary = {}
var _friendly_source_start_counts: Dictionary = {}
var _friendly_source_dead_counts: Dictionary = {}
var _friendly_source_fled_counts: Dictionary = {}
var _friendly_source_details: Dictionary = {}
var _combat_soldiers: Array[Node3D] = []
var _combat_soldiers_by_faction := {}
var _combat_spatial_buckets := {}
var _combat_spatial_dirty := true
var _combat_spatial_refresh_time := 0.0
var _flee_prompt_panel: Panel
var _flee_prompt_title: Label
var _flee_prompt_body: Label
var _flee_prompt_visible := false


func _ready() -> void:
	_combat_context = GameState.get_combat_context()
	_combat_map_context = GameState.get_combat_map_context()
	_biome_profile = CombatBiomeProfiles.profile_for_id(int(_combat_map_context.get("biome_id", CombatBiomeProfiles.DEFAULT_BIOME_ID)))
	_capture_combat_map_context()
	_setup_player_boundary_collision()
	_setup_environment()
	_setup_command_ui()
	_setup_flee_prompt()
	_place_player_on_terrain(PLAYER_SPAWN)


func _process(delta: float) -> void:
	_update_combat_spatial_index(delta)
	_update_battlefield_boundary()
	_remove_fleeing_soldiers_beyond_wall()

	if Input.is_key_pressed(KEY_ESCAPE):
		if _is_lord_combat():
			_finish_lord_combat("retreat")
		else:
			GameState.clear_combat_context()
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
		aim_label.text = "Aiming: 1.5x zoom | Early release cancels, full charge is the first firing window | Esc: map"

	_update_velocity_label()
	_check_lord_combat_result()


func register_combat_soldier(soldier: Node3D, soldier_faction: String) -> void:
	if soldier == null or _combat_soldiers.has(soldier):
		return

	_combat_soldiers.append(soldier)
	if not _combat_soldiers_by_faction.has(soldier_faction):
		_combat_soldiers_by_faction[soldier_faction] = []
	var faction_soldiers: Array = _combat_soldiers_by_faction[soldier_faction]
	faction_soldiers.append(soldier)
	_combat_spatial_dirty = true


func unregister_combat_soldier(soldier: Node3D, soldier_faction: String) -> void:
	if soldier == null:
		return

	_combat_soldiers.erase(soldier)
	if _combat_soldiers_by_faction.has(soldier_faction):
		var faction_soldiers: Array = _combat_soldiers_by_faction[soldier_faction]
		faction_soldiers.erase(soldier)
	_combat_spatial_dirty = true


func get_combat_soldiers() -> Array[Node3D]:
	return _combat_soldiers


func get_combat_soldiers_for_faction(soldier_faction: String) -> Array:
	return Array(_combat_soldiers_by_faction.get(soldier_faction, []))


func get_combat_soldier_count() -> int:
	return _combat_soldiers.size()


func get_combat_terrain_height(position: Vector3) -> float:
	return _terrain_height(position.x, position.z)


func get_combat_terrain_slope(position: Vector3) -> float:
	var normal := _terrain_normal(position.x, position.z)
	return 1.0 - clampf(normal.dot(Vector3.UP), 0.0, 1.0)


func get_nearby_combat_soldiers(center: Vector3, radius: float, soldier_faction := "") -> Array[Node3D]:
	if _combat_spatial_dirty or _combat_spatial_buckets.is_empty():
		_rebuild_combat_spatial_index()

	var result: Array[Node3D] = []
	var radius_squared := radius * radius
	var center_key := _combat_spatial_key(center)
	var cell_radius := int(ceil(radius / COMBAT_SPATIAL_CELL_SIZE))
	for x_offset in range(-cell_radius, cell_radius + 1):
		for z_offset in range(-cell_radius, cell_radius + 1):
			var bucket_key := Vector2i(center_key.x + x_offset, center_key.y + z_offset)
			var bucket: Array = _combat_spatial_buckets.get(bucket_key, [])
			for soldier in bucket:
				var node := soldier as Node3D
				if not _is_live_combat_soldier(node):
					continue
				if soldier_faction != "":
					if not node.has_method("get_faction") or node.get_faction() != soldier_faction:
						continue
				if node.global_position.distance_squared_to(center) <= radius_squared:
					result.append(node)
	return result


func _update_combat_spatial_index(delta: float) -> void:
	_combat_spatial_refresh_time = maxf(0.0, _combat_spatial_refresh_time - delta)
	if _combat_spatial_refresh_time > 0.0 and not _combat_spatial_dirty:
		return

	_combat_spatial_refresh_time = COMBAT_SPATIAL_REFRESH_SECONDS
	_rebuild_combat_spatial_index()


func _rebuild_combat_spatial_index() -> void:
	_prune_combat_soldier_registry()
	_combat_spatial_buckets.clear()
	for soldier in _combat_soldiers:
		if not _is_live_combat_soldier(soldier):
			continue
		var bucket_key := _combat_spatial_key(soldier.global_position)
		if not _combat_spatial_buckets.has(bucket_key):
			_combat_spatial_buckets[bucket_key] = []
		var bucket: Array = _combat_spatial_buckets[bucket_key]
		bucket.append(soldier)
	_combat_spatial_dirty = false


func _prune_combat_soldier_registry() -> void:
	for index in range(_combat_soldiers.size() - 1, -1, -1):
		if not _is_live_combat_soldier(_combat_soldiers[index]):
			_combat_soldiers.remove_at(index)

	for faction_key in _combat_soldiers_by_faction.keys():
		var faction_soldiers: Array = _combat_soldiers_by_faction[faction_key]
		for index in range(faction_soldiers.size() - 1, -1, -1):
			var soldier := faction_soldiers[index] as Node3D
			if not _is_live_combat_soldier(soldier):
				faction_soldiers.remove_at(index)


func _combat_spatial_key(position: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(position.x / COMBAT_SPATIAL_CELL_SIZE)),
		int(floor(position.z / COMBAT_SPATIAL_CELL_SIZE))
	)


func _is_live_combat_soldier(soldier: Node3D) -> bool:
	if soldier == null or not is_instance_valid(soldier):
		return false
	if soldier.has_method("is_alive") and not soldier.is_alive():
		return false
	return true


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	if _group_selection_mode:
		if key_event.keycode == KEY_F1:
			_select_command_group(COMMAND_GROUP_ALL)
		elif key_event.keycode == KEY_F2:
			_select_command_group(COMMAND_GROUP_MELEE)
		elif key_event.keycode == KEY_F3:
			_select_command_group(COMMAND_GROUP_ARCHERS)
		else:
			return
		_mark_input_as_handled()
		return

	if key_event.keycode == KEY_F1:
		if _command_mode:
			_issue_hold_position_order()
		else:
			_set_command_mode(true)
		_mark_input_as_handled()
	elif key_event.keycode == KEY_E and _flee_prompt_visible:
		_flee_from_battlefield()
		_mark_input_as_handled()
	elif _is_group_selection_key(key_event):
		_set_group_selection_mode(true)
		_mark_input_as_handled()
	elif key_event.keycode == KEY_F3:
		_issue_charge_order()
		_set_command_mode(false)
		_mark_input_as_handled()


func _mark_input_as_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _setup_player_boundary_collision() -> void:
	if player == null:
		return
	player.collision_mask = player.collision_mask | BATTLEFIELD_WALL_COLLISION_LAYER


func _setup_flee_prompt() -> void:
	_flee_prompt_panel = Panel.new()
	_flee_prompt_panel.name = "FleePrompt"
	_flee_prompt_panel.anchor_left = 0.5
	_flee_prompt_panel.anchor_right = 0.5
	_flee_prompt_panel.anchor_top = 1.0
	_flee_prompt_panel.anchor_bottom = 1.0
	_flee_prompt_panel.offset_left = -250.0
	_flee_prompt_panel.offset_right = 250.0
	_flee_prompt_panel.offset_top = -148.0
	_flee_prompt_panel.offset_bottom = -54.0
	_flee_prompt_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.045, 0.035, 0.88)
	style.border_color = Color("#d6b46a")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	_flee_prompt_panel.add_theme_stylebox_override("panel", style)

	var layout := VBoxContainer.new()
	layout.anchor_right = 1.0
	layout.anchor_bottom = 1.0
	layout.offset_left = 18.0
	layout.offset_top = 12.0
	layout.offset_right = -18.0
	layout.offset_bottom = -12.0
	layout.add_theme_constant_override("separation", 5)
	_flee_prompt_panel.add_child(layout)

	_flee_prompt_title = Label.new()
	_flee_prompt_title.add_theme_color_override("font_color", Color("#f2d58b"))
	_flee_prompt_title.add_theme_font_size_override("font_size", 20)
	_flee_prompt_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flee_prompt_title.text = "Edge of the field"
	layout.add_child(_flee_prompt_title)

	_flee_prompt_body = Label.new()
	_flee_prompt_body.add_theme_color_override("font_color", Color("#f4efe0"))
	_flee_prompt_body.add_theme_font_size_override("font_size", 16)
	_flee_prompt_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flee_prompt_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_flee_prompt_body)

	$HUD.add_child(_flee_prompt_panel)
	_update_flee_prompt(false)


func _flee_from_battlefield() -> void:
	if _combat_result_applied:
		return

	if _is_lord_combat():
		_finish_lord_combat("retreat")
	else:
		GameState.clear_combat_context()
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func _update_battlefield_boundary() -> void:
	if _battlefield_wall_material != null and player != null:
		_battlefield_wall_material.set_shader_parameter("player_position", player.global_position)
	_update_flee_prompt(_is_player_near_battlefield_wall())


func _update_flee_prompt(visible: bool) -> void:
	_flee_prompt_visible = visible
	if _flee_prompt_panel == null:
		return

	_flee_prompt_panel.visible = visible
	if not visible or _flee_prompt_body == null:
		return

	if _is_lord_combat():
		_flee_prompt_body.text = "Press E to flee back to the campaign map.\nBack away to keep fighting."
	else:
		_flee_prompt_body.text = "Press E to leave the sling test.\nBack away to keep fighting."


func _is_player_near_battlefield_wall() -> bool:
	if player == null or _combat_result_applied:
		return false
	return _distance_inside_battlefield_wall(player.global_position) <= BATTLEFIELD_FLEE_PROMPT_DISTANCE


func _distance_inside_battlefield_wall(position: Vector3) -> float:
	return BATTLEFIELD_WALL_HALF - maxf(absf(position.x), absf(position.z))


func _remove_fleeing_soldiers_beyond_wall() -> void:
	var soldiers := _combat_soldiers.duplicate()
	for soldier in soldiers:
		var soldier_node := soldier as Node3D
		if not _is_live_combat_soldier(soldier_node):
			continue
		if not soldier_node.has_method("is_fleeing") or not soldier_node.call("is_fleeing"):
			continue
		if not _is_past_battlefield_wall(soldier_node.global_position):
			continue
		if soldier_node.has_method("leave_battlefield"):
			soldier_node.call("leave_battlefield")
		else:
			soldier_node.queue_free()


func _is_past_battlefield_wall(position: Vector3) -> bool:
	var exit_half := BATTLEFIELD_WALL_HALF + BATTLEFIELD_NPC_EXIT_MARGIN
	return absf(position.x) >= exit_half or absf(position.z) >= exit_half


func set_last_sling_impact(impact_speed: float, damage: int, xp_gain := 0, xp_multiplier := 1.0, was_headshot := false, flight_distance := 0.0) -> void:
	_last_sling_impact_speed = impact_speed
	_last_sling_damage = damage
	_last_sling_xp_gain = maxi(0, xp_gain)
	_last_sling_xp_multiplier = maxf(1.0, xp_multiplier)
	_last_sling_headshot = was_headshot
	_last_sling_flight_distance = maxf(0.0, flight_distance)


func award_player_sling_xp(amount: int) -> int:
	return GameState.award_player_sling_xp(amount)


func get_sling_xp_map_distance() -> float:
	return BATTLEFIELD_WALL_HALF * 2.0


func _update_velocity_label() -> void:
	var live_speed := _current_sling_speed()
	var sling_xp := GameState.get_player_sling_xp()
	if _last_sling_impact_speed <= 0.0:
		velocity_label.text = "Stone velocity: %.1f | Sling XP: %d\nLast hit: --" % [live_speed, sling_xp]
	else:
		var hit_label := "headshot" if _last_sling_headshot else "hit"
		velocity_label.text = "Stone velocity: %.1f | Sling XP: %d\nLast %s: %.1fm -> %d dmg | +%d XP x%.1f" % [
			live_speed,
			sling_xp,
			hit_label,
			_last_sling_flight_distance,
			_last_sling_damage,
			_last_sling_xp_gain,
			_last_sling_xp_multiplier
		]


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
	_update_command_menu_label()
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
		_update_command_menu_label()
		_command_menu_label.visible = enabled or _group_selection_mode


func _set_group_selection_mode(enabled: bool) -> void:
	_group_selection_mode = enabled
	if _command_menu_label != null:
		_update_command_menu_label()
		_command_menu_label.visible = enabled or _command_mode


func _select_command_group(command_group: String) -> void:
	_selected_command_group = command_group
	_set_group_selection_mode(false)


func _update_command_menu_label() -> void:
	if _command_menu_label == null:
		return

	if _group_selection_mode:
		_command_menu_label.text = "Select group\nF1: ALL\nF2: melee\nF3: archers"
		return

	_command_menu_label.text = "Group: %s\nF1: hold position\n`/~: select group\nF3: charge" % _command_group_display_name(_selected_command_group)


func _is_group_selection_key(key_event: InputEventKey) -> bool:
	return key_event.keycode == KEY_QUOTELEFT or key_event.physical_keycode == KEY_QUOTELEFT or key_event.unicode == 96 or key_event.unicode == 126


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
		if point.x < -BATTLEFIELD_WALL_HALF or point.x > BATTLEFIELD_WALL_HALF or point.z < -BATTLEFIELD_WALL_HALF or point.z > BATTLEFIELD_WALL_HALF:
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

	var soldiers := _friendly_soldiers(_selected_command_group)
	var count := soldiers.size()
	for index in range(count):
		var soldier := soldiers[index]
		if soldier.has_method("receive_order"):
			soldier.call("receive_order", "hold", _formation_slot_position(_command_position, index, count), index)
	_set_command_mode(false)


func _issue_charge_order() -> void:
	var soldiers := _friendly_soldiers(_selected_command_group)
	for index in range(soldiers.size()):
		var soldier := soldiers[index]
		if soldier.has_method("receive_order"):
			soldier.call("receive_order", "charge", Vector3.ZERO, index)


func _friendly_soldiers(command_group := COMMAND_GROUP_ALL) -> Array[Node3D]:
	var soldiers: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group("combat_soldiers"):
		if not node.has_method("get_faction") or not node.has_method("is_alive"):
			continue
		if node.get_faction() != "friendly" or not node.is_alive():
			continue
		if not _soldier_matches_command_group(node, command_group):
			continue
		var soldier := node as Node3D
		if soldier != null:
			soldiers.append(soldier)
	return soldiers


func _soldier_matches_command_group(soldier: Node, command_group: String) -> bool:
	if command_group == COMMAND_GROUP_ALL:
		return true
	if not soldier.has_method("get_weapon_type"):
		return command_group == COMMAND_GROUP_MELEE

	var weapon_type := String(soldier.call("get_weapon_type"))
	if command_group == COMMAND_GROUP_ARCHERS:
		return weapon_type == "bow"
	if command_group == COMMAND_GROUP_MELEE:
		return weapon_type != "bow"
	return true


func _command_group_display_name(command_group: String) -> String:
	if command_group == COMMAND_GROUP_MELEE:
		return "melee"
	if command_group == COMMAND_GROUP_ARCHERS:
		return "archers"
	return "ALL"


func _formation_slot_position(center: Vector3, index: int, count: int) -> Vector3:
	var side := player.global_transform.basis.x
	side.y = 0.0
	if side.length() <= 0.01:
		side = Vector3.RIGHT
	side = side.normalized()

	var offset := (float(index) - float(count - 1) * 0.5) * FORMATION_SPACING
	var slot := center + side * offset
	slot.x = clampf(slot.x, -BATTLEFIELD_WALL_HALF + 1.0, BATTLEFIELD_WALL_HALF - 1.0)
	slot.z = clampf(slot.z, -BATTLEFIELD_WALL_HALF + 1.0, BATTLEFIELD_WALL_HALF - 1.0)
	slot.y = _terrain_height(slot.x, slot.z) + PLAYER_FOOT_CLEARANCE
	return slot


func _setup_environment() -> void:
	_add_world_environment()
	_add_sun()
	_add_terrain()
	_add_ground_visibility_underlay()
	_add_battlefield_boundary()
	_add_wadis()
	_add_path()
	_add_small_rocks()
	_add_ground_clumps()
	if _is_lord_combat():
		_add_lord_combat_parties()
	else:
		_add_test_targets_and_soldiers()


func _add_test_targets_and_soldiers() -> void:
	_add_target(Vector3(0.0, _terrain_height(0.0, -20.0), -20.0))
	_add_target(Vector3(8.5, _terrain_height(8.5, -30.0), -30.0))
	_add_target(Vector3(-13.0, _terrain_height(-13.0, -26.0), -26.0))
	_add_soldier(Vector3(-9.0, _terrain_height(-9.0, -12.0), -12.0), "enemy", "sword", 5, 5, 3)
	_add_soldier(Vector3(-5.5, _terrain_height(-5.5, -15.0), -15.0), "enemy", "sword", 5, 5, 3)
	_add_soldier(Vector3(-13.5, _terrain_height(-13.5, -9.0), -9.0), "enemy", "bow", 3, 5, 4)
	_add_soldier(Vector3(4.0, _terrain_height(4.0, -5.0), -5.0), "friendly", "sword", 5, 5, 3)
	_add_soldier(Vector3(7.0, _terrain_height(7.0, -8.0), -8.0), "friendly", "sword", 5, 5, 3)
	_add_soldier(Vector3(10.5, _terrain_height(10.5, -3.5), -3.5), "friendly", "bow", 3, 5, 4)


func _add_lord_combat_parties() -> void:
	var lead_enemy_count := maxi(0, int(_combat_context.get("enemy_party_size", 0)))
	var enemy_reinforcements := _combat_enemy_reinforcements()
	var enemy_reinforcement_count := _reinforcement_soldier_count(enemy_reinforcements)
	var enemy_count := lead_enemy_count + enemy_reinforcement_count
	var player_party := Dictionary(_combat_context.get("player_party", {}))
	var player_friendly_count := _party_combat_soldier_count(player_party)
	var reinforcements := _combat_friendly_reinforcements()
	var reinforcement_count := _reinforcement_soldier_count(reinforcements)
	var friendly_count := player_friendly_count + reinforcement_count
	_lord_enemy_start_count = enemy_count
	_lord_friendly_start_count = friendly_count
	_lord_enemy_dead_count = 0
	_lord_friendly_dead_count = 0
	_lord_enemy_fled_count = 0
	_lord_friendly_fled_count = 0
	_reset_enemy_source_tracking()
	_reset_friendly_source_tracking()
	var enemy_lord_id := String(_combat_context.get("enemy_lord_id", _combat_context.get("enemy_name", "")))
	var enemy_source_id := "enemy_lord:%s" % enemy_lord_id
	_register_enemy_source(enemy_source_id, "lord", String(_combat_context.get("enemy_name", enemy_lord_id)), lead_enemy_count, String(_combat_context.get("enemy_faction", "")), enemy_lord_id)
	_register_friendly_source("player", "player", "David's Band", player_friendly_count, "David's Band")

	var enemy_index := 0
	for index in range(lead_enemy_count):
		var weapon := _enemy_weapon_for_index(index)
		var position := _battle_spawn_position(enemy_index, enemy_count, "enemy")
		var soldier := _add_soldier(position, "enemy", weapon, 5, 5, 4 if weapon == "bow" else 3)
		_set_combat_source(soldier, enemy_source_id)
		_assign_battle_slot(soldier, _battle_engagement_slot_position(enemy_index, enemy_count, "enemy", weapon), enemy_index)
		enemy_index += 1

	for raw_reinforcement in enemy_reinforcements:
		var reinforcement := Dictionary(raw_reinforcement)
		var lord_id := String(reinforcement.get("lord_id", reinforcement.get("name", "")))
		var source_id := "enemy_lord:%s" % lord_id
		var count := maxi(0, int(reinforcement.get("party_size", 0)))
		if count <= 0:
			continue
		_register_enemy_source(source_id, "lord", String(reinforcement.get("name", lord_id)), count, String(reinforcement.get("faction", "")), lord_id)
		for index in range(count):
			var weapon := _enemy_weapon_for_index(enemy_index)
			var position := _battle_spawn_position(enemy_index, enemy_count, "enemy")
			var soldier := _add_soldier(position, "enemy", weapon, 5, 5, 4 if weapon == "bow" else 3)
			_set_combat_source(soldier, source_id)
			_assign_battle_slot(soldier, _battle_engagement_slot_position(enemy_index, enemy_count, "enemy", weapon), enemy_index)
			enemy_index += 1

	var friendly_index := 0
	for index in range(player_friendly_count):
		var weapon := _friendly_weapon_for_index(index)
		var position := _battle_spawn_position(friendly_index, friendly_count, "friendly")
		var soldier := _add_soldier(position, "friendly", weapon, 5, 5, 4 if weapon == "bow" else 3)
		_set_combat_source(soldier, "player")
		_assign_battle_slot(soldier, _battle_engagement_slot_position(friendly_index, friendly_count, "friendly", weapon), friendly_index)
		friendly_index += 1

	for raw_reinforcement in reinforcements:
		var reinforcement := Dictionary(raw_reinforcement)
		var lord_id := String(reinforcement.get("lord_id", reinforcement.get("name", "")))
		var source_id := "lord:%s" % lord_id
		var count := maxi(0, int(reinforcement.get("party_size", 0)))
		if count <= 0:
			continue
		_register_friendly_source(source_id, "lord", String(reinforcement.get("name", lord_id)), count, String(reinforcement.get("faction", "")), lord_id)
		for index in range(count):
			var weapon := _friendly_weapon_for_index(friendly_index)
			var position := _battle_spawn_position(friendly_index, friendly_count, "friendly")
			var soldier := _add_soldier(position, "friendly", weapon, 5, 5, 4 if weapon == "bow" else 3)
			_set_combat_source(soldier, source_id)
			_assign_battle_slot(soldier, _battle_engagement_slot_position(friendly_index, friendly_count, "friendly", weapon), friendly_index)
			friendly_index += 1


func _party_combat_soldier_count(player_party: Dictionary) -> int:
	var generic_count := int(player_party.get("generic_soldier_count", 0))
	var named_characters := Array(player_party.get("named_characters", []))
	return maxi(0, generic_count) + named_characters.size()


func _combat_friendly_reinforcements() -> Array:
	var reinforcements: Array = []
	for raw_reinforcement in Array(_combat_context.get("friendly_reinforcements", [])):
		if raw_reinforcement is Dictionary:
			reinforcements.append(Dictionary(raw_reinforcement).duplicate(true))
	return reinforcements


func _combat_enemy_reinforcements() -> Array:
	var reinforcements: Array = []
	for raw_reinforcement in Array(_combat_context.get("enemy_reinforcements", [])):
		if raw_reinforcement is Dictionary:
			reinforcements.append(Dictionary(raw_reinforcement).duplicate(true))
	return reinforcements


func _reinforcement_soldier_count(reinforcements: Array) -> int:
	var count := 0
	for raw_reinforcement in reinforcements:
		var reinforcement := Dictionary(raw_reinforcement)
		count += maxi(0, int(reinforcement.get("party_size", 0)))
	return count


func _reset_friendly_source_tracking() -> void:
	_friendly_source_start_counts.clear()
	_friendly_source_dead_counts.clear()
	_friendly_source_fled_counts.clear()
	_friendly_source_details.clear()


func _reset_enemy_source_tracking() -> void:
	_enemy_source_start_counts.clear()
	_enemy_source_dead_counts.clear()
	_enemy_source_fled_counts.clear()
	_enemy_source_details.clear()


func _register_enemy_source(source_id: String, source_type: String, source_name: String, start_count: int, faction: String = "", lord_id: String = "") -> void:
	if source_id.is_empty():
		return
	_enemy_source_start_counts[source_id] = maxi(0, start_count)
	_enemy_source_dead_counts[source_id] = 0
	_enemy_source_fled_counts[source_id] = 0
	_enemy_source_details[source_id] = {
		"source_id": source_id,
		"source_type": source_type,
		"name": source_name,
		"faction": faction,
		"lord_id": lord_id
	}


func _register_friendly_source(source_id: String, source_type: String, source_name: String, start_count: int, faction: String = "", lord_id: String = "") -> void:
	if source_id.is_empty():
		return
	_friendly_source_start_counts[source_id] = maxi(0, start_count)
	_friendly_source_dead_counts[source_id] = 0
	_friendly_source_fled_counts[source_id] = 0
	_friendly_source_details[source_id] = {
		"source_id": source_id,
		"source_type": source_type,
		"name": source_name,
		"faction": faction,
		"lord_id": lord_id
	}


func _set_combat_source(soldier: Node, source_id: String) -> void:
	if soldier == null:
		return
	soldier.set_meta("combat_source_id", source_id)


func _battle_spawn_position(index: int, count: int, faction: String) -> Vector3:
	var columns := mini(BATTLE_FORMATION_COLUMNS, maxi(1, count))
	var row := int(index / columns)
	var column := index % columns
	var row_width := float(columns - 1) * BATTLE_FORMATION_SPACING
	var x := float(column) * BATTLE_FORMATION_SPACING - row_width * 0.5
	var z := 14.0 + float(row) * BATTLE_FORMATION_SPACING
	if faction == "enemy":
		z = -18.0 - float(row) * BATTLE_FORMATION_SPACING

	x = clampf(x, -BATTLEFIELD_WALL_HALF + 2.0, BATTLEFIELD_WALL_HALF - 2.0)
	z = clampf(z, -BATTLEFIELD_WALL_HALF + 2.0, BATTLEFIELD_WALL_HALF - 2.0)
	return Vector3(x, _terrain_height(x, z) + PLAYER_FOOT_CLEARANCE, z)


func _battle_engagement_slot_position(index: int, count: int, faction: String, weapon: String) -> Vector3:
	var columns := mini(BATTLE_FORMATION_COLUMNS, maxi(1, count))
	var row := int(index / columns)
	var column := index % columns
	var row_width := float(columns - 1) * BATTLE_FORMATION_SPACING
	var x := float(column) * BATTLE_FORMATION_SPACING - row_width * 0.5
	var row_spacing := BATTLE_FORMATION_SPACING * 0.82
	var z := 6.5 + float(row) * row_spacing
	if faction == "enemy":
		z = -7.5 - float(row) * row_spacing

	if weapon == "bow":
		x += _battle_archer_side_offset(index)
		z += _battle_archer_rear_offset(faction)

	x = clampf(x, -BATTLEFIELD_WALL_HALF + 2.0, BATTLEFIELD_WALL_HALF - 2.0)
	z = clampf(z, -BATTLEFIELD_WALL_HALF + 2.0, BATTLEFIELD_WALL_HALF - 2.0)
	return Vector3(x, _terrain_height(x, z) + PLAYER_FOOT_CLEARANCE, z)


func _battle_archer_side_offset(index: int) -> float:
	var side := 1.0 if index % 2 == 0 else -1.0
	return side * BATTLE_ARCHER_SIDE_OFFSET


func _battle_archer_rear_offset(faction: String) -> float:
	return -BATTLE_ARCHER_REAR_OFFSET if faction == "enemy" else BATTLE_ARCHER_REAR_OFFSET


func _assign_battle_slot(soldier: Node3D, slot_position: Vector3, index: int) -> void:
	if soldier != null and soldier.has_method("assign_battle_slot"):
		soldier.call("assign_battle_slot", slot_position, index)


func _enemy_weapon_for_index(index: int) -> String:
	if index % 5 == 4:
		return "bow"
	return "sword"


func _friendly_weapon_for_index(index: int) -> String:
	if index % 6 == 5:
		return "bow"
	return "sword"


func _is_lord_combat() -> bool:
	return String(_combat_context.get("type", "")) == "lord"


func _on_combat_soldier_died(faction: String, soldier: Node = null) -> void:
	if not _is_lord_combat() or _combat_result_applied:
		return
	if faction == "enemy":
		_lord_enemy_dead_count += 1
		_record_source_loss(soldier, _enemy_source_dead_counts, "enemy_lord:%s" % String(_combat_context.get("enemy_lord_id", _combat_context.get("enemy_name", ""))))
	elif faction == "friendly":
		_lord_friendly_dead_count += 1
		_record_source_loss(soldier, _friendly_source_dead_counts, "player")


func _on_combat_soldier_left_battlefield(faction: String, soldier: Node = null) -> void:
	if not _is_lord_combat() or _combat_result_applied:
		return
	if faction == "enemy":
		_lord_enemy_fled_count += 1
		_record_source_loss(soldier, _enemy_source_fled_counts, "enemy_lord:%s" % String(_combat_context.get("enemy_lord_id", _combat_context.get("enemy_name", ""))))
	elif faction == "friendly":
		_lord_friendly_fled_count += 1
		_record_source_loss(soldier, _friendly_source_fled_counts, "player")


func _current_fleeing_soldier_count(faction: String) -> int:
	var count := 0
	for soldier in _combat_soldiers:
		var soldier_node := soldier as Node3D
		if soldier_node == null or not is_instance_valid(soldier_node):
			continue
		if soldier_node.has_method("is_alive") and not soldier_node.call("is_alive"):
			continue
		if not soldier_node.has_method("get_faction") or String(soldier_node.call("get_faction")) != faction:
			continue
		if soldier_node.has_method("is_fleeing") and soldier_node.call("is_fleeing"):
			count += 1
	return count


func _record_current_fleeing_soldiers() -> void:
	for soldier in _combat_soldiers:
		var soldier_node := soldier as Node3D
		if soldier_node == null or not is_instance_valid(soldier_node):
			continue
		if soldier_node.has_method("is_alive") and not soldier_node.call("is_alive"):
			continue
		if not soldier_node.has_method("is_fleeing") or not soldier_node.call("is_fleeing"):
			continue
		if not soldier_node.has_method("get_faction"):
			continue

		var faction := String(soldier_node.call("get_faction"))
		if faction == "enemy":
			_lord_enemy_fled_count += 1
			_record_source_loss(soldier_node, _enemy_source_fled_counts, "enemy_lord:%s" % String(_combat_context.get("enemy_lord_id", _combat_context.get("enemy_name", ""))))
		elif faction == "friendly":
			_lord_friendly_fled_count += 1
			_record_source_loss(soldier_node, _friendly_source_fled_counts, "player")


func _record_source_loss(soldier: Node, counter: Dictionary, fallback_source_id: String) -> void:
	var source_id := fallback_source_id
	if soldier != null and soldier.has_meta("combat_source_id"):
		source_id = String(soldier.get_meta("combat_source_id"))
	counter[source_id] = int(counter.get(source_id, 0)) + 1


func _check_lord_combat_result() -> void:
	if not _is_lord_combat() or _combat_result_applied:
		return
	var enemy_fleeing_count := _current_fleeing_soldier_count("enemy")
	if _lord_enemy_start_count <= 0 or _lord_enemy_dead_count + _lord_enemy_fled_count + enemy_fleeing_count >= _lord_enemy_start_count:
		_finish_lord_combat("victory")
		return
	if player.health <= 0:
		_finish_lord_combat("defeat")


func _finish_lord_combat(outcome: String) -> void:
	if _combat_result_applied:
		return
	_record_current_fleeing_soldiers()
	_combat_result_applied = true

	GameState.apply_lord_combat_result({
		"outcome": outcome,
		"enemy_lord_id": String(_combat_context.get("enemy_lord_id", _combat_context.get("enemy_name", ""))),
		"enemy_name": String(_combat_context.get("enemy_name", "Enemy lord")),
		"enemy_start_count": _lord_enemy_start_count,
		"enemy_dead_count": _lord_enemy_dead_count,
		"enemy_fled_count": _lord_enemy_fled_count,
		"enemy_source_losses": _enemy_source_loss_data(),
		"friendly_start_count": _lord_friendly_start_count,
		"friendly_dead_count": _lord_friendly_dead_count,
		"friendly_fled_count": _lord_friendly_fled_count,
		"friendly_source_losses": _friendly_source_loss_data(),
		"player_health": player.health,
		"player_max_health": player.max_health
	})
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _friendly_source_loss_data() -> Array[Dictionary]:
	var losses: Array[Dictionary] = []
	for source_id in _friendly_source_start_counts.keys():
		var details := Dictionary(_friendly_source_details.get(source_id, {})).duplicate(true)
		details["source_id"] = String(source_id)
		details["start"] = int(_friendly_source_start_counts.get(source_id, 0))
		details["dead"] = int(_friendly_source_dead_counts.get(source_id, 0))
		details["fled"] = int(_friendly_source_fled_counts.get(source_id, 0))
		losses.append(details)
	return losses


func _enemy_source_loss_data() -> Array[Dictionary]:
	var losses: Array[Dictionary] = []
	for source_id in _enemy_source_start_counts.keys():
		var details := Dictionary(_enemy_source_details.get(source_id, {})).duplicate(true)
		details["source_id"] = String(source_id)
		details["start"] = int(_enemy_source_start_counts.get(source_id, 0))
		details["dead"] = int(_enemy_source_dead_counts.get(source_id, 0))
		details["fled"] = int(_enemy_source_fled_counts.get(source_id, 0))
		losses.append(details)
	return losses


func _capture_combat_map_context() -> void:
	_combat_campaign_position = Vector2(_combat_map_context.get("campaign_position", GameState.campaign_position))
	_combat_chunk = Vector2i(
		int(floor(_combat_campaign_position.x / CAMPAIGN_CHUNK_SIZE)),
		int(floor(_combat_campaign_position.y / CAMPAIGN_CHUNK_SIZE))
	)
	_combat_seed = _seed_from_chunk(_combat_chunk)

	var chunk_center := (Vector2(_combat_chunk) + Vector2(0.5, 0.5)) * CAMPAIGN_CHUNK_SIZE
	_combat_local_terrain_offset = (_combat_campaign_position - chunk_center) * CAMPAIGN_TO_TERRAIN_SCALE
	_combat_decoration_offset = _wrap_offset_to_terrain(_combat_local_terrain_offset)
	_combat_uv_offset = _combat_campaign_position * (CAMPAIGN_TO_TERRAIN_SCALE / TERRAIN_SIZE)


func _seed_from_chunk(chunk: Vector2i) -> int:
	var roll := _hash21(Vector2(float(chunk.x), float(chunk.y)) + Vector2(19.37, -43.11))
	return maxi(1, int(floor(roll * 1000000000.0)))


func _wrap_offset_to_terrain(offset: Vector2) -> Vector2:
	return Vector2(
		wrapf(offset.x, -TERRAIN_HALF, TERRAIN_HALF),
		wrapf(offset.y, -TERRAIN_HALF, TERRAIN_HALF)
	)


func _profile_float(key: String, fallback: float) -> float:
	return float(_biome_profile.get(key, fallback))


func _profile_int(key: String, fallback: int) -> int:
	return int(_biome_profile.get(key, fallback))


func _profile_color(key: String, fallback: Color) -> Color:
	var value = _biome_profile.get(key, fallback)
	if value is Color:
		return value
	if value is String:
		return Color(String(value))
	return fallback


func _profile_texture(key: String, fallback: Texture2D) -> Texture2D:
	var path := String(_biome_profile.get(key, ""))
	if path.is_empty():
		return fallback

	var texture := load(path)
	if texture is Texture2D:
		return texture
	return fallback


func _add_world_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "CombatBiomeWorld"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = _profile_color("sky_color", Color("#64b7f0"))
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = _profile_color("ambient_color", Color("#e8e0c5"))
	environment.ambient_light_energy = _profile_float("ambient_energy", 0.58)
	environment.fog_enabled = true
	environment.fog_light_color = _profile_color("fog_color", Color("#c2d8e6"))
	environment.fog_density = _profile_float("fog_density", 0.0045)
	world.environment = environment
	add_child(world)


func _add_sun() -> void:
	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-38.0, 38.0, 0.0)
	light.light_color = _profile_color("sun_color", Color.WHITE)
	light.light_energy = _profile_float("sun_energy", 2.9)
	light.shadow_enabled = true
	add_child(light)

	var fill := DirectionalLight3D.new()
	fill.name = "SoftSkyFill"
	fill.rotation_degrees = Vector3(-68.0, -128.0, 0.0)
	fill.light_color = _profile_color("fill_color", Color("#9ec7ef"))
	fill.light_energy = _profile_float("fill_energy", 0.32)
	add_child(fill)


func _add_terrain() -> void:
	var terrain := StaticBody3D.new()
	terrain.name = "JudeanHillCountry"
	add_child(terrain)

	var terrain_heights := _build_terrain_height_grid()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "TerrainMesh"
	var mesh := _build_terrain_mesh(terrain_heights)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_terrain_material()
	terrain.add_child(mesh_instance)

	_add_terrain_heightmap_collision(terrain, terrain_heights)


func _add_ground_visibility_underlay() -> void:
	var underlay := MeshInstance3D.new()
	underlay.name = "GroundVisibilityUnderlay"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(TERRAIN_SIZE, TERRAIN_SIZE)
	underlay.mesh = mesh
	underlay.position.y = GROUND_UNDERLAY_Y
	underlay.material_override = _make_material(_profile_color("underlay_color", Color("#596f3c")), 1.0, 0.0)
	add_child(underlay)


func _add_battlefield_boundary() -> void:
	var root := Node3D.new()
	root.name = "BattlefieldBoundary"
	add_child(root)

	_battlefield_wall_material = _make_battlefield_wall_material()
	var wall_length := BATTLEFIELD_WALL_HALF * 2.0 + BATTLEFIELD_WALL_THICKNESS
	var wall_y := GROUND_UNDERLAY_Y + BATTLEFIELD_WALL_HEIGHT * 0.5
	var long_size := Vector3(wall_length, BATTLEFIELD_WALL_HEIGHT, BATTLEFIELD_WALL_THICKNESS)
	var side_size := Vector3(BATTLEFIELD_WALL_THICKNESS, BATTLEFIELD_WALL_HEIGHT, wall_length)

	_add_battlefield_wall_segment(root, "NorthBoundaryWall", Vector3(0.0, wall_y, -BATTLEFIELD_WALL_HALF), long_size)
	_add_battlefield_wall_segment(root, "SouthBoundaryWall", Vector3(0.0, wall_y, BATTLEFIELD_WALL_HALF), long_size)
	_add_battlefield_wall_segment(root, "WestBoundaryWall", Vector3(-BATTLEFIELD_WALL_HALF, wall_y, 0.0), side_size)
	_add_battlefield_wall_segment(root, "EastBoundaryWall", Vector3(BATTLEFIELD_WALL_HALF, wall_y, 0.0), side_size)


func _add_battlefield_wall_segment(parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> void:
	var wall := StaticBody3D.new()
	wall.name = node_name
	wall.position = position
	wall.collision_layer = BATTLEFIELD_WALL_COLLISION_LAYER
	wall.collision_mask = 0
	parent.add_child(wall)

	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	collision.shape = box_shape
	wall.add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "DistanceFadeWallMesh"
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = _battlefield_wall_material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wall.add_child(mesh_instance)


func _add_terrain_heightmap_collision(terrain: StaticBody3D, terrain_heights: PackedFloat32Array) -> void:
	var sample_count := TERRAIN_STEPS + 1
	var step_size := TERRAIN_SIZE / float(TERRAIN_STEPS)
	var map_data := PackedFloat32Array()
	map_data.resize(sample_count * sample_count)

	for index in range(map_data.size()):
		map_data[index] = terrain_heights[index] / step_size

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
	var x := clampf(target_position.x, -BATTLEFIELD_WALL_HALF + 2.0, BATTLEFIELD_WALL_HALF - 2.0)
	var z := clampf(target_position.z, -BATTLEFIELD_WALL_HALF + 2.0, BATTLEFIELD_WALL_HALF - 2.0)
	var ground_y := _terrain_height(x, z)
	player.global_position = Vector3(x, ground_y + PLAYER_FOOT_CLEARANCE, z)
	player.velocity = Vector3.ZERO


func _build_terrain_height_grid() -> PackedFloat32Array:
	var sample_count := TERRAIN_STEPS + 1
	var step_size := TERRAIN_SIZE / float(TERRAIN_STEPS)
	var heights := PackedFloat32Array()
	heights.resize(sample_count * sample_count)

	for z_index in range(sample_count):
		var z := -TERRAIN_HALF + float(z_index) * step_size
		for x_index in range(sample_count):
			var x := -TERRAIN_HALF + float(x_index) * step_size
			heights[z_index * sample_count + x_index] = _terrain_height(x, z)

	return heights


func _build_terrain_mesh(terrain_heights: PackedFloat32Array) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var sample_count := TERRAIN_STEPS + 1
	var step_size := TERRAIN_SIZE / float(TERRAIN_STEPS)

	for z_index in range(sample_count):
		var z := -TERRAIN_HALF + float(z_index) * step_size
		for x_index in range(sample_count):
			var x := -TERRAIN_HALF + float(x_index) * step_size
			var y := terrain_heights[z_index * sample_count + x_index]
			vertices.append(Vector3(x, y, z))
			normals.append(_terrain_grid_normal(x_index, z_index, terrain_heights))
			var color_blend := clampf((y + 0.8) / 10.5, 0.0, 1.0)
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


func _terrain_grid_normal(x_index: int, z_index: int, terrain_heights: PackedFloat32Array) -> Vector3:
	var sample_count := TERRAIN_STEPS + 1
	var step_size := TERRAIN_SIZE / float(TERRAIN_STEPS)
	var left_index := maxi(x_index - 1, 0)
	var right_index := mini(x_index + 1, sample_count - 1)
	var back_index := maxi(z_index - 1, 0)
	var front_index := mini(z_index + 1, sample_count - 1)

	var left := terrain_heights[z_index * sample_count + left_index]
	var right := terrain_heights[z_index * sample_count + right_index]
	var back := terrain_heights[back_index * sample_count + x_index]
	var front := terrain_heights[front_index * sample_count + x_index]
	var x_span := maxf(step_size, float(right_index - left_index) * step_size)
	var z_span := maxf(step_size, float(front_index - back_index) * step_size)
	return Vector3((left - right) / x_span, 1.0, (back - front) / z_span).normalized()


func _terrain_height(x: float, z: float) -> float:
	var sample := Vector2(x, z) + _combat_local_terrain_offset
	var north_ridge := _seeded_range(11, 1.25, 1.85) * exp(-pow((sample.y + _seeded_range(12, 14.0, 24.0)) / _seeded_range(13, 13.0, 19.0), 2.0))
	var west_swell := _seeded_range(21, 0.85, 1.45) * exp(-(pow((sample.x + _seeded_range(22, 18.0, 30.0)) / _seeded_range(23, 15.0, 22.0), 2.0) + pow((sample.y - _seeded_range(24, -4.0, 8.0)) / _seeded_range(25, 20.0, 29.0), 2.0)))
	var east_swell := _seeded_range(31, 0.65, 1.2) * exp(-(pow((sample.x - _seeded_range(32, 15.0, 28.0)) / _seeded_range(33, 19.0, 27.0), 2.0) + pow((sample.y + _seeded_range(34, 6.0, 16.0)) / _seeded_range(35, 17.0, 24.0), 2.0)))
	var shallow_wadi := -_seeded_range(41, 0.55, 1.05) * exp(-(pow((sample.x - _seeded_range(42, -5.0, 8.0)) / _seeded_range(43, 7.0, 12.0), 2.0) + pow((sample.y + _seeded_range(44, -6.0, 7.0)) / _seeded_range(45, 26.0, 38.0), 2.0)))
	var ripple := 0.22 * sin(sample.x * _seeded_range(51, 0.18, 0.28) + _seeded_range(52, -PI, PI)) + 0.14 * cos((sample.x + sample.y) * _seeded_range(53, 0.13, 0.22))
	var spawn_flatten := 0.45 * exp(-(pow(x / 10.0, 2.0) + pow((z - 8.0) / 8.0, 2.0)))
	var macro_height := (
		north_ridge * _profile_float("terrain_ridge_strength", 1.0)
		+ (west_swell + east_swell) * _profile_float("terrain_swell_strength", 1.0)
		+ shallow_wadi * _profile_float("terrain_wadi_strength", 1.0)
		+ ripple * _profile_float("terrain_ripple_strength", 1.0)
	)
	var extreme_weight := _terrain_extreme_weight(x, z)
	var outer_hills := _terrain_outer_hills(sample, extreme_weight) * _profile_float("terrain_outer_hill_strength", 1.0)
	var scaled_height := macro_height * _profile_float("terrain_height_scale", 1.0)
	var base_height := maxf(
		_profile_float("terrain_floor", -0.55),
		scaled_height * (1.0 + extreme_weight * 2.35) + outer_hills - spawn_flatten + _profile_float("terrain_height_offset", 0.0)
	)
	return base_height + _terrain_surface_relief(x, z)


func _terrain_extreme_weight(x: float, z: float) -> float:
	var edge_distance := maxf(absf(x), absf(z)) / TERRAIN_HALF
	return smoothstep(0.22, 0.88, edge_distance)


func _terrain_outer_hills(sample: Vector2, extreme_weight: float) -> float:
	if extreme_weight <= 0.0:
		return 0.0

	var long_ridge := pow(0.5 + 0.5 * sin(sample.x * _seeded_range(61, 0.035, 0.052) + _seeded_range(62, -PI, PI)), 1.45)
	var cross_ridge := pow(0.5 + 0.5 * cos(sample.y * _seeded_range(63, 0.032, 0.048) + _seeded_range(64, -PI, PI)), 1.55)
	var rolling_noise := _value_noise(sample * 0.035 + Vector2(_seeded_range(65, -20.0, 20.0), _seeded_range(66, -20.0, 20.0)))
	var hill_shape := long_ridge * _seeded_range(67, 3.1, 5.2) + cross_ridge * _seeded_range(68, 2.0, 3.7) + rolling_noise * _seeded_range(69, 1.1, 2.2)
	return extreme_weight * hill_shape


func _terrain_surface_relief(x: float, z: float) -> float:
	var uv := _terrain_uv(x, z)
	var secondary := _terrain_secondary_mask_at(uv)
	var rough_grass := (_value_noise((uv + _combat_uv_offset) * 42.0 + Vector2(3.0, -7.0)) - 0.5) * 0.035
	var relief_strength := _profile_float("surface_relief_strength", 1.0)
	var surface_drop := _profile_float("secondary_surface_drop", 0.09)
	return -secondary * surface_drop + rough_grass * (1.0 - secondary) * relief_strength


func _terrain_uv(x: float, z: float) -> Vector2:
	return Vector2((x + TERRAIN_HALF) / TERRAIN_SIZE, (z + TERRAIN_HALF) / TERRAIN_SIZE)


func _terrain_secondary_mask_at(uv: Vector2) -> float:
	var sampled_uv := _wrap_unit_uv(uv + _combat_uv_offset)
	var dirt_grain := smoothstep(0.48, 0.78, _value_noise((uv + _combat_uv_offset) * 18.0 + Vector2(11.0, -5.0))) * 0.30
	var dirt_mask := dirt_grain
	dirt_mask = maxf(dirt_mask, _terrain_patch(sampled_uv, _seeded_patch_center(101, Vector2(0.25, 0.50)), Vector2(0.12, 0.08), 0.95))
	dirt_mask = maxf(dirt_mask, _terrain_patch(sampled_uv, _seeded_patch_center(102, Vector2(0.70, 0.24)), Vector2(0.15, 0.10), 0.90))
	dirt_mask = maxf(dirt_mask, _terrain_patch(sampled_uv, _seeded_patch_center(103, Vector2(0.28, 0.72)), Vector2(0.09, 0.12), 0.82))
	dirt_mask = maxf(dirt_mask, _terrain_patch(sampled_uv, _seeded_patch_center(104, Vector2(0.47, 0.22)), Vector2(0.12, 0.08), 0.72))
	dirt_mask = maxf(dirt_mask, _terrain_patch(sampled_uv, _seeded_patch_center(105, Vector2(0.60, 0.63)), Vector2(0.10, 0.13), 0.78))
	dirt_mask = maxf(dirt_mask, _terrain_patch(sampled_uv, _seeded_patch_center(106, Vector2(0.80, 0.55)), Vector2(0.08, 0.11), 0.62))
	return clampf(smoothstep(0.08, 0.85, dirt_mask) * _profile_float("secondary_mask_strength", 0.88), 0.0, 1.0)


func _wrap_unit_uv(uv: Vector2) -> Vector2:
	return Vector2(wrapf(uv.x, 0.0, 1.0), wrapf(uv.y, 0.0, 1.0))


func _seeded_patch_center(salt: int, base_center: Vector2) -> Vector2:
	var offset := Vector2(_seeded_range(salt * 2, -0.055, 0.055), _seeded_range(salt * 2 + 1, -0.055, 0.055))
	return base_center + offset


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


func _add_wadis() -> void:
	var wadi_count := maxi(0, _profile_int("wadi_count", 0))
	if wadi_count <= 0:
		return

	var base_width := _profile_float("wadi_width", 3.4)
	var color := _profile_color("wadi_color", Color("#80684d"))
	color.a = _profile_float("wadi_alpha", 0.35)
	for wadi_index in range(wadi_count):
		var salt := 430 + wadi_index * 37
		var drift := _seeded_range(salt, -18.0, 18.0)
		var bend := _seeded_range(salt + 1, -26.0, 26.0)
		var raw_points := [
			Vector3(_seeded_range(salt + 2, -70.0, -44.0) + drift, 0.0, _seeded_range(salt + 3, -78.0, -58.0)),
			Vector3(_seeded_range(salt + 4, -42.0, -18.0) + bend, 0.0, _seeded_range(salt + 5, -42.0, -20.0)),
			Vector3(_seeded_range(salt + 6, -12.0, 16.0) - bend * 0.25, 0.0, _seeded_range(salt + 7, -10.0, 14.0)),
			Vector3(_seeded_range(salt + 8, 18.0, 44.0) - bend, 0.0, _seeded_range(salt + 9, 24.0, 48.0)),
			Vector3(_seeded_range(salt + 10, 48.0, 74.0) - drift, 0.0, _seeded_range(salt + 11, 58.0, 78.0)),
		]

		var wadi_points: Array[Vector3] = []
		for raw_point in raw_points:
			var shifted := Vector2(raw_point.x - _combat_decoration_offset.x * 0.55, raw_point.z - _combat_decoration_offset.y * 0.55)
			var ground_position := _wrap_ground_position_to_terrain(shifted, base_width)
			wadi_points.append(Vector3(ground_position.x, 0.0, ground_position.y))

		var sampled_points := _sample_path_points(wadi_points, 1.65)
		_register_decoration_exclusion_corridor(sampled_points, base_width * 0.42)
		_add_surface_ribbon("TerrainFollowingWadi", sampled_points, base_width, color)


func _add_path() -> void:
	var path_shift := Vector3(_combat_decoration_offset.x, 0.0, _combat_decoration_offset.y)
	var path_width := _profile_float("path_width", 2.4)
	var raw_path_points := [
		Vector3(_seeded_range(201, -70.0, -52.0), 0.0, _seeded_range(202, 30.0, 46.0)) - path_shift,
		Vector3(_seeded_range(203, -43.0, -27.0), 0.0, _seeded_range(204, 15.0, 30.0)) - path_shift,
		Vector3(_seeded_range(205, -20.0, -4.0), 0.0, _seeded_range(206, 2.0, 16.0)) - path_shift,
		Vector3(_seeded_range(207, 4.0, 20.0), 0.0, _seeded_range(208, -20.0, -4.0)) - path_shift,
		Vector3(_seeded_range(209, 30.0, 46.0), 0.0, _seeded_range(210, -46.0, -30.0)) - path_shift,
		Vector3(_seeded_range(211, 56.0, 74.0), 0.0, _seeded_range(212, -70.0, -52.0)) - path_shift,
	]
	var path_points: Array[Vector3] = []
	for raw_point in raw_path_points:
		var ground_position := _wrap_ground_position_to_terrain(Vector2(raw_point.x, raw_point.z), path_width)
		path_points.append(Vector3(ground_position.x, 0.0, ground_position.y))
	var sampled_points := _sample_path_points(path_points, 1.35)
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
	_add_surface_ribbon("TerrainFollowingPath", path_points, width, _profile_color("path_color", PATH_COLOR))


func _add_surface_ribbon(node_name: String, path_points: Array[Vector3], width: float, color: Color) -> void:
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
		colors.append(color)
		colors.append(color.darkened(0.04))

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
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(color, 0.98, 0.0, true, true)
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


func _add_ground_clumps() -> void:
	var clump_count := maxi(0, _profile_int("clump_count", 0))
	if clump_count <= 0:
		return

	var clump_radius := maxf(0.03, _profile_float("clump_radius", 0.10))
	var clump_height := maxf(0.05, _profile_float("clump_height", 0.32))
	for index in range(clump_count):
		var seed := _combat_seed + index * 53 + 901
		var angle := float(index) * _seeded_range(701, 2.05, 2.54) + _seeded_range(702, 0.0, TAU)
		var radius := 7.0 + fmod(float(index) * _seeded_range(703, 6.8, 10.4), TERRAIN_HALF - 11.0)
		var raw_position := Vector2(
			cos(angle) * radius + sin(float(index) * _seeded_range(704, 0.36, 0.66)) * 3.5 - _combat_decoration_offset.x,
			sin(angle) * radius + cos(float(index) * _seeded_range(705, 0.28, 0.58)) * 3.5 - _combat_decoration_offset.y
		)
		var ground_position := _wrap_ground_position_to_terrain(raw_position, clump_radius * 3.0)
		if ground_position.distance_to(Vector2(PLAYER_SPAWN.x, PLAYER_SPAWN.z)) < 5.0:
			continue

		var x := ground_position.x
		var z := ground_position.y
		var position := Vector3(x, _terrain_height(x, z), z)
		if _is_decoration_excluded(position, clump_radius * 2.2):
			continue
		_add_ground_clump(position, clump_radius, clump_height, seed)


func _add_ground_clump(position: Vector3, radius: float, height: float, seed: int) -> void:
	var clump := MeshInstance3D.new()
	clump.name = "BiomeGroundClump"
	clump.mesh = _ground_clump_mesh()
	var height_scale := height * lerpf(0.74, 1.32, _deterministic_unit(seed, 11))
	var radius_scale := radius * lerpf(0.68, 1.35, _deterministic_unit(seed, 17))
	clump.scale = Vector3(radius_scale, height_scale, radius_scale)
	clump.position = position + Vector3(0.0, height_scale * 0.5, 0.0)
	clump.rotation_degrees = Vector3(0.0, fmod(float(seed) * 31.0, 360.0), 0.0)
	clump.material_override = _make_clump_material()
	add_child(clump)


func _ground_clump_mesh() -> CylinderMesh:
	if _clump_mesh == null:
		_clump_mesh = CylinderMesh.new()
		_clump_mesh.top_radius = 0.22
		_clump_mesh.bottom_radius = 0.55
		_clump_mesh.height = 1.0
		_clump_mesh.radial_segments = 5
		_clump_mesh.rings = 1
	return _clump_mesh


func _make_clump_material() -> StandardMaterial3D:
	if _clump_material != null:
		return _clump_material

	_clump_material = StandardMaterial3D.new()
	_clump_material.albedo_color = _profile_color("clump_color", Color("#5f6f39"))
	_clump_material.roughness = 0.98
	return _clump_material


func _add_small_rocks() -> void:
	var rock_count := maxi(0, _profile_int("rock_count", SMALL_ROCK_COUNT))
	var rock_scale := maxf(0.05, _profile_float("rock_scale", 1.0))
	for index in range(rock_count):
		var rock_seed := _combat_seed + index * 37
		var angle := float(index) * _seeded_range(301, 2.15, 2.63) + _seeded_range(302, 0.0, TAU)
		var radius := 5.0 + fmod(float(index) * _seeded_range(303, 8.7, 12.2), TERRAIN_HALF - 8.0)
		var size_roll := pow(_deterministic_unit(rock_seed, 222), 1.9)
		var rock_radius := (0.16 + size_roll * 0.86) * rock_scale
		var raw_position := Vector2(
			cos(angle) * radius + sin(float(index) * _seeded_range(304, 0.42, 0.72)) * 2.8 - _combat_decoration_offset.x,
			sin(angle) * radius + cos(float(index) * _seeded_range(305, 0.24, 0.50)) * 2.8 - _combat_decoration_offset.y
		)
		var ground_position := _wrap_ground_position_to_terrain(raw_position, rock_radius * 1.25)
		if ground_position.distance_to(Vector2(PLAYER_SPAWN.x, PLAYER_SPAWN.z)) < 3.5:
			continue

		var x := ground_position.x
		var z := ground_position.y
		var rock_position := Vector3(x, _terrain_height(x, z), z)
		if _is_decoration_excluded(rock_position, rock_radius * 1.8):
			continue
		_add_small_rock(rock_position, rock_radius, rock_seed)


func _wrap_ground_position_to_terrain(position: Vector2, margin: float) -> Vector2:
	var safe_half := maxf(0.0, TERRAIN_HALF - margin)
	if safe_half <= 0.0:
		return Vector2.ZERO
	return Vector2(
		wrapf(position.x, -safe_half, safe_half),
		wrapf(position.y, -safe_half, safe_half)
	)


func _add_small_rock(position: Vector3, radius: float, index: int) -> void:
	var rock := MeshInstance3D.new()
	rock.name = "SmallTerrainRock"
	rock.mesh = _small_rock_mesh_for_seed(index)
	rock.position = position + Vector3(0.0, 0.035 + radius * 0.025, 0.0)
	rock.rotation_degrees = Vector3(0.0, fmod(float(index) * 43.0, 360.0), 0.0)
	rock.scale = Vector3.ONE * radius
	rock.material_override = _make_stone_material()
	add_child(rock)


func _small_rock_mesh_for_seed(seed: int) -> ArrayMesh:
	var variant := int(floor(_deterministic_unit(seed, 617) * float(SMALL_ROCK_MESH_VARIANTS)))
	if not _small_rock_mesh_cache.has(variant):
		_small_rock_mesh_cache[variant] = _make_small_rock_mesh(1.0, _combat_seed + variant * 101)
	return _small_rock_mesh_cache[variant] as ArrayMesh


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
		var underside_drop := height * (0.10 + _deterministic_unit(seed + 29, segment) * 0.18)
		var direction := Vector3(cos(angle) * squash_x, 0.0, sin(angle) * squash_z)
		bottom.append(direction * radius * ring_noise + Vector3(0.0, -underside_drop, 0.0))
		middle.append(direction * radius * ring_noise * 0.86 + Vector3(0.0, height * (0.38 + _deterministic_unit(seed, segment + 30) * 0.14), 0.0))
		top.append(direction * radius * top_noise + Vector3(0.0, height * (0.84 + _deterministic_unit(seed, segment + 60) * 0.18), 0.0))

	var bottom_center := Vector3(0.0, -height * (0.34 + _deterministic_unit(seed, 19) * 0.22), 0.0)
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


func _seeded_unit(salt: int) -> float:
	return _deterministic_unit(_combat_seed, salt)


func _seeded_range(salt: int, minimum: float, maximum: float) -> float:
	return lerpf(minimum, maximum, _seeded_unit(salt))


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


func _add_soldier(position: Vector3, faction: String, weapon_type: String, power: int, speed: int, dexterity: int) -> CharacterBody3D:
	var soldier := CharacterBody3D.new()
	var side := "Friendly" if faction == "friendly" else "Enemy"
	var role := "Archer" if weapon_type == "bow" else "Swordsman"
	soldier.name = "%s%s" % [side, role]
	soldier.set_script(SoldierEnemy)
	soldier.position = position
	soldier.rotation.y = PI if faction == "enemy" else 0.0
	soldier.call("setup", player, self, weapon_type, false, faction, power, speed, dexterity)
	if _is_lord_combat() and soldier.has_signal("died"):
		soldier.connect("died", Callable(self, "_on_combat_soldier_died").bind(soldier))
	if _is_lord_combat() and soldier.has_signal("left_battlefield"):
		soldier.connect("left_battlefield", Callable(self, "_on_combat_soldier_left_battlefield").bind(soldier))
	add_child(soldier)
	return soldier


func _make_battlefield_wall_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded;

uniform vec3 player_position = vec3(0.0, 0.0, 0.0);
uniform vec4 wall_color : source_color = vec4(0.74, 0.88, 1.0, 1.0);
uniform float fade_near = 1.4;
uniform float fade_far = 19.0;
uniform float max_alpha = 0.42;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float player_distance = distance(world_pos.xz, player_position.xz);
	float visibility = 1.0 - smoothstep(fade_near, fade_far, player_distance);
	float vertical_line = pow(abs(sin(world_pos.y * 2.7)), 14.0);
	float grid_x = pow(abs(sin(world_pos.x * 1.35)), 18.0);
	float grid_z = pow(abs(sin(world_pos.z * 1.35)), 18.0);
	float line_glow = clamp(vertical_line * 0.28 + max(grid_x, grid_z) * 0.72, 0.0, 1.0);
	ALBEDO = wall_color.rgb;
	EMISSION = wall_color.rgb * (0.25 + line_glow * 1.35);
	ALPHA = visibility * max_alpha * (0.28 + line_glow * 0.72);
}
"""

	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("wall_color", Color("#b9ddff"))
	material.set_shader_parameter("fade_near", BATTLEFIELD_WALL_FADE_NEAR)
	material.set_shader_parameter("fade_far", BATTLEFIELD_WALL_FADE_FAR)
	material.set_shader_parameter("max_alpha", 0.42)
	return material


func _make_stone_material() -> ShaderMaterial:
	if _stone_material != null:
		return _stone_material

	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform sampler2D stone_albedo : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D stone_height : repeat_enable, filter_linear_mipmap;
uniform vec4 rock_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
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

	ALBEDO = color * rock_tint.rgb * (0.78 + height_mix * 0.28 + object_variation * 0.04);
	ROUGHNESS = 0.96;
}
"""

	_stone_material = ShaderMaterial.new()
	_stone_material.shader = shader
	_stone_material.set_shader_parameter("stone_albedo", StoneAlbedo)
	_stone_material.set_shader_parameter("stone_height", StoneHeight)
	_stone_material.set_shader_parameter("rock_tint", _profile_color("rock_color", Color.WHITE))
	_stone_material.set_shader_parameter("stone_tile", 0.215)
	return _stone_material


func _make_terrain_material() -> Material:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D primary_albedo : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D primary_height : repeat_enable, filter_linear_mipmap;
uniform sampler2D secondary_albedo : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D secondary_height : repeat_enable, filter_linear_mipmap;
uniform vec4 primary_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 secondary_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float detail_tile = 7.33;
uniform float secondary_tile_scale = 1.2;
uniform float secondary_mask_strength = 0.88;
uniform float roughness_primary = 0.94;
uniform float roughness_secondary = 0.98;
uniform float normal_depth = 0.55;
uniform vec2 map_uv_offset = vec2(0.0, 0.0);
uniform vec2 patch_center_1 = vec2(0.25, 0.50);
uniform vec2 patch_center_2 = vec2(0.70, 0.24);
uniform vec2 patch_center_3 = vec2(0.28, 0.72);
uniform vec2 patch_center_4 = vec2(0.47, 0.22);
uniform vec2 patch_center_5 = vec2(0.60, 0.63);
uniform vec2 patch_center_6 = vec2(0.80, 0.55);

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

float secondary_mask_at(vec2 map_uv) {
	vec2 wrapped_uv = fract(map_uv);
	float dirt_grain = smoothstep(0.48, 0.78, value_noise(map_uv * 18.0 + vec2(11.0, -5.0))) * 0.30;
	float dirt_mask = dirt_grain;
	dirt_mask = max(dirt_mask, patch(wrapped_uv, patch_center_1, vec2(0.12, 0.08), 0.95));
	dirt_mask = max(dirt_mask, patch(wrapped_uv, patch_center_2, vec2(0.15, 0.10), 0.90));
	dirt_mask = max(dirt_mask, patch(wrapped_uv, patch_center_3, vec2(0.09, 0.12), 0.82));
	dirt_mask = max(dirt_mask, patch(wrapped_uv, patch_center_4, vec2(0.12, 0.08), 0.72));
	dirt_mask = max(dirt_mask, patch(wrapped_uv, patch_center_5, vec2(0.10, 0.13), 0.78));
	dirt_mask = max(dirt_mask, patch(wrapped_uv, patch_center_6, vec2(0.08, 0.11), 0.62));
	return clamp(smoothstep(0.08, 0.85, dirt_mask) * secondary_mask_strength, 0.0, 1.0);
}

void fragment() {
	vec2 map_uv = UV + map_uv_offset;
	vec2 detail_uv = UV * detail_tile + map_uv_offset * 18.0;

	float secondary_mask = secondary_mask_at(map_uv);
	vec2 secondary_uv = detail_uv * secondary_tile_scale;
	vec3 primary = texture(primary_albedo, detail_uv).rgb * primary_tint.rgb;
	vec3 secondary = texture(secondary_albedo, secondary_uv).rgb * secondary_tint.rgb;

	vec3 color = mix(primary, secondary, secondary_mask * 0.94);
	color *= 0.97 + value_noise(detail_uv * 26.0) * 0.06;

	vec2 bump_step = vec2(0.018, 0.0);
	float primary_h = texture(primary_height, detail_uv).r;
	float secondary_h = texture(secondary_height, secondary_uv).r;
	float h = mix(primary_h, secondary_h, secondary_mask);
	float hx = mix(texture(primary_height, detail_uv + bump_step.xy).r, texture(secondary_height, secondary_uv + bump_step.xy).r, secondary_mask);
	float hy = mix(texture(primary_height, detail_uv + bump_step.yx).r, texture(secondary_height, secondary_uv + bump_step.yx).r, secondary_mask);
	vec3 normal_sample = normalize(vec3((h - hx) * 2.2, (h - hy) * 2.2, 1.0));

	ALBEDO = color;
	NORMAL_MAP = normal_sample * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = normal_depth;
	ROUGHNESS = mix(roughness_primary, roughness_secondary, secondary_mask);
}
"""

	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("primary_albedo", _profile_texture("primary_albedo_path", TerrainGrassAlbedo))
	material.set_shader_parameter("primary_height", _profile_texture("primary_height_path", TerrainGrassHeight))
	material.set_shader_parameter("secondary_albedo", _profile_texture("secondary_albedo_path", TerrainDirtAlbedo))
	material.set_shader_parameter("secondary_height", _profile_texture("secondary_height_path", TerrainDirtHeight))
	material.set_shader_parameter("primary_tint", _profile_color("primary_tint", Color.WHITE))
	material.set_shader_parameter("secondary_tint", _profile_color("secondary_tint", Color.WHITE))
	material.set_shader_parameter("detail_tile", _profile_float("detail_tile", 7.33))
	material.set_shader_parameter("secondary_tile_scale", _profile_float("secondary_tile_scale", 1.2))
	material.set_shader_parameter("secondary_mask_strength", _profile_float("secondary_mask_strength", 0.88))
	material.set_shader_parameter("roughness_primary", _profile_float("roughness_primary", 0.94))
	material.set_shader_parameter("roughness_secondary", _profile_float("roughness_secondary", 0.98))
	material.set_shader_parameter("normal_depth", _profile_float("normal_depth", 0.55))
	material.set_shader_parameter("map_uv_offset", _combat_uv_offset)
	material.set_shader_parameter("patch_center_1", _seeded_patch_center(101, Vector2(0.25, 0.50)))
	material.set_shader_parameter("patch_center_2", _seeded_patch_center(102, Vector2(0.70, 0.24)))
	material.set_shader_parameter("patch_center_3", _seeded_patch_center(103, Vector2(0.28, 0.72)))
	material.set_shader_parameter("patch_center_4", _seeded_patch_center(104, Vector2(0.47, 0.22)))
	material.set_shader_parameter("patch_center_5", _seeded_patch_center(105, Vector2(0.60, 0.63)))
	material.set_shader_parameter("patch_center_6", _seeded_patch_center(106, Vector2(0.80, 0.55)))
	return material


func _make_material(albedo: Color, roughness: float, emission_energy: float, use_vertex_color := false, disable_cull := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = roughness
	material.vertex_color_use_as_albedo = use_vertex_color
	if albedo.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if disable_cull:
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = albedo
		material.emission_energy_multiplier = emission_energy
	return material
