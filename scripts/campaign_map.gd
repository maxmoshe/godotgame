extends Node2D

const MAP_SCALE := 3.0
const BASE_MAP_RECT := Rect2(Vector2(-900.0, -1250.0), Vector2(1800.0, 2500.0))
const MAP_RECT := Rect2(BASE_MAP_RECT.position * MAP_SCALE, BASE_MAP_RECT.size * MAP_SCALE)
const MAP_DATA_ROOT := "res://data/maps/southern_levant"
const MAP_MANIFEST_PATH := "res://data/maps/southern_levant/map_manifest.json"
const PAINTED_MAP_PLATE_PATH := "res://assets/map/base/chatgpt.png"
const ABNER_NAME := "Abner ben Ner"
const ABNER_DETECTION_RADIUS := 520.0
const ABNER_ESCAPE_RADIUS := 760.0
const ABNER_CATCH_RADIUS := 42.0
const ABNER_PURSUIT_SPEED_MULTIPLIER := 1.38
const ABNER_PRESSURE_ENABLED := false
const LORD_SIZE_SPEED_PENALTY_MEN := 100.0
const LORD_SIZE_SPEED_PENALTY_MAX := 0.20
const LORD_INTELLIGENCE_SPEED_BONUS_STAT := 50.0
const LORD_INTELLIGENCE_SPEED_BONUS_MAX := 0.30
const LORD_CAMPAIGN_SPEED_MULTIPLIER := 0.5
const LORD_ACTIVE_DWELL_MINUTES := Vector2(45.0, 180.0)
const LORD_IDLE_DWELL_MINUTES := Vector2(360.0, 1080.0)
const LORD_HOME_DWELL_MULTIPLIER := 1.35
const LORD_LARGE_PARTY_DWELL_MINUTES := 90.0
const LORD_INITIAL_DWELL_MIN_RATIO := 0.35
const LORD_INITIAL_DWELL_MAX_RATIO := 0.80
const OVERWORLD_AI_PLAN_INTERVAL_MINUTES := 15
const OVERWORLD_AI_STRATEGY_INTERVAL_MINUTES := 6 * 60
const OVERWORLD_AI_MAX_PURSUERS := 1
const OVERWORLD_AI_HIGH_PRESSURE_SCORE := 82.0
const OVERWORLD_AI_RELIEF_AFTER_ESCAPE_MINUTES := 90
const LORD_BASE_DETECTION_RADIUS := 360.0
const LORD_RUMOR_RADIUS := 780.0
const LORD_SEARCH_RADIUS := 300.0
const LORD_SEARCH_ARRIVAL_RADIUS := 58.0
const LORD_CATCH_RADIUS := 42.0
const LORD_COMBAT_REINFORCE_RADIUS := 540.0
const LORD_COMBAT_REINFORCE_LIMIT := 3
const LORD_GROUP_UP_RADIUS := 920.0
const LORD_GROUP_UP_ARRIVAL_RADIUS := 82.0
const LORD_WEAK_SOLO_RATIO := 0.72
const LORD_CAUTIOUS_SOLO_RATIO := 0.92
const LORD_CONFIDENT_GROUP_RATIO := 1.12
const LORD_ORDINARY_TARGET_NOTICE_MULTIPLIER := 0.62
const LORD_OPPORTUNISTIC_SOLO_RATIO := 1.18
const LORD_OPPORTUNISTIC_SUPPORTED_RATIO := 1.06
const LORD_WEAK_FLEE_RADIUS := 440.0
const LORD_WEAK_FLEE_CLEAR_RADIUS := 680.0
const LORD_FLEE_TARGET_DISTANCE := 760.0
const LORD_FLEE_SPEED_MULTIPLIER := 1.34
const LORD_ABSORBED_TOWN_RADIUS := 92.0
const LORD_MUSTER_LOITER_RADIUS := 74.0
const LORD_PURSUIT_SPEED_MULTIPLIER := 1.26
const LORD_SEARCH_SPEED_MULTIPLIER := 0.92
const LORD_DIRECT_SIGHT_CONFIDENCE := 94.0
const LORD_RUMOR_CONFIDENCE := 46.0
const LORD_PURSUIT_CONFIDENCE_MIN := 55.0
const LORD_SEARCH_CONFIDENCE_MIN := 16.0
const LORD_CONFIDENCE_DECAY_PER_HOUR := 8.0
const LORD_SAFE_PLACE_CONFIDENCE_LOSS := 24.0
const LORD_RECOVER_FATIGUE_THRESHOLD := 72.0
const LORD_RESUPPLY_THRESHOLD := 32.0
const LORD_RECOVERY_DWELL_MINUTES := Vector2(180.0, 480.0)
const LORD_MEMORY_LIMIT := 8
const LORD_MEMORY_EFFECT_DAYS := 4.0
const LORD_ROAD_GRAPH_MERGE_DISTANCE := 54.0
const LORD_ROAD_GRAPH_CONNECT_DISTANCE := 95.0
const LORD_ROAD_GUIDANCE_MIN_DISTANCE := 420.0
const LORD_ROAD_REJOIN_RADIUS := 80.0
const LORD_ROAD_MAX_DETOUR_MULTIPLIER := 1.9
const NPC_RENDER_RADIUS_BASE := 900.0
const NPC_FADE_BAND_BASE := 200.0
const NPC_ZOOM_REFERENCE := 0.82
const FALLBACK_MAP_PROJECTION_ID := "bbox_fit"
const WATER_EDGE_MARGIN := 20.0
const SETTLEMENT_SAFE_RADIUS := 54.0
const BLOCKING_WATER_KINDS := ["lake", "salt_lake", "wetland"]
const LAND_SEARCH_DIRECTIONS := [
	Vector2(1.0, 0.0),
	Vector2(0.707, 0.707),
	Vector2(0.0, 1.0),
	Vector2(-0.707, 0.707),
	Vector2(-1.0, 0.0),
	Vector2(-0.707, -0.707),
	Vector2(0.0, -1.0),
	Vector2(0.707, -0.707),
	Vector2(0.924, 0.383),
	Vector2(0.383, 0.924),
	Vector2(-0.383, 0.924),
	Vector2(-0.924, 0.383),
	Vector2(-0.924, -0.383),
	Vector2(-0.383, -0.924),
	Vector2(0.383, -0.924),
	Vector2(0.924, -0.383)
]
const LAND_SEARCH_RADII := [24.0, 48.0, 72.0, 108.0, 150.0, 210.0, 300.0, 420.0, 620.0, 900.0]
const LABEL_HALO_OFFSETS := [
	Vector2(-2.0, 0.0),
	Vector2(2.0, 0.0),
	Vector2(0.0, -2.0),
	Vector2(0.0, 2.0),
	Vector2(-1.5, -1.5),
	Vector2(1.5, -1.5),
	Vector2(-1.5, 1.5),
	Vector2(1.5, 1.5)
]
const FACTION_COLORS := {
	"House of Saul": "#5f4a9b",
	"Benjamin": "#6f5ab1",
	"Priestly": "#c7a75a",
	"Jebus": "#3f7187",
	"Judah": "#2f7d55",
	"David's Band": "#2f7d55",
	"Philistine Lords": "#a13d38",
	"Ephraim": "#4e8758",
	"Northern Israel": "#4e8758",
	"Galilee": "#5f8f6c",
	"Phoenician Coast": "#2f7f8e",
	"Ammon": "#8c6a3f",
	"Moab": "#9b7244",
	"Edom edge": "#9a5f35",
	"Aram-Damascus": "#7d5f8f",
	"Bashan": "#5e7f6b",
	"Geshur": "#4f7f88",
	"Kenite clans": "#9a7f45",
	"Amalekite clans": "#a05a3c",
	"Midianite clans": "#8f7352",
	"Negev clans": "#8a8143",
	"Jordan Rift": "#477995",
	"Wilderness": "#b18045",
	"Judah / Negev": "#7e8f48",
	"Sinai / Negev": "#b18045",
	"Northern road": "#6d6a58",
	"Contested": "#b8a15a",
	"Neutral": "#6d6a58"
}

var land_polygon := PackedVector2Array([
	Vector2(-430, -1180), Vector2(210, -1210), Vector2(515, -900),
	Vector2(590, -450), Vector2(540, 25), Vector2(650, 410),
	Vector2(520, 1110), Vector2(60, 1215), Vector2(-400, 1030),
	Vector2(-640, 560), Vector2(-590, -80), Vector2(-705, -620)
])

var great_sea := PackedVector2Array([
	Vector2(-1160, -1450), Vector2(-535, -1450), Vector2(-610, -820),
	Vector2(-560, -240), Vector2(-635, 320), Vector2(-545, 870),
	Vector2(-670, 1510), Vector2(-1160, 1510)
])

const SETTLEMENTS := [
	{"name": "Gibeah", "pos": Vector2(42, -172), "kind": "Saul's court"},
	{"name": "Ramah", "pos": Vector2(-25, -260), "kind": "Prophet's town"},
	{"name": "Nob", "pos": Vector2(92, -55), "kind": "Priestly town"},
	{"name": "Jebus", "pos": Vector2(102, 58), "kind": "Fortress"},
	{"name": "Bethlehem", "pos": Vector2(28, 258), "kind": "House of Jesse"},
	{"name": "Hebron", "pos": Vector2(-8, 630), "kind": "Judah stronghold"},
	{"name": "Keilah", "pos": Vector2(-168, 390), "kind": "Border town"},
	{"name": "Socoh", "pos": Vector2(-230, 235), "kind": "Valley town"},
	{"name": "Ziklag", "pos": Vector2(-265, 820), "kind": "David's refuge"},
	{"name": "En-gedi", "pos": Vector2(338, 545), "kind": "Wilderness spring"},
	{"name": "Gath", "pos": Vector2(-448, 182), "kind": "Philistine city"},
	{"name": "Ashkelon", "pos": Vector2(-590, 515), "kind": "Philistine port"},
	{"name": "Gaza", "pos": Vector2(-585, 895), "kind": "Philistine port"},
	{"name": "Aphek", "pos": Vector2(-312, -590), "kind": "Northern road"},
	{"name": "Shiloh", "pos": Vector2(88, -562), "kind": "Old sanctuary"},
	{"name": "Gilboa", "pos": Vector2(235, -1045), "kind": "Northern highlands"}
]

const NPC_PARTIES := [
	{
		"name": "Judean Scout",
		"pos": Vector2(150, 470),
		"kind": "NPC party",
		"dialogue": "A dust-stained scout from the hill country reins in and studies your banner. \"The roads south of Bethlehem are nervous. Saul's men ask too many questions, and Philistine riders have been seen near the lowland tracks.\""
	}
]

const LORD_PARTIES := [
	{
		"name": "Abner ben Ner",
		"title": "Commander of Saul's host",
		"faction": "House of Saul",
		"party_size": 86,
		"start": Vector2(42, -172),
		"start_name": "Gibeah",
		"home_name": "Gibeah",
		"role": "marshal",
		"task": {
			"type": "patrol",
			"target_name": "Gibeah road",
			"priority": 54.0,
			"reason": "Saul's commander keeps the northern hill roads under watch.",
			"confidence": 0.0
		},
		"boldness": 76.0,
		"caution": 52.0,
		"ambition": 74.0,
		"loyalty": 92.0,
		"route": [Vector2(42, -172), Vector2(92, -55), Vector2(88, -562), Vector2(235, -1045), Vector2(42, -172)],
		"route_names": ["Gibeah", "Nob", "Shiloh", "Gilboa", "Gibeah"],
		"speed": 48.0,
		"intelligence": 38,
		"color": "#5f4a9b",
		"dialogue": "Abner's men ride in close order, Benjaminite spears upright and Saul's standard held where every village watchman can see it."
	},
	{
		"name": "Abishai son of Zeruiah",
		"title": "Captain among David's men",
		"faction": "David's Band",
		"party_size": 39,
		"start": Vector2(28, 258),
		"start_name": "Bethlehem",
		"home_name": "Bethlehem",
		"role": "ally",
		"task": {},
		"boldness": 68.0,
		"caution": 44.0,
		"ambition": 58.0,
		"loyalty": 84.0,
		"route": [Vector2(28, 258), Vector2(-8, 630), Vector2(-265, 820), Vector2(338, 545), Vector2(-168, 390), Vector2(28, 258)],
		"route_names": ["Bethlehem", "Hebron", "Ziklag", "En-gedi", "Keilah", "Bethlehem"],
		"speed": 55.0,
		"intelligence": 31,
		"color": "#2f7d55",
		"dialogue": "Abishai keeps his band lean and quick. They look like men who know caves, goat paths, and the value of vanishing before dawn."
	},
	{
		"name": "Achish of Gath",
		"title": "Philistine seren",
		"faction": "Philistine Lords",
		"party_size": 118,
		"start": Vector2(-448, 182),
		"start_name": "Gath",
		"home_name": "Gath",
		"role": "border_lord",
		"task": {
			"type": "patrol",
			"target_name": "Philistine road",
			"priority": 46.0,
			"reason": "Philistine captains guard the coastal road and lowland approaches.",
			"confidence": 0.0
		},
		"boldness": 64.0,
		"caution": 62.0,
		"ambition": 52.0,
		"loyalty": 68.0,
		"route": [Vector2(-448, 182), Vector2(-590, 515), Vector2(-585, 895), Vector2(-448, 182), Vector2(-230, 235)],
		"route_names": ["Gath", "Ashkelon", "Gaza", "Gath", "Socoh"],
		"speed": 38.0,
		"intelligence": 34,
		"color": "#a13d38",
		"dialogue": "Bronze flashes among Achish's guard. Their captains speak in the clipped confidence of men who own the coastal road."
	},
	{
		"name": "Doeg the Edomite",
		"title": "Chief of Saul's herdsmen",
		"faction": "Edomite Retinue",
		"party_size": 27,
		"start": Vector2(92, -55),
		"start_name": "Nob",
		"home_name": "Gibeah",
		"role": "informer",
		"task": {
			"type": "errand",
			"target_name": "Saul's court",
			"priority": 36.0,
			"reason": "Doeg listens where frightened men talk too freely.",
			"confidence": 0.0
		},
		"boldness": 48.0,
		"caution": 70.0,
		"ambition": 72.0,
		"loyalty": 64.0,
		"route": [Vector2(92, -55), Vector2(42, -172), Vector2(-25, -260), Vector2(92, -55), Vector2(102, 58)],
		"route_names": ["Nob", "Gibeah", "Ramah", "Nob", "Jebus"],
		"speed": 43.0,
		"intelligence": 42,
		"color": "#8c5c2f",
		"dialogue": "Doeg's retinue is smaller than a war host, but no one on the road seems eager to meet his eye or ask where he is bound."
	},
	{
		"name": "Araunah of Jebus",
		"title": "Jebusite elder",
		"faction": "Jebus",
		"party_size": 44,
		"start": Vector2(102, 58),
		"start_name": "Jebus",
		"home_name": "Jebus",
		"role": "local_elder",
		"task": {},
		"boldness": 34.0,
		"caution": 78.0,
		"ambition": 38.0,
		"loyalty": 56.0,
		"route": [Vector2(102, 58), Vector2(338, 545), Vector2(28, 258), Vector2(102, 58)],
		"route_names": ["Jebus", "Jericho", "En-gedi", "Hebron", "Bethlehem", "Jebus"],
		"speed": 34.0,
		"intelligence": 36,
		"color": "#3f7187",
		"dialogue": "Araunah travels with household guards and pack animals. His men watch both Israelite hills and Philistine lowlands with equal suspicion."
	}
]

const ROADS := [
	[Vector2(-585, 895), Vector2(-520, 650), Vector2(-448, 182), Vector2(-312, -590), Vector2(235, -1045)],
	[Vector2(-448, 182), Vector2(-230, 235), Vector2(28, 258), Vector2(102, 58), Vector2(42, -172), Vector2(88, -562)],
	[Vector2(28, 258), Vector2(-8, 630), Vector2(-265, 820)],
	[Vector2(102, 58), Vector2(338, 545)],
	[Vector2(-230, 235), Vector2(-168, 390), Vector2(-8, 630)]
]

var _font: Font
var _lord_parties: Array[Dictionary] = []
var _map_manifest: Dictionary = {}
var _map_bbox := [33.6, 29.7, 36.714, 34.75]
var _land_features: Array = []
var _water_features: Array = []
var _biome_features: Array = []
var _relief_features: Array = []
var _settlement_features: Array = []
var _route_features: Array = []
var _chokepoint_features: Array = []
var _land_travel_polygons: Array[PackedVector2Array] = []
var _blocked_water_polygons: Array[PackedVector2Array] = []
var _settlement_entries: Array[Dictionary] = []
var _road_graph_points: Array = []
var _road_graph_edges: Array = []
var _painted_map_plate: Texture2D
var _map_render_calibration: Dictionary = {}
var _map_calibration_id := ""
var _map_calibration_points: Array[Dictionary] = []
var _map_calibration_image_size := Vector2.ZERO
var _map_calibration_softness_px := 140.0
var _map_calibration_power := 1.35
var _data_loaded := false
var player_position := Vector2.ZERO
var camera_zoom := 0.82


func _ready() -> void:
	_font = ThemeDB.fallback_font
	_load_painted_map_plate()
	_load_map_dataset()
	_initialize_lord_parties()
	_restore_lord_parties_from_game_state()
	queue_redraw()


func get_playable_rect() -> Rect2:
	return MAP_RECT.grow(-38.0)


func constrain_land_position(position: Vector2, fallback_position: Vector2 = Vector2.INF) -> Vector2:
	var clamped_position := _clamp_to_playable_rect(position)
	if _is_land_travel_position(clamped_position):
		return clamped_position

	if fallback_position != Vector2.INF:
		var clamped_fallback := _clamp_to_playable_rect(fallback_position)
		if _is_land_travel_position(clamped_fallback):
			return clamped_fallback

	var nearest_land := _nearest_land_position(clamped_position)
	if nearest_land != Vector2.INF:
		return nearest_land

	return _default_land_position()


func advance_lord_parties_for_real_seconds(real_seconds: float) -> void:
	_advance_lord_parties(real_seconds)


func update_lord_pressure(real_seconds: float, player_position: Vector2, player_is_safe: bool) -> Dictionary:
	var result := update_overworld_ai(real_seconds, player_position, player_is_safe)
	var forced_encounter = result.get("forced_encounter", {})
	if forced_encounter is Dictionary:
		return Dictionary(forced_encounter)
	return {}


func get_combat_map_context(position: Vector2) -> Dictionary:
	var safe_position := constrain_land_position(position, position)
	var biome_feature := _combat_biome_feature_at(safe_position)
	if biome_feature.is_empty():
		biome_feature = _nearest_combat_biome_feature(safe_position)
	if biome_feature.is_empty():
		return _fallback_combat_map_context(safe_position)

	var feature_properties := Dictionary(biome_feature.get("properties", {})).duplicate(true)
	var context := {
		"campaign_position": safe_position,
		"biome_id": int(feature_properties.get("biome_id", 3)),
		"biome_key": String(biome_feature.get("id", "biome_central_highlands")),
		"biome_name": String(feature_properties.get("name", "Central highlands")),
		"biome_properties": feature_properties
	}
	var relief_context := _combat_relief_context_at(safe_position)
	for key in relief_context.keys():
		context[key] = relief_context[key]
	return context


func update_overworld_ai(real_seconds: float, player_position: Vector2, player_is_safe: bool) -> Dictionary:
	var result := {
		"forced_encounter": {},
		"notices": [],
		"pressure_score": 0.0
	}
	if _lord_parties.is_empty() or real_seconds <= 0.0:
		return result

	var current_minute := GameState.get_game_total_minutes()
	var elapsed_minutes := real_seconds * GameState.GAME_MINUTES_PER_REAL_SECOND
	var notices: Array[String] = []
	var pressure_score := _calculate_overworld_pressure(player_position)
	_update_campaign_director(current_minute, pressure_score)

	for index in range(_lord_parties.size()):
		var lord: Dictionary = _ensure_lord_ai_state(_lord_parties[index])
		if GameState.is_lord_defeated(String(lord.get("name", ""))):
			continue

		lord = _decay_lord_ai_state(lord, elapsed_minutes)
		lord = _update_lord_perception(lord, player_position, player_is_safe, pressure_score, notices)
		if _should_replan_lord(lord, current_minute):
			lord = _plan_lord_task(lord, player_position, player_is_safe, pressure_score)
		var step_result := _execute_lord_task(lord, real_seconds, player_position, player_is_safe, notices)
		lord = Dictionary(step_result.get("lord", lord))
		var forced_encounter = step_result.get("forced_encounter", {})
		if forced_encounter is Dictionary and Dictionary(forced_encounter).is_empty() == false:
			result["forced_encounter"] = Dictionary(forced_encounter)
		_lord_parties[index] = lord

	if not notices.is_empty():
		result["notices"] = notices
		GameState.last_campaign_notice = notices[notices.size() - 1]
	result["pressure_score"] = _calculate_overworld_pressure(player_position)
	queue_redraw()
	return result


