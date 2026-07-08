extends Node3D

const WEAPON_BOW := "bow"

const BASE_MALE_PATH := "res://assets/characters/quaternius/universal_base_characters/base_characters/godot_ue/Superhero_Male_FullBody.gltf"
const OUTFIT_PEASANT_PATH := "res://assets/characters/quaternius/modular_character_outfits_fantasy/exports/gltf_godot_unreal/outfits/Male_Peasant.gltf"
const OUTFIT_RANGER_PATH := "res://assets/characters/quaternius/modular_character_outfits_fantasy/exports/gltf_godot_unreal/outfits/Male_Ranger.gltf"
const ANIMATION_SOURCE_PATH := "res://assets/characters/quaternius/universal_animation_library_2/unreal_godot/UAL2_Standard.glb"
const STARTER_SWORD_PATH := "res://assets/characters/quaternius/weapons/Sword.fbx"
const STARTER_SHIELD_PATH := "res://assets/characters/quaternius/weapons/Shield_Heater.fbx"
const STARTER_BOW_PATH := "res://assets/characters/quaternius/weapons/Bow_Wooden.fbx"
const STARTER_ARROW_PATH := "res://assets/characters/quaternius/weapons/Arrow.fbx"
const MODEL_BASE_ROTATION_DEGREES := Vector3(0.0, 180.0, 0.0)
const SWORD_ATTACHMENT_SCALE := 0.16
const SHIELD_ATTACHMENT_SCALE := 0.18
const BOW_ATTACHMENT_SCALE := 0.17
const ARROW_ATTACHMENT_SCALE := 0.20
const FACTION_FRIENDLY := "friendly"
const FACTION_ENEMY := "enemy"
const FRIENDLY_CLOTH_COLOR := Color("#2f6f8f")
const ENEMY_CLOTH_COLOR := Color("#9b2f26")
const FACTION_MARKER_COLOR_STRENGTH := 1.0
const HEAD_HAIR_NONE := 0
const HEAD_HAIR_BUZZED := 1
const HEAD_HAIR_SIMPLE_PARTED := 2
const HEAD_HAIR_LONG := 3
const HEAD_HAIR_BEARD := 4
const HAIRSTYLE_BASE_PATH := "res://assets/characters/quaternius/universal_base_characters/hairstyles/rigged_to_head_bone/gltf_godot_unreal/"
const BASE_HEAD_BONES := {
	"Head": true,
	"neck_01": true,
}
const BASE_HEAD_MIN_Y := 1.50
const BASE_HEAD_FALLBACK_MIN_Y := 1.52
const MIN_HEAD_TRIANGLES := 1200
# The Mixamo longbow packs retarget with yaw and pitch offsets on this rig.
# Keep this clip-level so sword/general fallback animations keep normal facing.
const MIXAMO_BOW_PACK_ROTATION_DEGREES := Vector3(-13.0, 90.0, 0.0)

const MIXAMO_ANIMATION_LIBRARY := {
	"mixamo_sword_idle": {
		"path": "res://assets/characters/quaternius/mixamo/Sword and Shield Pack/sword and shield idle.fbx",
		"loop": true,
	},
	"mixamo_sword_walk": {
		"path": "res://assets/characters/quaternius/mixamo/Sword and Shield Pack/sword and shield walk.fbx",
		"loop": true,
	},
	"mixamo_sword_attack": {
		"path": "res://assets/characters/quaternius/mixamo/Sword and Shield Pack/sword and shield attack.fbx",
		"loop": false,
	},
	"mixamo_sword_inward_slash": {
		"path": "res://assets/characters/quaternius/mixamo/Stable Sword Inward Slash.fbx",
		"loop": false,
	},
	"mixamo_sword_slash": {
		"path": "res://assets/characters/quaternius/mixamo/Sword and Shield Pack/sword and shield slash.fbx",
		"loop": false,
	},
	"mixamo_bow_idle": {
		"path": "res://assets/characters/quaternius/mixamo/Longbow Locomotion Pack/standing idle 01.fbx",
		"loop": true,
	},
	"mixamo_bow_walk": {
		"path": "res://assets/characters/quaternius/mixamo/Longbow Locomotion Pack/standing walk forward.fbx",
		"loop": true,
	},
	"mixamo_bow_walk_back": {
		"path": "res://assets/characters/quaternius/mixamo/Longbow Locomotion Pack/standing walk back.fbx",
		"loop": true,
	},
	"mixamo_bow_draw": {
		"path": "res://assets/characters/quaternius/mixamo/Longbow Aiming Pack/standing draw arrow.fbx",
		"loop": false,
	},
	"mixamo_bow_fire": {
		"path": "res://assets/characters/quaternius/mixamo/Longbow Aiming Pack/standing aim recoil.fbx",
		"loop": false,
	},
	"mixamo_hit_front": {
		"path": "res://assets/characters/quaternius/mixamo/Standing React Large From Front.fbx",
		"loop": false,
	},
	"mixamo_kidney_hit": {
		"path": "res://assets/characters/quaternius/mixamo/Kidney Hit.fbx",
		"loop": false,
	},
	"mixamo_head_hit": {
		"path": "res://assets/characters/quaternius/mixamo/Head Hit.fbx",
		"loop": false,
	},
	"mixamo_sword_hit": {
		"path": "res://assets/characters/quaternius/mixamo/Sword and Shield Pack/sword and shield impact.fbx",
		"loop": false,
	},
	"mixamo_death": {
		"path": "res://assets/characters/quaternius/mixamo/Standing Death Forward 01.fbx",
		"loop": false,
	},
	"mixamo_sword_death": {
		"path": "res://assets/characters/quaternius/mixamo/Sword and Shield Pack/sword and shield death.fbx",
		"loop": false,
	},
}

