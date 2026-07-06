extends Node2D

const MAP_SCALE := 3.0
const BASE_MAP_RECT := Rect2(Vector2(-900.0, -1250.0), Vector2(1800.0, 2500.0))
const MAP_RECT := Rect2(BASE_MAP_RECT.position * MAP_SCALE, BASE_MAP_RECT.size * MAP_SCALE)
const MAP_DATA_ROOT := "res://data/maps/southern_levant"
const MAP_MANIFEST_PATH := "res://data/maps/southern_levant/map_manifest.json"
const PAINTED_MAP_PLATE_PATH := "res://assets/map/base/southern_levant_painted_reference_plate_v1.png"
const ABNER_NAME := "Abner ben Ner"
const ABNER_DETECTION_RADIUS := 520.0
const ABNER_ESCAPE_RADIUS := 760.0
const ABNER_CATCH_RADIUS := 42.0
const ABNER_PURSUIT_SPEED_MULTIPLIER := 1.38
const ABNER_PRESSURE_ENABLED := false
const NPC_RENDER_RADIUS_BASE := 900.0
const NPC_FADE_BAND_BASE := 200.0
const NPC_ZOOM_REFERENCE := 0.82
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
		"route": [Vector2(42, -172), Vector2(92, -55), Vector2(88, -562), Vector2(235, -1045), Vector2(42, -172)],
		"route_names": ["Gibeah", "Nob", "Shiloh", "Gilboa", "Gibeah"],
		"speed": 48.0,
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
		"route": [Vector2(28, 258), Vector2(-8, 630), Vector2(-265, 820), Vector2(338, 545), Vector2(-168, 390), Vector2(28, 258)],
		"route_names": ["Bethlehem", "Hebron", "Ziklag", "En-gedi", "Keilah", "Bethlehem"],
		"speed": 55.0,
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
		"route": [Vector2(-448, 182), Vector2(-590, 515), Vector2(-585, 895), Vector2(-448, 182), Vector2(-230, 235)],
		"route_names": ["Gath", "Ashkelon", "Gaza", "Gath", "Socoh"],
		"speed": 38.0,
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
		"route": [Vector2(92, -55), Vector2(42, -172), Vector2(-25, -260), Vector2(92, -55), Vector2(102, 58)],
		"route_names": ["Nob", "Gibeah", "Ramah", "Nob", "Jebus"],
		"speed": 43.0,
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
		"route": [Vector2(102, 58), Vector2(338, 545), Vector2(28, 258), Vector2(102, 58)],
		"route_names": ["Jebus", "En-gedi", "Bethlehem", "Jebus"],
		"speed": 34.0,
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
var _settlement_entries: Array[Dictionary] = []
var _painted_map_plate: Texture2D
var _data_loaded := false
var player_position := Vector2.ZERO
var camera_zoom := 0.82


func _ready() -> void:
	_font = ThemeDB.fallback_font
	_load_painted_map_plate()
	_load_map_dataset()
	_initialize_lord_parties()
	_restore_lord_parties_from_game_state()
	if not ABNER_PRESSURE_ENABLED:
		GameState.clear_lord_pursuit_state(ABNER_NAME)
	queue_redraw()


func get_playable_rect() -> Rect2:
	return MAP_RECT.grow(-38.0)


func advance_lord_parties_for_real_seconds(real_seconds: float) -> void:
	_advance_lord_parties(real_seconds)