func get_nearest_hostile_lord_info(world_position: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for lord in _lord_parties:
		if not _is_hostile_lord(lord):
			continue
		var lord_position: Vector2 = lord["pos"]
		var distance := world_position.distance_to(lord_position)
		if distance < best_distance:
			best_distance = distance
			best = _target_from_lord(lord)
			best["distance"] = distance
			best["direction"] = _direction_text(lord_position - world_position)
			best["state"] = String(lord.get("state", "patrol"))
			best["task_type"] = _lord_task_type(lord)
			best["confidence"] = _lord_knowledge_confidence(lord)
	return best


func get_rumor_facts(world_position: Vector2) -> Array[Dictionary]:
	var facts: Array[Dictionary] = []
	for lord in _lord_parties:
		if not _is_hostile_lord(lord):
			continue
		var lord_position := Vector2(lord.get("pos", Vector2.ZERO))
		var distance := world_position.distance_to(lord_position)
		var knowledge := _lord_local_knowledge(lord)
		var legacy_profile := _lord_legacy_profile(lord)
		facts.append({
			"type": "lord",
			"name": String(lord.get("name", "Unknown lord")),
			"faction": String(lord.get("faction", "Unknown faction")),
			"state": String(lord.get("state", "patrol")),
			"task_type": _lord_task_type(lord),
			"task_reason": _lord_task_reason(lord),
			"distance": distance,
			"direction": _direction_text(lord_position - world_position),
			"confidence": float(knowledge.get("confidence", 0.0)),
			"knowledge_source": String(knowledge.get("source", "")),
			"last_seen_minute": int(knowledge.get("minute", -1)),
			"history_rank": String(legacy_profile.get("label", "unknown")),
			"nemesis_score": float(legacy_profile.get("nemesis_score", 0.0))
		})
	facts.sort_custom(Callable(self, "_compare_rumor_facts"))
	return facts


func get_ai_debug_snapshot() -> Dictionary:
	var lord_snapshots: Array[Dictionary] = []
	for lord in _lord_parties:
		var knowledge := _lord_local_knowledge(lord)
		var memory_profile := _lord_memory_profile(lord)
		var legacy_profile := _lord_legacy_profile(lord)
		var strength_profile := _lord_strength_profile(lord)
		var coordination := _coordination_role_for(lord, _active_pursuer_count(String(lord.get("name", ""))) > 0, float(_overworld_ai_director().get("pressure_score", 0.0)), false)
		lord_snapshots.append({
			"name": String(lord.get("name", "")),
			"state": String(lord.get("state", "")),
			"task": _lord_task_data(lord),
			"position": lord.get("pos", Vector2.ZERO),
			"waiting_at": String(lord.get("waiting_at", "")),
			"hold_minutes": float(lord.get("hold_minutes", 0.0)),
			"supplies": float(lord.get("supplies", 0.0)),
			"fatigue": float(lord.get("fatigue", 0.0)),
			"knowledge": knowledge,
			"memory": Array(lord.get("memory", [])).duplicate(true),
			"memory_profile": memory_profile,
			"legacy_profile": legacy_profile,
			"strength_profile": strength_profile,
			"coordination_role": String(coordination.get("id", "routine"))
		})
	return {
		"minute": GameState.get_game_total_minutes(),
		"director": Dictionary(GameState.map_state.get("overworld_ai", {})).duplicate(true),
		"lords": lord_snapshots,
		"road_graph_nodes": _road_graph_points.size()
	}


func force_player_sighting_for_debug(world_position: Vector2, confidence: float = LORD_DIRECT_SIGHT_CONFIDENCE) -> void:
	for index in range(_lord_parties.size()):
		var lord := _ensure_lord_ai_state(_lord_parties[index])
		if not _is_hostile_lord(lord):
			continue
		lord = _set_lord_knowledge(lord, world_position, confidence, "debug sighting")
		lord["next_plan_minute"] = 0
		_lord_parties[index] = lord
	queue_redraw()


func seed_nemesis_for_debug(world_position: Vector2) -> Dictionary:
	var best_index := -1
	var best_distance := INF
	for index in range(_lord_parties.size()):
		var lord := _ensure_lord_ai_state(_lord_parties[index])
		if not _is_hostile_lord(lord):
			continue
		var distance := Vector2(lord.get("pos", Vector2.ZERO)).distance_to(world_position)
		if distance < best_distance:
			best_distance = distance
			best_index = index

	if best_index < 0:
		return {}

	var lord := _ensure_lord_ai_state(_lord_parties[best_index])
	var lord_name := String(lord.get("name", ""))
	GameState.record_lord_history_event(lord_name, "sighting", {"text": "Debug nemesis seed: a remembered sighting.", "position": world_position})
	GameState.record_lord_history_event(lord_name, "safe_escape", {"text": "Debug nemesis seed: the player band escaped once.", "position": world_position})
	GameState.record_lord_history_event(lord_name, "defeated_by_player", {"text": "Debug nemesis seed: the player band humiliated this lord.", "position": world_position})
	lord = _set_lord_knowledge(lord, world_position, LORD_DIRECT_SIGHT_CONFIDENCE, "debug nemesis")
	lord["next_plan_minute"] = 0
	_lord_parties[best_index] = lord
	queue_redraw()
	return GameState.get_lord_history(lord_name)


func _debug_replace_lord_parties_for_sim(lords: Array) -> void:
	_lord_parties.clear()
	for raw_lord in lords:
		if not (raw_lord is Dictionary):
			continue
		var lord := Dictionary(raw_lord).duplicate(true)
		var position := Vector2(lord.get("pos", lord.get("start", Vector2.ZERO)))
		var fallback := Vector2(lord.get("start", position))
		lord["pos"] = constrain_land_position(position, fallback)
		if not lord.has("route"):
			lord["route"] = [lord["pos"]]
		if not lord.has("route_index"):
			lord["route_index"] = 0
		lord = _ensure_lord_ai_state(lord)
		lord["hold_minutes"] = maxf(0.0, float(lord.get("hold_minutes", 0.0)))
		lord["waiting_at"] = String(lord.get("waiting_at", ""))
		lord["next_plan_minute"] = int(lord.get("next_plan_minute", 0))
		_lord_parties.append(lord)
	queue_redraw()


func break_player_trail_at(world_position: Vector2, reason: String = "hiding") -> void:
	var current_minute := GameState.get_game_total_minutes()
	var director := _overworld_ai_director()
	director["pressure_relief_until_minute"] = current_minute + OVERWORLD_AI_RELIEF_AFTER_ESCAPE_MINUTES
	GameState.map_state["overworld_ai"] = director
	for index in range(_lord_parties.size()):
		var lord := _ensure_lord_ai_state(_lord_parties[index])
		if not _is_hostile_lord(lord):
			_lord_parties[index] = lord
			continue
		var knowledge := _lord_local_knowledge(lord)
		var confidence := maxf(0.0, float(knowledge.get("confidence", 0.0)) - LORD_SAFE_PLACE_CONFIDENCE_LOSS * 1.6)
		knowledge["confidence"] = confidence
		knowledge["source"] = reason
		lord["local_knowledge"] = knowledge
		if String(lord.get("state", "")) == "pursuing":
			lord = _remember_lord_event(lord, "safe_escape", "The player band vanished into refuge: %s." % reason, world_position)
			GameState.clear_lord_pursuit_state(String(lord.get("name", "")))
			lord["state"] = "search" if confidence >= LORD_SEARCH_CONFIDENCE_MIN else "recover"
			lord["next_plan_minute"] = 0
		_lord_parties[index] = lord
	queue_redraw()


func get_recruitable_settlement_names() -> Array[String]:
	var names: Array[String] = []
	for settlement in _settlements_for_gameplay():
		var name := String(settlement.get("name", ""))
		if GameState.can_recruit_from_settlement(name):
			names.append(name)
	return names


func get_lord_save_data() -> Array:
	var save_data: Array = []
	for lord in _lord_parties:
		var lord_name := String(lord.get("name", ""))
		if GameState.is_lord_defeated(lord_name):
			continue
		save_data.append({
			"name": lord_name,
			"map_projection_id": _active_map_projection_id(),
			"pos": lord.get("pos", Vector2.ZERO),
			"route_index": int(lord.get("route_index", 1)),
			"party_size": int(lord.get("party_size", 0)),
			"intelligence": int(lord.get("intelligence", 0)),
			"hold_minutes": float(lord.get("hold_minutes", 0.0)),
			"waiting_at": String(lord.get("waiting_at", "")),
			"role": String(lord.get("role", _default_lord_role(lord))),
			"state": String(lord.get("state", "patrol")),
			"task": _lord_task_data(lord),
			"standing_order": String(lord.get("standing_order", _lord_task_type(lord))),
			"supplies": float(lord.get("supplies", 100.0)),
			"morale": float(lord.get("morale", 65.0)),
			"fatigue": float(lord.get("fatigue", 0.0)),
			"boldness": float(lord.get("boldness", 50.0)),
			"caution": float(lord.get("caution", 50.0)),
			"ambition": float(lord.get("ambition", 50.0)),
			"loyalty": float(lord.get("loyalty", 50.0)),
			"local_knowledge": _lord_local_knowledge(lord),
			"last_player_sighting": _lord_local_knowledge(lord),
			"memory": Array(lord.get("memory", [])).duplicate(true),
			"next_plan_minute": int(lord.get("next_plan_minute", GameState.get_game_total_minutes())),
			"recovery_until_minute": int(lord.get("recovery_until_minute", 0))
		})
	return save_data


func get_nearest_settlement(world_position: Vector2, radius: float = 95.0) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := radius
	for settlement in _settlements_for_gameplay():
		var settlement_position := _map_position_from_entry(settlement)
		var distance := world_position.distance_to(settlement_position)
		if distance <= best_distance:
			best = _target_from_entry(settlement, "settlement")
			best_distance = distance
	return best


func get_hovered_location(world_position: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF

	for settlement in _settlements_for_gameplay():
		var settlement_position := _map_position_from_entry(settlement)
		var distance := world_position.distance_to(settlement_position)
		if distance <= _settlement_hover_radius(settlement) and distance < best_distance:
			best = _settlement_target_with_lord_presence(settlement)
			best_distance = distance

	return best


func get_click_target(world_position: Vector2, radius: float = 42.0) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := radius

	for lord in _lord_parties:
		if _is_lord_absorbed(lord):
			continue
		var lord_position: Vector2 = lord["pos"]
		var lord_distance := world_position.distance_to(lord_position)
		if lord_distance <= best_distance:
			best = _target_from_lord(lord)
			best_distance = lord_distance

	for party in NPC_PARTIES:
		var party_position := _scaled_point(party["pos"])
		var party_distance := world_position.distance_to(party_position)
		if party_distance <= best_distance:
			best = _target_from_entry(party, "npc")
			best_distance = party_distance

	for settlement in _settlements_for_gameplay():
		var settlement_position := _map_position_from_entry(settlement)
		var settlement_distance := world_position.distance_to(settlement_position)
		if settlement_distance <= best_distance:
			best = _target_from_entry(settlement, "settlement")
			best_distance = settlement_distance

	return best


func get_lord_target(lord_name: String) -> Dictionary:
	for lord in _lord_parties:
		if String(lord.get("name", "")) == lord_name:
			if _is_lord_absorbed(lord):
				return {}
			return _target_from_lord(lord)
	return {}


func _settlement_target_with_lord_presence(settlement: Dictionary) -> Dictionary:
	var target := _target_from_entry(settlement, "settlement")
	var absorbed_lords := _absorbed_lords_at_settlement(String(target.get("name", "")))
	if not absorbed_lords.is_empty():
		target["contained_lords"] = absorbed_lords
		target["grouped_lords"] = absorbed_lords
		target["group_count"] = absorbed_lords.size()
	return target


func _absorbed_lords_at_settlement(settlement_name: String) -> Array[Dictionary]:
	var absorbed_lords: Array[Dictionary] = []
	if settlement_name.is_empty():
		return absorbed_lords
	for lord in _lord_parties:
		if not (lord is Dictionary):
			continue
		var lord_dict := Dictionary(lord)
		var absorption := _lord_absorption_info(lord_dict)
		if String(absorption.get("kind", "")) != "settlement":
			continue
		if String(absorption.get("name", "")) != settlement_name:
			continue
		absorbed_lords.append(_lord_presence_summary(lord_dict))
	absorbed_lords.sort_custom(Callable(self, "_compare_lord_presence_name"))
	return absorbed_lords


func _is_lord_absorbed(lord: Dictionary) -> bool:
	return not _lord_absorption_info(lord).is_empty()


func _lord_absorption_info(lord: Dictionary) -> Dictionary:
	var lord_name := String(lord.get("name", ""))
	if lord_name.is_empty() or GameState.is_lord_defeated(lord_name):
		return {}

	var lord_position := Vector2(lord.get("pos", Vector2.ZERO))
	var waiting_at := String(lord.get("waiting_at", "")).strip_edges()
	var hold_minutes := float(lord.get("hold_minutes", 0.0))
	if hold_minutes > 0.0 and not waiting_at.is_empty():
		var settlement_position := _position_for_named_settlement(waiting_at, Vector2.INF)
		if settlement_position != Vector2.INF and lord_position.distance_to(settlement_position) <= LORD_ABSORBED_TOWN_RADIUS:
			return {
				"kind": "settlement",
				"name": waiting_at,
				"pos": settlement_position
			}
		var nearby_settlement := get_nearest_settlement(lord_position, LORD_ABSORBED_TOWN_RADIUS)
		if not nearby_settlement.is_empty():
			return {
				"kind": "settlement",
				"name": String(nearby_settlement.get("name", "")),
				"pos": Vector2(nearby_settlement.get("pos", lord_position))
			}

	return {}


func _lord_presence_summary(lord: Dictionary) -> Dictionary:
	return {
		"lord_id": String(lord.get("name", "")),
		"name": String(lord.get("name", "Unknown lord")),
		"title": String(lord.get("title", "lord")),
		"faction": String(lord.get("faction", "")),
		"party_size": int(lord.get("party_size", 0)),
		"state": String(lord.get("state", "")),
		"task_type": _lord_task_type(lord),
		"waiting_at": String(lord.get("waiting_at", ""))
	}


func _compare_lord_presence_name(left, right) -> bool:
	return String(Dictionary(left).get("name", "")) < String(Dictionary(right).get("name", ""))


func get_lord_combat_reinforcements(target_lord: Dictionary) -> Array[Dictionary]:
	var reinforcements: Array[Dictionary] = []
	if not _is_hostile_lord(target_lord):
		return reinforcements

	var target_name := String(target_lord.get("lord_id", target_lord.get("name", "")))
	var target_position := Vector2(target_lord.get("pos", Vector2.INF))
	if target_position == Vector2.INF:
		return reinforcements

	for lord in _lord_parties:
		var lord_name := String(lord.get("name", ""))
		if lord_name == target_name or GameState.is_lord_defeated(lord_name):
			continue
		if not _lord_can_join_common_enemy_fight(lord, target_lord):
			continue
		var lord_position := Vector2(lord.get("pos", Vector2.ZERO))
		var distance := lord_position.distance_to(target_position)
		if distance > LORD_COMBAT_REINFORCE_RADIUS:
			continue
		reinforcements.append({
			"lord_id": lord_name,
			"name": lord_name,
			"title": String(lord.get("title", "ally")),
			"faction": String(lord.get("faction", "")),
			"party_size": int(lord.get("party_size", 0)),
			"distance": distance,
			"direction": _direction_text(lord_position - target_position)
		})

	reinforcements.sort_custom(Callable(self, "_compare_reinforcement_distance"))
	if reinforcements.size() > LORD_COMBAT_REINFORCE_LIMIT:
		reinforcements = reinforcements.slice(0, LORD_COMBAT_REINFORCE_LIMIT)
	return reinforcements


func get_enemy_lord_combat_reinforcements(target_lord: Dictionary) -> Array[Dictionary]:
	var reinforcements: Array[Dictionary] = []
	if not _is_hostile_lord(target_lord):
		return reinforcements

	var target_name := String(target_lord.get("lord_id", target_lord.get("name", "")))
	var target_position := Vector2(target_lord.get("pos", Vector2.INF))
	if target_position == Vector2.INF:
		for lord in _lord_parties:
			if String(lord.get("name", "")) == target_name:
				target_position = Vector2(lord.get("pos", Vector2.INF))
				break
	if target_position == Vector2.INF:
		return reinforcements

	for lord in _lord_parties:
		var lord_name := String(lord.get("name", ""))
		if lord_name == target_name or GameState.is_lord_defeated(lord_name):
			continue
		if not _lords_can_group_for_hunt(target_lord, lord):
			continue
		var lord_position := Vector2(lord.get("pos", Vector2.ZERO))
		var distance := lord_position.distance_to(target_position)
		if distance > LORD_COMBAT_REINFORCE_RADIUS:
			continue
		reinforcements.append({
			"lord_id": lord_name,
			"name": lord_name,
			"title": String(lord.get("title", "lord")),
			"faction": String(lord.get("faction", "")),
			"party_size": int(lord.get("party_size", 0)),
			"distance": distance,
			"direction": _direction_text(lord_position - target_position)
		})

	reinforcements.sort_custom(Callable(self, "_compare_reinforcement_distance"))
	if reinforcements.size() > LORD_COMBAT_REINFORCE_LIMIT:
		reinforcements = reinforcements.slice(0, LORD_COMBAT_REINFORCE_LIMIT)
	return reinforcements


func _compare_reinforcement_distance(left, right) -> bool:
	return float(Dictionary(left).get("distance", INF)) < float(Dictionary(right).get("distance", INF))


func _draw() -> void:
	_draw_base()
	_draw_terrain()
	_draw_blocked_water_overlay()
	_draw_roads()
	_draw_threat_circles()
	_draw_chokepoints()
	_draw_settlements()
	_draw_lord_parties()
	_draw_npc_parties()
	_draw_frame()


func _draw_base() -> void:
	draw_rect(MAP_RECT.grow(260.0), Color("#d9c59a"))

	if _painted_map_plate != null:
		draw_texture_rect(_painted_map_plate, MAP_RECT, false)
		return

	if _data_loaded and not _land_features.is_empty():
		for feature in _land_features:
			var feature_dict := Dictionary(feature)
			var properties := Dictionary(feature_dict.get("properties", {}))
			var kind := String(properties.get("kind", ""))
			if kind == "sea_context":
				_draw_feature_polygons(feature_dict, Color("#486f88"), Color("#35566c"), 2.0)
				_draw_sea_texture(feature_dict)
		for feature in _land_features:
			var feature_dict := Dictionary(feature)
			var properties := Dictionary(feature_dict.get("properties", {}))
			var kind := String(properties.get("kind", ""))
			if kind == "land":
				_draw_feature_polygons(feature_dict, Color("#bda676"), Color("#6d5737"), 3.0)
				_draw_coast_shading(feature_dict)
	else:
		draw_colored_polygon(_scaled_points(great_sea), Color("#486f88"))
		draw_colored_polygon(_scaled_points(land_polygon), Color("#bda676"))
		_draw_polygon_outline(_scaled_points(land_polygon), Color("#6d5737"), 4.0)

	_draw_paper_grain()


func _draw_terrain() -> void:
	if _painted_map_plate != null:
		_draw_water_labels()
		return

	if _data_loaded:
		_draw_biome_features()
		_draw_relief_features()
		_draw_water_features()
		return

	var hill_color := Color("#8f7e58")
	var ridge_color := Color("#69553a")
	var wilderness := Color("#a18661")

	draw_colored_polygon(_scaled_points(PackedVector2Array([
		Vector2(-70, -695), Vector2(245, -665), Vector2(340, -275),
		Vector2(220, 180), Vector2(30, 320), Vector2(-120, 25)
	])), Color("#a99368"))

	draw_colored_polygon(_scaled_points(PackedVector2Array([
		Vector2(-45, 180), Vector2(250, 230), Vector2(430, 635),
		Vector2(320, 1005), Vector2(10, 1008), Vector2(-120, 635)
	])), wilderness)

	draw_colored_polygon(_scaled_points(PackedVector2Array([
		Vector2(-610, 45), Vector2(-320, -20), Vector2(-180, 620),
		Vector2(-330, 1015), Vector2(-585, 870)
	])), Color("#c1aa72"))

	var ridge_points := [
		[Vector2(118, -640), Vector2(188, -450), Vector2(115, -270), Vector2(166, -65), Vector2(97, 145), Vector2(132, 320)],
		[Vector2(30, 240), Vector2(75, 435), Vector2(5, 610), Vector2(65, 820), Vector2(22, 1010)],
		[Vector2(-430, 170), Vector2(-310, 265), Vector2(-262, 420), Vector2(-175, 560), Vector2(-260, 775)]
	]
	for ridge in ridge_points:
		var scaled_ridge := _scaled_points(PackedVector2Array(ridge))
		draw_polyline(scaled_ridge, ridge_color, 5.0, true)
		draw_polyline(scaled_ridge, hill_color, 2.0, true)

	_draw_region_label("Ephraim", _scaled_point(Vector2(35, -690)))
	_draw_region_label("Benjamin", _scaled_point(Vector2(130, -190)))
	_draw_region_label("Judah", _scaled_point(Vector2(45, 505)))
	_draw_region_label("Philistine Plain", _scaled_point(Vector2(-462, 345)))
	_draw_region_label("Wilderness", _scaled_point(Vector2(330, 825)))
	_draw_region_label("Great Sea", _scaled_point(Vector2(-825, 50)), Color("#dbe8e8"))


func _draw_roads() -> void:
	if _data_loaded and not _route_features.is_empty():
		for feature in _route_features:
			var feature_dict := Dictionary(feature)
			var geometry := Dictionary(feature_dict.get("geometry", {}))
			var route_lines := _geometry_to_lines(geometry)
			for line in route_lines:
				draw_polyline(line, Color(0.28, 0.18, 0.10, 0.38), 9.0, true)
				draw_polyline(line, Color("#d8c083"), 4.0, true)
		return

	for road in ROADS:
		var points := _scaled_points(PackedVector2Array(road))
		draw_polyline(points, Color(0.28, 0.18, 0.10, 0.38), 9.0, true)
		draw_polyline(points, Color("#d8c083"), 4.0, true)


func _draw_settlements() -> void:
	var s := _ui_scale()
	for settlement in _settlements_for_gameplay():
		var pos := _map_position_from_entry(settlement)
		var fill := _settlement_owner_color(settlement)
		var ring := Color("#f3dfaa")
		var marker_scale := _settlement_marker_scale(settlement)
		var marker_radius := 5.0 * s * marker_scale

		draw_circle(pos + Vector2(3.0 * s, 4.0 * s), 12.0 * s * marker_scale, Color(0.07, 0.04, 0.02, 0.35))
		draw_circle(pos, 9.5 * s * marker_scale, Color("#5a361e"))
		draw_circle(pos, 7.4 * s * marker_scale, ring)
		draw_circle(pos, marker_radius, fill)
		draw_circle(pos + Vector2(-2.0 * s * marker_scale, -2.0 * s * marker_scale), 2.0 * s * marker_scale, fill.lightened(0.55))
		var absorbed_lord_count := _absorbed_lords_at_settlement(String(settlement.get("name", ""))).size()
		if absorbed_lord_count > 0:
			_draw_lord_presence_badge(pos + Vector2(13.0 * s * marker_scale, -13.0 * s * marker_scale), absorbed_lord_count, s)

		if _font and _should_draw_settlement_label(settlement):
			var font_size := _settlement_label_size(settlement) * s
			var label_position := pos + _settlement_label_offset(settlement) * s
			_draw_halo_label(
				String(settlement["name"]),
				label_position,
				font_size,
				Color("#2b1d12"),
				Color(0.96, 0.88, 0.68, 0.92),
				Color(0.05, 0.03, 0.015, 0.38),
				HORIZONTAL_ALIGNMENT_LEFT,
				220.0 * s
			)


func _draw_npc_parties() -> void:
	for party in NPC_PARTIES:
		var pos := _scaled_point(party["pos"])
		var distance := pos.distance_to(player_position)
		if distance > _effective_npc_render_radius():
			continue
		var alpha := _npc_distance_alpha(distance)

		var shadow_color := Color(0.07, 0.04, 0.02, 0.30 * alpha)
		var ring_color := Color("#efe0a6")
		ring_color.a = alpha
		var fill_color := Color("#3c7c45")
		fill_color.a = alpha
		var highlight_color := Color("#f7edc8")
		highlight_color.a = alpha

		draw_circle(pos + Vector2(4.0, 5.0), 13.0, shadow_color)
		draw_circle(pos, 11.0, ring_color)
		draw_circle(pos, 7.0, fill_color)
		draw_circle(pos + Vector2(3.0, -3.0), 3.0, highlight_color)

		if _font:
			var label_color := Color("#2b1d12")
			label_color.a = alpha
			_draw_halo_label(
				String(party["name"]),
				pos + Vector2(15.0, -10.0),
				17.0,
				label_color,
				Color(0.96, 0.88, 0.68, 0.70 * alpha),
				Color(0.05, 0.03, 0.015, 0.30 * alpha),
				HORIZONTAL_ALIGNMENT_LEFT,
				190.0
			)


func _draw_lord_parties() -> void:
	for lord in _lord_parties:
		if _is_lord_absorbed(lord):
			continue
		var pos: Vector2 = lord["pos"]
		var distance := pos.distance_to(player_position)
		if distance > _effective_npc_render_radius():
			continue
		var alpha := _npc_distance_alpha(distance)
		var faction_color := Color(String(lord.get("color", "#704c2f")))
		faction_color.a = alpha
		var is_pursuing := _is_lord_pursuing(lord)
		var diamond := PackedVector2Array([
			pos + Vector2(0.0, -16.0),
			pos + Vector2(14.0, 0.0),
			pos + Vector2(0.0, 16.0),
			pos + Vector2(-14.0, 0.0)
		])

		var shadow_color := Color(0.06, 0.035, 0.02, 0.34 * alpha)
		var fill_color := Color("#f0dda4")
		fill_color.a = alpha
		var outline_color := Color("#b12824") if is_pursuing else Color("#51351e")
		outline_color.a = alpha
		var highlight_color := Color("#fff2be")
		highlight_color.a = alpha

		draw_circle(pos + Vector2(4.0, 6.0), 17.0, shadow_color)
		draw_colored_polygon(diamond, fill_color)
		draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), outline_color, 3.0 if is_pursuing else 2.0, true)
		draw_circle(pos, 8.0, faction_color)
		draw_circle(pos + Vector2(3.0, -4.0), 3.0, highlight_color)

		if _font:
			var label := "%s (%d)" % [String(lord["name"]), int(lord["party_size"])]
			var label_color := Color("#2b1d12")
			label_color.a = alpha
			_draw_halo_label(
				label,
				pos + Vector2(18.0, -13.0),
				17.0,
				label_color,
				Color(0.96, 0.88, 0.68, 0.76 * alpha),
				Color(0.05, 0.03, 0.015, 0.32 * alpha),
				HORIZONTAL_ALIGNMENT_LEFT,
				260.0
			)


func _draw_lord_presence_badge(position: Vector2, count: int, scale: float = 1.0, alpha: float = 1.0) -> void:
	if count <= 0:
		return
	var radius := 9.0 * scale
	var shadow := Color(0.05, 0.025, 0.01, 0.34 * alpha)
	var fill := Color("#f1d48a")
	fill.a = alpha
	var edge := Color("#53351c")
	edge.a = alpha
	draw_circle(position + Vector2(1.8 * scale, 2.4 * scale), radius + 1.0 * scale, shadow)
	draw_circle(position, radius, fill)
	draw_arc(position, radius, 0.0, TAU, 24, edge, 1.8 * scale, true)
	if _font:
		var label := str(count)
		var font_size := int(round(12.0 * scale))
		var text_size := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
		var text_position := position - Vector2(text_size.x * 0.5, -text_size.y * 0.32)
		var text_color := Color("#2b1d12")
		text_color.a = alpha
		draw_string(_font, text_position, label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, text_color)


func _draw_frame() -> void:
	draw_rect(MAP_RECT, Color("#5c4328"), false, 10.0)
	draw_rect(MAP_RECT.grow(-18.0), Color(0.22, 0.13, 0.06, 0.28), false, 2.0)