const MIXAMO_BONE_MAP := {
	"mixamorig_Spine": "spine_01",
	"mixamorig_Spine1": "spine_02",
	"mixamorig_Spine2": "spine_03",
	"mixamorig_Neck": "neck_01",
	"mixamorig_Head": "Head",
	"mixamorig_LeftShoulder": "clavicle_l",
	"mixamorig_LeftArm": "upperarm_l",
	"mixamorig_LeftForeArm": "lowerarm_l",
	"mixamorig_LeftHand": "hand_l",
	"mixamorig_LeftHandThumb1": "thumb_01_l",
	"mixamorig_LeftHandThumb2": "thumb_02_l",
	"mixamorig_LeftHandThumb3": "thumb_03_l",
	"mixamorig_LeftHandThumb4": "thumb_04_leaf_l",
	"mixamorig_LeftHandIndex1": "index_01_l",
	"mixamorig_LeftHandIndex2": "index_02_l",
	"mixamorig_LeftHandIndex3": "index_03_l",
	"mixamorig_LeftHandIndex4": "index_04_leaf_l",
	"mixamorig_LeftHandMiddle1": "middle_01_l",
	"mixamorig_LeftHandMiddle2": "middle_02_l",
	"mixamorig_LeftHandMiddle3": "middle_03_l",
	"mixamorig_LeftHandMiddle4": "middle_04_leaf_l",
	"mixamorig_LeftHandRing1": "ring_01_l",
	"mixamorig_LeftHandRing2": "ring_02_l",
	"mixamorig_LeftHandRing3": "ring_03_l",
	"mixamorig_LeftHandRing4": "ring_04_leaf_l",
	"mixamorig_LeftHandPinky1": "pinky_01_l",
	"mixamorig_LeftHandPinky2": "pinky_02_l",
	"mixamorig_LeftHandPinky3": "pinky_03_l",
	"mixamorig_LeftHandPinky4": "pinky_04_leaf_l",
	"mixamorig_RightShoulder": "clavicle_r",
	"mixamorig_RightArm": "upperarm_r",
	"mixamorig_RightForeArm": "lowerarm_r",
	"mixamorig_RightHand": "hand_r",
	"mixamorig_RightHandThumb1": "thumb_01_r",
	"mixamorig_RightHandThumb2": "thumb_02_r",
	"mixamorig_RightHandThumb3": "thumb_03_r",
	"mixamorig_RightHandThumb4": "thumb_04_leaf_r",
	"mixamorig_RightHandIndex1": "index_01_r",
	"mixamorig_RightHandIndex2": "index_02_r",
	"mixamorig_RightHandIndex3": "index_03_r",
	"mixamorig_RightHandIndex4": "index_04_leaf_r",
	"mixamorig_RightHandMiddle1": "middle_01_r",
	"mixamorig_RightHandMiddle2": "middle_02_r",
	"mixamorig_RightHandMiddle3": "middle_03_r",
	"mixamorig_RightHandMiddle4": "middle_04_leaf_r",
	"mixamorig_RightHandRing1": "ring_01_r",
	"mixamorig_RightHandRing2": "ring_02_r",
	"mixamorig_RightHandRing3": "ring_03_r",
	"mixamorig_RightHandRing4": "ring_04_leaf_r",
	"mixamorig_RightHandPinky1": "pinky_01_r",
	"mixamorig_RightHandPinky2": "pinky_02_r",
	"mixamorig_RightHandPinky3": "pinky_03_r",
	"mixamorig_RightHandPinky4": "pinky_04_leaf_r",
	"mixamorig_LeftUpLeg": "thigh_l",
	"mixamorig_LeftLeg": "calf_l",
	"mixamorig_LeftFoot": "foot_l",
	"mixamorig_LeftToeBase": "ball_l",
	"mixamorig_LeftToe_End": "ball_leaf_l",
	"mixamorig_RightUpLeg": "thigh_r",
	"mixamorig_RightLeg": "calf_r",
	"mixamorig_RightFoot": "foot_r",
	"mixamorig_RightToeBase": "ball_r",
	"mixamorig_RightToe_End": "ball_leaf_r",
}

