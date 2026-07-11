extends Node

const CampaignMap := preload("res://scripts/campaign_map.gd")
const CombatBiomeProfiles := preload("res://scripts/combat_biome_profiles.gd")

const SAMPLE_POINTS := [
	{"id": 1, "name": "Coastal plain", "coordinates": [34.42, 32.45]},
	{"id": 2, "name": "Shephelah foothills", "coordinates": [34.82, 31.67]},
	{"id": 3, "name": "Central highlands", "coordinates": [35.22, 31.88]},
	{"id": 4, "name": "Galilee hills", "coordinates": [35.45, 33.35]},
	{"id": 5, "name": "Jordan Rift", "coordinates": [35.55, 31.84]},
	{"id": 6, "name": "Transjordan plateau", "coordinates": [35.95, 31.84]},
	{"id": 7, "name": "Negev wilderness", "coordinates": [34.65, 30.55]},
]


func _ready() -> void:
	var failures: Array[String] = []
	var campaign_map := CampaignMap.new()
	campaign_map.call("_load_painted_map_plate")
	campaign_map.call("_load_map_dataset")

	for sample in SAMPLE_POINTS:
		var sample_dict := Dictionary(sample)
		var expected_id := int(sample_dict["id"])
		var map_position: Vector2 = campaign_map.call("_geo_to_map", Array(sample_dict["coordinates"]))
		var context := campaign_map.get_combat_map_context(map_position)
		var actual_id := int(context.get("biome_id", 0))
		var profile := CombatBiomeProfiles.profile_for_id(actual_id)
		if actual_id != expected_id:
			failures.append("%s expected biome %d, got %d at %s" % [
				String(sample_dict["name"]),
				expected_id,
				actual_id,
				str(map_position)
			])
		if not CombatBiomeProfiles.has_profile(actual_id):
			failures.append("%s returned missing profile id %d" % [String(sample_dict["name"]), actual_id])
		_validate_profile_textures(profile, failures)

	_validate_game_state_combat_map_context(failures)
	campaign_map.free()

	if failures.is_empty():
		print("Combat biome validation passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _validate_profile_textures(profile: Dictionary, failures: Array[String]) -> void:
	for key in ["primary_albedo_path", "primary_height_path", "secondary_albedo_path", "secondary_height_path"]:
		var path := String(profile.get(key, ""))
		if path.is_empty():
			failures.append("Profile %d has empty %s" % [int(profile.get("biome_id", 0)), key])
			continue
		if not FileAccess.file_exists(path):
			failures.append("Profile %d missing %s: %s" % [int(profile.get("biome_id", 0)), key, path])

	for key in ["path_albedo_path", "path_height_path", "rock_albedo_path", "rock_height_path"]:
		var path := String(profile.get(key, ""))
		if path.is_empty():
			continue
		if not FileAccess.file_exists(path):
			failures.append("Profile %d missing optional %s: %s" % [int(profile.get("biome_id", 0)), key, path])


func _validate_game_state_combat_map_context(failures: Array[String]) -> void:
	GameState.clear_combat_context()
	GameState.clear_combat_map_context()
	if GameState.has_combat_map_context():
		failures.append("GameState reports combat map context after clear.")

	GameState.set_combat_map_context({
		"campaign_position": Vector2(12.0, 34.0),
		"biome_id": 5,
		"biome_key": "biome_jordan_rift",
		"biome_name": "Jordan Rift",
		"biome_properties": {}
	})
	GameState.clear_combat_context()
	if not GameState.has_combat_map_context():
		failures.append("GameState lost combat map context after clearing combat context.")

	var stored_context := GameState.get_combat_map_context()
	if int(stored_context.get("biome_id", 0)) != 5:
		failures.append("GameState combat map context expected biome 5, got %d." % int(stored_context.get("biome_id", 0)))
	GameState.clear_combat_map_context()