func _draw_threat_circles() -> void:
	for lord in _lord_parties:
		if _is_lord_absorbed(lord):
			continue
		if not _is_hostile_lord(lord):
			continue
		var pos: Vector2 = lord["pos"]
		var detection_radius := _lord_detection_radius(lord)
		var state := String(lord.get("state", "patrol"))
		var fill := Color(0.72, 0.24, 0.08, 0.045)
		var edge := Color(0.72, 0.24, 0.08, 0.18)
		var line_width := 2.0
		if state == "search":
			fill = Color(0.90, 0.45, 0.08, 0.07)
			edge = Color(0.90, 0.45, 0.08, 0.34)
			line_width = 3.0
		elif _is_lord_pursuing(lord):
			fill = Color(0.95, 0.08, 0.04, 0.14)
			edge = Color(0.95, 0.08, 0.04, 0.58)
			line_width = 4.0
		draw_circle(pos, detection_radius, fill)
		draw_arc(pos, detection_radius, 0.0, TAU, 96, edge, line_width, true)


func _draw_biome_features() -> void:
	for feature in _features_sorted_by_render_priority(_biome_features):
		var feature_dict := Dictionary(feature)
		var properties := Dictionary(feature_dict.get("properties", {}))
		var biome_id := int(properties.get("biome_id", 0))
		var fill := _biome_color(biome_id)
		_draw_feature_polygons(feature_dict, fill, Color.TRANSPARENT, 0.0)
		_draw_biome_soft_edge(feature_dict, biome_id)
		_draw_biome_texture(feature_dict, biome_id)


func _draw_relief_features() -> void:
	for feature in _relief_features:
		var feature_dict := Dictionary(feature)
		var properties := Dictionary(feature_dict.get("properties", {}))
		var geometry := Dictionary(feature_dict.get("geometry", {}))
		var kind := String(properties.get("kind", ""))
		if kind == "ridge_line":
			for line in _geometry_to_lines(geometry):
				draw_polyline(line, Color(0.24, 0.17, 0.10, 0.50), 8.0, true)
				draw_polyline(line, Color(0.80, 0.70, 0.50, 0.45), 3.0, true)
				_draw_mountain_marks_on_line(line)
		else:
			var shade_rank := int(properties.get("shade_rank", 1))
			var fill := Color(0.18, 0.13, 0.08, clampf(float(shade_rank) * 0.028, 0.02, 0.13))
			_draw_feature_polygons(feature_dict, fill, Color(0.20, 0.14, 0.08, 0.06), 1.0)
			_draw_relief_hachures(feature_dict, shade_rank, kind)


func _draw_sea_texture(feature: Dictionary) -> void:
	for polygon in _geometry_to_polygons(Dictionary(feature.get("geometry", {}))):
		if polygon.size() < 3:
			continue

		var bounds := _polygon_bounds(polygon)
		var wave_color := Color(0.74, 0.86, 0.88, 0.10)
		var y := bounds.position.y + 160.0
		while y < bounds.end.y:
			var x := bounds.position.x + 120.0
			while x < bounds.end.x:
				var start := Vector2(x, y)
				if _point_in_polygon(start, polygon):
					draw_arc(start, 42.0, PI * 0.08, PI * 0.92, 12, wave_color, 2.0, true)
				x += 330.0
			y += 260.0


func _draw_coast_shading(feature: Dictionary) -> void:
	var coast_color := Color(0.96, 0.86, 0.58, 0.18)
	var shadow_color := Color(0.18, 0.11, 0.06, 0.20)
	for polygon in _geometry_to_polygons(Dictionary(feature.get("geometry", {}))):
		if polygon.size() < 3:
			continue
		var closed := PackedVector2Array(polygon)
		closed.append(polygon[0])
		draw_polyline(closed, shadow_color, 16.0, true)
		draw_polyline(closed, coast_color, 7.0, true)


func _draw_paper_grain() -> void:
	var line_color := Color(0.42, 0.30, 0.16, 0.045)
	for i in range(11):
		var y := MAP_RECT.position.y + float(i) * 250.0 * MAP_SCALE
		draw_line(
			Vector2(MAP_RECT.position.x - 180.0 * MAP_SCALE, y),
			Vector2(MAP_RECT.end.x + 180.0 * MAP_SCALE, y + 64.0 * MAP_SCALE),
			line_color,
			2.0
		)

	var fleck_color := Color(0.30, 0.20, 0.10, 0.055)
	var x := MAP_RECT.position.x + 160.0
	while x < MAP_RECT.end.x:
		var y := MAP_RECT.position.y + 140.0
		while y < MAP_RECT.end.y:
			var jitter := _stable_jitter(Vector2(x, y), 38.0)
			draw_circle(Vector2(x, y) + jitter, 2.0, fleck_color)
			y += 520.0
		x += 480.0


func _draw_relief_hachures(feature: Dictionary, shade_rank: int, kind: String) -> void:
	if shade_rank <= 0:
		if kind == "elevation_zone":
			_draw_rift_floor_lines(feature)
		return

	var alpha := clampf(0.035 + float(shade_rank) * 0.028, 0.04, 0.16)
	var color := Color(0.23, 0.16, 0.09, alpha)
	var spacing := 330.0 - float(shade_rank) * 36.0
	var length := 34.0 + float(shade_rank) * 8.0
	for polygon in _geometry_to_polygons(Dictionary(feature.get("geometry", {}))):
		if polygon.size() < 3:
			continue
		var bounds := _polygon_bounds(polygon)
		var y := bounds.position.y + spacing * 0.45
		while y < bounds.end.y:
			var x := bounds.position.x + spacing * 0.35
			while x < bounds.end.x:
				var center := Vector2(x, y) + _stable_jitter(Vector2(x, y), 26.0)
				if _point_in_polygon(center, polygon):
					var tilt := Vector2(0.42, 1.0).normalized()
					draw_line(center - tilt * length * 0.45, center + tilt * length * 0.45, color, 2.0)
				x += spacing
			y += spacing


func _draw_rift_floor_lines(feature: Dictionary) -> void:
	var color := Color(0.18, 0.30, 0.30, 0.12)
	for polygon in _geometry_to_polygons(Dictionary(feature.get("geometry", {}))):
		if polygon.size() < 3:
			continue
		var bounds := _polygon_bounds(polygon)
		var x := bounds.position.x + 90.0
		while x < bounds.end.x:
			var y := bounds.position.y + 120.0
			var line := PackedVector2Array()
			while y < bounds.end.y:
				var point := Vector2(x + sin(y * 0.008) * 16.0, y)
				if _point_in_polygon(point, polygon):
					line.append(point)
				y += 95.0
			if line.size() > 1:
				draw_polyline(line, color, 2.0, true)
			x += 160.0


func _draw_biome_texture(feature: Dictionary, biome_id: int) -> void:
	for polygon in _geometry_to_polygons(Dictionary(feature.get("geometry", {}))):
		if polygon.size() < 3:
			continue

		var bounds := _polygon_bounds(polygon)
		var spacing := 230.0
		var y := bounds.position.y + 105.0
		while y < bounds.end.y:
			var x := bounds.position.x + 85.0
			while x < bounds.end.x:
				var point := Vector2(x, y)
				if _point_in_polygon(point, polygon):
					_draw_biome_mark(point, biome_id)
				x += spacing
			y += spacing


func _draw_biome_soft_edge(feature: Dictionary, biome_id: int) -> void:
	var edge_color := _biome_color(biome_id).lightened(0.08)
	for polygon in _geometry_to_polygons(Dictionary(feature.get("geometry", {}))):
		if polygon.size() < 3:
			continue
		var closed := PackedVector2Array(polygon)
		closed.append(polygon[0])
		edge_color.a = 0.10
		draw_polyline(closed, edge_color, 72.0, true)
		edge_color.a = 0.14
		draw_polyline(closed, edge_color.lightened(0.10), 28.0, true)
		_draw_biome_border_texture(closed, biome_id)


func _draw_biome_border_texture(closed_polygon: PackedVector2Array, biome_id: int) -> void:
	if closed_polygon.size() < 2:
		return

	var color := _biome_color(biome_id).darkened(0.22)
	color.a = 0.18
	for index in range(closed_polygon.size() - 1):
		var start := closed_polygon[index]
		var end := closed_polygon[index + 1]
		var segment := end - start
		var distance := segment.length()
		if distance < 120.0:
			continue
		var normal := Vector2(-segment.y, segment.x).normalized()
		var count := int(distance / 220.0)
		for mark_index in range(count):
			var t := (float(mark_index) + 0.5) / float(count)
			var center := start.lerp(end, t) + normal * (12.0 if mark_index % 2 == 0 else -12.0)
			match biome_id:
				1, 5:
					draw_line(center + normal * -16.0, center + normal * 16.0, color, 2.0)
				3, 4, 6:
					_draw_mountain_mark(center, 22.0, color)
				_:
					draw_arc(center, 18.0, PI * 0.12, PI * 0.72, 6, color, 2.0, true)


func _draw_biome_mark(point: Vector2, biome_id: int) -> void:
	match biome_id:
		1:
			draw_line(point + Vector2(-18.0, 6.0), point + Vector2(18.0, -6.0), Color(0.36, 0.46, 0.25, 0.16), 2.0)
		2:
			draw_arc(point, 30.0, PI * 0.10, PI * 0.90, 10, Color(0.36, 0.27, 0.16, 0.16), 2.0, true)
		3:
			_draw_mountain_mark(point, 34.0, Color(0.31, 0.25, 0.17, 0.24))
		4:
			_draw_mountain_mark(point, 30.0, Color(0.24, 0.34, 0.19, 0.22))
		5:
			draw_line(point + Vector2(-8.0, -30.0), point + Vector2(10.0, 30.0), Color(0.20, 0.37, 0.41, 0.18), 3.0)
		6:
			_draw_mountain_mark(point, 28.0, Color(0.31, 0.23, 0.14, 0.20))
		7:
			draw_arc(point, 25.0, PI * 0.08, PI * 0.52, 8, Color(0.54, 0.37, 0.18, 0.16), 2.0, true)


func _draw_mountain_marks_on_line(line: PackedVector2Array) -> void:
	if line.size() < 2:
		return

	for index in range(line.size() - 1):
		var start := line[index]
		var end := line[index + 1]
		var segment := end - start
		var distance := segment.length()
		if distance < 80.0:
			continue
		var count := maxi(1, int(distance / 210.0))
		for mark_index in range(count):
			var t := (float(mark_index) + 0.5) / float(count)
			_draw_mountain_mark(start.lerp(end, t), 42.0, Color(0.25, 0.18, 0.10, 0.45))


func _draw_mountain_mark(center: Vector2, size: float, color: Color) -> void:
	var half := size * 0.5
	var peak := center + Vector2(0.0, -half)
	var left := center + Vector2(-half, half * 0.72)
	var right := center + Vector2(half, half * 0.72)
	var ridge := center + Vector2(0.0, -half * 0.12)
	draw_polyline(PackedVector2Array([left, peak, right]), color, 3.0, true)
	draw_line(peak, ridge, color.lightened(0.40), 2.0)


func _draw_water_features() -> void:
	for feature in _water_features:
		var feature_dict := Dictionary(feature)
		var properties := Dictionary(feature_dict.get("properties", {}))
		var geometry := Dictionary(feature_dict.get("geometry", {}))
		var geometry_type := String(geometry.get("type", ""))
		var kind := String(properties.get("kind", ""))

		if geometry_type == "Polygon" or geometry_type == "MultiPolygon":
			var fill := Color("#4c7f98")
			if kind == "salt_lake":
				fill = Color("#6d91a1")
			elif kind == "wetland":
				fill = Color("#5b8d73")
			fill.a = 0.88
			_draw_feature_polygons(feature_dict, fill, Color("#315a70"), 2.0)
		elif geometry_type == "LineString" or geometry_type == "MultiLineString":
			var color := Color("#477995")
			if kind.contains("wadi"):
				color = Color("#6f8e91")
			for line in _geometry_to_lines(geometry):
				draw_polyline(line, Color(0.17, 0.28, 0.34, 0.20), 7.0, true)
				draw_polyline(line, color, 3.0, true)
		elif geometry_type == "Point":
			var point := _geo_to_map(Array(geometry.get("coordinates", [])))
			if kind != "sea_label":
				draw_circle(point, 9.0, Color(0.16, 0.28, 0.30, 0.32))
				draw_circle(point, 5.0, Color("#a9d0c1"))

		if properties.get("show_label", false) == true:
			_draw_water_label(feature_dict)


func _draw_water_labels() -> void:
	for feature in _water_features:
		var feature_dict := Dictionary(feature)
		var properties := Dictionary(feature_dict.get("properties", {}))
		if properties.get("show_label", false) == true:
			_draw_water_label(feature_dict)


func _draw_water_label(feature: Dictionary) -> void:
	if _font == null:
		return

	var properties := Dictionary(feature.get("properties", {}))
	var label := String(properties.get("name", ""))
	if label.is_empty():
		return

	var position := _water_label_position(feature)
	if position == Vector2.INF:
		return

	var s := _ui_scale()
	var label_color := Color("#dbe8e8")
	var halo_color := Color(0.04, 0.14, 0.18, 0.72)
	var shadow_color := Color(0.01, 0.05, 0.07, 0.58)
	var label_offset := Vector2(-132.0 * s, -8.0 * s)
	_draw_halo_label(
		label,
		position + label_offset,
		20.0 * s,
		label_color,
		halo_color,
		shadow_color,
		HORIZONTAL_ALIGNMENT_CENTER,
		264.0 * s,
		3.0 * s
	)


func _water_label_position(feature: Dictionary) -> Vector2:
	var properties := Dictionary(feature.get("properties", {}))
	if properties.has("label_coordinates"):
		return _geo_to_map(Array(properties.get("label_coordinates", [])))

	var geometry := Dictionary(feature.get("geometry", {}))
	var geometry_type := String(geometry.get("type", ""))
	if geometry_type == "Point":
		return _geo_to_map(Array(geometry.get("coordinates", [])))
	if geometry_type == "Polygon" or geometry_type == "MultiPolygon":
		return _feature_label_position(feature)
	if geometry_type == "LineString" or geometry_type == "MultiLineString":
		var lines := _geometry_to_lines(geometry)
		if lines.is_empty() or lines[0].is_empty():
			return Vector2.INF
		var sum := Vector2.ZERO
		for point in lines[0]:
			sum += point
		return sum / float(lines[0].size())

	return Vector2.INF


func _draw_blocked_water_overlay() -> void:
	if _blocked_water_polygons.is_empty():
		return

	var fill := Color(0.04, 0.14, 0.18, 0.085)
	var inner_edge := Color(0.88, 0.98, 1.0, 0.16)
	var outer_edge := Color(0.02, 0.08, 0.11, 0.18)

	for polygon in _blocked_water_polygons:
		if polygon.size() < 3:
			continue

		draw_colored_polygon(polygon, fill)

		var closed := PackedVector2Array(polygon)
		closed.append(polygon[0])
		draw_polyline(closed, outer_edge, 7.0, true)
		draw_polyline(closed, inner_edge, 2.0, true)


func _draw_chokepoints() -> void:
	if not _data_loaded:
		return

	var s := _ui_scale()
	for feature in _chokepoint_features:
		var feature_dict := Dictionary(feature)
		var geometry := Dictionary(feature_dict.get("geometry", {}))
		if String(geometry.get("type", "")) != "Point":
			continue
		var pos := _geo_to_map(Array(geometry.get("coordinates", [])))
		var size := 7.0 * s
		var points := PackedVector2Array([
			pos + Vector2(0.0, -size),
			pos + Vector2(size, 0.0),
			pos + Vector2(0.0, size),
			pos + Vector2(-size, 0.0)
		])
		draw_colored_polygon(points, Color("#d6b067"))
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color("#5c3b1f"), 2.0, true)


func _draw_region_label(text: String, position: Vector2, color: Color = Color("#4f3a24")) -> void:
	var s := _ui_scale()
	if _font:
		_draw_halo_label(text, position, 28.0 * s, color, Color(0.96, 0.88, 0.68, 0.70), Color(0.05, 0.03, 0.015, 0.24), HORIZONTAL_ALIGNMENT_CENTER, 260.0 * s)


func _draw_halo_label(
	text: String,
	position: Vector2,
	font_size: float,
	text_color: Color,
	halo_color: Color,
	shadow_color: Color,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
	width: float = -1.0,
	halo_width: float = 2.5
) -> void:
	if _font == null or text.is_empty():
		return

	draw_string(_font, position + Vector2(2.0, 2.0), text, alignment, width, font_size, shadow_color)
	for offset in LABEL_HALO_OFFSETS:
		draw_string(_font, position + offset.normalized() * halo_width, text, alignment, width, font_size, halo_color)
	draw_string(_font, position, text, alignment, width, font_size, text_color)


func _draw_polygon_outline(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 3:
		return
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, color, width, true)


func _draw_feature_polygons(feature: Dictionary, fill: Color, outline: Color, outline_width: float) -> void:
	var geometry := Dictionary(feature.get("geometry", {}))
	for polygon in _geometry_to_polygons(geometry):
		if polygon.size() < 3:
			continue
		draw_colored_polygon(polygon, fill)
		if outline.a > 0.0 and outline_width > 0.0:
			_draw_polygon_outline(polygon, outline, outline_width)


func _geometry_to_polygons(geometry: Dictionary) -> Array[PackedVector2Array]:
	var polygons: Array[PackedVector2Array] = []
	var geometry_type := String(geometry.get("type", ""))
	var coordinates := Array(geometry.get("coordinates", []))

	if geometry_type == "Polygon":
		if not coordinates.is_empty():
			polygons.append(_geo_ring_to_points(Array(coordinates[0])))
	elif geometry_type == "MultiPolygon":
		for polygon in coordinates:
			var rings := Array(polygon)
			if not rings.is_empty():
				polygons.append(_geo_ring_to_points(Array(rings[0])))

	return polygons


func _geometry_to_lines(geometry: Dictionary) -> Array[PackedVector2Array]:
	var lines: Array[PackedVector2Array] = []
	var geometry_type := String(geometry.get("type", ""))
	var coordinates := Array(geometry.get("coordinates", []))

	if geometry_type == "LineString":
		lines.append(_geo_line_to_points(coordinates))
	elif geometry_type == "MultiLineString":
		for line in coordinates:
			lines.append(_geo_line_to_points(Array(line)))

	return lines


func _geo_ring_to_points(ring: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for coordinate in ring:
		points.append(_geo_to_map(Array(coordinate)))
	if points.size() > 1 and points[0].distance_to(points[points.size() - 1]) <= 0.01:
		points.remove_at(points.size() - 1)
	return points


func _geo_line_to_points(line: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for coordinate in line:
		points.append(_geo_to_map(Array(coordinate)))
	return points


func _feature_label_position(feature: Dictionary) -> Vector2:
	var geometry := Dictionary(feature.get("geometry", {}))
	var polygons := _geometry_to_polygons(geometry)
	if polygons.is_empty():
		return Vector2.INF

	var points := polygons[0]
	if points.is_empty():
		return Vector2.INF

	var sum := Vector2.ZERO
	for point in points:
		sum += point
	return sum / float(points.size())


func _features_sorted_by_render_priority(features: Array) -> Array:
	var sorted := features.duplicate()
	sorted.sort_custom(Callable(self, "_compare_feature_render_priority"))
	return sorted


func _compare_feature_render_priority(left, right) -> bool:
	return _feature_render_priority(Dictionary(left)) < _feature_render_priority(Dictionary(right))


func _feature_render_priority(feature: Dictionary) -> int:
	var properties := Dictionary(feature.get("properties", {}))
	return int(properties.get("render_priority", 0))


func _combat_biome_feature_at(position: Vector2) -> Dictionary:
	var best_feature: Dictionary = {}
	var best_priority := -999999
	for raw_feature in _biome_features:
		if not (raw_feature is Dictionary):
			continue

		var feature := Dictionary(raw_feature)
		var priority := _feature_render_priority(feature)
		if priority < best_priority:
			continue

		for polygon in _geometry_to_polygons(Dictionary(feature.get("geometry", {}))):
			if polygon.size() >= 3 and _point_in_polygon(position, polygon):
				best_feature = feature
				best_priority = priority
				break
	return best_feature


func _nearest_combat_biome_feature(position: Vector2) -> Dictionary:
	var best_feature: Dictionary = {}
	var best_distance := INF
	var best_priority := -999999
	for raw_feature in _biome_features:
		if not (raw_feature is Dictionary):
			continue

		var feature := Dictionary(raw_feature)
		var distance := _distance_to_feature_polygons(position, feature)
		var priority := _feature_render_priority(feature)
		if distance < best_distance or (is_equal_approx(distance, best_distance) and priority > best_priority):
			best_feature = feature
			best_distance = distance
			best_priority = priority
	return best_feature


func _distance_to_feature_polygons(position: Vector2, feature: Dictionary) -> float:
	var best_distance := INF
	for polygon in _geometry_to_polygons(Dictionary(feature.get("geometry", {}))):
		if polygon.size() < 3:
			continue
		if _point_in_polygon(position, polygon):
			return 0.0
		best_distance = minf(best_distance, _distance_to_polygon_edges(position, polygon))
	return best_distance


func _combat_relief_context_at(position: Vector2) -> Dictionary:
	var best_context: Dictionary = {}
	var best_rank := -999999
	for raw_feature in _relief_features:
		if not (raw_feature is Dictionary):
			continue

		var feature := Dictionary(raw_feature)
		var properties := Dictionary(feature.get("properties", {}))
		var kind := String(properties.get("kind", ""))
		if kind != "elevation_zone":
			continue

		for polygon in _geometry_to_polygons(Dictionary(feature.get("geometry", {}))):
			if polygon.size() < 3 or not _point_in_polygon(position, polygon):
				continue

			var shade_rank := int(properties.get("shade_rank", 0))
			if shade_rank >= best_rank:
				best_rank = shade_rank
				best_context = {
					"relief_kind": kind,
					"relief_name": String(properties.get("name", "")),
					"relief_shade_rank": shade_rank
				}
	return best_context


func _fallback_combat_map_context(position: Vector2) -> Dictionary:
	return {
		"campaign_position": position,
		"biome_id": 3,
		"biome_key": "biome_central_highlands",
		"biome_name": "Central highlands",
		"biome_properties": {}
	}


func _clamp_to_playable_rect(position: Vector2) -> Vector2:
	var playable_rect := get_playable_rect()
	return Vector2(
		clampf(position.x, playable_rect.position.x, playable_rect.end.x),
		clampf(position.y, playable_rect.position.y, playable_rect.end.y)
	)


func _is_land_travel_position(position: Vector2) -> bool:
	if not get_playable_rect().has_point(position):
		return false

	if _is_settlement_safe_position(position):
		return true

	if not _land_travel_polygons.is_empty():
		var inside_land := false
		for polygon in _land_travel_polygons:
			if _point_in_polygon(position, polygon):
				inside_land = true
				break
		if not inside_land:
			return false

	for polygon in _blocked_water_polygons:
		if _point_in_polygon(position, polygon):
			return false
		if _distance_to_polygon_edges(position, polygon) <= WATER_EDGE_MARGIN:
			return false

	return true


func _is_settlement_safe_position(position: Vector2) -> bool:
	for settlement in _settlement_entries:
		if position.distance_to(_map_position_from_entry(settlement)) <= SETTLEMENT_SAFE_RADIUS:
			return true
	return false


func _nearest_land_position(position: Vector2) -> Vector2:
	for radius in LAND_SEARCH_RADII:
		var best_position := Vector2.INF
		var best_distance := INF

		for direction in LAND_SEARCH_DIRECTIONS:
			var sample := _clamp_to_playable_rect(position + direction.normalized() * float(radius))
			if not _is_land_travel_position(sample):
				continue

			var distance := position.distance_to(sample)
			if distance < best_distance:
				best_distance = distance
				best_position = sample

		if best_position != Vector2.INF:
			return best_position

	return Vector2.INF


func _default_land_position() -> Vector2:
	var settlement_position := _position_for_named_settlement("Jebus", MAP_RECT.get_center())
	if _is_land_travel_position(settlement_position):
		return settlement_position
	return _clamp_to_playable_rect(MAP_RECT.get_center())


func _distance_to_polygon_edges(point: Vector2, polygon: PackedVector2Array) -> float:
	if polygon.size() < 2:
		return INF

	var best_distance := INF
	for index in range(polygon.size()):
		var start := polygon[index]
		var end := polygon[(index + 1) % polygon.size()]
		best_distance = minf(best_distance, _distance_to_segment(point, start, end))
	return best_distance


func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.01:
		return point.distance_to(start)

	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)


func _polygon_bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()

	var min_point := points[0]
	var max_point := points[0]
	for point in points:
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)
	return Rect2(min_point, max_point - min_point)


func _point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	var inside := false
	var previous_index := polygon.size() - 1
	for index in range(polygon.size()):
		var current := polygon[index]
		var previous := polygon[previous_index]
		var crosses_y := (current.y > point.y) != (previous.y > point.y)
		if crosses_y:
			var intersect_x := (previous.x - current.x) * (point.y - current.y) / (previous.y - current.y) + current.x
			if point.x < intersect_x:
				inside = not inside
		previous_index = index
	return inside