const MIXAMO_ROOT_BONES_TO_SKIP := {
	"mixamorig_Hips": true,
}

const SWORD_IDLE_CLIPS := ["mixamo_sword_idle", "Idle_Shield", "Idle_Shield_Loop", "Idle_No", "Idle_No_Loop", "A_TPose"]
const BOW_IDLE_CLIPS := ["mixamo_bow_idle", "Idle_Shield", "Idle_Shield_Loop", "Idle_No", "Idle_No_Loop", "A_TPose"]
const SWORD_WALK_CLIPS := ["mixamo_sword_walk", "Sword_Dash", "Zombie_Walk_Fwd", "Zombie_Walk_Fwd_Loop", "Walk_Carry", "Walk_Carry_Loop"]
const BOW_WALK_CLIPS := ["mixamo_bow_walk", "Zombie_Walk_Fwd", "Zombie_Walk_Fwd_Loop", "Walk_Carry", "Walk_Carry_Loop"]
const BOW_BACKWARD_WALK_CLIPS := ["mixamo_bow_walk_back", "mixamo_bow_walk", "Zombie_Walk_Fwd", "Zombie_Walk_Fwd_Loop", "Walk_Carry", "Walk_Carry_Loop"]
const SWORD_ATTACK_CLIPS := ["mixamo_sword_inward_slash", "mixamo_sword_slash", "Sword_Regular_A", "Sword_Regular_B", "Sword_Regular_C", "mixamo_sword_attack", "Sword_Regular_A_Rec", "Sword_Regular_B_Rec", "Melee_Hook"]
const RANGED_ATTACK_CLIPS := ["mixamo_bow_draw", "mixamo_bow_fire", "OverhandThrow", "Melee_Hook"]
const HIT_CLIPS := ["mixamo_kidney_hit", "mixamo_head_hit", "mixamo_hit_front", "Hit_Knockback", "mixamo_sword_hit"]
const DEATH_CLIPS := ["mixamo_sword_death", "mixamo_death", "Hit_Knockback"]

@export var default_weapon_type := "sword"
@export var debug_log := false

var _faction := "enemy"
var _weapon_type := "sword"
var _has_shield := false
var _model_root: Node3D
var _animation_player: AnimationPlayer
var _current_state := ""
var _state_lock_time := 0.0
var _hit_overlay_material: StandardMaterial3D
var _meshes: Array[MeshInstance3D] = []
var _appearance_profile := {}

static var _packed_scene_cache := {}
static var _faction_marker_shader: Shader
static var _appearance_material_cache := {}


func _ready() -> void:
	if _model_root == null:
		setup_visual(_faction, default_weapon_type, _has_shield)


func setup_visual(new_faction: String, new_weapon_type: String, new_has_shield := false, new_appearance_profile := {}) -> bool:
	_faction = new_faction
	_weapon_type = new_weapon_type
	_has_shield = new_has_shield
	_clear_visual()
	_appearance_profile = Dictionary(new_appearance_profile).duplicate(true)
	var outfit := _load_gltf_scene(_outfit_path_for_weapon(_weapon_type)) as Node3D
	if outfit == null:
		_log("Could not load Quaternius outfit.")
		return false
	var base_character := _load_gltf_scene(BASE_MALE_PATH) as Node3D
	if base_character == null:
		outfit.free()
		_log("Could not load Quaternius base character.")
		return false

	outfit.name = "ImportedOutfit"
	if not _merge_base_character_head(outfit, base_character):
		outfit.free()
		base_character.free()
		_log("Could not merge Quaternius base head onto outfit skeleton.")
		return false
	base_character.free()

	add_child(outfit)
	_model_root = outfit
	_collect_meshes(_model_root)
	_apply_facing_and_scale()
	_apply_faction_colors()
	_apply_head_appearance()
	_attach_weapon_models()

	if not _attach_animation_player():
		_log("Could not attach UAL2 animation player.")
		_clear_visual()
		return false

	_hit_overlay_material = _make_hit_overlay_material()
	play_idle()
	return true


func update_combat_state(delta: float, flat_speed: float, is_attacking: bool, attack_kind: String, is_moving_backward := false) -> void:
	if _animation_player == null:
		return

	_state_lock_time = maxf(0.0, _state_lock_time - delta)
	if _state_lock_time > 0.0:
		return

	if is_attacking:
		if _current_state != "attack":
			play_attack(attack_kind)
		return

	if flat_speed > 0.05:
		play_walk(flat_speed, is_moving_backward)
	else:
		play_idle()


func play_idle() -> void:
	var clips := BOW_IDLE_CLIPS if _weapon_type == WEAPON_BOW else SWORD_IDLE_CLIPS
	_play_first_available("idle", clips, 0.18, 1.0, true)