func update_lord_pressure(real_seconds: float, player_position: Vector2, player_is_safe: bool) -> Dictionary:
	if _lord_parties.is_empty() or real_seconds <= 0.0:
		return {}

	var caught_target: Dictionary = {}
	for index in range(_lord_parties.size()):
		var lord: Dictionary = _lord_parties[index]
		if String(lord.get("name", "")) == ABNER_NAME:
			if ABNER_PRESSURE_ENABLED:
				var result := _advance_abner_pressure(lord, real_seconds, player_position, player_is_safe)
				lord = result["lord"]
				var caught = result["caught"]
				if caught is Dictionary and not Dictionary(caught).is_empty():
					caught_target = Dictionary(caught)
			else:
				GameState.clear_lord_pursuit_state(ABNER_NAME)
				lord = _advance_lord_on_route(lord, real_seconds)
		else:
			lord = _advance_lord_on_route(lord, real_seconds)
		_lord_parties[index] = lord

	queue_redraw()
	return caught_target


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
	return best


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
			"pos": lord.get("pos", Vector2.ZERO),
			"route_index": int(lord.get("route_index", 1)),
			"party_size": int(lord.get("party_size", 0))
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
	if not ABNER_PRESSURE_ENABLED:
		return

	for lord in _lord_parties:
		if String(lord.get("name", "")) != ABNER_NAME:
			continue
		var pos: Vector2 = lord["pos"]
		var detection_radius := _abner_detection_radius()
		var fill := Color(0.72, 0.10, 0.08, 0.08)
		var edge := Color(0.72, 0.10, 0.08, 0.30)
		if _is_lord_pursuing(lord):
			fill = Color(0.95, 0.08, 0.04, 0.14)
			edge = Color(0.95, 0.08, 0.04, 0.58)
		draw_circle(pos, detection_radius, fill)
		draw_arc(pos, detection_radius, 0.0, TAU, 96, edge, 4.0, true)


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

	var layers := Dictionary(_map_manifest.get("layers", {}))
	_land_features = _load_layer_features(String(layers.get("land_outline", "")))
	_water_features = _load_layer_features(String(layers.get("water", "")))
	_biome_features = _load_layer_features(String(layers.get("biomes", "")))
	_relief_features = _load_layer_features(String(layers.get("relief", "")))
	_settlement_features = _load_layer_features(String(layers.get("settlements", "")))
	_route_features = _load_layer_features(String(layers.get("routes", "")))
	_chokepoint_features = _load_layer_features(String(layers.get("chokepoints", "")))
	_build_settlement_entries()

	_data_loaded = not _land_features.is_empty() and not _settlement_entries.is_empty()
	if not _data_loaded:
		push_warning("Campaign map dataset is incomplete; using built-in fallback map.")


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

	var west := float(_map_bbox[0])
	var south := float(_map_bbox[1])
	var east := float(_map_bbox[2])
	var north := float(_map_bbox[3])
	var longitude := float(coordinates[0])
	var latitude := float(coordinates[1])
	var x_ratio := clampf((longitude - west) / (east - west), 0.0, 1.0)
	var y_ratio := clampf((north - latitude) / (north - south), 0.0, 1.0)
	return MAP_RECT.position + Vector2(x_ratio * MAP_RECT.size.x, y_ratio * MAP_RECT.size.y)


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
		for index in range(_lord_parties.size()):
			if String(_lord_parties[index].get("name", "")) != saved_name:
				continue
			var lord := _lord_parties[index]
			lord["pos"] = Vector2(saved_lord.get("pos", lord.get("pos", Vector2.ZERO)))
			lord["route_index"] = int(saved_lord.get("route_index", lord.get("route_index", 1)))
			lord["party_size"] = int(saved_lord.get("party_size", lord.get("party_size", 0)))
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

	var pos: Vector2 = lord["pos"]
	var route_index := clampi(int(lord.get("route_index", 1)), 0, route.size() - 1)
	var target: Vector2 = route[route_index]
	var remaining := float(lord.get("speed", 40.0)) * MAP_SCALE * delta
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

		route_index = (route_index + 1) % route.size()
		target = route[route_index]
		hop_guard -= 1

	lord["pos"] = pos
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
		var to_player := player_position - pos
		if to_player.length() > 0.01:
			var step := float(lord.get("speed", 40.0)) * MAP_SCALE * ABNER_PURSUIT_SPEED_MULTIPLIER * delta
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
		GameState.set_lord_pursuit_state(ABNER_NAME, {"state": "pursuing", "started_minute": GameState.get_game_total_minutes()})
		GameState.adjust_morale(-2)
		GameState.last_campaign_notice = "Abner has seen your trail and turns toward you."

	return {"lord": lord, "caught": {}}


func _is_lord_pursuing(lord: Dictionary) -> bool:
	var name := String(lord.get("name", ""))
	if name == ABNER_NAME and not ABNER_PRESSURE_ENABLED:
		return false
	return String(GameState.get_lord_pursuit_state(name).get("state", "")) == "pursuing"


func _is_hostile_lord(lord: Dictionary) -> bool:
	var faction := String(lord.get("faction", ""))
	return faction == "House of Saul" or faction == "Philistine Lords" or faction == "Edomite Retinue"


func _abner_detection_radius() -> float:
	return ABNER_DETECTION_RADIUS + float(GameState.heat) * 2.5


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