func _stable_jitter(point: Vector2, amount: float) -> Vector2:
	var seed := sin(point.x * 12.9898 + point.y * 78.233) * 43758.5453
	var fraction: float = seed - floor(seed)
	var seed_b := sin(point.x * 93.9898 + point.y * 24.233) * 24634.6345
	var fraction_b: float = seed_b - floor(seed_b)
	return Vector2((fraction - 0.5) * amount, (fraction_b - 0.5) * amount)


func _biome_color(biome_id: int) -> Color:
	var color := Color("#bda676")
	match biome_id:
		1:
			color = Color("#cfbd78")
		2:
			color = Color("#b99f68")
		3:
			color = Color("#8f8b66")
		4:
			color = Color("#7fa06d")
		5:
			color = Color("#8fb4a7")
		6:
			color = Color("#a58d62")
		7:
			color = Color("#c8a86e")
	color.a = 0.96
	return color


func _settlement_owner_color(settlement: Dictionary) -> Color:
	var owner := String(settlement.get("owner_faction", "Neutral"))
	if owner.contains("/"):
		owner = owner.strip_edges()
	var color_text := String(FACTION_COLORS.get(owner, FACTION_COLORS.get("Neutral")))
	return Color(color_text)


func _settlement_marker_scale(settlement: Dictionary) -> float:
	var label_tier := String(settlement.get("label_tier", "major"))
	if not settlement.has("label_tier"):
		label_tier = _inferred_settlement_label_tier(settlement)
	if label_tier == "minor":
		return 0.72
	if label_tier == "regional":
		return 0.88
	if label_tier == "capital":
		return 1.20
	return 1.0


func _settlement_hover_radius(settlement: Dictionary) -> float:
	return 6.0 * _ui_scale() * _settlement_marker_scale(settlement)


func _should_draw_settlement_label(settlement: Dictionary) -> bool:
	var label_tier := String(settlement.get("label_tier", "major"))
	if not settlement.has("label_tier"):
		label_tier = _inferred_settlement_label_tier(settlement)
	if label_tier == "minor":
		return camera_zoom >= 0.95
	if label_tier == "regional":
		return camera_zoom >= 0.68
	return true


func _settlement_label_size(settlement: Dictionary) -> float:
	var label_tier := String(settlement.get("label_tier", "major"))
	if not settlement.has("label_tier"):
		label_tier = _inferred_settlement_label_tier(settlement)
	if label_tier == "capital":
		return 21.0
	if label_tier == "minor":
		return 14.5
	if label_tier == "regional":
		return 16.5
	return 18.0


func _settlement_label_offset(settlement: Dictionary) -> Vector2:
	var custom_offset = settlement.get("label_offset", null)
	if custom_offset is Array and Array(custom_offset).size() >= 2:
		var offset_array := Array(custom_offset)
		return Vector2(float(offset_array[0]), float(offset_array[1]))

	var name := String(settlement.get("name", ""))
	match name:
		"Jericho", "En-gedi", "Rabbah", "Dibon", "Bozrah":
			return Vector2(14.0, 18.0)
		"Gaza", "Ashkelon", "Ashdod", "Tyre":
			return Vector2(14.0, -15.0)
		"Jebus", "Bethlehem", "Gibeah", "Ramah", "Nob":
			return Vector2(15.0, -10.0)
	return Vector2(13.0, -9.0)


func _inferred_settlement_label_tier(settlement: Dictionary) -> String:
	var name := String(settlement.get("name", ""))
	var kind := String(settlement.get("kind", ""))
	var density := int(settlement.get("settlement_density", 3))
	if name in ["Jebus", "Hebron", "Gath", "Gaza", "Ashkelon", "Shechem", "Jericho", "Rabbah", "Tyre"]:
		return "capital"
	if density >= 5 or kind.contains("city") or kind.contains("port") or kind.contains("Fortress"):
		return "major"
	if density <= 2 or kind.contains("spring") or kind.contains("oasis"):
		return "minor"
	return "regional"


func _scaled_point(point: Vector2) -> Vector2:
	return point * MAP_SCALE


func _scaled_points(points: PackedVector2Array) -> PackedVector2Array:
	var scaled := PackedVector2Array()
	for point in points:
		scaled.append(_scaled_point(point))
	return scaled


func _load_map_dataset() -> void:
	_map_manifest = _load_json(MAP_MANIFEST_PATH)
	if _map_manifest.is_empty():
		push_warning("Campaign map dataset manifest could not be loaded; using built-in fallback map.")
		return

	var bbox := Array(_map_manifest.get("bbox", _map_bbox))
	if bbox.size() == 4:
		_map_bbox = [float(bbox[0]), float(bbox[1]), float(bbox[2]), float(bbox[3])]

	_load_map_render_calibration()

	var layers := Dictionary(_map_manifest.get("layers", {}))
	_land_features = _load_layer_features(String(layers.get("land_outline", "")))
	_water_features = _load_layer_features(String(layers.get("water", "")))
	_biome_features = _load_layer_features(String(layers.get("biomes", "")))
	_relief_features = _load_layer_features(String(layers.get("relief", "")))
	_settlement_features = _load_layer_features(String(layers.get("settlements", "")))
	_route_features = _load_layer_features(String(layers.get("routes", "")))
	_chokepoint_features = _load_layer_features(String(layers.get("chokepoints", "")))
	_build_land_travel_masks()
	_build_settlement_entries()
	_build_road_graph()

	_data_loaded = not _land_features.is_empty() and not _settlement_entries.is_empty()
	if not _data_loaded:
		push_warning("Campaign map dataset is incomplete; using built-in fallback map.")


func _load_map_render_calibration() -> void:
	_map_render_calibration = {}
	_map_calibration_id = ""
	_map_calibration_points.clear()
	_map_calibration_image_size = Vector2.ZERO
	_map_calibration_softness_px = 140.0
	_map_calibration_power = 1.35

	var calibration := _selected_map_render_calibration()
	if calibration.is_empty():
		return

	_map_render_calibration = calibration
	_map_calibration_id = String(calibration.get("id", ""))

	var image_size := Array(calibration.get("image_size_px", []))
	if image_size.size() < 2:
		return

	_map_calibration_image_size = Vector2(float(image_size[0]), float(image_size[1]))
	if _map_calibration_image_size.x <= 0.0 or _map_calibration_image_size.y <= 0.0:
		_map_calibration_image_size = Vector2.ZERO
		return

	_map_calibration_softness_px = float(calibration.get("softness_px", _map_calibration_softness_px))
	_map_calibration_power = float(calibration.get("power", _map_calibration_power))

	var control_points := Array(calibration.get("control_points", []))
	for point in control_points:
		if not (point is Dictionary):
			continue

		var point_dict := Dictionary(point)
		var coordinates := Array(point_dict.get("coordinates", []))
		var pixel := Array(point_dict.get("pixel", []))
		if coordinates.size() < 2 or pixel.size() < 2:
			continue

		var target_pixel := Vector2(float(pixel[0]), float(pixel[1]))
		var raw_pixel := _geo_to_raw_calibration_pixel(coordinates)
		_map_calibration_points.append({
			"name": String(point_dict.get("name", "")),
			"raw_pixel": raw_pixel,
			"delta_pixel": target_pixel - raw_pixel
		})


func _selected_map_render_calibration() -> Dictionary:
	var calibrations = _map_manifest.get("render_calibrations", [])

	if calibrations is Array:
		for calibration_entry in Array(calibrations):
			if not (calibration_entry is Dictionary):
				continue

			var calibration_dict := Dictionary(calibration_entry)
			if String(calibration_dict.get("asset", "")) == PAINTED_MAP_PLATE_PATH:
				return calibration_dict

	if calibrations is Dictionary:
		for key in Dictionary(calibrations).keys():
			var calibration_entry = Dictionary(calibrations).get(key)
			if not (calibration_entry is Dictionary):
				continue

			var calibration_dict := Dictionary(calibration_entry)
			if String(calibration_dict.get("asset", "")) == PAINTED_MAP_PLATE_PATH:
				return calibration_dict

	return {}


func _active_map_projection_id() -> String:
	if not _map_calibration_id.is_empty():
		return _map_calibration_id
	return FALLBACK_MAP_PROJECTION_ID


func _load_painted_map_plate() -> void:
	if ResourceLoader.exists(PAINTED_MAP_PLATE_PATH, "Texture2D"):
		var imported_texture := load(PAINTED_MAP_PLATE_PATH)
		if imported_texture is Texture2D:
			_painted_map_plate = imported_texture
			return

	var image := Image.load_from_file(PAINTED_MAP_PLATE_PATH)
	if image == null or image.is_empty():
		push_warning("Painted map plate could not be loaded; using data-rendered fallback map.")
		return
	_painted_map_plate = ImageTexture.create_from_image(image)


func _load_layer_features(relative_path: String) -> Array:
	if relative_path.is_empty():
		return []

	var layer := _load_json("%s/%s" % [MAP_DATA_ROOT, relative_path])
	if layer.is_empty():
		return []

	return Array(layer.get("features", []))


func _build_road_graph() -> void:
	_road_graph_points.clear()
	_road_graph_edges.clear()

	for line in _road_lines_for_navigation():
		if line.size() < 2:
			continue
		for index in range(line.size() - 1):
			var from_index := _road_graph_node_index(line[index])
			var to_index := _road_graph_node_index(line[index + 1])
			_add_road_graph_edge(from_index, to_index)

	_connect_nearby_road_nodes()


func _road_lines_for_navigation() -> Array[PackedVector2Array]:
	var lines: Array[PackedVector2Array] = []
	if not _route_features.is_empty():
		for feature in _route_features:
			var feature_dict := Dictionary(feature)
			var geometry := Dictionary(feature_dict.get("geometry", {}))
			for line in _geometry_to_lines(geometry):
				if line.size() >= 2:
					lines.append(line)
		if not lines.is_empty():
			return lines

	for road in ROADS:
		var fallback_line := _scaled_points(PackedVector2Array(road))
		if fallback_line.size() >= 2:
			lines.append(fallback_line)
	return lines


func _road_graph_node_index(position: Vector2) -> int:
	for index in range(_road_graph_points.size()):
		if Vector2(_road_graph_points[index]).distance_to(position) <= LORD_ROAD_GRAPH_MERGE_DISTANCE:
			return index

	_road_graph_points.append(position)
	_road_graph_edges.append([])
	return _road_graph_points.size() - 1


func _add_road_graph_edge(from_index: int, to_index: int) -> void:
	if from_index == to_index:
		return
	if from_index < 0 or to_index < 0:
		return
	if from_index >= _road_graph_points.size() or to_index >= _road_graph_points.size():
		return

	var cost := Vector2(_road_graph_points[from_index]).distance_to(Vector2(_road_graph_points[to_index]))
	if cost <= 0.01:
		return

	if not _road_graph_has_edge(from_index, to_index):
		var from_edges := Array(_road_graph_edges[from_index])
		from_edges.append({"to": to_index, "cost": cost})
		_road_graph_edges[from_index] = from_edges
	if not _road_graph_has_edge(to_index, from_index):
		var to_edges := Array(_road_graph_edges[to_index])
		to_edges.append({"to": from_index, "cost": cost})
		_road_graph_edges[to_index] = to_edges


func _road_graph_has_edge(from_index: int, to_index: int) -> bool:
	if from_index < 0 or from_index >= _road_graph_edges.size():
		return false

	for raw_edge in Array(_road_graph_edges[from_index]):
		var edge := Dictionary(raw_edge)
		if int(edge.get("to", -1)) == to_index:
			return true
	return false


func _connect_nearby_road_nodes() -> void:
	for left_index in range(_road_graph_points.size()):
		for right_index in range(left_index + 1, _road_graph_points.size()):
			var distance := Vector2(_road_graph_points[left_index]).distance_to(Vector2(_road_graph_points[right_index]))
			if distance <= LORD_ROAD_GRAPH_CONNECT_DISTANCE:
				_add_road_graph_edge(left_index, right_index)


func _ensure_road_graph() -> void:
	if not _road_graph_points.is_empty():
		return
	_build_road_graph()


func _road_graph_waypoint(current_position: Vector2, final_target: Vector2, direct_distance: float) -> Vector2:
	_ensure_road_graph()
	if _road_graph_points.size() < 2:
		return Vector2.INF

	var path := _road_path_between(current_position, final_target)
	if path.is_empty():
		return Vector2.INF

	var road_distance := current_position.distance_to(Vector2(path[0]))
	road_distance += _road_path_distance(path)
	road_distance += Vector2(path[path.size() - 1]).distance_to(final_target)
	if road_distance > direct_distance * LORD_ROAD_MAX_DETOUR_MULTIPLIER:
		return Vector2.INF

	var waypoint := Vector2(path[0])
	if current_position.distance_to(waypoint) <= LORD_ROAD_REJOIN_RADIUS and path.size() > 1:
		waypoint = Vector2(path[1])
	if current_position.distance_to(waypoint) <= 0.01:
		return Vector2.INF
	return waypoint


func _road_path_between(start_position: Vector2, end_position: Vector2) -> Array:
	var start_index := _nearest_road_graph_node_index(start_position)
	var end_index := _nearest_road_graph_node_index(end_position)
	if start_index < 0 or end_index < 0:
		return []
	if start_index == end_index:
		return [Vector2(_road_graph_points[start_index])]

	var open_nodes: Array = [start_index]
	var costs: Dictionary = {}
	var previous: Dictionary = {}
	costs[start_index] = 0.0

	while not open_nodes.is_empty():
		var current_index := _pop_lowest_cost_road_node(open_nodes, costs)
		if current_index == end_index:
			break

		var current_cost := float(costs.get(current_index, INF))
		for raw_edge in Array(_road_graph_edges[current_index]):
			var edge := Dictionary(raw_edge)
			var next_index := int(edge.get("to", -1))
			if next_index < 0:
				continue
			var next_cost := current_cost + float(edge.get("cost", INF))
			if next_cost >= float(costs.get(next_index, INF)):
				continue
			costs[next_index] = next_cost
			previous[next_index] = current_index
			if not open_nodes.has(next_index):
				open_nodes.append(next_index)

	if not costs.has(end_index):
		return []

	var path_indices: Array = []
	var cursor := end_index
	path_indices.push_front(cursor)
	while cursor != start_index and previous.has(cursor):
		cursor = int(previous[cursor])
		path_indices.push_front(cursor)

	if path_indices.is_empty() or int(path_indices[0]) != start_index:
		return []

	var path: Array = []
	for raw_index in path_indices:
		path.append(Vector2(_road_graph_points[int(raw_index)]))
	return path


func _nearest_road_graph_node_index(position: Vector2) -> int:
	var best_index := -1
	var best_distance := INF
	for index in range(_road_graph_points.size()):
		var distance := position.distance_to(Vector2(_road_graph_points[index]))
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index


func _pop_lowest_cost_road_node(open_nodes: Array, costs: Dictionary) -> int:
	var best_open_index := 0
	var best_node := int(open_nodes[0])
	var best_cost := float(costs.get(best_node, INF))
	for open_index in range(1, open_nodes.size()):
		var node_index := int(open_nodes[open_index])
		var node_cost := float(costs.get(node_index, INF))
		if node_cost < best_cost:
			best_cost = node_cost
			best_node = node_index
			best_open_index = open_index
	open_nodes.remove_at(best_open_index)
	return best_node


func _road_path_distance(path: Array) -> float:
	if path.size() < 2:
		return 0.0

	var distance := 0.0
	for index in range(path.size() - 1):
		distance += Vector2(path[index]).distance_to(Vector2(path[index + 1]))
	return distance


func _build_land_travel_masks() -> void:
	_land_travel_polygons.clear()
	_blocked_water_polygons.clear()

	if not _build_calibrated_land_travel_masks():
		for feature in _land_features:
			var feature_dict := Dictionary(feature)
			var properties := Dictionary(feature_dict.get("properties", {}))
			if String(properties.get("kind", "")) != "land":
				continue

			for polygon in _geometry_to_polygons(Dictionary(feature_dict.get("geometry", {}))):
				if polygon.size() >= 3:
					_land_travel_polygons.append(polygon)

	if _build_calibrated_blocking_water_masks():
		return

	for feature in _water_features:
		var feature_dict := Dictionary(feature)
		var properties := Dictionary(feature_dict.get("properties", {}))
		var kind := String(properties.get("kind", ""))
		if not BLOCKING_WATER_KINDS.has(kind):
			continue

		for polygon in _geometry_to_polygons(Dictionary(feature_dict.get("geometry", {}))):
			if polygon.size() >= 3:
				_blocked_water_polygons.append(polygon)


func _build_calibrated_land_travel_masks() -> bool:
	if _map_render_calibration.is_empty() or _map_calibration_image_size == Vector2.ZERO:
		return false

	var land_masks := Array(_map_render_calibration.get("land_travel_polygons_px", []))
	if land_masks.is_empty():
		return false

	for mask in land_masks:
		if not (mask is Dictionary):
			continue

		var mask_dict := Dictionary(mask)
		var points := PackedVector2Array()
		for point in Array(mask_dict.get("points", [])):
			var point_array := Array(point)
			if point_array.size() < 2:
				continue
			points.append(_map_pixel_to_map(Vector2(float(point_array[0]), float(point_array[1]))))

		if points.size() >= 3:
			_land_travel_polygons.append(points)

	return not _land_travel_polygons.is_empty()


func _build_calibrated_blocking_water_masks() -> bool:
	if _map_render_calibration.is_empty() or _map_calibration_image_size == Vector2.ZERO:
		return false

	var water_masks := Array(_map_render_calibration.get("blocking_water_polygons_px", []))
	if water_masks.is_empty():
		return false

	for mask in water_masks:
		if not (mask is Dictionary):
			continue

		var mask_dict := Dictionary(mask)
		var points := PackedVector2Array()
		for point in Array(mask_dict.get("points", [])):
			var point_array := Array(point)
			if point_array.size() < 2:
				continue
			points.append(_map_pixel_to_map(Vector2(float(point_array[0]), float(point_array[1]))))

		if points.size() >= 3:
			_blocked_water_polygons.append(points)

	return not _blocked_water_polygons.is_empty()


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Missing JSON map data: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Could not open JSON map data: %s" % path)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_warning("Invalid JSON object in map data: %s" % path)
		return {}

	return Dictionary(parsed)


func _build_settlement_entries() -> void:
	_settlement_entries.clear()

	for feature in _settlement_features:
		var feature_dict := Dictionary(feature)
		var geometry := Dictionary(feature_dict.get("geometry", {}))
		if String(geometry.get("type", "")) != "Point":
			continue

		var properties := Dictionary(feature_dict.get("properties", {}))
		var coordinates := Array(geometry.get("coordinates", []))
		var entry := properties.duplicate(true)
		entry["id"] = String(feature_dict.get("id", ""))
		entry["pos"] = _geo_to_map(coordinates)
		entry["geo"] = coordinates
		entry["pos_projected"] = true
		if not entry.has("owner_faction"):
			entry["owner_faction"] = "Neutral"
		if not entry.has("kind"):
			entry["kind"] = "Settlement"
		_settlement_entries.append(entry)


func _geo_to_map(coordinates: Array) -> Vector2:
	if coordinates.size() < 2:
		return Vector2.ZERO

	if not _map_calibration_points.is_empty() and _map_calibration_image_size != Vector2.ZERO:
		return _map_pixel_to_map(_geo_to_calibrated_map_pixel(coordinates))

	var normalized := _geo_to_normalized(coordinates)
	return MAP_RECT.position + Vector2(normalized.x * MAP_RECT.size.x, normalized.y * MAP_RECT.size.y)


func _geo_to_normalized(coordinates: Array) -> Vector2:
	var west := float(_map_bbox[0])
	var south := float(_map_bbox[1])
	var east := float(_map_bbox[2])
	var north := float(_map_bbox[3])
	var longitude := float(coordinates[0])
	var latitude := float(coordinates[1])
	var x_ratio := clampf((longitude - west) / (east - west), 0.0, 1.0)
	var y_ratio := clampf((north - latitude) / (north - south), 0.0, 1.0)
	return Vector2(x_ratio, y_ratio)


func _geo_to_raw_calibration_pixel(coordinates: Array) -> Vector2:
	var normalized := _geo_to_normalized(coordinates)
	return Vector2(
		normalized.x * _map_calibration_image_size.x,
		normalized.y * _map_calibration_image_size.y
	)


func _geo_to_calibrated_map_pixel(coordinates: Array) -> Vector2:
	var raw_pixel := _geo_to_raw_calibration_pixel(coordinates)
	var weighted_delta := Vector2.ZERO
	var weight_total := 0.0
	var softness_squared := _map_calibration_softness_px * _map_calibration_softness_px

	for point in _map_calibration_points:
		var anchor_raw_pixel := Vector2(point.get("raw_pixel", Vector2.ZERO))
		var delta_pixel := Vector2(point.get("delta_pixel", Vector2.ZERO))
		var distance_squared := raw_pixel.distance_squared_to(anchor_raw_pixel)

		if distance_squared < 0.01:
			return raw_pixel + delta_pixel

		var weight := 1.0 / pow(distance_squared + softness_squared, _map_calibration_power)
		weighted_delta += delta_pixel * weight
		weight_total += weight

	if weight_total <= 0.0:
		return raw_pixel

	return raw_pixel + weighted_delta / weight_total


func _map_pixel_to_map(pixel: Vector2) -> Vector2:
	return MAP_RECT.position + Vector2(
		(pixel.x / _map_calibration_image_size.x) * MAP_RECT.size.x,
		(pixel.y / _map_calibration_image_size.y) * MAP_RECT.size.y
	)


func _settlements_for_gameplay() -> Array:
	if not _settlement_entries.is_empty():
		return _settlement_entries
	return SETTLEMENTS


func _map_position_from_entry(entry: Dictionary) -> Vector2:
	var position := Vector2(entry.get("pos", Vector2.ZERO))
	if entry.get("pos_projected", false) == true:
		return position
	return _scaled_point(position)


func _position_for_named_settlement(settlement_name: String, fallback: Vector2) -> Vector2:
	for settlement in _settlement_entries:
		if String(settlement.get("name", "")) == settlement_name:
			return _map_position_from_entry(settlement)
	return fallback


func _route_from_settlement_names(route_names: Array, fallback_route: Array) -> Array:
	if route_names.is_empty() or _settlement_entries.is_empty():
		return _scaled_route(fallback_route)

	var route: Array = []
	for route_name in route_names:
		var found := false
		for settlement in _settlement_entries:
			if String(settlement.get("name", "")) != String(route_name):
				continue
			route.append(_map_position_from_entry(settlement))
			found = true
			break
		if not found:
			return _scaled_route(fallback_route)
	return route


func _initialize_lord_parties() -> void:
	_lord_parties.clear()

	for template in LORD_PARTIES:
		var lord: Dictionary = template.duplicate(true)
		if GameState.is_lord_defeated(String(lord.get("name", ""))):
			continue
		lord["pos"] = _position_for_named_settlement(String(template.get("start_name", "")), _scaled_point(template["start"]))
		lord["route"] = _route_from_settlement_names(Array(template.get("route_names", [])), Array(template["route"]))
		lord["route_index"] = 1
		lord = _ensure_lord_ai_state(lord)
		lord["hold_minutes"] = _initial_lord_hold_minutes(lord)
		lord["waiting_at"] = String(template.get("start_name", ""))
		_lord_parties.append(lord)