func play_walk(flat_speed := 1.0, is_moving_backward := false) -> void:
	var speed_scale := clampf(flat_speed / 3.4, 0.75, 1.35)
	var clips := SWORD_WALK_CLIPS
	if _weapon_type == WEAPON_BOW:
		clips = BOW_BACKWARD_WALK_CLIPS if is_moving_backward else BOW_WALK_CLIPS
	_play_first_available("walk", clips, 0.12, speed_scale, true)


func play_attack(attack_kind: String) -> void:
	var clips := RANGED_ATTACK_CLIPS if attack_kind == WEAPON_BOW else SWORD_ATTACK_CLIPS
	_play_first_available("attack", clips, 0.05, 1.15, false)
	_state_lock_time = 0.44


func play_hit(stagger_seconds := 0.50) -> void:
	if _current_state == "death":
		return
	_play_first_available("hit", HIT_CLIPS, 0.04, 1.0, false)
	_state_lock_time = maxf(_state_lock_time, stagger_seconds)


func play_death() -> void:
	_current_state = "death"
	_play_first_available("death", DEATH_CLIPS, 0.04, 0.85, false)


func set_hit_flash(active: bool) -> void:
	for mesh in _meshes:
		if mesh != null:
			mesh.material_overlay = _hit_overlay_material if active else null


func has_imported_model() -> bool:
	return _model_root != null


func _clear_visual() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	_model_root = null
	_animation_player = null
	_current_state = ""
	_state_lock_time = 0.0
	_meshes.clear()


func _outfit_path_for_weapon(weapon: String) -> String:
	if weapon == WEAPON_BOW:
		return OUTFIT_RANGER_PATH
	return OUTFIT_PEASANT_PATH


func _apply_facing_and_scale() -> void:
	if _model_root == null:
		return
	_model_root.position = Vector3.ZERO
	_model_root.rotation_degrees = MODEL_BASE_ROTATION_DEGREES
	_model_root.scale = Vector3.ONE


func _set_model_rotation(rotation_degrees: Vector3) -> void:
	if _model_root != null:
		_model_root.rotation_degrees = rotation_degrees


func _apply_faction_colors() -> void:
	var cloth_color := FRIENDLY_CLOTH_COLOR if _faction == FACTION_FRIENDLY else ENEMY_CLOTH_COLOR
	var colored_markers := 0
	for marker_mesh in _find_faction_marker_meshes():
		if marker_mesh == null:
			continue
		marker_mesh.material_override = _make_faction_marker_material(marker_mesh, cloth_color)
		colored_markers += 1
	if colored_markers > 0:
		return

	for mesh in _meshes:
		if mesh == null or _is_skin_or_head_mesh(mesh.name):
			continue
		mesh.material_override = _make_faction_marker_material(mesh, cloth_color)
		return


func _apply_head_appearance() -> void:
	if _appearance_profile.is_empty():
		return

	var skin_color := _appearance_color("skin_color", Color("#e4b98f"))
	var hair_color := _appearance_color("hair_color", Color("#3a2316"))
	var skin_material := _make_appearance_material(skin_color, 0.88)
	var hair_material := _make_appearance_material(hair_color, 0.96)

	for mesh in _meshes:
		if mesh == null:
			continue
		var lower_name := String(mesh.name).to_lower()
		if _is_base_body_mesh_name(mesh.name) or lower_name.contains("superhero"):
			mesh.material_override = skin_material
		elif lower_name.contains("eyebrow") or lower_name.contains("brow"):
			mesh.material_override = hair_material

	var skeleton := _find_skeleton(_model_root)
	if skeleton == null or skeleton.find_bone("Head") < 0:
		return

	if _weapon_type != WEAPON_BOW:
		_merge_modular_hairstyle(skeleton, _hairstyle_path_for_profile(), hair_color)


func _attach_weapon_models() -> void:
	var skeleton := _find_skeleton(_model_root)
	if skeleton == null:
		_log("Could not find skeleton for Quaternius weapon attachments.")
		return

	if _weapon_type == WEAPON_BOW:
		_attach_weapon_scene(
			skeleton,
			"hand_l",
			STARTER_BOW_PATH,
			"ImportedBow",
			Vector3(0.0, 0.015, 0.0),
			Vector3(0.0, 90.0, 0.0),
			BOW_ATTACHMENT_SCALE
		)
		_attach_weapon_scene(
			skeleton,
			"hand_r",
			STARTER_ARROW_PATH,
			"ImportedArrow",
			Vector3(0.0, 0.0, 0.14),
			Vector3(90.0, 0.0, 0.0),
			ARROW_ATTACHMENT_SCALE
		)
		return

	_attach_weapon_scene(
		skeleton,
		"hand_r",
		STARTER_SWORD_PATH,
		"ImportedSword",
		Vector3(-0.005, 0.06, 0.03),
		Vector3(0.0, -87.0, 90.0),
		SWORD_ATTACHMENT_SCALE
	)
	_attach_weapon_scene(
		skeleton,
		"lowerarm_l",
		STARTER_SHIELD_PATH,
		"ImportedShield",
		Vector3(0.0, 0.08, 0.0),
		Vector3.ZERO,
		SHIELD_ATTACHMENT_SCALE
	)


