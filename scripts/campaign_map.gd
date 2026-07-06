extends Node2D

const MAP_SCALE := 3.0
const BASE_MAP_RECT := Rect2(Vector2(-900.0, -1250.0), Vector2(1800.0, 2500.0))
const MAP_RECT := Rect2(BASE_MAP_RECT.position * MAP_SCALE, BASE_MAP_RECT.size * MAP_SCALE)

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
		"route": [Vector2(42, -172), Vector2(92, -55), Vector2(88, -562), Vector2(235, -1045), Vector2(42, -172)],
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
		"route": [Vector2(28, 258), Vector2(-8, 630), Vector2(-265, 820), Vector2(338, 545), Vector2(-168, 390), Vector2(28, 258)],
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
		"route": [Vector2(-448, 182), Vector2(-590, 515), Vector2(-585, 895), Vector2(-448, 182), Vector2(-230, 235)],
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
		"route": [Vector2(92, -55), Vector2(42, -172), Vector2(-25, -260), Vector2(92, -55), Vector2(102, 58)],
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
		"route": [Vector2(102, 58), Vector2(338, 545), Vector2(28, 258), Vector2(102, 58)],
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


func _ready() -> void:
	_font = ThemeDB.fallback_font
	_initialize_lord_parties()
	queue_redraw()


func get_playable_rect() -> Rect2:
	return MAP_RECT.grow(-38.0)


func advance_lord_parties_for_real_seconds(real_seconds: float) -> void:
	_advance_lord_parties(real_seconds)


func get_nearest_settlement(world_position: Vector2, radius: float = 95.0) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := radius
	for settlement in SETTLEMENTS:
		var settlement_position := _scaled_point(settlement["pos"])
		var distance := world_position.distance_to(settlement_position)
		if distance <= best_distance:
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

	for settlement in SETTLEMENTS:
		var settlement_position := _scaled_point(settlement["pos"])
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
	_draw_settlements()
	_draw_lord_parties()
	_draw_npc_parties()
	_draw_frame()


func _draw_base() -> void:
	draw_rect(MAP_RECT.grow(260.0), Color("#d9c59a"))
	draw_colored_polygon(_scaled_points(great_sea), Color("#486f88"))
	draw_colored_polygon(_scaled_points(land_polygon), Color("#bda676"))
	_draw_polygon_outline(_scaled_points(land_polygon), Color("#6d5737"), 4.0)

	for i in range(9):
		var y := MAP_RECT.position.y + float(i) * 290.0 * MAP_SCALE
		draw_line(Vector2(MAP_RECT.position.x - 180.0 * MAP_SCALE, y), Vector2(MAP_RECT.end.x + 180.0 * MAP_SCALE, y + 80.0 * MAP_SCALE), Color(0.38, 0.29, 0.18, 0.08), 2.0)


func _draw_terrain() -> void:
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
	for road in ROADS:
		var points := _scaled_points(PackedVector2Array(road))
		draw_polyline(points, Color(0.28, 0.18, 0.10, 0.38), 9.0, true)
		draw_polyline(points, Color("#d8c083"), 4.0, true)


func _draw_settlements() -> void:
	for settlement in SETTLEMENTS:
		var pos := _scaled_point(settlement["pos"])
		var is_philistine := String(settlement["kind"]).contains("Philistine")
		var fill := Color("#7f2f2d") if is_philistine else Color("#294f66")
		var ring := Color("#f3dfaa")

		draw_circle(pos, 11.0, Color(0.18, 0.11, 0.07, 0.34))
		draw_circle(pos, 8.0, ring)
		draw_circle(pos, 5.0, fill)

		if _font:
			draw_string(_font, pos + Vector2(13.0, -9.0), String(settlement["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18.0, Color("#2b1d12"))


func _draw_npc_parties() -> void:
	for party in NPC_PARTIES:
		var pos := _scaled_point(party["pos"])
		draw_circle(pos + Vector2(4.0, 5.0), 13.0, Color(0.07, 0.04, 0.02, 0.30))
		draw_circle(pos, 11.0, Color("#efe0a6"))
		draw_circle(pos, 7.0, Color("#3c7c45"))
		draw_circle(pos + Vector2(3.0, -3.0), 3.0, Color("#f7edc8"))

		if _font:
			draw_string(_font, pos + Vector2(15.0, -10.0), String(party["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17.0, Color("#2b1d12"))


func _draw_lord_parties() -> void:
	for lord in _lord_parties:
		var pos: Vector2 = lord["pos"]
		var faction_color := Color(String(lord.get("color", "#704c2f")))
		var diamond := PackedVector2Array([
			pos + Vector2(0.0, -16.0),
			pos + Vector2(14.0, 0.0),
			pos + Vector2(0.0, 16.0),
			pos + Vector2(-14.0, 0.0)
		])

		draw_circle(pos + Vector2(4.0, 6.0), 17.0, Color(0.06, 0.035, 0.02, 0.34))
		draw_colored_polygon(diamond, Color("#f0dda4"))
		draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#51351e"), 2.0, true)
		draw_circle(pos, 8.0, faction_color)
		draw_circle(pos + Vector2(3.0, -4.0), 3.0, Color("#fff2be"))

		if _font:
			var label := "%s (%d)" % [String(lord["name"]), int(lord["party_size"])]
			draw_string(_font, pos + Vector2(18.0, -13.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17.0, Color("#2b1d12"))


func _draw_frame() -> void:
	draw_rect(MAP_RECT, Color("#5c4328"), false, 10.0)
	draw_rect(MAP_RECT.grow(-18.0), Color(0.22, 0.13, 0.06, 0.28), false, 2.0)


func _draw_region_label(text: String, position: Vector2, color: Color = Color("#4f3a24")) -> void:
	if _font:
		draw_string(_font, position, text, HORIZONTAL_ALIGNMENT_CENTER, 260.0, 28.0, color)


func _draw_polygon_outline(points: PackedVector2Array, color: Color, width: float) -> void:
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, color, width, true)


func _scaled_point(point: Vector2) -> Vector2:
	return point * MAP_SCALE


func _scaled_points(points: PackedVector2Array) -> PackedVector2Array:
	var scaled := PackedVector2Array()
	for point in points:
		scaled.append(_scaled_point(point))
	return scaled


func _initialize_lord_parties() -> void:
	_lord_parties.clear()

	for template in LORD_PARTIES:
		var lord: Dictionary = template.duplicate(true)
		lord["pos"] = _scaled_point(template["start"])
		lord["route"] = _scaled_route(template["route"])
		lord["route_index"] = 1
		_lord_parties.append(lord)


func _advance_lord_parties(delta: float) -> void:
	if _lord_parties.is_empty() or delta <= 0.0:
		return

	for index in range(_lord_parties.size()):
		var lord: Dictionary = _lord_parties[index]
		var route: Array = lord.get("route", [])
		if route.size() < 2:
			continue

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
		_lord_parties[index] = lord

	queue_redraw()


func _scaled_route(route: Array) -> Array:
	var scaled: Array = []
	for point in route:
		scaled.append(_scaled_point(point))
	return scaled


func _target_from_entry(entry: Dictionary, target_type: String) -> Dictionary:
	var target: Dictionary = entry.duplicate()
	target["pos"] = _scaled_point(entry["pos"])
	target["type"] = target_type
	return target


func _target_from_lord(lord: Dictionary) -> Dictionary:
	var target: Dictionary = lord.duplicate(true)
	target["type"] = "lord"
	target["lord_id"] = String(lord.get("name", ""))
	return target