func _restore_lord_parties_from_game_state() -> void:
	var saved_parties := Array(GameState.map_state.get("lord_parties", []))
	if saved_parties.is_empty():
		return

	for saved in saved_parties:
		if not (saved is Dictionary):
			continue
		var saved_lord := Dictionary(saved)
		var saved_name := String(saved_lord.get("name", ""))
		if String(saved_lord.get("map_projection_id", "")) != _active_map_projection_id():
			continue
		for index in range(_lord_parties.size()):
			if String(_lord_parties[index].get("name", "")) != saved_name:
				continue
			var lord := _lord_parties[index]
			var restored_position := Vector2(saved_lord.get("pos", lord.get("pos", Vector2.ZERO)))
			var fallback_position := Vector2(lord.get("pos", Vector2.ZERO))
			lord["pos"] = constrain_land_position(restored_position, fallback_position)
			lord["route_index"] = int(saved_lord.get("route_index", lord.get("route_index", 1)))
			lord["party_size"] = int(saved_lord.get("party_size", lord.get("party_size", 0)))
			lord["intelligence"] = int(saved_lord.get("intelligence", lord.get("intelligence", 0)))
			lord["hold_minutes"] = maxf(0.0, float(saved_lord.get("hold_minutes", 0.0)))
			lord["waiting_at"] = String(saved_lord.get("waiting_at", ""))
			lord["role"] = String(saved_lord.get("role", lord.get("role", _default_lord_role(lord))))
			lord["state"] = String(saved_lord.get("state", lord.get("state", "patrol")))
			lord["task"] = _normalize_lord_task(saved_lord.get("task", lord.get("task", {})))
			lord["standing_order"] = String(saved_lord.get("standing_order", lord.get("standing_order", _lord_task_type(lord))))
			lord["supplies"] = clampf(float(saved_lord.get("supplies", lord.get("supplies", 100.0))), 0.0, 100.0)
			lord["morale"] = clampf(float(saved_lord.get("morale", lord.get("morale", 65.0))), 0.0, 100.0)
			lord["fatigue"] = clampf(float(saved_lord.get("fatigue", lord.get("fatigue", 0.0))), 0.0, 100.0)
			lord["boldness"] = clampf(float(saved_lord.get("boldness", lord.get("boldness", 50.0))), 0.0, 100.0)
			lord["caution"] = clampf(float(saved_lord.get("caution", lord.get("caution", 50.0))), 0.0, 100.0)
			lord["ambition"] = clampf(float(saved_lord.get("ambition", lord.get("ambition", 50.0))), 0.0, 100.0)
			lord["loyalty"] = clampf(float(saved_lord.get("loyalty", lord.get("loyalty", 50.0))), 0.0, 100.0)
			lord["local_knowledge"] = _normalize_lord_knowledge(saved_lord.get("local_knowledge", saved_lord.get("last_player_sighting", lord.get("local_knowledge", {}))))
			lord["memory"] = _normalize_lord_memory(Array(saved_lord.get("memory", lord.get("memory", []))))
			lord["next_plan_minute"] = int(saved_lord.get("next_plan_minute", lord.get("next_plan_minute", GameState.get_game_total_minutes())))
			lord["recovery_until_minute"] = int(saved_lord.get("recovery_until_minute", lord.get("recovery_until_minute", 0)))
			lord = _ensure_lord_ai_state(lord)
			_lord_parties[index] = lord
			break


func _advance_lord_parties(delta: float) -> void:
	if _lord_parties.is_empty() or delta <= 0.0:
		return

	for index in range(_lord_parties.size()):
		_lord_parties[index] = _advance_lord_on_route(_lord_parties[index], delta)

	queue_redraw()


func _advance_lord_on_route(lord: Dictionary, delta: float) -> Dictionary:
	var route: Array = lord.get("route", [])
	if route.size() < 2:
		return lord

	var hold_minutes := float(lord.get("hold_minutes", 0.0))
	if hold_minutes > 0.0:
		hold_minutes = maxf(0.0, hold_minutes - delta * GameState.GAME_MINUTES_PER_REAL_SECOND)
		lord["hold_minutes"] = hold_minutes
		if hold_minutes > 0.0:
			return lord
		lord["waiting_at"] = ""

	var pos: Vector2 = lord["pos"]
	var previous_pos := pos
	var route_index := clampi(int(lord.get("route_index", 1)), 0, route.size() - 1)
	var target: Vector2 = route[route_index]
	var remaining := _lord_campaign_speed(lord) * MAP_SCALE * delta
	var hop_guard := route.size() + 2

	while remaining > 0.0 and hop_guard > 0:
		var to_target := target - pos
		var distance := to_target.length()
		if distance <= 0.01:
			route_index = (route_index + 1) % route.size()
			target = route[route_index]
			hop_guard -= 1
			continue

		var step := minf(remaining, distance)
		pos += to_target.normalized() * step
		remaining -= step

		if step < distance:
			break

		var arrived_name := _settlement_name_at_position(target)
		var next_hold_minutes := _roll_lord_town_hold_minutes(lord, arrived_name)
		route_index = (route_index + 1) % route.size()
		target = route[route_index]
		hop_guard -= 1
		if next_hold_minutes > 0.0:
			lord["hold_minutes"] = next_hold_minutes
			lord["waiting_at"] = arrived_name
			break

	lord["pos"] = constrain_land_position(pos, previous_pos)
	lord["route_index"] = route_index
	return lord


func _advance_abner_pressure(lord: Dictionary, delta: float, player_position: Vector2, player_is_safe: bool) -> Dictionary:
	if not ABNER_PRESSURE_ENABLED:
		GameState.clear_lord_pursuit_state(ABNER_NAME)
		return {"lord": _advance_lord_on_route(lord, delta), "caught": {}}

	var pos: Vector2 = lord["pos"]
	var distance := pos.distance_to(player_position)
	var is_pursuing := _is_lord_pursuing(lord)

	if is_pursuing and player_is_safe:
		GameState.clear_lord_pursuit_state(ABNER_NAME)
		GameState.last_campaign_notice = "Abner loses your trail among friendly walls and narrow paths."
		return {"lord": _advance_lord_on_route(lord, delta), "caught": {}}

	if is_pursuing and distance > ABNER_ESCAPE_RADIUS:
		GameState.clear_lord_pursuit_state(ABNER_NAME)
		GameState.last_campaign_notice = "Abner's riders fall behind. For now, the road opens."
		return {"lord": _advance_lord_on_route(lord, delta), "caught": {}}

	if is_pursuing:
		lord["hold_minutes"] = 0.0
		lord["waiting_at"] = ""
		var to_player := player_position - pos
		if to_player.length() > 0.01:
			var step := _lord_campaign_speed(lord) * MAP_SCALE * ABNER_PURSUIT_SPEED_MULTIPLIER * delta
			pos += to_player.normalized() * minf(step, to_player.length())
			lord["pos"] = pos
		if pos.distance_to(player_position) <= ABNER_CATCH_RADIUS:
			var caught := _target_from_lord(lord)
			caught["forced"] = true
			caught["dialogue"] = "Abner's riders close the last stretch at a hard pace. There is no more room to pretend this is only dust on the road."
			return {"lord": lord, "caught": caught}
		return {"lord": lord, "caught": {}}

	lord = _advance_lord_on_route(lord, delta)
	pos = lord["pos"]
	if pos.distance_to(player_position) <= _abner_detection_radius():
		lord["hold_minutes"] = 0.0
		lord["waiting_at"] = ""
		GameState.set_lord_pursuit_state(ABNER_NAME, {"state": "pursuing", "started_minute": GameState.get_game_total_minutes()})
		GameState.adjust_morale(-2)
		GameState.last_campaign_notice = "Abner has seen your trail and turns toward you."

	return {"lord": lord, "caught": {}}


func _ensure_lord_ai_state(lord: Dictionary) -> Dictionary:
	var normalized_task := _normalize_lord_task(lord.get("task", {}))
	if not lord.has("standing_order"):
		lord["standing_order"] = String(normalized_task.get("type", ""))
	lord["task"] = normalized_task
	lord["role"] = String(lord.get("role", _default_lord_role(lord)))
	lord["state"] = String(lord.get("state", ""))
	if String(lord["state"]).strip_edges().is_empty():
		lord["state"] = "patrol" if _lord_has_task(lord) else "holding"
	lord["supplies"] = clampf(float(lord.get("supplies", 100.0)), 0.0, 100.0)
	lord["morale"] = clampf(float(lord.get("morale", 65.0)), 0.0, 100.0)
	lord["fatigue"] = clampf(float(lord.get("fatigue", 0.0)), 0.0, 100.0)
	lord["boldness"] = clampf(float(lord.get("boldness", 50.0)), 0.0, 100.0)
	lord["caution"] = clampf(float(lord.get("caution", 50.0)), 0.0, 100.0)
	lord["ambition"] = clampf(float(lord.get("ambition", 50.0)), 0.0, 100.0)
	lord["loyalty"] = clampf(float(lord.get("loyalty", 50.0)), 0.0, 100.0)
	lord["local_knowledge"] = _normalize_lord_knowledge(lord.get("local_knowledge", lord.get("last_player_sighting", {})))
	lord["memory"] = _normalize_lord_memory(Array(lord.get("memory", [])))
	lord["next_plan_minute"] = int(lord.get("next_plan_minute", GameState.get_game_total_minutes() + randi_range(1, OVERWORLD_AI_PLAN_INTERVAL_MINUTES)))
	lord["recovery_until_minute"] = int(lord.get("recovery_until_minute", 0))
	lord["last_safe_confidence_minute"] = int(lord.get("last_safe_confidence_minute", -99999))
	lord["last_rumor_minute"] = int(lord.get("last_rumor_minute", -99999))
	return lord


func _default_lord_role(lord: Dictionary) -> String:
	var name := String(lord.get("name", ""))
	var faction := String(lord.get("faction", ""))
	if name == ABNER_NAME:
		return "marshal"
	if faction == "House of Saul":
		return "retainer"
	if faction == "Philistine Lords":
		return "border_lord"
	if faction == "David's Band":
		return "ally"
	if faction == "Edomite Retinue":
		return "informer"
	if faction == "Jebus":
		return "local_elder"
	return "local_notable"


func _normalize_lord_task(raw_task) -> Dictionary:
	var task: Dictionary = {}
	if raw_task is Dictionary:
		task = Dictionary(raw_task).duplicate(true)
	else:
		var raw_text := String(raw_task).strip_edges().to_lower()
		if raw_text.is_empty() or raw_text == "none" or raw_text == "idle":
			return {}
		task = {"type": raw_text}

	var task_type := String(task.get("type", "")).strip_edges().to_lower()
	if task_type.is_empty() or task_type == "none" or task_type == "idle":
		return {}

	task["type"] = task_type
	task["target_name"] = String(task.get("target_name", ""))
	task["priority"] = float(task.get("priority", 0.0))
	task["created_minute"] = int(task.get("created_minute", GameState.get_game_total_minutes()))
	task["expires_minute"] = int(task.get("expires_minute", 0))
	task["reason"] = String(task.get("reason", ""))
	task["confidence"] = clampf(float(task.get("confidence", 0.0)), 0.0, 100.0)
	if task.has("target_pos"):
		var raw_position = task.get("target_pos", Vector2.ZERO)
		if raw_position is Vector2:
			task["target_pos"] = Vector2(raw_position)
		else:
			task.erase("target_pos")
	return task


func _lord_task_data(lord: Dictionary) -> Dictionary:
	return _normalize_lord_task(lord.get("task", {}))


func _lord_task_type(lord: Dictionary) -> String:
	return String(_lord_task_data(lord).get("type", ""))


func _lord_task_reason(lord: Dictionary) -> String:
	return String(_lord_task_data(lord).get("reason", ""))


func _normalize_lord_knowledge(raw_knowledge) -> Dictionary:
	var knowledge: Dictionary = {}
	if raw_knowledge is Dictionary:
		knowledge = Dictionary(raw_knowledge).duplicate(true)
	var position := Vector2.ZERO
	var raw_position = knowledge.get("position", knowledge.get("pos", Vector2.ZERO))
	if raw_position is Vector2:
		position = Vector2(raw_position)
	knowledge["position"] = position
	knowledge["confidence"] = clampf(float(knowledge.get("confidence", 0.0)), 0.0, 100.0)
	knowledge["minute"] = int(knowledge.get("minute", -1))
	knowledge["source"] = String(knowledge.get("source", ""))
	return knowledge


func _lord_local_knowledge(lord: Dictionary) -> Dictionary:
	return _normalize_lord_knowledge(lord.get("local_knowledge", lord.get("last_player_sighting", {})))


func _lord_knowledge_confidence(lord: Dictionary) -> float:
	return float(_lord_local_knowledge(lord).get("confidence", 0.0))


func _normalize_lord_memory(raw_memory: Array) -> Array:
	var memory: Array = []
	var start_index := maxi(0, raw_memory.size() - LORD_MEMORY_LIMIT)
	for index in range(start_index, raw_memory.size()):
		var entry = raw_memory[index]
		if entry is Dictionary:
			memory.append(Dictionary(entry).duplicate(true))
	return memory


func _compare_rumor_facts(left, right) -> bool:
	var left_fact := Dictionary(left)
	var right_fact := Dictionary(right)
	var left_score := _rumor_state_priority(String(left_fact.get("state", ""))) + float(left_fact.get("confidence", 0.0)) * 0.01
	var right_score := _rumor_state_priority(String(right_fact.get("state", ""))) + float(right_fact.get("confidence", 0.0)) * 0.01
	if absf(left_score - right_score) > 0.01:
		return left_score > right_score
	return float(left_fact.get("distance", INF)) < float(right_fact.get("distance", INF))


func _rumor_state_priority(state: String) -> float:
	match state:
		"pursuing":
			return 4.0
		"search":
			return 3.0
		"retreat":
			return 3.4
		"intercept":
			return 2.0
		"muster":
			return 2.5
		"patrol":
			return 1.0
		_:
			return 0.0


func _decay_lord_ai_state(lord: Dictionary, elapsed_minutes: float) -> Dictionary:
	var hours := maxf(0.0, elapsed_minutes / 60.0)
	var state := String(lord.get("state", "patrol"))
	var knowledge := _lord_local_knowledge(lord)
	var decay_multiplier := 1.0
	if state == "recover" or state == "holding":
		decay_multiplier = 1.35
	decay_multiplier *= _lord_history_confidence_decay_multiplier(lord)
	knowledge["confidence"] = maxf(0.0, float(knowledge.get("confidence", 0.0)) - LORD_CONFIDENCE_DECAY_PER_HOUR * hours * decay_multiplier)
	lord["local_knowledge"] = knowledge

	var fatigue := float(lord.get("fatigue", 0.0))
	var supplies := float(lord.get("supplies", 100.0))
	match state:
		"pursuing":
			fatigue += 18.0 * hours
			supplies -= 5.5 * hours
		"search", "intercept", "muster":
			fatigue += 10.0 * hours
			supplies -= 3.5 * hours
		"retreat":
			fatigue += 14.0 * hours
			supplies -= 4.5 * hours
		"patrol":
			fatigue += 6.0 * hours
			supplies -= 2.5 * hours
		"recover":
			fatigue -= 16.0 * hours
			supplies += 14.0 * hours
		_:
			fatigue -= 8.0 * hours
			supplies += 5.0 * hours

	lord["fatigue"] = clampf(fatigue, 0.0, 100.0)
	lord["supplies"] = clampf(supplies, 0.0, 100.0)
	if state == "recover" and GameState.get_game_total_minutes() >= int(lord.get("recovery_until_minute", 0)):
		lord["next_plan_minute"] = 0
	return lord


func _update_lord_perception(lord: Dictionary, player_position: Vector2, player_is_safe: bool, pressure_score: float, notices: Array[String]) -> Dictionary:
	var current_minute := GameState.get_game_total_minutes()
	var lord_position := Vector2(lord.get("pos", Vector2.ZERO))
	var distance := lord_position.distance_to(player_position)
	var knowledge := _lord_local_knowledge(lord)

	if _is_hostile_lord(lord) and player_is_safe:
		var last_safe_minute := int(lord.get("last_safe_confidence_minute", -99999))
		if current_minute - last_safe_minute >= OVERWORLD_AI_PLAN_INTERVAL_MINUTES:
			lord["last_safe_confidence_minute"] = current_minute
			knowledge["confidence"] = maxf(0.0, float(knowledge.get("confidence", 0.0)) - LORD_SAFE_PLACE_CONFIDENCE_LOSS)
			knowledge["source"] = "walls and narrow streets"
			lord["local_knowledge"] = knowledge
			if _is_lord_pursuing_player(lord):
				GameState.clear_lord_pursuit_state(String(lord.get("name", "")))
				lord["state"] = "search" if float(knowledge.get("confidence", 0.0)) >= LORD_SEARCH_CONFIDENCE_MIN else "recover"
				lord["next_plan_minute"] = 0
				_set_director_relief(current_minute + OVERWORLD_AI_RELIEF_AFTER_ESCAPE_MINUTES)
				notices.append("%s loses your trail among walls, gates, and conflicting witnesses." % String(lord.get("name", "A lord")))

	var direct_target := _nearest_direct_war_target(lord, player_position, player_is_safe)
	if not direct_target.is_empty():
		return _react_to_direct_war_target(lord, direct_target, pressure_score, notices)

	if not _is_hostile_lord(lord):
		return lord

	var last_rumor_minute := int(lord.get("last_rumor_minute", -99999))
	if current_minute - last_rumor_minute >= 45 and distance <= _lord_rumor_radius(lord) and _lord_can_hear_rumor(lord, player_position):
		lord["last_rumor_minute"] = current_minute
		var distance_ratio := clampf(distance / maxf(1.0, _lord_rumor_radius(lord)), 0.0, 1.0)
		var rumor_confidence := LORD_RUMOR_CONFIDENCE + float(GameState.heat) * 0.32 - distance_ratio * 18.0
		if rumor_confidence > float(knowledge.get("confidence", 0.0)) + 5.0:
			lord = _set_lord_knowledge(lord, player_position, rumor_confidence, "gate rumor")
			lord["next_plan_minute"] = 0
	return lord


func _lord_can_hear_rumor(lord: Dictionary, player_position: Vector2) -> bool:
	if not _is_hostile_lord(lord):
		return false
	if GameState.heat >= 18:
		return true
	return not get_nearest_settlement(player_position, 95.0).is_empty()


func _player_war_target(world_position: Vector2, distance: float = 0.0) -> Dictionary:
	return {
		"kind": "player",
		"id": "player",
		"name": "your band",
		"faction": "David's Band",
		"pos": world_position,
		"distance": maxf(0.0, distance),
		"strength": _player_campaign_strength()
	}


func _lord_war_target(lord: Dictionary, distance: float, strength: float = -1.0) -> Dictionary:
	var lord_name := String(lord.get("name", "enemy lord"))
	return {
		"kind": "lord",
		"id": lord_name,
		"lord_id": lord_name,
		"name": lord_name,
		"faction": String(lord.get("faction", "")),
		"title": String(lord.get("title", "")),
		"role": String(lord.get("role", "")),
		"party_size": int(lord.get("party_size", 0)),
		"is_faction_leader": _is_faction_leader_lord(lord),
		"pos": Vector2(lord.get("pos", Vector2.ZERO)),
		"distance": maxf(0.0, distance),
		"strength": _lord_campaign_strength(lord) if strength < 0.0 else strength
	}


func _nearest_direct_war_target(lord: Dictionary, player_position: Vector2, player_is_safe: bool) -> Dictionary:
	var lord_position := Vector2(lord.get("pos", Vector2.ZERO))
	var detection_radius := _lord_detection_radius(lord)
	var best_target: Dictionary = {}
	var best_score := INF

	if _is_hostile_lord(lord) and not player_is_safe:
		var player_distance := lord_position.distance_to(player_position)
		if player_distance <= detection_radius:
			best_target = _player_war_target(player_position, player_distance)
			best_score = player_distance - 260.0

	for other_lord in _lord_parties:
		if not (other_lord is Dictionary):
			continue
		var enemy_lord := Dictionary(other_lord)
		var enemy_name := String(enemy_lord.get("name", ""))
		if enemy_name.is_empty() or enemy_name == String(lord.get("name", "")):
			continue
		if GameState.is_lord_defeated(enemy_name):
			continue
		if not _lords_are_at_war(lord, enemy_lord):
			continue

		var enemy_position := Vector2(enemy_lord.get("pos", Vector2.ZERO))
		var enemy_distance := lord_position.distance_to(enemy_position)
		if enemy_distance > detection_radius:
			continue
		var enemy_is_strategic := _is_faction_leader_lord(enemy_lord)
		var ordinary_notice_radius := maxf(LORD_WEAK_FLEE_RADIUS, detection_radius * LORD_ORDINARY_TARGET_NOTICE_MULTIPLIER)
		if not enemy_is_strategic and enemy_distance > ordinary_notice_radius:
			continue
		var enemy_strength := _lord_campaign_strength(enemy_lord)
		var score := enemy_distance - minf(enemy_strength, 160.0) * 0.10
		if enemy_is_strategic:
			score -= 120.0
		else:
			score += 180.0
		if score < best_score:
			best_score = score
			best_target = _lord_war_target(enemy_lord, enemy_distance, enemy_strength)

	return best_target


func _react_to_direct_war_target(lord: Dictionary, target: Dictionary, pressure_score: float, notices: Array[String]) -> Dictionary:
	var current_minute := GameState.get_game_total_minutes()
	var target_kind := String(target.get("kind", "lord"))
	var target_name := String(target.get("name", "enemy force"))
	var target_position := Vector2(target.get("pos", Vector2.INF))
	var target_distance := float(target.get("distance", Vector2(lord.get("pos", Vector2.ZERO)).distance_to(target_position)))
	var target_is_player := target_kind == "player"

	if target_is_player:
		lord = _set_lord_knowledge(lord, target_position, LORD_DIRECT_SIGHT_CONFIDENCE, "direct sighting")

	if _lord_should_retreat_from_target(lord, target):
		var was_retreating := String(lord.get("state", "")) == "retreat"
		lord["task"] = _make_lord_retreat_task(lord, target, 112.0, "%s is too close and this force is too weak to stand." % target_name, LORD_DIRECT_SIGHT_CONFIDENCE)
		lord["state"] = "retreat"
		lord["hold_minutes"] = 0.0
		lord["waiting_at"] = ""
		lord["next_plan_minute"] = current_minute + randi_range(4, 8)
		GameState.clear_lord_pursuit_state(String(lord.get("name", "")))
		if target_is_player and not was_retreating:
			lord = _remember_lord_event(lord, "retreated_from_player", "Backed away from a stronger band.", target_position)
			notices.append("%s pulls back instead of facing your stronger band alone." % String(lord.get("name", "A hostile lord")))
		return lord

	if not _lord_should_engage_war_target(lord, target):
		if target_is_player:
			_mark_direct_sighting(current_minute)
			lord["next_plan_minute"] = current_minute + randi_range(6, 12)
		return lord

	if _lord_should_muster_before_target(lord, target):
		var was_pursuing_player := _is_lord_pursuing_player(lord)
		lord["task"] = _make_lord_muster_task(lord, LORD_DIRECT_SIGHT_CONFIDENCE, "%s has been seen, but this force will not risk a weak solo chase." % target_name, LORD_DIRECT_SIGHT_CONFIDENCE)
		lord["state"] = "muster"
		lord["hold_minutes"] = 0.0
		lord["waiting_at"] = ""
		lord["next_plan_minute"] = current_minute + randi_range(4, 8)
		GameState.clear_lord_pursuit_state(String(lord.get("name", "")))
		if target_is_player:
			_mark_direct_sighting(current_minute)
			if not was_pursuing_player:
				lord = _remember_lord_event(lord, "sighting", "Saw the player band but chose to gather support.", target_position)
				notices.append("%s sees your trail, but gathers support instead of charging alone." % String(lord.get("name", "A hostile lord")))
		return lord

	if target_is_player and not _director_allows_hunt(lord, pressure_score, true, target_distance):
		var knowledge := _lord_local_knowledge(lord)
		lord = _set_lord_knowledge(lord, target_position, maxf(float(knowledge.get("confidence", 0.0)), LORD_RUMOR_CONFIDENCE), "blocked by pressure")
		lord["next_plan_minute"] = 0
		return lord

	if not _lord_should_pursue_war_target(lord, target):
		return lord

	var was_pursuing_player := _is_lord_pursuing_player(lord)
	lord["task"] = _make_lord_pursue_target_task(target, 100.0, "%s has been seen directly." % target_name, LORD_DIRECT_SIGHT_CONFIDENCE)
	lord["state"] = "pursuing"
	lord["hold_minutes"] = 0.0
	lord["waiting_at"] = ""
	lord["next_plan_minute"] = current_minute + randi_range(4, 8)
	if target_is_player:
		GameState.set_lord_pursuit_state(String(lord.get("name", "")), {
			"state": "pursuing",
			"started_minute": current_minute,
			"confidence": LORD_DIRECT_SIGHT_CONFIDENCE
		})
		_mark_direct_sighting(current_minute)
		if not was_pursuing_player:
			GameState.adjust_morale(-2)
			lord = _remember_lord_event(lord, "sighting", "Saw the player band on the road.", target_position)
			notices.append("%s has seen your trail and turns toward you." % String(lord.get("name", "A hostile lord")))
	else:
		GameState.clear_lord_pursuit_state(String(lord.get("name", "")))
	return lord


func _director_allows_hunt(lord: Dictionary, pressure_score: float, direct_sight: bool, distance: float) -> bool:
	if not _is_hostile_lord(lord):
		return false
	if _is_lord_pursuing_player(lord):
		return true
	var current_minute := GameState.get_game_total_minutes()
	var director := _overworld_ai_director()
	var relief_until := int(director.get("pressure_relief_until_minute", 0))
	if current_minute < relief_until:
		return direct_sight and distance <= _lord_detection_radius(lord) * 0.45
	if _active_pursuer_count() >= OVERWORLD_AI_MAX_PURSUERS:
		return false
	if pressure_score >= OVERWORLD_AI_HIGH_PRESSURE_SCORE and not direct_sight:
		return false
	return true