func _attach_weapon_scene(
	skeleton: Skeleton3D,
	bone_name: String,
	path: String,
	node_name: String,
	local_position: Vector3,
	local_rotation_degrees: Vector3,
	uniform_scale: float
) -> Node3D:
	if skeleton.find_bone(bone_name) < 0:
		_log("Could not find bone %s for %s." % [bone_name, node_name])
		return null

	var weapon_root := _load_imported_scene(path) as Node3D
	if weapon_root == null:
		_log("Could not load weapon model: %s" % path)
		return null

	var attachment := BoneAttachment3D.new()
	attachment.name = "%sAttachment" % node_name
	attachment.bone_name = bone_name
	skeleton.add_child(attachment)

	weapon_root.name = node_name
	weapon_root.position = local_position
	weapon_root.rotation_degrees = local_rotation_degrees
	weapon_root.scale = Vector3.ONE * uniform_scale
	attachment.add_child(weapon_root)
	_collect_meshes(weapon_root)
	return weapon_root


func _hairstyle_path_for_profile() -> String:
	match int(_appearance_profile.get("hair_style", HEAD_HAIR_SIMPLE_PARTED)):
		HEAD_HAIR_BUZZED:
			return HAIRSTYLE_BASE_PATH + "Hair_Buzzed.gltf"
		HEAD_HAIR_LONG:
			return HAIRSTYLE_BASE_PATH + "Hair_Long.gltf"
		HEAD_HAIR_BEARD:
			return HAIRSTYLE_BASE_PATH + "Hair_Beard.gltf"
		_:
			return HAIRSTYLE_BASE_PATH + "Hair_SimpleParted.gltf"


func _merge_modular_hairstyle(target_skeleton: Skeleton3D, path: String, hair_color: Color) -> void:
	if path.is_empty() or target_skeleton == null:
		return

	var hair_root := _load_gltf_scene(path)
	if hair_root == null:
		_log("Could not load modular hairstyle: %s" % path)
		return

	var hair_skeleton := _find_skeleton(hair_root)
	if hair_skeleton == null:
		hair_root.free()
		_log("Could not find hairstyle skeleton: %s" % path)
		return

	for child in hair_skeleton.get_children():
		var mesh := child as MeshInstance3D
		if mesh == null:
			continue
		hair_skeleton.remove_child(mesh)
		mesh.owner = null
		target_skeleton.add_child(mesh)
		mesh.set("skeleton", NodePath(".."))
		mesh.material_override = _make_faction_marker_material(mesh, hair_color)
		_meshes.append(mesh)

	hair_root.free()


func _appearance_color(key: String, fallback: Color) -> Color:
	var value = _appearance_profile.get(key, fallback)
	if value is Color:
		return value
	return fallback


func _make_appearance_material(color: Color, roughness: float) -> StandardMaterial3D:
	var key := "%.3f:%.3f:%.3f:%.3f:%.3f" % [color.r, color.g, color.b, color.a, roughness]
	if _appearance_material_cache.has(key):
		return _appearance_material_cache[key] as StandardMaterial3D

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	_appearance_material_cache[key] = material
	return material


func _find_faction_marker_meshes() -> Array[MeshInstance3D]:
	var markers: Array[MeshInstance3D] = []
	for mesh in _meshes:
		if mesh == null:
			continue
		if _is_faction_marker_mesh(mesh.name):
			markers.append(mesh)
	return markers


func _is_faction_marker_mesh(mesh_name: StringName) -> bool:
	var lower_name := String(mesh_name).to_lower()
	if _weapon_type == WEAPON_BOW:
		return lower_name.contains("ranger_head_hood") or lower_name == "male_ranger_body"
	return lower_name.contains("peasant_body")


func _make_faction_marker_material(mesh: MeshInstance3D, faction_color: Color) -> ShaderMaterial:
	var source_material := _source_marker_material(mesh)
	var material := ShaderMaterial.new()
	material.shader = _get_faction_marker_shader()
	material.set_shader_parameter("faction_color", faction_color)
	material.set_shader_parameter("color_strength", FACTION_MARKER_COLOR_STRENGTH)
	if source_material == null:
		material.set_shader_parameter("base_color", Color.WHITE)
		material.set_shader_parameter("source_roughness", 0.88)
		material.set_shader_parameter("source_metallic", 0.0)
		material.set_shader_parameter("use_source_texture", false)
		return material

	material.set_shader_parameter("base_color", source_material.albedo_color)
	material.set_shader_parameter("source_roughness", source_material.roughness)
	material.set_shader_parameter("source_metallic", source_material.metallic)
	material.set_shader_parameter("use_source_texture", source_material.albedo_texture != null)
	if source_material.albedo_texture != null:
		material.set_shader_parameter("source_texture", source_material.albedo_texture)
	return material


