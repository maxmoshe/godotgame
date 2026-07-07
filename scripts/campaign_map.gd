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
			"last_seen_minute": int(knowledge.get("minute", -1))
		})
	facts.sort_custom(Callable(self, "_compare_rumor_facts"))
	return facts


func get_ai_debug_snapshot() -> Dictionary:
	var lord_snapshots: Array[Dictionary] = []
	for lord in _lord_parties:
		var knowledge := _lord_local_knowledge(lord)
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
			"memory": Array(lord.get("memory", [])).duplicate(true)
		})
	return {
		"minute": GameState.get_game_total_minutes(),
		"director": Dictionary(GameState.map_state.get("overworld_ai", {})).duplicate(true),
		"lords": lord_snapshots
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
			best = _target_from_entry(settlement, "settlement")
			best_distance = distance

	return best


func get_click_target(world_position: Vector2, radius: float = 42.0) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := radius

	for lord in _lord_parties:
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
			return _target_from_lord(lord)
	return {}


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


func _draw_frame() -> void:
	draw_rect(MAP_RECT, Color("#5c4328"), false, 10.0)
	draw_rect(MAP_RECT.grow(-18.0), Color(0.22, 0.13, 0.06, 0.28), false, 2.0)


func _draw_threat_circles() -> void:
	for lord in _lord_parties:
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
		"intercept":
			return 2.0
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
	knowledge["confidence"] = maxf(0.0, float(knowledge.get("confidence", 0.0)) - LORD_CONFIDENCE_DECAY_PER_HOUR * hours * decay_multiplier)
	lord["local_knowledge"] = knowledge

	var fatigue := float(lord.get("fatigue", 0.0))
	var supplies := float(lord.get("supplies", 100.0))
	match state:
		"pursuing":
			fatigue += 18.0 * hours
			supplies -= 5.5 * hours
		"search", "intercept":
			fatigue += 10.0 * hours
			supplies -= 3.5 * hours
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
	if not _is_hostile_lord(lord):
		return lord

	var current_minute := GameState.get_game_total_minutes()
	var lord_position := Vector2(lord.get("pos", Vector2.ZERO))
	var distance := lord_position.distance_to(player_position)
	var knowledge := _lord_local_knowledge(lord)

	if player_is_safe:
		var last_safe_minute := int(lord.get("last_safe_confidence_minute", -99999))
		if current_minute - last_safe_minute >= OVERWORLD_AI_PLAN_INTERVAL_MINUTES:
			lord["last_safe_confidence_minute"] = current_minute
			knowledge["confidence"] = maxf(0.0, float(knowledge.get("confidence", 0.0)) - LORD_SAFE_PLACE_CONFIDENCE_LOSS)
			knowledge["source"] = "walls and narrow streets"
			lord["local_knowledge"] = knowledge
			if _is_lord_pursuing(lord):
				GameState.clear_lord_pursuit_state(String(lord.get("name", "")))
				lord["state"] = "search" if float(knowledge.get("confidence", 0.0)) >= LORD_SEARCH_CONFIDENCE_MIN else "recover"
				lord["next_plan_minute"] = 0
				_set_director_relief(current_minute + OVERWORLD_AI_RELIEF_AFTER_ESCAPE_MINUTES)
				notices.append("%s loses your trail among walls, gates, and conflicting witnesses." % String(lord.get("name", "A lord")))
		return lord

	if distance <= _lord_detection_radius(lord):
		if _director_allows_hunt(lord, pressure_score, true, distance):
			var was_pursuing := _is_lord_pursuing(lord)
			lord = _set_lord_knowledge(lord, player_position, LORD_DIRECT_SIGHT_CONFIDENCE, "direct sighting")
			lord["task"] = _make_lord_task("pursue", 100.0, "The party has been seen directly.", "", player_position, LORD_DIRECT_SIGHT_CONFIDENCE)
			lord["state"] = "pursuing"
			lord["hold_minutes"] = 0.0
			lord["waiting_at"] = ""
			lord["next_plan_minute"] = current_minute + randi_range(4, 8)
			GameState.set_lord_pursuit_state(String(lord.get("name", "")), {
				"state": "pursuing",
				"started_minute": current_minute,
				"confidence": LORD_DIRECT_SIGHT_CONFIDENCE
			})
			_mark_direct_sighting(current_minute)
			if not was_pursuing:
				GameState.adjust_morale(-2)
				lord = _remember_lord_event(lord, "sighting", "Saw David's band on the road.", player_position)
				notices.append("%s has seen your trail and turns toward you." % String(lord.get("name", "A hostile lord")))
		else:
			lord = _set_lord_knowledge(lord, player_position, maxf(float(knowledge.get("confidence", 0.0)), LORD_RUMOR_CONFIDENCE), "blocked by pressure")
			lord["next_plan_minute"] = 0
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


func _director_allows_hunt(lord: Dictionary, pressure_score: float, direct_sight: bool, distance: float) -> bool:
	if not _is_hostile_lord(lord):
		return false
	if _is_lord_pursuing(lord):
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
		if String(lord.get("state", "")) == "pursuing" or String(GameState.get_lord_pursuit_state(lord_name).get("state", "")) == "pursuing":
			count += 1
	return count


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
	candidates.append(_make_lord_task("stay_home", stay_score, "No urgent order is worth leaving the town for.", _lord_home_name(lord), _lord_home_position(lord), confidence))

	var patrol_score := 24.0 - fatigue * 0.20 - maxf(0.0, 45.0 - supplies) * 0.35
	if standing_order in ["patrol", "errand", "scout"]:
		patrol_score += 34.0
	if hostile:
		patrol_score += float(GameState.heat) * 0.24 + ambition * 0.10
	candidates.append(_make_lord_task("patrol", patrol_score, "The standing route still matters.", "", Vector2.INF, confidence))

	var recover_score := fatigue * 0.75 + maxf(0.0, 100.0 - supplies) * 0.65
	if current_minute < int(lord.get("recovery_until_minute", 0)):
		recover_score += 90.0
	if fatigue >= LORD_RECOVER_FATIGUE_THRESHOLD or supplies <= LORD_RESUPPLY_THRESHOLD:
		recover_score += 28.0
	candidates.append(_make_lord_task("recover", recover_score, "Men, animals, and supplies need rest.", _lord_home_name(lord), _lord_home_position(lord), confidence))

	var knowledge_position := _lord_knowledge_position(lord)
	var search_score := -INF
	if hostile and confidence >= LORD_SEARCH_CONFIDENCE_MIN and knowledge_position != Vector2.INF:
		search_score = confidence * 0.78 + float(GameState.heat) * 0.25 + ambition * 0.16 - caution * 0.10
		if player_is_safe:
			search_score -= 30.0
	candidates.append(_make_lord_task("search", search_score, "Reports point to a road or town worth searching.", "", knowledge_position, confidence))

	var pursue_score := -INF
	if hostile and confidence >= LORD_PURSUIT_CONFIDENCE_MIN and not player_is_safe and _director_allows_hunt(lord, pressure_score, false, Vector2(lord.get("pos", Vector2.ZERO)).distance_to(player_position)):
		pursue_score = confidence * 1.10 + boldness * 0.35 + loyalty * 0.16 + float(GameState.heat) * 0.25 - caution * 0.18
	candidates.append(_make_lord_task("pursue", pursue_score, "The trail is fresh enough to risk a hard chase.", "", knowledge_position, confidence))

	var intercept_score := -INF
	var intercept_name := _likely_player_destination_name(lord)
	var intercept_position := _position_for_named_settlement(intercept_name, Vector2.INF)
	if hostile and GameState.heat >= 20 and intercept_position != Vector2.INF:
		intercept_score = float(GameState.heat) * 0.62 + ambition * 0.18 + boldness * 0.12 - fatigue * 0.22
		if confidence >= LORD_PURSUIT_CONFIDENCE_MIN:
			intercept_score -= 20.0
	candidates.append(_make_lord_task("intercept", intercept_score, "If David is not visible, cover the place he is likely to need.", intercept_name, intercept_position, confidence))

	return candidates


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


func _state_for_lord_task(task_type: String) -> String:
	match task_type:
		"pursue":
			return "pursuing"
		"search":
			return "search"
		"intercept":
			return "intercept"
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
		"intercept":
			return _execute_lord_intercept(lord, real_seconds)
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
	if player_is_safe:
		return _break_lord_pursuit_to_search(lord, notices, "safe walls")

	var knowledge := _lord_local_knowledge(lord)
	var confidence := float(knowledge.get("confidence", 0.0))
	if confidence < LORD_PURSUIT_CONFIDENCE_MIN:
		return _break_lord_pursuit_to_search(lord, notices, "a fading trail")

	var target_position := _task_target_position(_lord_task_data(lord), Vector2(knowledge.get("position", player_position)))
	lord["state"] = "pursuing"
	lord["hold_minutes"] = 0.0
	lord["waiting_at"] = ""
	GameState.set_lord_pursuit_state(String(lord.get("name", "")), {
		"state": "pursuing",
		"started_minute": int(GameState.get_lord_pursuit_state(String(lord.get("name", ""))).get("started_minute", GameState.get_game_total_minutes())),
		"confidence": confidence
	})
	lord = _move_lord_toward(lord, target_position, real_seconds, LORD_PURSUIT_SPEED_MULTIPLIER)

	var lord_position := Vector2(lord.get("pos", Vector2.ZERO))
	if lord_position.distance_to(player_position) <= LORD_CATCH_RADIUS:
		var caught := _target_from_lord(lord)
		caught["forced"] = true
		caught["dialogue"] = "%s's riders close the last stretch at a hard pace. There is no more room to pretend this is only dust on the road." % String(lord.get("name", "The hostile lord"))
		lord = _remember_lord_event(lord, "caught_player", "Caught David's band on the road.", player_position)
		return {"lord": lord, "forced_encounter": caught}

	if lord_position.distance_to(player_position) > _lord_escape_radius(lord) and confidence < LORD_DIRECT_SIGHT_CONFIDENCE * 0.72:
		return _break_lord_pursuit_to_search(lord, notices, "too much distance")
	return {"lord": lord, "forced_encounter": {}}


func _break_lord_pursuit_to_search(lord: Dictionary, notices: Array[String], reason: String) -> Dictionary:
	GameState.clear_lord_pursuit_state(String(lord.get("name", "")))
	var knowledge := _lord_local_knowledge(lord)
	var confidence := maxf(0.0, float(knowledge.get("confidence", 0.0)) - 12.0)
	knowledge["confidence"] = confidence
	lord["local_knowledge"] = knowledge
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
	var to_target := target_position - pos
	if to_target.length() <= 0.01:
		return lord
	var step := _lord_campaign_speed(lord) * MAP_SCALE * real_seconds * speed_multiplier
	pos += to_target.normalized() * minf(step, to_target.length())
	lord["pos"] = constrain_land_position(pos, previous_pos)
	lord["hold_minutes"] = 0.0
	lord["waiting_at"] = ""
	return lord


func _task_target_position(task: Dictionary, fallback: Vector2) -> Vector2:
	if task.has("target_pos"):
		var raw_position = task.get("target_pos", fallback)
		if raw_position is Vector2:
			return Vector2(raw_position)
	return fallback


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
	return lord


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


func _likely_player_destination_name(lord: Dictionary) -> String:
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
	return clampf(radius, 280.0, 700.0)


func _lord_rumor_radius(lord: Dictionary) -> float:
	var radius := LORD_RUMOR_RADIUS + float(GameState.heat) * 5.0
	if String(lord.get("role", "")) == "informer":
		radius += 180.0
	if String(lord.get("faction", "")) == "House of Saul":
		radius += 100.0
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


func _is_hostile_lord(lord: Dictionary) -> bool:
	var faction := String(lord.get("faction", ""))
	return faction == "House of Saul" or faction == "Philistine Lords" or faction == "Edomite Retinue"


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