func _active_pursuer_count(except_lord_name: String = "") -> int:
	var count := 0
	for lord in _lord_parties:
		var lord_name := String(lord.get("name", ""))
		if lord_name == except_lord_name:
			continue
		if _is_lord_pursuing_player(lord):
			count += 1
	return count


func _coordination_role_for(lord: Dictionary, active_hunt_elsewhere: bool, pressure_score: float, player_is_safe: bool) -> Dictionary:
	if not _is_hostile_lord(lord):
		return {"id": "local", "reason": ""}
	if _is_lord_pursuing_player(lord):
		return {
			"id": "pursuer",
			"reason": "This lord already owns the hard chase.",
			"pursue": 8.0,
			"search": 3.0
		}

	var role := String(lord.get("role", ""))
	var faction := String(lord.get("faction", ""))
	var caution := float(lord.get("caution", 50.0))
	if active_hunt_elsewhere:
		if role == "informer":
			return {
				"id": "relay",
				"reason": "With another host chasing, informers spread and price the news.",
				"stay": 4.0,
				"search": 14.0,
				"pursue": -20.0,
				"intercept": 14.0,
				"destination": "Nob"
			}
		if faction == "Philistine Lords" or caution >= 60.0:
			return {
				"id": "blocker",
				"reason": "With another host chasing, cautious captains block likely roads.",
				"patrol": 5.0,
				"search": 6.0,
				"pursue": -12.0,
				"intercept": 24.0,
				"destination": _likely_blocking_destination_name(lord)
			}
		return {
			"id": "sweeper",
			"reason": "With another host chasing, this party sweeps nearby roads.",
			"patrol": -4.0,
			"search": 18.0,
			"pursue": -8.0,
			"intercept": 8.0
		}

	if pressure_score >= 55.0 and not player_is_safe:
		return {
			"id": "net",
			"reason": "Pressure is high enough that hostile parties keep a loose net.",
			"patrol": 3.0,
			"search": 8.0,
			"intercept": 10.0
		}

	return {"id": "routine", "reason": ""}


func _likely_blocking_destination_name(lord: Dictionary) -> String:
	var faction := String(lord.get("faction", ""))
	var role := String(lord.get("role", ""))
	if role == "informer" or faction == "Edomite Retinue":
		return "Nob"
	if faction == "Philistine Lords":
		return "Ziklag"
	if faction == "House of Saul":
		if GameState.get_party_men_count() >= GameState.get_objective_target_men():
			return "Ziklag"
		return "Bethlehem"
	return _lord_home_name(lord)


func _lord_strength_profile(lord: Dictionary) -> Dictionary:
	return _lord_strength_profile_against(lord, _player_campaign_strength())


func _lord_strength_profile_against(lord: Dictionary, opposing_strength: float) -> Dictionary:
	var target_strength := maxf(1.0, opposing_strength)
	var solo_strength := _lord_campaign_strength(lord)
	var nearby_support := _nearby_hostile_support_strength(lord, LORD_COMBAT_REINFORCE_RADIUS)
	var potential_support := _nearby_hostile_support_strength(lord, LORD_GROUP_UP_RADIUS)
	var nearby_support_count := _nearby_supporting_lord_count(lord, LORD_COMBAT_REINFORCE_RADIUS)
	var potential_support_count := _nearby_supporting_lord_count(lord, LORD_GROUP_UP_RADIUS)
	var effective_strength := solo_strength + nearby_support
	var group_strength := solo_strength + potential_support
	var solo_ratio := solo_strength / target_strength
	var effective_ratio := effective_strength / target_strength
	var group_ratio := group_strength / target_strength
	var can_pursue := solo_ratio >= LORD_CAUTIOUS_SOLO_RATIO or effective_ratio >= LORD_CONFIDENT_GROUP_RATIO
	return {
		"player_strength": _player_campaign_strength(),
		"target_strength": target_strength,
		"solo_strength": solo_strength,
		"nearby_support": nearby_support,
		"potential_support": potential_support,
		"nearby_support_count": nearby_support_count,
		"potential_support_count": potential_support_count,
		"effective_strength": effective_strength,
		"group_strength": group_strength,
		"solo_ratio": solo_ratio,
		"effective_ratio": effective_ratio,
		"group_ratio": group_ratio,
		"can_pursue": can_pursue
	}


func _lord_should_muster_before_pursuit(lord: Dictionary) -> bool:
	if not _is_hostile_lord(lord):
		return false
	return _lord_should_muster_before_target(lord, _player_war_target(player_position, Vector2(lord.get("pos", Vector2.ZERO)).distance_to(player_position)))


func _lord_should_muster_before_target(lord: Dictionary, target: Dictionary) -> bool:
	if target.is_empty():
		return false
	var target_strength := float(target.get("strength", _player_campaign_strength()))
	var profile := _lord_strength_profile_against(lord, target_strength)
	if bool(profile.get("can_pursue", false)):
		return false
	if int(profile.get("potential_support_count", 0)) <= 0 or float(profile.get("potential_support", 0.0)) <= 0.0:
		return false
	if float(profile.get("group_ratio", 0.0)) <= float(profile.get("solo_ratio", 0.0)) + 0.04:
		return false
	if not _lord_target_is_worth_mustering(lord, target, profile):
		return false
	return float(profile.get("solo_ratio", 0.0)) < LORD_CAUTIOUS_SOLO_RATIO


func _lord_target_is_worth_mustering(lord: Dictionary, target: Dictionary, profile: Dictionary) -> bool:
	var group_ratio := float(profile.get("group_ratio", 0.0))
	if _is_strategic_war_target(target):
		return group_ratio >= LORD_WEAK_SOLO_RATIO
	var distance_to_target := float(target.get("distance", Vector2(lord.get("pos", Vector2.ZERO)).distance_to(Vector2(target.get("pos", Vector2.ZERO)))))
	if distance_to_target > LORD_GROUP_UP_RADIUS * 0.72:
		return false
	return group_ratio >= LORD_CAUTIOUS_SOLO_RATIO


func _lord_should_engage_war_target(lord: Dictionary, target: Dictionary) -> bool:
	if target.is_empty():
		return false
	if _lord_should_muster_before_target(lord, target):
		return true
	return _lord_should_pursue_war_target(lord, target)


func _lord_should_pursue_war_target(lord: Dictionary, target: Dictionary) -> bool:
	if target.is_empty():
		return false
	var target_strength := float(target.get("strength", _player_campaign_strength()))
	var profile := _lord_strength_profile_against(lord, target_strength)
	if not bool(profile.get("can_pursue", false)):
		return false
	if _is_strategic_war_target(target):
		return true
	var distance_to_target := float(target.get("distance", Vector2(lord.get("pos", Vector2.ZERO)).distance_to(Vector2(target.get("pos", Vector2.ZERO)))))
	var ordinary_commit_radius := maxf(LORD_COMBAT_REINFORCE_RADIUS, _lord_detection_radius(lord) * LORD_ORDINARY_TARGET_NOTICE_MULTIPLIER)
	if distance_to_target > ordinary_commit_radius:
		return false
	if float(profile.get("solo_ratio", 0.0)) >= LORD_OPPORTUNISTIC_SOLO_RATIO:
		return true
	return int(profile.get("nearby_support_count", 0)) > 0 and float(profile.get("effective_ratio", 0.0)) >= LORD_OPPORTUNISTIC_SUPPORTED_RATIO


func _lord_should_retreat_from_player(lord: Dictionary, player_position: Vector2, distance_to_player: float) -> bool:
	return _lord_should_retreat_from_target(lord, _player_war_target(player_position, distance_to_player))


func _lord_should_retreat_from_target(lord: Dictionary, target: Dictionary) -> bool:
	if target.is_empty():
		return false
	var distance_to_target := float(target.get("distance", Vector2(lord.get("pos", Vector2.ZERO)).distance_to(Vector2(target.get("pos", Vector2.ZERO)))))
	if distance_to_target > LORD_WEAK_FLEE_RADIUS:
		return false
	var target_strength := float(target.get("strength", _player_campaign_strength()))
	var profile := _lord_strength_profile_against(lord, target_strength)
	var solo_ratio := float(profile.get("solo_ratio", 0.0))
	var effective_ratio := float(profile.get("effective_ratio", solo_ratio))
	if effective_ratio >= LORD_CAUTIOUS_SOLO_RATIO:
		return false
	if solo_ratio < LORD_WEAK_SOLO_RATIO:
		return true
	return distance_to_target <= LORD_WEAK_FLEE_RADIUS * 0.58 and effective_ratio < LORD_WEAK_SOLO_RATIO


func _player_campaign_strength() -> float:
	var party_data := GameState.get_party_data()
	var generic_count := maxi(0, int(party_data.get("generic_soldier_count", 0)))
	var named_characters := Array(party_data.get("named_characters", []))
	var morale_factor := lerpf(0.78, 1.15, clampf(float(GameState.morale) / 100.0, 0.0, 1.0))
	var david_factor := 1.25
	return maxf(1.0, (float(generic_count) + float(named_characters.size()) * 1.25 + david_factor) * morale_factor)


func _lord_campaign_strength(lord: Dictionary) -> float:
	var party_size := maxf(0.0, float(int(lord.get("party_size", 0))))
	var morale_factor := lerpf(0.78, 1.08, clampf(float(lord.get("morale", 65.0)) / 100.0, 0.0, 1.0))
	var supply_factor := lerpf(0.72, 1.03, clampf(float(lord.get("supplies", 100.0)) / 100.0, 0.0, 1.0))
	var fatigue_factor := lerpf(1.0, 0.62, clampf(float(lord.get("fatigue", 0.0)) / 100.0, 0.0, 1.0))
	var command_factor := lerpf(0.95, 1.12, clampf(float(int(lord.get("intelligence", 0))) / 50.0, 0.0, 1.0))
	return maxf(1.0, party_size * morale_factor * supply_factor * fatigue_factor * command_factor)


func _nearby_hostile_support_strength(lord: Dictionary, radius: float) -> float:
	var support := 0.0
	var lord_position := Vector2(lord.get("pos", Vector2.ZERO))
	for other_lord in _lord_parties:
		if not (other_lord is Dictionary):
			continue
		if not _lords_can_support_each_other(lord, Dictionary(other_lord)):
			continue
		if GameState.is_lord_defeated(String(other_lord.get("name", ""))):
			continue
		if lord_position.distance_to(Vector2(other_lord.get("pos", Vector2.ZERO))) > radius:
			continue
		support += _lord_campaign_strength(other_lord)
	return support


func _nearby_supporting_lord_count(lord: Dictionary, radius: float) -> int:
	var count := 0
	var lord_position := Vector2(lord.get("pos", Vector2.ZERO))
	for other_lord in _lord_parties:
		if not (other_lord is Dictionary):
			continue
		if not _lords_can_support_each_other(lord, Dictionary(other_lord)):
			continue
		if GameState.is_lord_defeated(String(other_lord.get("name", ""))):
			continue
		if lord_position.distance_to(Vector2(other_lord.get("pos", Vector2.ZERO))) > radius:
			continue
		count += 1
	return count


func _best_hostile_group_target(lord: Dictionary) -> Dictionary:
	var lord_position := Vector2(lord.get("pos", Vector2.ZERO))
	var best: Dictionary = {}
	var best_score := INF
	for other_lord in _lord_parties:
		if not (other_lord is Dictionary):
			continue
		if not _lords_can_support_each_other(lord, Dictionary(other_lord)):
			continue
		if GameState.is_lord_defeated(String(other_lord.get("name", ""))):
			continue
		var other_position := Vector2(other_lord.get("pos", Vector2.ZERO))
		var distance := lord_position.distance_to(other_position)
		if distance > LORD_GROUP_UP_RADIUS:
			continue
		var strength := _lord_campaign_strength(other_lord)
		var score := distance - strength * 4.0
		if score < best_score:
			best_score = score
			best = {
				"lord_id": String(other_lord.get("name", "another lord")),
				"name": String(other_lord.get("name", "another lord")),
				"pos": other_position,
				"strength": strength,
				"distance": distance
			}
	if not best.is_empty():
		return best
	return {}


func _best_lord_retreat_target(lord: Dictionary, threat: Dictionary) -> Dictionary:
	var lord_position := Vector2(lord.get("pos", Vector2.ZERO))
	var threat_position := Vector2(threat.get("pos", lord_position))
	var current_threat_distance := lord_position.distance_to(threat_position)
	var best: Dictionary = {}
	var best_score := INF

	for other_lord in _lord_parties:
		if not (other_lord is Dictionary):
			continue
		if not _lords_can_support_each_other(lord, Dictionary(other_lord)):
			continue
		if GameState.is_lord_defeated(String(other_lord.get("name", ""))):
			continue
		var other_position := Vector2(other_lord.get("pos", Vector2.ZERO))
		var distance := lord_position.distance_to(other_position)
		if distance > LORD_GROUP_UP_RADIUS * 1.35:
			continue
		var threat_distance := other_position.distance_to(threat_position)
		var strength := _lord_campaign_strength(other_lord)
		var score := distance - strength * 3.5
		if threat_distance <= current_threat_distance + 90.0:
			score += 360.0
		if score < best_score:
			best_score = score
			best = {
				"name": String(other_lord.get("name", "support")),
				"pos": other_position,
				"distance": distance
			}

	var home_position := _lord_home_position(lord)
	if home_position != Vector2.INF:
		var home_score := lord_position.distance_to(home_position) + 80.0
		if home_position.distance_to(threat_position) <= current_threat_distance + 90.0:
			home_score += 420.0
		if home_score < best_score:
			best_score = home_score
			best = {
				"name": _lord_home_name(lord),
				"pos": home_position,
				"distance": lord_position.distance_to(home_position)
			}

	var away_direction := lord_position - threat_position
	if away_direction.length() <= 0.01:
		away_direction = Vector2.RIGHT.rotated(randf() * TAU)
	var away_position := constrain_land_position(lord_position + away_direction.normalized() * LORD_FLEE_TARGET_DISTANCE, lord_position)
	if away_position != Vector2.INF:
		var away_score := 220.0
		if away_position.distance_to(threat_position) <= current_threat_distance + 90.0:
			away_score += 600.0
		if best.is_empty() or away_score < best_score:
			best = {
				"name": "open ground",
				"pos": away_position,
				"distance": lord_position.distance_to(away_position)
			}

	return best


func _lords_can_group_for_hunt(lord: Dictionary, other_lord: Dictionary) -> bool:
	return _lords_can_support_each_other(lord, other_lord)


func _lords_can_support_each_other(lord: Dictionary, other_lord: Dictionary) -> bool:
	var lord_name := String(lord.get("name", ""))
	var other_name := String(other_lord.get("name", ""))
	if lord_name.is_empty() or lord_name == other_name:
		return false
	var faction := String(lord.get("faction", ""))
	var other_faction := String(other_lord.get("faction", ""))
	return _factions_are_allied(faction, other_faction)


func _should_replan_lord(lord: Dictionary, current_minute: int) -> bool:
	if _lord_task_type(lord).is_empty():
		return true
	return current_minute >= int(lord.get("next_plan_minute", current_minute))


func _plan_lord_task(lord: Dictionary, player_position: Vector2, player_is_safe: bool, pressure_score: float) -> Dictionary:
	var selected_task := _select_best_lord_task(lord, player_position, player_is_safe, pressure_score)
	if selected_task.is_empty():
		selected_task = _make_lord_task("stay_home", 1.0, "No useful work is pressing.")

	var task_type := String(selected_task.get("type", ""))
	lord["task"] = selected_task
	lord["state"] = _state_for_lord_task(task_type)
	if task_type in ["pursue", "search", "intercept", "muster", "retreat", "recover"]:
		lord["hold_minutes"] = 0.0
		lord["waiting_at"] = ""
	lord["next_plan_minute"] = GameState.get_game_total_minutes() + OVERWORLD_AI_PLAN_INTERVAL_MINUTES + randi_range(-4, 6)
	if task_type != "pursue":
		GameState.clear_lord_pursuit_state(String(lord.get("name", "")))
	if task_type == "recover" and int(lord.get("recovery_until_minute", 0)) <= GameState.get_game_total_minutes():
		lord["recovery_until_minute"] = GameState.get_game_total_minutes() + int(randf_range(LORD_RECOVERY_DWELL_MINUTES.x, LORD_RECOVERY_DWELL_MINUTES.y))
	return lord


func _select_best_lord_task(lord: Dictionary, player_position: Vector2, player_is_safe: bool, pressure_score: float) -> Dictionary:
	var candidates := _score_lord_tasks(lord, player_position, player_is_safe, pressure_score)
	var best_task: Dictionary = {}
	var best_score := -INF
	for candidate in candidates:
		var candidate_task := Dictionary(candidate)
		var score := float(candidate_task.get("priority", -INF))
		if score > best_score:
			best_score = score
			best_task = candidate_task
	return best_task


func _score_lord_tasks(lord: Dictionary, player_position: Vector2, player_is_safe: bool, pressure_score: float) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var current_minute := GameState.get_game_total_minutes()
	var standing_order := String(lord.get("standing_order", ""))
	var hostile := _is_hostile_lord(lord)
	var confidence := _lord_knowledge_confidence(lord)
	var fatigue := float(lord.get("fatigue", 0.0))
	var supplies := float(lord.get("supplies", 100.0))
	var boldness := float(lord.get("boldness", 50.0))
	var caution := float(lord.get("caution", 50.0))
	var ambition := float(lord.get("ambition", 50.0))
	var loyalty := float(lord.get("loyalty", 50.0))
	var at_home := _is_lord_near_home(lord)
	var strategy := _faction_strategy_for(lord, pressure_score)
	var active_hunt_elsewhere := _active_pursuer_count(String(lord.get("name", ""))) > 0
	var coordination := _coordination_role_for(lord, active_hunt_elsewhere, pressure_score, player_is_safe)
	var memory_profile := _lord_memory_profile(lord)
	var legacy_profile := _lord_legacy_profile(lord)
	var strength_profile := _lord_strength_profile(lord)
	var distance_to_player := Vector2(lord.get("pos", Vector2.ZERO)).distance_to(player_position)

	var stay_score := 22.0 + caution * 0.24
	if standing_order.is_empty():
		stay_score += 54.0
	if at_home:
		stay_score += 18.0
	if not hostile:
		stay_score += 18.0
	stay_score += fatigue * 0.12 + maxf(0.0, 60.0 - supplies) * 0.28
	if hostile:
		stay_score -= float(GameState.heat) * 0.18
	stay_score += float(strategy.get("stay", 0.0))
	stay_score += float(coordination.get("stay", 0.0))
	stay_score += float(memory_profile.get("stay", 0.0))
	stay_score += float(legacy_profile.get("stay", 0.0))
	candidates.append(_make_lord_task("stay_home", stay_score, "No urgent order is worth leaving the town for.", _lord_home_name(lord), _lord_home_position(lord), confidence))

	var patrol_score := 24.0 - fatigue * 0.20 - maxf(0.0, 45.0 - supplies) * 0.35
	if standing_order in ["patrol", "errand", "scout"]:
		patrol_score += 34.0
	if hostile:
		patrol_score += float(GameState.heat) * 0.24 + ambition * 0.10
	patrol_score += float(strategy.get("patrol", 0.0))
	patrol_score += float(coordination.get("patrol", 0.0))
	patrol_score += float(memory_profile.get("patrol", 0.0))
	patrol_score += float(legacy_profile.get("patrol", 0.0))
	candidates.append(_make_lord_task("patrol", patrol_score, _layered_task_reason(strategy, coordination, memory_profile, legacy_profile, "The standing route still matters."), "", Vector2.INF, confidence))

	var recover_score := fatigue * 0.75 + maxf(0.0, 100.0 - supplies) * 0.65
	if current_minute < int(lord.get("recovery_until_minute", 0)):
		recover_score += 90.0
	if fatigue >= LORD_RECOVER_FATIGUE_THRESHOLD or supplies <= LORD_RESUPPLY_THRESHOLD:
		recover_score += 28.0
	recover_score += float(strategy.get("recover", 0.0))
	recover_score += float(coordination.get("recover", 0.0))
	recover_score += float(memory_profile.get("recover", 0.0))
	recover_score += float(legacy_profile.get("recover", 0.0))
	candidates.append(_make_lord_task("recover", recover_score, "Men, animals, and supplies need rest.", _lord_home_name(lord), _lord_home_position(lord), confidence))

	var knowledge_position := _lord_knowledge_position(lord)
	var search_score := -INF
	if hostile and confidence >= LORD_SEARCH_CONFIDENCE_MIN and knowledge_position != Vector2.INF:
		search_score = confidence * 0.78 + float(GameState.heat) * 0.25 + ambition * 0.16 - caution * 0.10
		if player_is_safe:
			search_score -= 30.0
		search_score += float(strategy.get("search", 0.0))
		if active_hunt_elsewhere:
			search_score += 8.0
		search_score += float(coordination.get("search", 0.0))
		search_score += float(memory_profile.get("search", 0.0))
		search_score += float(legacy_profile.get("search", 0.0))
	candidates.append(_make_lord_task("search", search_score, _layered_task_reason(strategy, coordination, memory_profile, legacy_profile, "Reports point to a road or town worth searching."), "", knowledge_position, confidence))

	var retreat_score := -INF
	if hostile and _lord_should_retreat_from_player(lord, player_position, distance_to_player):
		retreat_score = 118.0 + caution * 0.35 + maxf(0.0, LORD_WEAK_SOLO_RATIO - float(strength_profile.get("solo_ratio", 0.0))) * 70.0
		retreat_score += maxf(0.0, LORD_CAUTIOUS_SOLO_RATIO - float(strength_profile.get("effective_ratio", 0.0))) * 44.0
		retreat_score += maxf(0.0, LORD_WEAK_FLEE_RADIUS - distance_to_player) * 0.08
	candidates.append(_make_lord_retreat_task(lord, _player_war_target(player_position, distance_to_player), retreat_score, "The nearby enemy force is too strong to face alone.", confidence))

	var pursue_score := -INF
	if hostile and bool(strength_profile.get("can_pursue", false)) and confidence >= LORD_PURSUIT_CONFIDENCE_MIN and not player_is_safe and _director_allows_hunt(lord, pressure_score, false, distance_to_player):
		pursue_score = confidence * 1.10 + boldness * 0.35 + loyalty * 0.16 + float(GameState.heat) * 0.25 - caution * 0.18
		pursue_score += float(strategy.get("pursue", 0.0))
		pursue_score += float(coordination.get("pursue", 0.0))
		pursue_score += float(memory_profile.get("pursue", 0.0))
		pursue_score += float(legacy_profile.get("pursue", 0.0))
	candidates.append(_make_lord_task("pursue", pursue_score, _layered_task_reason(strategy, coordination, memory_profile, legacy_profile, "The trail is fresh enough to risk a hard chase."), "", knowledge_position, confidence))

	var intercept_score := -INF
	var intercept_name := _likely_player_destination_name(lord, strategy, coordination)
	var intercept_position := _position_for_named_settlement(intercept_name, Vector2.INF)
	if hostile and GameState.heat >= 20 and intercept_position != Vector2.INF:
		intercept_score = float(GameState.heat) * 0.62 + ambition * 0.18 + boldness * 0.12 - fatigue * 0.22
		if confidence >= LORD_PURSUIT_CONFIDENCE_MIN:
			intercept_score -= 20.0
		intercept_score += float(strategy.get("intercept", 0.0))
		if active_hunt_elsewhere:
			intercept_score += 22.0
		intercept_score += float(coordination.get("intercept", 0.0))
		intercept_score += float(memory_profile.get("intercept", 0.0))
		intercept_score += float(legacy_profile.get("intercept", 0.0))
	candidates.append(_make_lord_task("intercept", intercept_score, _layered_task_reason(strategy, coordination, memory_profile, legacy_profile, "If the target is not visible, cover the place he is likely to need."), intercept_name, intercept_position, confidence))

	var muster_score := -INF
	if hostile and _lord_should_muster_before_pursuit(lord) and not player_is_safe:
		muster_score = confidence * 0.82 + caution * 0.24 + loyalty * 0.18 + float(GameState.heat) * 0.28
		muster_score += maxf(0.0, LORD_CAUTIOUS_SOLO_RATIO - float(strength_profile.get("solo_ratio", 0.0))) * 58.0
		if float(strength_profile.get("solo_ratio", 0.0)) < LORD_WEAK_SOLO_RATIO:
			muster_score += 22.0
		muster_score += maxf(0.0, float(strength_profile.get("group_ratio", 0.0)) - float(strength_profile.get("solo_ratio", 0.0))) * 16.0
		if confidence >= LORD_PURSUIT_CONFIDENCE_MIN:
			muster_score += 16.0
		if active_hunt_elsewhere:
			muster_score += 8.0
	candidates.append(_make_lord_muster_task(lord, muster_score, "This force is too weak to chase alone; gather another lord before pressing the enemy.", confidence))

	return candidates