func _get_faction_marker_shader() -> Shader:
	if _faction_marker_shader != null:
		return _faction_marker_shader

	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D source_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_source_texture = false;
uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 faction_color : source_color = vec4(1.0);
uniform float color_strength : hint_range(0.0, 1.0) = 1.0;
uniform float source_roughness : hint_range(0.0, 1.0) = 0.88;
uniform float source_metallic : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 texel = use_source_texture ? texture(source_texture, UV) : vec4(1.0);
	vec4 base = base_color * texel;
	vec3 luminance_weights = vec3(0.2126, 0.7152, 0.0722);
	float base_luminance = dot(base.rgb, luminance_weights);
	float faction_luminance = max(dot(faction_color.rgb, luminance_weights), 0.001);
	vec3 colorized = clamp(faction_color.rgb * (base_luminance / faction_luminance), vec3(0.0), vec3(1.0));
	ALBEDO = mix(base.rgb, colorized, color_strength);
	ALPHA = base.a;
	ROUGHNESS = source_roughness;
	METALLIC = source_metallic;
}
"""
	_faction_marker_shader = shader
	return _faction_marker_shader


func _source_marker_material(mesh: MeshInstance3D) -> StandardMaterial3D:
	var override_material := mesh.material_override as StandardMaterial3D
	if override_material != null:
		return override_material.duplicate() as StandardMaterial3D
	if mesh.mesh == null or mesh.mesh.get_surface_count() <= 0:
		return null

	var surface_material := mesh.mesh.surface_get_material(0) as StandardMaterial3D
	if surface_material == null:
		return null
	return surface_material.duplicate() as StandardMaterial3D


func _is_skin_or_head_mesh(mesh_name: StringName) -> bool:
	var lower_name := String(mesh_name).to_lower()
	return lower_name == "head" \
		or lower_name.ends_with("_head") \
		or lower_name.contains("skin") \
		or lower_name.contains("fullbody") \
		or lower_name.contains("superhero") \
		or lower_name.contains("eye") \
		or lower_name.contains("brow") \
		or lower_name.contains("beard") \
		or lower_name.contains("hair")


func _attach_animation_player() -> bool:
	var animation_source := _load_gltf_scene(ANIMATION_SOURCE_PATH)
	if animation_source == null:
		return false

	var source_player := _find_animation_player(animation_source)
	if source_player == null:
		animation_source.free()
		return false

	_animation_player = source_player.duplicate() as AnimationPlayer
	_animation_player.name = "AnimationPlayer"
	_model_root.add_child(_animation_player)
	animation_source.free()
	_prepare_animation_loops()
	_attach_mixamo_animations()
	return true


func _prepare_animation_loops() -> void:
	if _animation_player == null:
		return
	for animation_name in _animation_player.get_animation_list():
		var animation := _animation_player.get_animation(animation_name)
		if animation == null:
			continue
		if animation_name.ends_with("_Loop"):
			animation.loop_mode = Animation.LOOP_LINEAR
		else:
			animation.loop_mode = Animation.LOOP_NONE


func _attach_mixamo_animations() -> void:
	if _animation_player == null:
		return

	var library := _animation_player.get_animation_library("")
	if library == null:
		library = AnimationLibrary.new()
		_animation_player.add_animation_library("", library)

	for animation_name in MIXAMO_ANIMATION_LIBRARY.keys():
		if library.has_animation(animation_name):
			continue
		var config: Dictionary = MIXAMO_ANIMATION_LIBRARY[animation_name]
		var animation := _load_mixamo_animation(String(config.get("path", "")), bool(config.get("loop", false)))
		if animation == null:
			_log("Could not load Mixamo animation: %s" % animation_name)
			continue
		animation.resource_name = animation_name
		library.add_animation(animation_name, animation)


func _load_mixamo_animation(path: String, should_loop: bool) -> Animation:
	var resource := ResourceLoader.load(path)
	var packed_scene := resource as PackedScene
	if packed_scene == null:
		return null

	var source_root := packed_scene.instantiate()
	var source_player := _find_animation_player(source_root)
	if source_player == null:
		source_root.free()
		return null

	var source_animation := _first_source_animation(source_player)
	if source_animation == null:
		source_root.free()
		return null

	var animation := source_animation.duplicate(true) as Animation
	source_root.free()
	if animation == null:
		return null

	var retargeted_tracks := _retarget_mixamo_animation(animation)
	if retargeted_tracks <= 0:
		return null

	animation.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
	return animation


func _first_source_animation(source_player: AnimationPlayer) -> Animation:
	if source_player.has_animation("mixamo_com"):
		return source_player.get_animation("mixamo_com")
	for animation_name in source_player.get_animation_list():
		var animation := source_player.get_animation(animation_name)
		if animation != null:
			return animation
	return null


func _retarget_mixamo_animation(animation: Animation) -> int:
	var retargeted_tracks := 0
	for track_index in range(animation.get_track_count() - 1, -1, -1):
		var path_text := str(animation.track_get_path(track_index))
		var separator := path_text.rfind(":")
		if separator < 0:
			animation.remove_track(track_index)
			continue

		var source_bone := path_text.substr(separator + 1)
		if MIXAMO_ROOT_BONES_TO_SKIP.has(source_bone):
			animation.remove_track(track_index)
			continue
		if not MIXAMO_BONE_MAP.has(source_bone):
			animation.remove_track(track_index)
			continue

		var target_bone := String(MIXAMO_BONE_MAP[source_bone])
		animation.track_set_path(track_index, NodePath("Armature/Skeleton3D:%s" % target_bone))
		retargeted_tracks += 1
	return retargeted_tracks


func _play_first_available(state: String, clips: Array, blend: float, speed_scale: float, loop := false) -> void:
	if _animation_player == null:
		return
	var clip := _first_available_clip(clips)
	if clip.is_empty():
		_set_model_rotation(MODEL_BASE_ROTATION_DEGREES)
		return
	_set_model_rotation(_model_rotation_for_clip(clip))
	if _current_state == state and _animation_player.current_animation == clip and _animation_player.is_playing():
		return
	var animation := _animation_player.get_animation(clip)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	_animation_player.play(clip, blend, speed_scale)
	_current_state = state


func _first_available_clip(clips: Array) -> String:
	if _animation_player == null:
		return ""
	for clip in clips:
		var clip_name := String(clip)
		if _animation_player.has_animation(clip_name):
			return clip_name
	return ""


func _model_rotation_for_clip(clip_name: String) -> Vector3:
	if clip_name.begins_with("mixamo_bow_"):
		return MIXAMO_BOW_PACK_ROTATION_DEGREES
	return MODEL_BASE_ROTATION_DEGREES


func _collect_meshes(root: Node) -> void:
	if root is MeshInstance3D:
		_meshes.append(root)
	for child in root.get_children():
		_collect_meshes(child)


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func _merge_base_character_head(outfit_root: Node, base_root: Node) -> bool:
	var outfit_skeleton := _find_skeleton(outfit_root)
	var base_skeleton := _find_skeleton(base_root)
	if outfit_skeleton == null or base_skeleton == null:
		return false

	var head_bone_indices := _bone_indices_for_names(base_skeleton, BASE_HEAD_BONES)
	var moved_meshes := 0
	var moved_head := false
	for child in base_skeleton.get_children():
		var mesh := child as MeshInstance3D
		if mesh == null:
			continue
		if _is_base_body_mesh_name(mesh.name):
			if not _keep_base_body_head_only(mesh, head_bone_indices):
				continue
			moved_head = true
		elif not _is_base_face_mesh_name(mesh.name):
			continue
		base_skeleton.remove_child(mesh)
		mesh.owner = null
		outfit_skeleton.add_child(mesh)
		mesh.set("skeleton", NodePath(".."))
		moved_meshes += 1
	return moved_meshes > 0 and moved_head


func _bone_indices_for_names(skeleton: Skeleton3D, bone_names: Dictionary) -> Dictionary:
	var indices := {}
	for bone_name in bone_names.keys():
		var bone_index := skeleton.find_bone(String(bone_name))
		if bone_index >= 0:
			indices[bone_index] = true
	return indices


func _is_base_face_mesh_name(mesh_name: StringName) -> bool:
	var name_text := String(mesh_name)
	return name_text == "Eyebrows" or name_text == "Eyes"


func _is_base_body_mesh_name(mesh_name: StringName) -> bool:
	var name_text := String(mesh_name)
	return name_text.begins_with("SuperHero_") or name_text.begins_with("Superhero_")


func _keep_base_body_head_only(mesh: MeshInstance3D, head_bone_indices: Dictionary) -> bool:
	var source_mesh := mesh.mesh
	if source_mesh == null:
		return false

	var filtered_mesh := _make_head_only_mesh(source_mesh, head_bone_indices, true)
	if filtered_mesh == null:
		filtered_mesh = _make_head_only_mesh(source_mesh, {}, false)
	if filtered_mesh == null:
		return false

	mesh.mesh = filtered_mesh
	return true


func _make_head_only_mesh(source_mesh: Mesh, head_bone_indices: Dictionary, use_bone_filter: bool) -> ArrayMesh:
	var filtered_mesh := ArrayMesh.new()
	var kept_triangles := 0

	for surface_index in range(source_mesh.get_surface_count()):
		if source_mesh.surface_get_primitive_type(surface_index) != Mesh.PRIMITIVE_TRIANGLES:
			continue

		var arrays := source_mesh.surface_get_arrays(surface_index)
		var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		if vertices.is_empty():
			continue

		var source_indices := arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
		var bones := arrays[Mesh.ARRAY_BONES] as PackedInt32Array
		var weights := arrays[Mesh.ARRAY_WEIGHTS] as PackedFloat32Array
		var filtered_indices := _head_only_indices(
			vertices,
			source_indices,
			bones,
			weights,
			head_bone_indices,
			use_bone_filter
		)
		if filtered_indices.is_empty():
			continue

		var filtered_arrays := arrays.duplicate(true)
		filtered_arrays[Mesh.ARRAY_INDEX] = filtered_indices
		filtered_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, filtered_arrays)
		var filtered_surface := filtered_mesh.get_surface_count() - 1
		var material := source_mesh.surface_get_material(surface_index)
		if material != null:
			filtered_mesh.surface_set_material(filtered_surface, material)
		kept_triangles += int(filtered_indices.size() / 3)

	if kept_triangles < MIN_HEAD_TRIANGLES:
		return null

	filtered_mesh.resource_name = source_mesh.resource_name
	return filtered_mesh


func _head_only_indices(
	vertices: PackedVector3Array,
	source_indices: PackedInt32Array,
	bones: PackedInt32Array,
	weights: PackedFloat32Array,
	head_bone_indices: Dictionary,
	use_bone_filter: bool
) -> PackedInt32Array:
	var filtered_indices := PackedInt32Array()
	var triangle_count := int(source_indices.size() / 3) if not source_indices.is_empty() else int(vertices.size() / 3)

	for triangle_index in range(triangle_count):
		var first_index := triangle_index * 3
		var a := int(source_indices[first_index]) if not source_indices.is_empty() else first_index
		var b := int(source_indices[first_index + 1]) if not source_indices.is_empty() else first_index + 1
		var c := int(source_indices[first_index + 2]) if not source_indices.is_empty() else first_index + 2
		if _is_head_vertex(a, vertices, bones, weights, head_bone_indices, use_bone_filter) \
				and _is_head_vertex(b, vertices, bones, weights, head_bone_indices, use_bone_filter) \
				and _is_head_vertex(c, vertices, bones, weights, head_bone_indices, use_bone_filter):
			filtered_indices.append(a)
			filtered_indices.append(b)
			filtered_indices.append(c)

	return filtered_indices


func _is_head_vertex(
	vertex_index: int,
	vertices: PackedVector3Array,
	bones: PackedInt32Array,
	weights: PackedFloat32Array,
	head_bone_indices: Dictionary,
	use_bone_filter: bool
) -> bool:
	if vertex_index < 0 or vertex_index >= vertices.size():
		return false

	if not use_bone_filter or head_bone_indices.is_empty() or bones.is_empty() or weights.is_empty():
		return vertices[vertex_index].y >= BASE_HEAD_FALLBACK_MIN_Y
	if vertices[vertex_index].y < BASE_HEAD_MIN_Y:
		return false

	var influences_per_vertex := int(bones.size() / vertices.size())
	var influence_offset := vertex_index * influences_per_vertex
	var strongest_bone := -1
	var strongest_weight := -1.0
	for influence_index in range(influences_per_vertex):
		var weight_index := influence_offset + influence_index
		if weight_index >= weights.size() or weight_index >= bones.size():
			break
		var influence_weight := float(weights[weight_index])
		if influence_weight > strongest_weight:
			strongest_weight = influence_weight
			strongest_bone = int(bones[weight_index])

	return head_bone_indices.has(strongest_bone)


func _find_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root
	for child in root.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


static func _load_gltf_scene(path: String) -> Node:
	if not FileAccess.file_exists(path):
		return null
	if _packed_scene_cache.has(path):
		var cached_scene := _packed_scene_cache[path] as PackedScene
		if cached_scene != null:
			return cached_scene.instantiate()

	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file(path, state)
	if error != OK:
		return null

	var root := document.generate_scene(state)
	if root == null:
		return null

	var packed_scene := PackedScene.new()
	error = packed_scene.pack(root)
	if error == OK:
		_packed_scene_cache[path] = packed_scene
		var instance := packed_scene.instantiate()
		root.free()
		return instance

	return root


static func _load_imported_scene(path: String) -> Node:
	if not FileAccess.file_exists(path):
		return null
	if _packed_scene_cache.has(path):
		var cached_scene := _packed_scene_cache[path] as PackedScene
		if cached_scene != null:
			return cached_scene.instantiate()

	var packed_scene := ResourceLoader.load(path) as PackedScene
	if packed_scene == null:
		return null

	_packed_scene_cache[path] = packed_scene
	return packed_scene.instantiate()


func _make_hit_overlay_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.15, 0.08, 0.42)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _log(message: String) -> void:
	if debug_log:
		push_warning(message)