func _faction_strategy_for(lord: Dictionary, pressure_score: float) -> Dictionary:
	var faction := String(lord.get("faction", ""))
	var role := String(lord.get("role", ""))
	var heat := float(GameState.heat)
	var party_ready_for_ziklag := GameState.get_party_men_count() >= GameState.get_objective_target_men()
	if faction == "House of Saul":
		if heat >= 40.0 or pressure_score >= 55.0:
			return {
				"id": "tighten_net",
				"reason": "Saul's men are tightening the road net.",
				"stay": -16.0,
				"patrol": 8.0,
				"search": 15.0,
				"pursue": 12.0,
				"intercept": 12.0,
				"destination": "Bethlehem"
			}
		return {
			"id": "hold_hill_roads",
			"reason": "Saul's men are holding the hill roads.",
			"patrol": 8.0,
			"search": 5.0,
			"intercept": 4.0,
			"destination": "Bethlehem"
		}
	if faction == "Philistine Lords":
		if party_ready_for_ziklag or heat >= 30.0:
			return {
				"id": "guard_ziklag",
				"reason": "Philistine captains are guarding the southern refuge roads.",
				"stay": -6.0,
				"patrol": 8.0,
				"search": 6.0,
				"pursue": -4.0,
				"intercept": 18.0,
				"destination": "Ziklag"
			}
		return {
			"id": "secure_lowlands",
			"reason": "Philistine captains are securing the lowland road.",
			"stay": 4.0,
			"patrol": 10.0,
			"intercept": 8.0,
			"destination": "Gath"
		}
	if faction == "Edomite Retinue" or role == "informer":
		return {
			"id": "sell_information",
			"reason": "Doeg's men are more useful as informers than shock riders.",
			"stay": 5.0,
			"patrol": 6.0,
			"search": 14.0,
			"pursue": -14.0,
			"intercept": 8.0,
			"destination": "Nob"
		}
	if faction == "David's Band":
		return {
			"id": "guard_davidic_towns",
			"reason": "Allied captains favor safe towns and known paths.",
			"stay": 12.0,
			"patrol": 5.0,
			"recover": 4.0,
			"destination": "Ziklag"
		}
	return {
		"id": "local_balance",
		"reason": "Local powers avoid wasteful marches unless the road forces them.",
		"stay": 8.0,
		"patrol": 3.0,
		"recover": 4.0,
		"destination": _lord_home_name(lord)
	}


func _strategy_reason(strategy: Dictionary, fallback: String) -> String:
	var reason := String(strategy.get("reason", ""))
	if reason.is_empty():
		return fallback
	return "%s %s" % [fallback, reason]


func _layered_task_reason(strategy: Dictionary, coordination: Dictionary, memory_profile: Dictionary, legacy_profile: Dictionary, fallback: String) -> String:
	var pieces := PackedStringArray()
	pieces.append(_strategy_reason(strategy, fallback))

	var coordination_reason := String(coordination.get("reason", ""))
	if not coordination_reason.is_empty():
		pieces.append(coordination_reason)

	var memory_text := _memory_reason(memory_profile)
	if not memory_text.is_empty():
		pieces.append(memory_text)

	var legacy_text := _legacy_reason(legacy_profile)
	if not legacy_text.is_empty():
		pieces.append(legacy_text)

	return " ".join(pieces)


func _make_lord_task(task_type: String, priority: float, reason: String, target_name: String = "", target_pos: Vector2 = Vector2.INF, confidence: float = 0.0) -> Dictionary:
	var task := {
		"type": task_type,
		"target_name": target_name,
		"priority": priority,
		"created_minute": GameState.get_game_total_minutes(),
		"expires_minute": 0,
		"reason": reason,
		"confidence": clampf(confidence, 0.0, 100.0)
	}
	if target_pos != Vector2.INF:
		task["target_pos"] = target_pos
	return task


func _make_lord_muster_task(lord: Dictionary, priority: float, reason: String, confidence: float = 0.0) -> Dictionary:
	var target := _best_hostile_group_target(lord)
	if target.is_empty():
		return _make_lord_task("patrol", minf(priority, 10.0), "No allied support is close enough to muster.", "", Vector2.INF, confidence)
	var target_name := String(target.get("name", _lord_home_name(lord)))
	var target_position := Vector2(target.get("pos", _lord_home_position(lord)))
	if target_position == Vector2.INF:
		target_position = _lord_home_position(lord)
	var task := _make_lord_task("muster", priority, reason, target_name, target_position, confidence)
	task["target_kind"] = "lord"
	task["target_lord_id"] = String(target.get("lord_id", target_name))
	return task


func _make_lord_retreat_task(lord: Dictionary, threat: Dictionary, priority: float, reason: String, confidence: float = 0.0) -> Dictionary:
	var target := _best_lord_retreat_target(lord, threat)
	var target_name := String(target.get("name", _lord_home_name(lord)))
	var target_position := Vector2(target.get("pos", _lord_home_position(lord)))
	if target_position == Vector2.INF:
		target_position = _lord_home_position(lord)
	var task := _make_lord_task("retreat", priority, reason, target_name, target_position, confidence)
	task["threat_kind"] = String(threat.get("kind", "lord"))
	task["threat_name"] = String(threat.get("name", "enemy force"))
	task["threat_lord_id"] = String(threat.get("lord_id", threat.get("id", "")))
	task["threat_pos"] = Vector2(threat.get("pos", Vector2.INF))
	return task


func _make_lord_pursue_target_task(target: Dictionary, priority: float, reason: String, confidence: float = 0.0) -> Dictionary:
	var target_position := Vector2(target.get("pos", Vector2.INF))
	var task := _make_lord_task("pursue", priority, reason, String(target.get("name", "")), target_position, confidence)
	task["target_kind"] = String(target.get("kind", "lord"))
	task["target_lord_id"] = String(target.get("lord_id", target.get("id", "")))
	task["target_faction"] = String(target.get("faction", ""))
	return task


func _state_for_lord_task(task_type: String) -> String:
	match task_type:
		"pursue":
			return "pursuing"
		"search":
			return "search"
		"retreat":
			return "retreat"
		"intercept":
			return "intercept"
		"muster":
			return "muster"
		"recover":
			return "recover"
		"stay_home":
			return "holding"
		_:
			return "patrol"


func _execute_lord_task(lord: Dictionary, real_seconds: float, player_position: Vector2, player_is_safe: bool, notices: Array[String]) -> Dictionary:
	var task_type := _lord_task_type(lord)
	match task_type:
		"pursue":
			return _execute_lord_pursuit(lord, real_seconds, player_position, player_is_safe, notices)
		"search":
			return _execute_lord_search(lord, real_seconds, notices)
		"retreat":
			return _execute_lord_retreat(lord, real_seconds, player_position)
		"intercept":
			return _execute_lord_intercept(lord, real_seconds)
		"muster":
			return _execute_lord_muster(lord, real_seconds)
		"recover":
			return _execute_lord_recovery(lord, real_seconds)
		"stay_home":
			return _execute_lord_stay_home(lord, real_seconds)
		_:
			if not _lord_has_task(lord) and not _is_hostile_lord(lord):
				return _execute_lord_stay_home(lord, real_seconds)
			lord["state"] = "patrol"
			GameState.clear_lord_pursuit_state(String(lord.get("name", "")))
			return {"lord": _advance_lord_on_route(lord, real_seconds), "forced_encounter": {}}


func _execute_lord_pursuit(lord: Dictionary, real_seconds: float, player_position: Vector2, player_is_safe: bool, notices: Array[String]) -> Dictionary:
	var task := _lord_task_data(lord)
	var target_kind := String(task.get("target_kind", "player"))
	var pursuing_player := target_kind.is_empty() or target_kind == "player"
	if pursuing_player and player_is_safe:
		return _break_lord_pursuit_to_search(lord, notices, "safe walls")

	var knowledge := _lord_local_knowledge(lord)
	var confidence := float(knowledge.get("confidence", 0.0))
	if pursuing_player and confidence < LORD_PURSUIT_CONFIDENCE_MIN:
		return _break_lord_pursuit_to_search(lord, notices, "a fading trail")

	var fallback_position := Vector2(knowledge.get("position", player_position)) if pursuing_player else _task_target_position(task, Vector2.INF)
	var target_position := _live_task_target_position(task, fallback_position)
	if target_position == Vector2.INF:
		lord["task"] = _make_lord_task("patrol", 10.0, "The enemy target is gone.")
		lord["state"] = "patrol"
		lord["next_plan_minute"] = 0
		GameState.clear_lord_pursuit_state(String(lord.get("name", "")))
		return {"lord": _advance_lord_on_route(lord, real_seconds), "forced_encounter": {}}

	lord["state"] = "pursuing"
	lord["hold_minutes"] = 0.0
	lord["waiting_at"] = ""
	if pursuing_player:
		GameState.set_lord_pursuit_state(String(lord.get("name", "")), {
			"state": "pursuing",
			"started_minute": int(GameState.get_lord_pursuit_state(String(lord.get("name", ""))).get("started_minute", GameState.get_game_total_minutes())),
			"confidence": confidence
		})
	else:
		GameState.clear_lord_pursuit_state(String(lord.get("name", "")))
	lord = _move_lord_toward(lord, target_position, real_seconds, LORD_PURSUIT_SPEED_MULTIPLIER)

	var lord_position := Vector2(lord.get("pos", Vector2.ZERO))
	if pursuing_player and lord_position.distance_to(player_position) <= LORD_CATCH_RADIUS:
		var caught := _target_from_lord(lord)
		caught["forced"] = true
		caught["dialogue"] = "%s's riders close the last stretch at a hard pace. There is no more room to pretend this is only dust on the road." % String(lord.get("name", "The hostile lord"))
		lord = _remember_lord_event(lord, "caught_player", "Caught the player band on the road.", player_position)
		return {"lord": lord, "forced_encounter": caught}

	if pursuing_player and lord_position.distance_to(player_position) > _lord_escape_radius(lord) and confidence < LORD_DIRECT_SIGHT_CONFIDENCE * 0.72:
		return _break_lord_pursuit_to_search(lord, notices, "too much distance")
	return {"lord": lord, "forced_encounter": {}}


func _break_lord_pursuit_to_search(lord: Dictionary, notices: Array[String], reason: String) -> Dictionary:
	GameState.clear_lord_pursuit_state(String(lord.get("name", "")))
	var knowledge := _lord_local_knowledge(lord)
	var confidence := maxf(0.0, float(knowledge.get("confidence", 0.0)) - 12.0)
	knowledge["confidence"] = confidence
	lord["local_knowledge"] = knowledge
	lord = _remember_lord_event(lord, "lost_trail", "Lost the player band's trail: %s." % reason, Vector2(knowledge.get("position", lord.get("pos", Vector2.ZERO))))
	if confidence >= LORD_SEARCH_CONFIDENCE_MIN:
		lord["task"] = _make_lord_task("search", confidence, "The chase broke, but the last report still matters.", "", Vector2(knowledge.get("position", Vector2.ZERO)), confidence)
		lord["state"] = "search"
	else:
		lord["task"] = _make_lord_task("recover", 50.0, "The trail is gone and the men need order.", _lord_home_name(lord), _lord_home_position(lord), confidence)
		lord["state"] = "recover"
	lord["next_plan_minute"] = 0
	_set_director_relief(GameState.get_game_total_minutes() + OVERWORLD_AI_RELIEF_AFTER_ESCAPE_MINUTES)
	notices.append("%s breaks off the chase: %s." % [String(lord.get("name", "A hostile lord")), reason])
	return {"lord": lord, "forced_encounter": {}}


func _execute_lord_search(lord: Dictionary, real_seconds: float, notices: Array[String]) -> Dictionary:
	var task := _lord_task_data(lord)
	var knowledge := _lord_local_knowledge(lord)
	var target_position := _task_target_position(task, _lord_knowledge_position(lord))
	if target_position == Vector2.INF:
		lord["task"] = _make_lord_task("patrol", 10.0, "No usable report remains.")
		lord["state"] = "patrol"
		return {"lord": _advance_lord_on_route(lord, real_seconds), "forced_encounter": {}}

	lord["state"] = "search"
	lord = _move_lord_toward(lord, target_position, real_seconds, LORD_SEARCH_SPEED_MULTIPLIER)
	var lord_position := Vector2(lord.get("pos", Vector2.ZERO))
	if lord_position.distance_to(target_position) <= LORD_SEARCH_ARRIVAL_RADIUS:
		var confidence := maxf(0.0, float(knowledge.get("confidence", 0.0)) - 18.0)
		knowledge["confidence"] = confidence
		lord["local_knowledge"] = knowledge
		if confidence >= LORD_SEARCH_CONFIDENCE_MIN:
			var next_search := _next_search_position(lord, target_position)
			var next_name := _settlement_name_at_position(next_search, 140.0)
			lord["task"] = _make_lord_task("search", confidence, "The first place was cold; check the next road and gate.", next_name, next_search, confidence)
		else:
			var next_task := "recover" if float(lord.get("fatigue", 0.0)) > 45.0 or float(lord.get("supplies", 100.0)) < 55.0 else "patrol"
			lord = _remember_lord_event(lord, "cold_search", "Searched the last report and found only cold tracks.", target_position)
			lord["task"] = _make_lord_task(next_task, 24.0, "The report has gone stale.")
			lord["state"] = _state_for_lord_task(next_task)
			lord["next_plan_minute"] = 0
			notices.append("%s finds only cold tracks and confused talk." % String(lord.get("name", "A hostile lord")))
	return {"lord": lord, "forced_encounter": {}}


func _execute_lord_intercept(lord: Dictionary, real_seconds: float) -> Dictionary:
	var task := _lord_task_data(lord)
	var target_position := _task_target_position(task, Vector2.INF)
	if target_position == Vector2.INF:
		lord["task"] = _make_lord_task("patrol", 10.0, "No intercept point is useful.")
		lord["state"] = "patrol"
		return {"lord": _advance_lord_on_route(lord, real_seconds), "forced_encounter": {}}

	lord["state"] = "intercept"
	lord = _move_lord_toward(lord, target_position, real_seconds, 0.86)
	if Vector2(lord.get("pos", Vector2.ZERO)).distance_to(target_position) <= LORD_SEARCH_ARRIVAL_RADIUS:
		var target_name := String(task.get("target_name", ""))
		lord["hold_minutes"] = maxf(float(lord.get("hold_minutes", 0.0)), randf_range(90.0, 240.0))
		lord["waiting_at"] = target_name
		lord["task"] = _make_lord_task("patrol", 18.0, "The intercept watch has been posted.")
		lord["state"] = "patrol"
	return {"lord": lord, "forced_encounter": {}}


func _execute_lord_retreat(lord: Dictionary, real_seconds: float, player_position: Vector2) -> Dictionary:
	var task := _lord_task_data(lord)
	var target_position := _task_target_position(task, Vector2.INF)
	if target_position == Vector2.INF:
		lord["task"] = _make_lord_task("recover", 35.0, "No clean retreat point is useful; fall back to home.", _lord_home_name(lord), _lord_home_position(lord))
		lord["state"] = "recover"
		lord["next_plan_minute"] = 0
		return {"lord": lord, "forced_encounter": {}}

	lord["state"] = "retreat"
	lord["hold_minutes"] = 0.0
	lord["waiting_at"] = ""
	GameState.clear_lord_pursuit_state(String(lord.get("name", "")))
	lord = _move_lord_toward(lord, target_position, real_seconds, LORD_FLEE_SPEED_MULTIPLIER)

	var lord_position := Vector2(lord.get("pos", Vector2.ZERO))
	var threat_position := _retreat_threat_position(task, player_position)
	var distance_to_threat := lord_position.distance_to(threat_position) if threat_position != Vector2.INF else LORD_WEAK_FLEE_CLEAR_RADIUS
	if distance_to_threat >= LORD_WEAK_FLEE_CLEAR_RADIUS:
		lord["next_plan_minute"] = 0
		return {"lord": lord, "forced_encounter": {}}

	if lord_position.distance_to(target_position) <= LORD_GROUP_UP_ARRIVAL_RADIUS:
		var next_task := _make_lord_muster_task(lord, 60.0, "The retreat reached a rally point; gather support before moving again.")
		lord["task"] = next_task
		lord["state"] = _state_for_lord_task(String(next_task.get("type", "")))
		lord["next_plan_minute"] = 0
	return {"lord": lord, "forced_encounter": {}}


func _retreat_threat_position(task: Dictionary, player_position: Vector2) -> Vector2:
	var threat_kind := String(task.get("threat_kind", ""))
	if threat_kind == "player":
		return player_position
	if threat_kind == "lord":
		var lord_position := _lord_position_for_name(String(task.get("threat_lord_id", "")))
		if lord_position != Vector2.INF:
			return lord_position
	var raw_position = task.get("threat_pos", Vector2.INF)
	if raw_position is Vector2:
		return Vector2(raw_position)
	return Vector2.INF


func _execute_lord_muster(lord: Dictionary, real_seconds: float) -> Dictionary:
	var task := _lord_task_data(lord)
	var target_position := _live_task_target_position(task, _task_target_position(task, Vector2.INF))
	if target_position == Vector2.INF:
		lord["task"] = _make_lord_task("patrol", 10.0, "No rally point is useful.")
		lord["state"] = "patrol"
		return {"lord": _advance_lord_on_route(lord, real_seconds), "forced_encounter": {}}
	var rally_position := _muster_loiter_position(lord, target_position)

	lord["state"] = "muster"
	GameState.clear_lord_pursuit_state(String(lord.get("name", "")))
	var lord_position := Vector2(lord.get("pos", Vector2.ZERO))
	var at_target := lord_position.distance_to(rally_position) <= LORD_GROUP_UP_ARRIVAL_RADIUS
	var hold_minutes := float(lord.get("hold_minutes", 0.0))
	if hold_minutes > 0.0 and at_target:
		var remaining_hold := maxf(0.0, hold_minutes - real_seconds * GameState.GAME_MINUTES_PER_REAL_SECOND)
		lord["hold_minutes"] = remaining_hold
		if remaining_hold <= 0.0:
			lord["waiting_at"] = ""
			lord["next_plan_minute"] = 0
		return {"lord": lord, "forced_encounter": {}}
	if hold_minutes > 0.0 and not at_target:
		lord["hold_minutes"] = 0.0
		lord["waiting_at"] = ""

	lord = _move_lord_toward(lord, rally_position, real_seconds, 0.88)
	if Vector2(lord.get("pos", Vector2.ZERO)).distance_to(rally_position) <= LORD_GROUP_UP_ARRIVAL_RADIUS:
		var rally_hold := maxf(float(lord.get("hold_minutes", 0.0)), randf_range(75.0, 210.0))
		lord["hold_minutes"] = rally_hold
		lord["waiting_at"] = String(task.get("target_name", "rally point"))
		lord["next_plan_minute"] = GameState.get_game_total_minutes() + randi_range(4, 8)
	return {"lord": lord, "forced_encounter": {}}


func _muster_loiter_position(lord: Dictionary, target_position: Vector2) -> Vector2:
	if target_position == Vector2.INF:
		return Vector2.INF
	var nearby_settlement := get_nearest_settlement(target_position, LORD_ABSORBED_TOWN_RADIUS)
	if not nearby_settlement.is_empty():
		return Vector2(nearby_settlement.get("pos", target_position))

	var angle := _stable_lord_angle(lord)
	for index in range(8):
		var candidate := target_position + Vector2.RIGHT.rotated(angle + TAU * float(index) / 8.0) * LORD_MUSTER_LOITER_RADIUS
		var constrained = constrain_land_position(candidate, target_position)
		if constrained is Vector2 and Vector2(constrained).distance_to(target_position) >= LORD_MUSTER_LOITER_RADIUS * 0.45:
			return Vector2(constrained)
	return target_position


func _stable_lord_angle(lord: Dictionary) -> float:
	var name := String(lord.get("name", "lord"))
	var value := 0
	for index in range(name.length()):
		value = (value * 31 + name.unicode_at(index)) % 360
	return deg_to_rad(float(value))


func _execute_lord_stay_home(lord: Dictionary, real_seconds: float) -> Dictionary:
	var home_position := _lord_home_position(lord)
	var home_name := _lord_home_name(lord)
	if home_position != Vector2.INF and Vector2(lord.get("pos", Vector2.ZERO)).distance_to(home_position) > SETTLEMENT_SAFE_RADIUS:
		lord["state"] = "holding"
		lord = _move_lord_toward(lord, home_position, real_seconds, 0.72)
		return {"lord": lord, "forced_encounter": {}}

	lord["state"] = "holding"
	lord["waiting_at"] = home_name
	if float(lord.get("hold_minutes", 0.0)) <= 0.0:
		lord["hold_minutes"] = _roll_lord_town_hold_minutes(lord, home_name)
	var elapsed_hours := real_seconds * GameState.GAME_MINUTES_PER_REAL_SECOND / 60.0
	lord["fatigue"] = clampf(float(lord.get("fatigue", 0.0)) - 10.0 * elapsed_hours, 0.0, 100.0)
	lord["supplies"] = clampf(float(lord.get("supplies", 100.0)) + 7.0 * elapsed_hours, 0.0, 100.0)
	return {"lord": lord, "forced_encounter": {}}


func _execute_lord_recovery(lord: Dictionary, real_seconds: float) -> Dictionary:
	var home_position := _lord_home_position(lord)
	var home_name := _lord_home_name(lord)
	if home_position != Vector2.INF and Vector2(lord.get("pos", Vector2.ZERO)).distance_to(home_position) > SETTLEMENT_SAFE_RADIUS:
		lord["state"] = "recover"
		lord = _move_lord_toward(lord, home_position, real_seconds, 0.68)
		return {"lord": lord, "forced_encounter": {}}

	lord["state"] = "recover"
	lord["waiting_at"] = home_name
	lord["hold_minutes"] = maxf(float(lord.get("hold_minutes", 0.0)), 60.0)
	var elapsed_hours := real_seconds * GameState.GAME_MINUTES_PER_REAL_SECOND / 60.0
	lord["fatigue"] = clampf(float(lord.get("fatigue", 0.0)) - 18.0 * elapsed_hours, 0.0, 100.0)
	lord["supplies"] = clampf(float(lord.get("supplies", 100.0)) + 16.0 * elapsed_hours, 0.0, 100.0)
	if float(lord.get("fatigue", 0.0)) <= 20.0 and float(lord.get("supplies", 100.0)) >= 76.0 and GameState.get_game_total_minutes() >= int(lord.get("recovery_until_minute", 0)):
		lord["task"] = _make_lord_task("stay_home", 40.0, "Recovery is done; wait for a meaningful order.", home_name, home_position)
		lord["state"] = "holding"
		lord["next_plan_minute"] = 0
	return {"lord": lord, "forced_encounter": {}}


func _move_lord_toward(lord: Dictionary, target_position: Vector2, real_seconds: float, speed_multiplier: float) -> Dictionary:
	if target_position == Vector2.INF or real_seconds <= 0.0:
		return lord
	var pos := Vector2(lord.get("pos", Vector2.ZERO))
	var previous_pos := pos
	var move_target := _road_guided_lord_target(lord, pos, target_position)
	var to_target := move_target - pos
	if to_target.length() <= 0.01:
		return lord
	var step := _lord_campaign_speed(lord) * MAP_SCALE * real_seconds * speed_multiplier
	pos += to_target.normalized() * minf(step, to_target.length())
	lord["pos"] = constrain_land_position(pos, previous_pos)
	lord["hold_minutes"] = 0.0
	lord["waiting_at"] = ""
	return lord


func _road_guided_lord_target(lord: Dictionary, current_position: Vector2, final_target: Vector2) -> Vector2:
	var state := String(lord.get("state", ""))
	if not state in ["pursuing", "search", "retreat", "intercept", "muster", "recover", "holding"]:
		return final_target

	var direct_distance := current_position.distance_to(final_target)
	if direct_distance <= LORD_ROAD_GUIDANCE_MIN_DISTANCE:
		return final_target

	var graph_waypoint := _road_graph_waypoint(current_position, final_target, direct_distance)
	if graph_waypoint != Vector2.INF:
		return graph_waypoint

	return _route_guided_lord_target(lord, current_position, final_target, direct_distance)


func _route_guided_lord_target(lord: Dictionary, current_position: Vector2, final_target: Vector2, current_distance: float) -> Vector2:
	var route: Array = lord.get("route", [])
	if route.size() < 2:
		return final_target

	var best_waypoint := final_target
	var best_score := current_distance
	for raw_waypoint in route:
		if not (raw_waypoint is Vector2):
			continue
		var waypoint := Vector2(raw_waypoint)
		var distance_from_current := current_position.distance_to(waypoint)
		if distance_from_current <= 45.0:
			continue
		var distance_to_target := waypoint.distance_to(final_target)
		var score := distance_from_current * 0.35 + distance_to_target
		if distance_to_target < current_distance * 0.94 and score < best_score:
			best_score = score
			best_waypoint = waypoint
	return best_waypoint


func _task_target_position(task: Dictionary, fallback: Vector2) -> Vector2:
	if task.has("target_pos"):
		var raw_position = task.get("target_pos", fallback)
		if raw_position is Vector2:
			return Vector2(raw_position)
	return fallback


func _live_task_target_position(task: Dictionary, fallback: Vector2) -> Vector2:
	var target_kind := String(task.get("target_kind", ""))
	if target_kind == "lord":
		var lord_id := String(task.get("target_lord_id", ""))
		var lord_position := _lord_position_for_name(lord_id)
		if lord_position != Vector2.INF:
			return lord_position
	return _task_target_position(task, fallback)


func _lord_position_for_name(lord_name: String) -> Vector2:
	if lord_name.is_empty():
		return Vector2.INF
	for lord in _lord_parties:
		if not (lord is Dictionary):
			continue
		var lord_dict := Dictionary(lord)
		if String(lord_dict.get("name", "")) == lord_name and not GameState.is_lord_defeated(lord_name):
			return Vector2(lord_dict.get("pos", Vector2.INF))
	return Vector2.INF


func _lord_knowledge_position(lord: Dictionary) -> Vector2:
	var knowledge := _lord_local_knowledge(lord)
	if float(knowledge.get("confidence", 0.0)) <= 0.0:
		return Vector2.INF
	return Vector2(knowledge.get("position", Vector2.ZERO))


func _set_lord_knowledge(lord: Dictionary, position: Vector2, confidence: float, source: String) -> Dictionary:
	var knowledge := {
		"position": constrain_land_position(position, Vector2(lord.get("pos", position))),
		"confidence": clampf(confidence, 0.0, 100.0),
		"minute": GameState.get_game_total_minutes(),
		"source": source
	}
	lord["local_knowledge"] = knowledge
	lord["last_player_sighting"] = knowledge.duplicate(true)
	return lord


func _remember_lord_event(lord: Dictionary, kind: String, text: String, position: Vector2) -> Dictionary:
	var memory := _normalize_lord_memory(Array(lord.get("memory", [])))
	memory.append({
		"kind": kind,
		"text": text,
		"position": position,
		"minute": GameState.get_game_total_minutes()
	})
	lord["memory"] = _normalize_lord_memory(memory)
	if _is_hostile_lord(lord):
		GameState.record_lord_history_event(String(lord.get("name", "")), kind, {
			"text": text,
			"position": position
		})
	return lord


func _lord_memory_profile(lord: Dictionary) -> Dictionary:
	var profile := {
		"label": "normal",
		"sightings": 0.0,
		"successes": 0.0,
		"failures": 0.0,
		"stay": 0.0,
		"patrol": 0.0,
		"search": 0.0,
		"pursue": 0.0,
		"intercept": 0.0,
		"recover": 0.0
	}

	var current_minute := GameState.get_game_total_minutes()
	var memory_span := LORD_MEMORY_EFFECT_DAYS * 24.0 * 60.0
	for raw_entry in _normalize_lord_memory(Array(lord.get("memory", []))):
		var entry := Dictionary(raw_entry)
		var kind := String(entry.get("kind", ""))
		var age_minutes := maxf(0.0, float(current_minute - int(entry.get("minute", current_minute))))
		var weight := clampf(1.0 - age_minutes / memory_span, 0.15, 1.0)
		match kind:
			"sighting":
				profile["sightings"] = float(profile.get("sightings", 0.0)) + weight
				profile["search"] = float(profile.get("search", 0.0)) + 3.0 * weight
				profile["pursue"] = float(profile.get("pursue", 0.0)) + 2.0 * weight
			"caught_player":
				profile["successes"] = float(profile.get("successes", 0.0)) + weight
				profile["search"] = float(profile.get("search", 0.0)) + 4.0 * weight
				profile["pursue"] = float(profile.get("pursue", 0.0)) + 9.0 * weight
			"lost_trail", "safe_escape", "cold_search":
				profile["failures"] = float(profile.get("failures", 0.0)) + weight
				profile["stay"] = float(profile.get("stay", 0.0)) + 2.0 * weight
				profile["search"] = float(profile.get("search", 0.0)) + 2.0 * weight
				profile["pursue"] = float(profile.get("pursue", 0.0)) - 8.0 * weight
				profile["intercept"] = float(profile.get("intercept", 0.0)) + 7.0 * weight
				profile["recover"] = float(profile.get("recover", 0.0)) + 2.0 * weight

	var failures := float(profile.get("failures", 0.0))
	var successes := float(profile.get("successes", 0.0))
	if failures >= 1.5 and failures > successes:
		profile["label"] = "cagey"
		profile["pursue"] = float(profile.get("pursue", 0.0)) - 6.0
		profile["intercept"] = float(profile.get("intercept", 0.0)) + 8.0
	elif successes >= 0.75:
		profile["label"] = "emboldened"
		profile["pursue"] = float(profile.get("pursue", 0.0)) + 4.0
	elif float(profile.get("sightings", 0.0)) >= 1.5:
		profile["label"] = "alert"
		profile["search"] = float(profile.get("search", 0.0)) + 5.0

	return profile


func _memory_reason(memory_profile: Dictionary) -> String:
	match String(memory_profile.get("label", "normal")):
		"cagey":
			return "Past failures make him favor roadblocks over blind pursuit."
		"emboldened":
			return "Past success makes him quicker to press the chase."
		"alert":
			return "Repeated reports keep his men alert."
		_:
			return ""


func _lord_legacy_profile(lord: Dictionary) -> Dictionary:
	var history := GameState.get_lord_history(String(lord.get("name", "")))
	var rank := String(history.get("rank", "unknown"))
	var grudge := float(history.get("grudge", 0.0))
	var respect := float(history.get("respect", 0.0))
	var fear := float(history.get("fear", 0.0))
	var confidence := float(history.get("confidence", 0.0))
	var nemesis_score := float(history.get("nemesis_score", 0.0))
	var profile := {
		"label": rank,
		"nemesis_score": nemesis_score,
		"grudge": grudge,
		"respect": respect,
		"fear": fear,
		"confidence": confidence,
		"stay": fear * 0.10 - grudge * 0.04,
		"patrol": confidence * 0.04,
		"search": grudge * 0.05 + respect * 0.04 + confidence * 0.04,
		"pursue": grudge * 0.08 + confidence * 0.08 - fear * 0.12,
		"intercept": grudge * 0.08 + respect * 0.05 + fear * 0.08,
		"recover": fear * 0.04,
		"detection_bonus": clampf(nemesis_score * 0.45 + confidence * 0.35 - fear * 0.15, 0.0, 85.0),
		"rumor_bonus": clampf(grudge * 0.70 + respect * 0.20, 0.0, 120.0),
		"confidence_decay_multiplier": clampf(1.0 - confidence * 0.004 + fear * 0.003, 0.70, 1.24)
	}

	match rank:
		"nemesis":
			profile["stay"] = float(profile.get("stay", 0.0)) - 10.0
			profile["patrol"] = float(profile.get("patrol", 0.0)) - 3.0
			profile["search"] = float(profile.get("search", 0.0)) + 9.0
			profile["pursue"] = float(profile.get("pursue", 0.0)) + 10.0
			profile["intercept"] = float(profile.get("intercept", 0.0)) + 6.0
			profile["confidence_decay_multiplier"] = minf(float(profile.get("confidence_decay_multiplier", 1.0)), 0.72)
			profile["detection_bonus"] = float(profile.get("detection_bonus", 0.0)) + 35.0
			profile["rumor_bonus"] = float(profile.get("rumor_bonus", 0.0)) + 60.0
		"rival":
			profile["stay"] = float(profile.get("stay", 0.0)) - 2.0
			profile["patrol"] = float(profile.get("patrol", 0.0)) + 2.0
			profile["search"] = float(profile.get("search", 0.0)) + 4.0
			profile["pursue"] = float(profile.get("pursue", 0.0)) + 2.0
			profile["intercept"] = float(profile.get("intercept", 0.0)) + 4.0
			profile["confidence_decay_multiplier"] = minf(float(profile.get("confidence_decay_multiplier", 1.0)), 0.88)
		"haunted":
			profile["stay"] = float(profile.get("stay", 0.0)) + 12.0
			profile["search"] = float(profile.get("search", 0.0)) + 4.0
			profile["pursue"] = float(profile.get("pursue", 0.0)) - 16.0
			profile["intercept"] = float(profile.get("intercept", 0.0)) + 10.0
			profile["recover"] = float(profile.get("recover", 0.0)) + 8.0
			profile["confidence_decay_multiplier"] = maxf(float(profile.get("confidence_decay_multiplier", 1.0)), 1.12)
			profile["detection_bonus"] = float(profile.get("detection_bonus", 0.0)) + 15.0
		"watchful":
			profile["patrol"] = float(profile.get("patrol", 0.0)) + 1.0
			profile["search"] = float(profile.get("search", 0.0)) + 1.0

	return profile


func _legacy_reason(legacy_profile: Dictionary) -> String:
	match String(legacy_profile.get("label", "unknown")):
		"nemesis":
			return "Old hatred makes this personal."
		"rival":
			return "Past encounters make him read the player band's road more closely."
		"haunted":
			return "Past defeats make him cautious, but not blind."
		"watchful":
			return "He remembers enough to stay alert."
		_:
			return ""


func _lord_history_confidence_decay_multiplier(lord: Dictionary) -> float:
	return float(_lord_legacy_profile(lord).get("confidence_decay_multiplier", 1.0))


func _next_search_position(lord: Dictionary, search_center: Vector2) -> Vector2:
	var route: Array = lord.get("route", [])
	if route.size() >= 2:
		var best_index := 0
		var best_distance := INF
		for index in range(route.size()):
			var route_point := Vector2(route[index])
			var distance := route_point.distance_to(search_center)
			if distance < best_distance:
				best_distance = distance
				best_index = index
		return Vector2(route[(best_index + 1) % route.size()])

	var nearest := get_nearest_settlement(search_center, 260.0)
	if not nearest.is_empty():
		return Vector2(nearest.get("pos", search_center))
	return constrain_land_position(search_center + Vector2(randf_range(-LORD_SEARCH_RADIUS, LORD_SEARCH_RADIUS), randf_range(-LORD_SEARCH_RADIUS, LORD_SEARCH_RADIUS)), search_center)


func _likely_player_destination_name(lord: Dictionary, strategy: Dictionary = {}, coordination: Dictionary = {}) -> String:
	var coordination_destination := String(coordination.get("destination", ""))
	if not coordination_destination.is_empty():
		return coordination_destination
	var strategy_destination := String(strategy.get("destination", ""))
	if not strategy_destination.is_empty():
		return strategy_destination
	var faction := String(lord.get("faction", ""))
	if GameState.get_party_men_count() >= GameState.get_objective_target_men():
		return "Ziklag"
	if faction == "Philistine Lords":
		return "Ziklag"
	if faction == "Edomite Retinue":
		return "Nob"
	if faction == "House of Saul":
		return "Bethlehem"
	return _lord_home_name(lord)


func _lord_home_position(lord: Dictionary) -> Vector2:
	return _position_for_named_settlement(_lord_home_name(lord), Vector2.INF)


func _is_lord_near_home(lord: Dictionary) -> bool:
	var home_position := _lord_home_position(lord)
	return home_position != Vector2.INF and Vector2(lord.get("pos", Vector2.ZERO)).distance_to(home_position) <= SETTLEMENT_SAFE_RADIUS


func _lord_detection_radius(lord: Dictionary) -> float:
	var radius := LORD_BASE_DETECTION_RADIUS
	if String(lord.get("name", "")) == ABNER_NAME:
		radius = maxf(radius, ABNER_DETECTION_RADIUS)
	radius += float(int(lord.get("intelligence", 0))) * 3.0
	radius += float(GameState.heat) * 2.4
	if String(lord.get("role", "")) == "informer":
		radius += 70.0
	if String(lord.get("state", "")) in ["pursuing", "search"]:
		radius += 75.0
	radius += float(_lord_legacy_profile(lord).get("detection_bonus", 0.0))
	return clampf(radius, 280.0, 700.0)


func _lord_rumor_radius(lord: Dictionary) -> float:
	var radius := LORD_RUMOR_RADIUS + float(GameState.heat) * 5.0
	if String(lord.get("role", "")) == "informer":
		radius += 180.0
	if String(lord.get("faction", "")) == "House of Saul":
		radius += 100.0
	radius += float(_lord_legacy_profile(lord).get("rumor_bonus", 0.0))
	return radius


func _lord_escape_radius(lord: Dictionary) -> float:
	return maxf(ABNER_ESCAPE_RADIUS, _lord_detection_radius(lord) * 1.55)


func _calculate_overworld_pressure(world_position: Vector2) -> float:
	var score := float(GameState.heat) * 0.45
	for lord in _lord_parties:
		if not _is_hostile_lord(lord):
			continue
		var distance := Vector2(lord.get("pos", Vector2.ZERO)).distance_to(world_position)
		var proximity := clampf((_lord_rumor_radius(lord) - distance) / maxf(1.0, _lord_rumor_radius(lord)), 0.0, 1.0)
		score += proximity * 18.0
		score += _lord_knowledge_confidence(lord) * 0.22
		match String(lord.get("state", "")):
			"pursuing":
				if _lord_task_targets_player(lord):
					score += 22.0
			"search":
				score += 10.0
			"intercept":
				score += 6.0
	return clampf(score, 0.0, 100.0)


func _overworld_ai_director() -> Dictionary:
	var raw_director = GameState.map_state.get("overworld_ai", {})
	var director: Dictionary = {}
	if raw_director is Dictionary:
		director = Dictionary(raw_director).duplicate(true)
	director["pressure_score"] = float(director.get("pressure_score", 0.0))
	director["next_strategy_minute"] = int(director.get("next_strategy_minute", GameState.get_game_total_minutes()))
	director["pressure_relief_until_minute"] = int(director.get("pressure_relief_until_minute", 0))
	director["last_direct_sighting_minute"] = int(director.get("last_direct_sighting_minute", -1))
	return director


func _update_campaign_director(current_minute: int, pressure_score: float) -> void:
	var director := _overworld_ai_director()
	director["pressure_score"] = pressure_score
	if current_minute >= int(director.get("next_strategy_minute", current_minute)):
		director["next_strategy_minute"] = current_minute + OVERWORLD_AI_STRATEGY_INTERVAL_MINUTES
		if pressure_score < 35.0 and current_minute > int(director.get("pressure_relief_until_minute", 0)):
			director["pressure_relief_until_minute"] = 0
	GameState.map_state["overworld_ai"] = director


func _set_director_relief(until_minute: int) -> void:
	var director := _overworld_ai_director()
	director["pressure_relief_until_minute"] = maxi(int(director.get("pressure_relief_until_minute", 0)), until_minute)
	GameState.map_state["overworld_ai"] = director


func _mark_direct_sighting(current_minute: int) -> void:
	var director := _overworld_ai_director()
	director["last_direct_sighting_minute"] = current_minute
	GameState.map_state["overworld_ai"] = director


func _initial_lord_hold_minutes(lord: Dictionary) -> float:
	var start_name := String(lord.get("start_name", ""))
	var hold_minutes := _roll_lord_town_hold_minutes(lord, start_name)
	if hold_minutes <= 0.0:
		return 0.0
	return hold_minutes * randf_range(LORD_INITIAL_DWELL_MIN_RATIO, LORD_INITIAL_DWELL_MAX_RATIO)


func _roll_lord_town_hold_minutes(lord: Dictionary, settlement_name: String) -> float:
	if settlement_name.is_empty():
		return 0.0

	var dwell_window := LORD_ACTIVE_DWELL_MINUTES if _lord_has_task(lord) else LORD_IDLE_DWELL_MINUTES
	var hold_minutes := randf_range(dwell_window.x, dwell_window.y)
	hold_minutes *= _lord_task_dwell_multiplier(lord)
	if settlement_name == _lord_home_name(lord):
		hold_minutes *= LORD_HOME_DWELL_MULTIPLIER
	hold_minutes += _lord_party_supply_dwell_bonus(lord)
	return maxf(15.0, hold_minutes)


func _lord_party_supply_dwell_bonus(lord: Dictionary) -> float:
	var party_size := maxf(0.0, float(int(lord.get("party_size", 0))))
	var party_ratio := clampf(party_size / LORD_SIZE_SPEED_PENALTY_MEN, 0.0, 1.0)
	return party_ratio * LORD_LARGE_PARTY_DWELL_MINUTES


func _lord_task_dwell_multiplier(lord: Dictionary) -> float:
	var task := _lord_task_type(lord)
	if task.is_empty() or task == "none" or task == "idle":
		return 1.0
	if task == "stay_home" or task == "recover":
		return 1.0
	if task.contains("hunt") or task.contains("pursue"):
		return 0.35
	if task.contains("scout"):
		return 0.55
	if task.contains("patrol"):
		return 0.62
	if task.contains("errand") or task.contains("message"):
		return 0.78
	if task.contains("trade") or task.contains("supply"):
		return 1.10
	return 0.85


func _lord_has_task(lord: Dictionary) -> bool:
	var task := _lord_task_type(lord)
	return not task.is_empty() and task != "none" and task != "idle" and task != "stay_home" and task != "recover"


func _lord_home_name(lord: Dictionary) -> String:
	return String(lord.get("home_name", lord.get("start_name", "")))


func _settlement_name_at_position(position: Vector2, radius: float = 86.0) -> String:
	var best_name := ""
	var best_distance := radius
	for settlement in _settlements_for_gameplay():
		var settlement_dict := Dictionary(settlement)
		var settlement_position := _map_position_from_entry(settlement_dict)
		var distance := position.distance_to(settlement_position)
		if distance <= best_distance:
			best_distance = distance
			best_name = String(settlement_dict.get("name", ""))
	return best_name


func _is_lord_pursuing(lord: Dictionary) -> bool:
	var name := String(lord.get("name", ""))
	return String(lord.get("state", "")) == "pursuing" or String(GameState.get_lord_pursuit_state(name).get("state", "")) == "pursuing"


func _is_lord_pursuing_player(lord: Dictionary) -> bool:
	var name := String(lord.get("name", ""))
	return String(GameState.get_lord_pursuit_state(name).get("state", "")) == "pursuing" or (String(lord.get("state", "")) == "pursuing" and _lord_task_targets_player(lord))


func _lord_task_targets_player(lord: Dictionary) -> bool:
	var task := _lord_task_data(lord)
	if String(task.get("type", "")) != "pursue":
		return false
	var target_kind := String(task.get("target_kind", "player"))
	return target_kind.is_empty() or target_kind == "player"


func _is_hostile_lord(lord: Dictionary) -> bool:
	var faction := String(lord.get("faction", ""))
	return faction == "House of Saul" or faction == "Philistine Lords" or faction == "Edomite Retinue"


func _is_player_friendly_lord(lord: Dictionary) -> bool:
	var faction := String(lord.get("faction", ""))
	var role := String(lord.get("role", ""))
	return faction == "David's Band" or faction == "Judah" or role == "ally"


func _is_strategic_war_target(target: Dictionary) -> bool:
	if String(target.get("kind", "")) == "player":
		return true
	if bool(target.get("is_faction_leader", false)):
		return true
	var role := String(target.get("role", ""))
	var title := String(target.get("title", "")).to_lower()
	if role in ["king", "faction_leader", "marshal", "border_lord"]:
		return true
	return title.contains("king") or title.contains("commander") or title.contains("seren")


func _is_faction_leader_lord(lord: Dictionary) -> bool:
	var role := String(lord.get("role", ""))
	var title := String(lord.get("title", "")).to_lower()
	if String(lord.get("name", "")) == ABNER_NAME:
		return true
	if role in ["king", "faction_leader", "marshal", "border_lord"]:
		return true
	return title.contains("king") or title.contains("commander") or title.contains("seren")


func _factions_are_allied(faction: String, other_faction: String) -> bool:
	if faction.is_empty() or other_faction.is_empty():
		return false
	if faction == other_faction:
		return true
	if (faction == "House of Saul" and other_faction == "Edomite Retinue") or (faction == "Edomite Retinue" and other_faction == "House of Saul"):
		return true
	if (faction == "David's Band" and other_faction == "Judah") or (faction == "Judah" and other_faction == "David's Band"):
		return true
	return false


func _factions_are_at_war(faction: String, other_faction: String) -> bool:
	if faction.is_empty() or other_faction.is_empty() or _factions_are_allied(faction, other_faction):
		return false
	if faction == "Jebus" or other_faction == "Jebus":
		return false
	var davidic := ["David's Band", "Judah"]
	var saulide := ["House of Saul", "Edomite Retinue"]
	if faction in davidic and other_faction in saulide:
		return true
	if faction in saulide and other_faction in davidic:
		return true
	if faction == "Philistine Lords" and (other_faction in davidic or other_faction in saulide):
		return true
	if other_faction == "Philistine Lords" and (faction in davidic or faction in saulide):
		return true
	return false


func _lords_are_at_war(lord: Dictionary, other_lord: Dictionary) -> bool:
	if int(lord.get("party_size", 0)) <= 0 or int(other_lord.get("party_size", 0)) <= 0:
		return false
	return _factions_are_at_war(String(lord.get("faction", "")), String(other_lord.get("faction", "")))


func _lord_can_join_common_enemy_fight(lord: Dictionary, target_lord: Dictionary) -> bool:
	if not _is_player_friendly_lord(lord) or not _is_hostile_lord(target_lord):
		return false
	if int(lord.get("party_size", 0)) <= 0:
		return false
	if float(lord.get("supplies", 100.0)) <= 6.0:
		return false
	if String(lord.get("state", "")) == "recover" and float(lord.get("fatigue", 0.0)) >= 92.0:
		return false
	return true


func _abner_detection_radius() -> float:
	return ABNER_DETECTION_RADIUS + float(GameState.heat) * 2.5


func _lord_campaign_speed(lord: Dictionary) -> float:
	var base_speed := float(lord.get("speed", 40.0))
	return base_speed * LORD_CAMPAIGN_SPEED_MULTIPLIER * _lord_party_size_speed_multiplier(lord) * _lord_intelligence_speed_multiplier(lord)


func _lord_party_size_speed_multiplier(lord: Dictionary) -> float:
	var party_size := maxf(0.0, float(int(lord.get("party_size", 0))))
	var penalty_ratio := clampf(party_size / LORD_SIZE_SPEED_PENALTY_MEN, 0.0, 1.0)
	return 1.0 - LORD_SIZE_SPEED_PENALTY_MAX * penalty_ratio


func _lord_intelligence_speed_multiplier(lord: Dictionary) -> float:
	var intelligence := maxf(0.0, float(int(lord.get("intelligence", 0))))
	var bonus_ratio := clampf(intelligence / LORD_INTELLIGENCE_SPEED_BONUS_STAT, 0.0, 1.0)
	return 1.0 + LORD_INTELLIGENCE_SPEED_BONUS_MAX * bonus_ratio


func _direction_text(offset: Vector2) -> String:
	if offset.length() <= 0.01:
		return "here"
	var horizontal := "east" if offset.x > 0.0 else "west"
	var vertical := "south" if offset.y > 0.0 else "north"
	if absf(offset.x) > absf(offset.y) * 1.6:
		return horizontal
	if absf(offset.y) > absf(offset.x) * 1.6:
		return vertical
	return "%s-%s" % [vertical, horizontal]


func _scaled_route(route: Array) -> Array:
	var scaled: Array = []
	for point in route:
		scaled.append(_scaled_point(point))
	return scaled


func _target_from_entry(entry: Dictionary, target_type: String) -> Dictionary:
	var target: Dictionary = entry.duplicate()
	target["pos"] = _map_position_from_entry(entry)
	target["type"] = target_type
	return target


func _target_from_lord(lord: Dictionary) -> Dictionary:
	var target: Dictionary = lord.duplicate(true)
	target["type"] = "lord"
	target["lord_id"] = String(lord.get("name", ""))
	return target


func _effective_npc_render_radius() -> float:
	return NPC_RENDER_RADIUS_BASE * (camera_zoom / NPC_ZOOM_REFERENCE)


func _effective_npc_fade_band() -> float:
	return NPC_FADE_BAND_BASE * (camera_zoom / NPC_ZOOM_REFERENCE)


func _npc_distance_alpha(distance: float) -> float:
	var radius := _effective_npc_render_radius()
	var band := _effective_npc_fade_band()
	var fade_start := radius - band
	if distance <= fade_start:
		return 1.0
	return clampf(1.0 - (distance - fade_start) / band, 0.0, 1.0)


func _ui_scale() -> float:
	return clampf(NPC_ZOOM_REFERENCE / camera_zoom, 1.0, 5.0)
