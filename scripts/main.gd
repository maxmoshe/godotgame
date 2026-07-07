extends Node2D

const STARTING_DAY := 1
const MINUTES_PER_DAY := 24 * 60
const TIME_LABEL_MINUTE_STEP := 5
const MOVEMENT_EPSILON := 0.05
const MIN_RECRUIT_COUNT := 1
const MAX_RECRUIT_COUNT := 3
const TOWN_RECRUIT_BONUS := 2
const CITY_RECRUIT_BONUS := 4
const FOOD_BUY_AMOUNT := 4
const FOOD_BUY_SILVER_COST := 5
const FOOD_TAKE_AMOUNT := 7
const FOOD_TAKE_MINIMUM_MEN := 12
const ZOOM_MIN := 0.18
const ZOOM_MAX := 1.2
const ZOOM_STEP := 0.08
const ZOOM_LERP_SPEED := 8.0
const LOCATION_TOOLTIP_SIZE := Vector2(326.0, 150.0)
const LOCATION_TOOLTIP_COMPACT_HEIGHT := 96.0
const LOCATION_TOOLTIP_OFFSET := Vector2(18.0, 18.0)
const LOCATION_TOOLTIP_MARGIN := 10.0
const LOCATION_FORTRESS_KEYWORDS := ["fortress", "stronghold", "watch", "outpost"]
const LOCATION_VILLAGE_KEYWORDS := ["village", "camp", "well", "spring", "oasis", "shrine", "mine", "copper", "clan", "house"]
const LOCATION_CITY_KEYWORDS := ["city", "port", "capital", "court", "sanctuary"]
const PLAYER_SIZE_SPEED_PENALTY_MEN := 100.0
const PLAYER_SIZE_SPEED_PENALTY_MAX := 0.20
const PLAYER_INTELLIGENCE_SPEED_BONUS_STAT := 50.0
const PLAYER_INTELLIGENCE_SPEED_BONUS_MAX := 0.30
const PLAYER_CAMPAIGN_SPEED_MULTIPLIER := 0.5
const HIDE_MINUTES := 3 * 60
const AI_DEBUG_ADVANCE_HOURS := 6
const PRESSURE_WARY_THRESHOLD := 25.0
const PRESSURE_DANGEROUS_THRESHOLD := 55.0
const PRESSURE_HUNTED_THRESHOLD := 80.0
const CHEAT_COMPANIONS := [
	{"name": "Joab", "health": 120, "max_health": 120},
	{"name": "Abishai", "health": 115, "max_health": 115},
	{"name": "Asahel", "health": 105, "max_health": 105},
	{"name": "Benaiah", "health": 130, "max_health": 130}
]

@onready var campaign_map = $CampaignMap
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var location_label: Label = $HUD/LocationLabel
@onready var time_label: Label = $HUD/TimeLabel
@onready var status_label: Label = $HUD/StatusLabel
@onready var dialogue_panel: Panel = $HUD/DialoguePanel
@onready var dialogue_title: Label = $HUD/DialoguePanel/TitleLabel
@onready var dialogue_body: Label = $HUD/DialoguePanel/BodyLabel
@onready var dialogue_continue_button: Button = $HUD/DialoguePanel/ContinueButton
@onready var dialogue_recruit_button: Button = $HUD/DialoguePanel/RecruitButton
@onready var dialogue_attack_button: Button = $HUD/DialoguePanel/AttackButton
@onready var dialogue_trade_button: Button = $HUD/DialoguePanel/TradeButton
@onready var dialogue_rumor_button: Button = $HUD/DialoguePanel/RumorButton
@onready var dialogue_buy_food_button: Button = $HUD/DialoguePanel/BuyFoodButton
@onready var dialogue_take_food_button: Button = $HUD/DialoguePanel/TakeFoodButton
@onready var dialogue_hide_button: Button = $HUD/DialoguePanel/HideButton
@onready var dialogue_leave_button: Button = $HUD/DialoguePanel/LeaveButton
@onready var inventory_panel: Panel = $HUD/InventoryPanel
@onready var market_panel: Panel = $HUD/MarketPanel
@onready var party_panel: Panel = $HUD/PartyPanel

var _last_location := ""
var _pending_encounter: Dictionary = {}
var _dialogue_pages: Array[String] = []
var _dialogue_page_index := 0
var _dialogue_target: Dictionary = {}
var _dialogue_recruit_count := 0
var _last_shown_game_minute := -1
var _last_player_position := Vector2.ZERO
var _target_zoom := 0.82
var _cheat_panel: Panel
var _cheat_notice_label: Label
var _cheat_companion_index := 0
var _loot_panel_active := false
var _loot_take_silver_button: Button
var _location_tooltip: Panel
var _location_tooltip_name_label: Label
var _location_tooltip_type_label: Label
var _location_tooltip_faction_label: Label
var _location_tooltip_lords_label: Label


func _ready() -> void:
	player.world_bounds = campaign_map.get_playable_rect()
	player.set("movement_constraint", Callable(campaign_map, "constrain_land_position"))
	_restore_campaign_state()
	_update_player_campaign_speed()
	_last_player_position = player.global_position
	campaign_map.player_position = player.global_position
	_target_zoom = camera.zoom.x
	dialogue_panel.visible = false
	inventory_panel.visible = false
	market_panel.visible = false
	party_panel.visible = false
	_build_cheat_panel()
	_build_loot_controls()
	_build_location_tooltip()
	dialogue_continue_button.pressed.connect(_advance_dialogue)
	dialogue_recruit_button.pressed.connect(_recruit_soldiers)
	dialogue_attack_button.pressed.connect(_start_lord_combat)
	dialogue_trade_button.pressed.connect(_open_trade)
	dialogue_rumor_button.pressed.connect(_ask_for_news)
	dialogue_buy_food_button.pressed.connect(_buy_food)
	dialogue_take_food_button.pressed.connect(_take_food)
	dialogue_hide_button.pressed.connect(_hide_until_dark)
	dialogue_leave_button.pressed.connect(_close_dialogue)
	_open_pending_campaign_loot()
	_update_location_label(true)
	_update_time_label()
	_update_status_label()


func _process(delta: float) -> void:
	_smooth_zoom(delta)
	_update_player_campaign_speed()
	campaign_map.player_position = player.global_position
	if _advance_time_if_player_moved(delta):
		GameState.advance_travel_survival(delta)
		GameState.save_party_data(party_panel.get_party_data())
		campaign_map.queue_redraw()
		var caught_target: Dictionary = campaign_map.update_lord_pressure(delta, player.global_position, _is_player_in_safe_place())
		if not caught_target.is_empty() and not dialogue_panel.visible:
			_force_lord_encounter(caught_target)
			_update_status_label()
			return
	_update_time_label()
	_update_status_label()
	GameState.campaign_position = player.global_position

	if _is_manual_movement_pressed() and not _pending_encounter.is_empty():
		_pending_encounter = {}

	if _should_follow_mouse_pointer():
		player.travel_to(get_global_mouse_position())

	if not _pending_encounter.is_empty() and not dialogue_panel.visible:
		if not _refresh_pending_lord_encounter():
			return
		var target_position: Vector2 = _pending_encounter["pos"]
		if player.global_position.distance_to(target_position) <= 34.0:
			player.stop_travel()
			_show_dialogue(_pending_encounter)

	_update_location_label(false)
	_update_location_tooltip()


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_H:
		_toggle_cheat_panel()
		_mark_input_handled()
		return

	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_I:
		inventory_panel.visible = not inventory_panel.visible
		if inventory_panel.visible:
			party_panel.visible = false
			if _cheat_panel != null:
				_cheat_panel.visible = false
		if not inventory_panel.visible:
			market_panel.visible = false
		_mark_input_handled()
		return

	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_P:
		party_panel.visible = not party_panel.visible
		if party_panel.visible:
			inventory_panel.visible = false
			market_panel.visible = false
			if _cheat_panel != null:
				_cheat_panel.visible = false
		_mark_input_handled()
		return

	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_F:
		_mark_input_handled()
		_save_campaign_state()
		GameState.clear_combat_context()
		_set_current_combat_map_context()
		get_tree().change_scene_to_file("res://scenes/combat_test.tscn")
		return

	if dialogue_panel.visible:
		if _is_dialogue_advance_click(event):
			_advance_dialogue()
			_mark_input_handled()
		return

	if _is_pointer_over_inventory() or _is_pointer_over_market() or _is_pointer_over_party() or _is_pointer_over_cheat_panel():
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event == null:
		return

	if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_target_zoom = clampf(_target_zoom + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
		_mark_input_handled()
		return

	if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_target_zoom = clampf(_target_zoom - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
		_mark_input_handled()
		return

	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return

	var world_position := get_global_mouse_position()
	var target: Dictionary = campaign_map.get_click_target(world_position)

	if target.is_empty():
		_pending_encounter = {}
		player.travel_to(world_position)
		return

	_pending_encounter = target
	player.travel_to(target["pos"])


func _refresh_pending_lord_encounter() -> bool:
	if String(_pending_encounter.get("type", "")) != "lord":
		return true

	var lord_id := String(_pending_encounter.get("lord_id", _pending_encounter.get("name", "")))
	var live_target: Dictionary = campaign_map.get_lord_target(lord_id)
	if live_target.is_empty():
		_pending_encounter = {}
		player.stop_travel()
		return false

	_pending_encounter = live_target
	player.travel_to(live_target["pos"])
	return true


func _update_location_label(force: bool) -> void:
	var settlement: Dictionary = campaign_map.get_nearest_settlement(player.global_position)
	var label := "Open country"

	if not settlement.is_empty():
		label = "%s - %s" % [String(settlement["name"]), String(settlement["kind"])]

	if force or label != _last_location:
		_last_location = label
		location_label.text = label


func _restore_campaign_state() -> void:
	player.global_position = campaign_map.constrain_land_position(GameState.campaign_position)
	if GameState.has_player_inventory():
		inventory_panel.load_slots(GameState.player_inventory_slots)
	if GameState.has_market_inventory():
		market_panel.load_slots(GameState.market_inventory_slots)
	party_panel.load_party_data(GameState.get_party_data())


func _open_pending_campaign_loot() -> void:
	if not GameState.has_pending_campaign_loot():
		return

	var loot := GameState.get_pending_campaign_loot()
	_loot_panel_active = true
	player.stop_travel()

	dialogue_title.text = "Battlefield Loot"
	dialogue_body.text = "The field is yours. Drag spoils from the left into your inventory. Silver waits separately."
	dialogue_panel.visible = true
	inventory_panel.visible = true
	market_panel.visible = true
	party_panel.visible = false
	if _cheat_panel != null:
		_cheat_panel.visible = false

	market_panel.clear_inventory()
	market_panel.set_title_text("Battlefield Loot")
	for item in Array(loot.get("items", [])):
		if not (item is Dictionary):
			continue
		var loot_item := Dictionary(item)
		market_panel.add_item(String(loot_item.get("id", "")), int(loot_item.get("amount", 0)))

	_hide_settlement_action_buttons()
	dialogue_continue_button.visible = false
	dialogue_leave_button.text = "Leave loot"
	_update_loot_silver_button()


func _save_campaign_state() -> void:
	GameState.campaign_position = player.global_position
	GameState.player_inventory_slots = inventory_panel.get_slots_copy()
	if not _loot_panel_active:
		GameState.market_inventory_slots = market_panel.get_slots_copy()
	GameState.save_party_data(party_panel.get_party_data())
	GameState.map_state["lord_parties"] = campaign_map.get_lord_save_data()


func _advance_time_if_player_moved(delta: float) -> bool:
	var current_position: Vector2 = player.global_position
	var position_changed := current_position.distance_to(_last_player_position) > MOVEMENT_EPSILON
	var has_velocity := player.velocity.length() > MOVEMENT_EPSILON
	var time_advanced := position_changed or has_velocity
	if time_advanced:
		GameState.advance_game_time(delta)
	_last_player_position = current_position
	return time_advanced


func _update_time_label() -> void:
	var total_minutes := GameState.get_game_total_minutes()
	var shown_total_minutes := total_minutes - total_minutes % TIME_LABEL_MINUTE_STEP
	if shown_total_minutes == _last_shown_game_minute:
		return

	_last_shown_game_minute = shown_total_minutes
	GameState.game_total_minutes = total_minutes
	var day := STARTING_DAY + int(shown_total_minutes / MINUTES_PER_DAY)
	var minute_of_day := shown_total_minutes % MINUTES_PER_DAY
	var hour := int(minute_of_day / 60)
	var minute := minute_of_day % 60
	time_label.text = "Day %d  %02d:%02d" % [day, hour, minute]


func _update_status_label() -> void:
	var pressure_score := _get_ai_pressure_score()
	var status := "%s\n%s\n%s" % [GameState.get_survival_text(), GameState.get_objective_text(), _pressure_status_text(pressure_score)]
	if not GameState.last_campaign_notice.is_empty():
		status += "\n%s" % GameState.last_campaign_notice
	status_label.text = status
	status_label.modulate = _status_label_color(pressure_score)


func _get_ai_pressure_score() -> float:
	if campaign_map == null:
		return 0.0
	var snapshot: Dictionary = campaign_map.get_ai_debug_snapshot()
	var director := Dictionary(snapshot.get("director", {}))
	return clampf(float(director.get("pressure_score", 0.0)), 0.0, 100.0)


func _pressure_status_text(pressure_score: float) -> String:
	return "Pursuit pressure: %s (%d)" % [_pressure_band_name(pressure_score), int(round(pressure_score))]


func _pressure_band_name(pressure_score: float) -> String:
	if pressure_score >= PRESSURE_HUNTED_THRESHOLD:
		return "Hunted"
	if pressure_score >= PRESSURE_DANGEROUS_THRESHOLD:
		return "Dangerous"
	if pressure_score >= PRESSURE_WARY_THRESHOLD:
		return "Wary"
	return "Quiet"


func _status_label_color(pressure_score: float) -> Color:
	if GameState.food <= 2 or GameState.morale <= 25 or pressure_score >= PRESSURE_HUNTED_THRESHOLD:
		return Color("#ffb09c")
	if pressure_score >= PRESSURE_DANGEROUS_THRESHOLD:
		return Color("#ffe0a0")
	return Color.WHITE


func _update_player_campaign_speed() -> void:
	var party_data: Dictionary = party_panel.get_party_data()
	var men := int(party_data.get("generic_soldier_count", 0))
	var intelligence := int(party_data.get("leader_intelligence", 0))
	player.set("campaign_speed_multiplier", _campaign_speed_multiplier(men, intelligence))


func _campaign_speed_multiplier(men: int, intelligence: int) -> float:
	var men_ratio := clampf(maxf(0.0, float(men)) / PLAYER_SIZE_SPEED_PENALTY_MEN, 0.0, 1.0)
	var intelligence_ratio := clampf(maxf(0.0, float(intelligence)) / PLAYER_INTELLIGENCE_SPEED_BONUS_STAT, 0.0, 1.0)
	var men_multiplier := 1.0 - PLAYER_SIZE_SPEED_PENALTY_MAX * men_ratio
	var intelligence_multiplier := 1.0 + PLAYER_INTELLIGENCE_SPEED_BONUS_MAX * intelligence_ratio
	return PLAYER_CAMPAIGN_SPEED_MULTIPLIER * men_multiplier * intelligence_multiplier


func _build_location_tooltip() -> void:
	_location_tooltip = Panel.new()
	_location_tooltip.name = "LocationTooltip"
	_location_tooltip.visible = false
	_location_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_location_tooltip.size = LOCATION_TOOLTIP_SIZE
	_location_tooltip.add_theme_stylebox_override("panel", _make_location_tooltip_style())
	hud.add_child(_location_tooltip)

	_location_tooltip_name_label = _make_location_tooltip_label(14.0, 22, Color("#f4dfaa"))
	_location_tooltip_type_label = _make_location_tooltip_label(46.0, 16, Color("#e0c88f"))
	_location_tooltip_faction_label = _make_location_tooltip_label(68.0, 16, Color("#cdb989"))
	_location_tooltip_lords_label = _make_location_tooltip_label(96.0, 15, Color("#f0dca8"), 42.0)
	_location_tooltip_lords_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_location_tooltip_lords_label.clip_text = true
	_location_tooltip.add_child(_location_tooltip_name_label)
	_location_tooltip.add_child(_location_tooltip_type_label)
	_location_tooltip.add_child(_location_tooltip_faction_label)
	_location_tooltip.add_child(_location_tooltip_lords_label)


func _make_location_tooltip_label(top: float, font_size: int, color: Color, height: float = 24.0) -> Label:
	var label := Label.new()
	label.offset_left = 14.0
	label.offset_top = top
	label.offset_right = LOCATION_TOOLTIP_SIZE.x - 14.0
	label.offset_bottom = top + height
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_location_tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.075, 0.045, 0.94)
	style.border_color = Color("#d0a65c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style


func _update_location_tooltip() -> void:
	var viewport := get_viewport()
	if viewport == null:
		_hide_location_tooltip()
		return

	if _should_hide_location_tooltip():
		_hide_location_tooltip()
		return

	var location: Dictionary = campaign_map.get_hovered_location(get_global_mouse_position())
	if location.is_empty():
		_hide_location_tooltip()
		return

	_render_location_tooltip(location)
	_position_location_tooltip(viewport.get_mouse_position())
	_location_tooltip.visible = true


func _render_location_tooltip(location: Dictionary) -> void:
	_location_tooltip_name_label.text = String(location.get("name", "Unknown location"))
	_location_tooltip_type_label.text = "Type: %s" % _location_type_for(location)
	_location_tooltip_faction_label.text = "Faction: %s" % _location_faction_for(location)
	var lord_presence_text := _location_lord_presence_text(location)
	_location_tooltip_lords_label.text = lord_presence_text
	_location_tooltip_lords_label.visible = not lord_presence_text.is_empty()
	_location_tooltip.size = Vector2(
		LOCATION_TOOLTIP_SIZE.x,
		LOCATION_TOOLTIP_SIZE.y if not lord_presence_text.is_empty() else LOCATION_TOOLTIP_COMPACT_HEIGHT
	)


func _position_location_tooltip(mouse_position: Vector2) -> void:
	var viewport_size := get_viewport_rect().size
	var tooltip_size := _location_tooltip.size if _location_tooltip != null else LOCATION_TOOLTIP_SIZE
	var tooltip_position := mouse_position + LOCATION_TOOLTIP_OFFSET

	if tooltip_position.x + tooltip_size.x > viewport_size.x - LOCATION_TOOLTIP_MARGIN:
		tooltip_position.x = mouse_position.x - tooltip_size.x - LOCATION_TOOLTIP_OFFSET.x
	if tooltip_position.y + tooltip_size.y > viewport_size.y - LOCATION_TOOLTIP_MARGIN:
		tooltip_position.y = mouse_position.y - tooltip_size.y - LOCATION_TOOLTIP_OFFSET.y

	tooltip_position.x = clampf(
		tooltip_position.x,
		LOCATION_TOOLTIP_MARGIN,
		maxf(LOCATION_TOOLTIP_MARGIN, viewport_size.x - tooltip_size.x - LOCATION_TOOLTIP_MARGIN)
	)
	tooltip_position.y = clampf(
		tooltip_position.y,
		LOCATION_TOOLTIP_MARGIN,
		maxf(LOCATION_TOOLTIP_MARGIN, viewport_size.y - tooltip_size.y - LOCATION_TOOLTIP_MARGIN)
	)
	_location_tooltip.position = tooltip_position


func _location_type_for(location: Dictionary) -> String:
	var explicit_label := String(location.get("location_class_label", "")).strip_edges()
	if not explicit_label.is_empty():
		return explicit_label

	var settlement_class := String(location.get("settlement_class", "")).strip_edges()
	if not settlement_class.is_empty():
		return _title_from_snake_case(settlement_class)

	var kind := String(location.get("kind", "")).to_lower()
	for keyword in LOCATION_FORTRESS_KEYWORDS:
		if kind.contains(String(keyword)):
			return "Fortress"
	for keyword in LOCATION_VILLAGE_KEYWORDS:
		if kind.contains(String(keyword)):
			return "Village"
	for keyword in LOCATION_CITY_KEYWORDS:
		if kind.contains(String(keyword)):
			return "City"

	var defense_bonus := int(location.get("defense_bonus", 0))
	var density := int(location.get("settlement_density", 0))
	if defense_bonus >= 5 and density <= 4:
		return "Fortress"
	if kind.contains("town") and density <= 3:
		return "Town"
	if density > 0 and density <= 2:
		return "Village"
	return "City"


func _title_from_snake_case(value: String) -> String:
	var words := value.split("_", false)
	for index in range(words.size()):
		var word := String(words[index])
		if word.is_empty():
			continue
		words[index] = word.substr(0, 1).to_upper() + word.substr(1)
	return " ".join(words)


func _location_faction_for(location: Dictionary) -> String:
	var faction := String(location.get("owner_faction", "")).strip_edges()
	if faction.is_empty() or faction == "Neutral":
		return "No controlling faction"
	return faction


func _location_lord_presence_text(location: Dictionary) -> String:
	var grouped_lords := Array(location.get("contained_lords", location.get("grouped_lords", [])))
	if grouped_lords.is_empty():
		return ""
	var pieces := PackedStringArray()
	var total_men := 0
	var visible_count := mini(grouped_lords.size(), 4)
	for index in range(visible_count):
		var lord := Dictionary(grouped_lords[index])
		var party_size := int(lord.get("party_size", 0))
		total_men += party_size
		pieces.append("%s (%d)" % [String(lord.get("name", "Lord")), party_size])
	for index in range(visible_count, grouped_lords.size()):
		var lord := Dictionary(grouped_lords[index])
		total_men += int(lord.get("party_size", 0))
	if grouped_lords.size() > visible_count:
		pieces.append("+%d more" % (grouped_lords.size() - visible_count))
	return "Inside: %s | %d men" % [", ".join(pieces), total_men]


func _should_hide_location_tooltip() -> bool:
	return dialogue_panel.visible \
		or _is_pointer_over_inventory() \
		or _is_pointer_over_market() \
		or _is_pointer_over_party() \
		or _is_pointer_over_cheat_panel()


func _hide_location_tooltip() -> void:
	if _location_tooltip != null:
		_location_tooltip.visible = false


func _build_cheat_panel() -> void:
	_cheat_panel = Panel.new()
	_cheat_panel.name = "CheatPanel"
	_cheat_panel.visible = false
	_cheat_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_cheat_panel.offset_left = 454.0
	_cheat_panel.offset_top = 118.0
	_cheat_panel.offset_right = 826.0
	_cheat_panel.offset_bottom = 560.0
	_cheat_panel.add_theme_stylebox_override("panel", _make_cheat_panel_style())
	hud.add_child(_cheat_panel)

	var layout := VBoxContainer.new()
	layout.position = Vector2(22.0, 18.0)
	layout.size = Vector2(328.0, 404.0)
	layout.add_theme_constant_override("separation", 10)
	_cheat_panel.add_child(layout)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(328.0, 34.0)
	header.add_theme_constant_override("separation", 8)
	layout.add_child(header)

	var title := Label.new()
	title.text = "Dev Cheats"
	title.custom_minimum_size = Vector2(238.0, 32.0)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#f0dda5"))
	header.add_child(title)

	var close_button := _make_cheat_button("Close")
	close_button.custom_minimum_size = Vector2(82.0, 32.0)
	close_button.pressed.connect(_toggle_cheat_panel)
	header.add_child(close_button)

	var resources := GridContainer.new()
	resources.columns = 2
	resources.add_theme_constant_override("h_separation", 8)
	resources.add_theme_constant_override("v_separation", 8)
	layout.add_child(resources)
	_add_cheat_button(resources, "+25 Food", Callable(self, "_cheat_adjust_food").bind(25))
	_add_cheat_button(resources, "+100 Silver", Callable(self, "_cheat_adjust_silver").bind(100))
	_add_cheat_button(resources, "+10 Morale", Callable(self, "_cheat_adjust_morale").bind(10))
	_add_cheat_button(resources, "Cool Heat", Callable(self, "_cheat_adjust_heat").bind(-100))

	var party := GridContainer.new()
	party.columns = 2
	party.add_theme_constant_override("h_separation", 8)
	party.add_theme_constant_override("v_separation", 8)
	layout.add_child(party)
	_add_cheat_button(party, "+5 Soldiers", Callable(self, "_cheat_add_soldiers").bind(5))
	_add_cheat_button(party, "+25 Soldiers", Callable(self, "_cheat_add_soldiers").bind(25))
	_add_cheat_button(party, "Add Companion", Callable(self, "_cheat_add_companion"))
	_add_cheat_button(party, "Heal Party", Callable(self, "_cheat_heal_party"))

	_add_cheat_button(layout, "Fill Inventory Supplies", Callable(self, "_cheat_add_inventory_supplies"), Vector2(328.0, 36.0))

	var ai_debug := GridContainer.new()
	ai_debug.columns = 2
	ai_debug.add_theme_constant_override("h_separation", 8)
	ai_debug.add_theme_constant_override("v_separation", 8)
	layout.add_child(ai_debug)
	_add_cheat_button(ai_debug, "AI Snapshot", Callable(self, "_cheat_show_ai_snapshot"))
	_add_cheat_button(ai_debug, "Fake Sighting", Callable(self, "_cheat_fake_ai_sighting"))
	_add_cheat_button(ai_debug, "Advance 6h", Callable(self, "_cheat_advance_ai_hours").bind(AI_DEBUG_ADVANCE_HOURS))
	_add_cheat_button(ai_debug, "Break Trail", Callable(self, "_cheat_break_ai_trail"))
	_add_cheat_button(ai_debug, "Seed Nemesis", Callable(self, "_cheat_seed_ai_nemesis"))

	_cheat_notice_label = Label.new()
	_cheat_notice_label.custom_minimum_size = Vector2(328.0, 118.0)
	_cheat_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cheat_notice_label.add_theme_font_size_override("font_size", 14)
	_cheat_notice_label.add_theme_color_override("font_color", Color("#d6c391"))
	_cheat_notice_label.text = "Press H to close."
	layout.add_child(_cheat_notice_label)


func _build_loot_controls() -> void:
	_loot_take_silver_button = Button.new()
	_loot_take_silver_button.name = "TakeLootSilverButton"
	_loot_take_silver_button.visible = false
	_loot_take_silver_button.focus_mode = Control.FOCUS_NONE
	_loot_take_silver_button.offset_left = 292.0
	_loot_take_silver_button.offset_top = 224.0
	_loot_take_silver_button.offset_right = 456.0
	_loot_take_silver_button.offset_bottom = 260.0
	_loot_take_silver_button.add_theme_font_size_override("font_size", 18)
	_loot_take_silver_button.pressed.connect(_take_loot_silver)
	dialogue_panel.add_child(_loot_take_silver_button)


func _take_loot_silver() -> void:
	if not _loot_panel_active:
		return

	var silver_gain := GameState.claim_pending_campaign_loot_silver()
	if silver_gain <= 0:
		_update_loot_silver_button()
		return

	GameState.last_campaign_notice = "You take %d silver from the field." % silver_gain
	_update_loot_silver_button()
	_update_status_label()


func _update_loot_silver_button() -> void:
	if _loot_take_silver_button == null:
		return
	var silver_available := GameState.get_pending_campaign_loot_silver()
	_loot_take_silver_button.visible = _loot_panel_active and silver_available > 0
	_loot_take_silver_button.text = "Take %d Silver" % silver_available


func _make_cheat_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.06, 0.97)
	style.border_color = Color("#c99d55")
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	return style


func _add_cheat_button(parent: Control, text: String, callback: Callable, minimum_size := Vector2(160.0, 36.0)) -> void:
	var button := _make_cheat_button(text)
	button.custom_minimum_size = minimum_size
	button.pressed.connect(callback)
	parent.add_child(button)


func _make_cheat_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	return button


func _toggle_cheat_panel() -> void:
	if _cheat_panel == null:
		return
	_cheat_panel.visible = not _cheat_panel.visible
	if _cheat_panel.visible:
		inventory_panel.visible = false
		market_panel.visible = false
		party_panel.visible = false
		_cheat_notice_label.text = "Press H to close."


func _cheat_adjust_food(amount: int) -> void:
	GameState.adjust_food(amount)
	_finish_cheat("Food %s. Current food: %d." % [_format_signed_amount(amount), GameState.food])


func _cheat_adjust_silver(amount: int) -> void:
	GameState.adjust_silver(amount)
	_finish_cheat("Silver %s. Current silver: %d." % [_format_signed_amount(amount), GameState.silver])


func _cheat_adjust_morale(amount: int) -> void:
	GameState.adjust_morale(amount)
	_finish_cheat("Morale %s. Current morale: %d." % [_format_signed_amount(amount), GameState.morale])


func _cheat_adjust_heat(amount: int) -> void:
	GameState.adjust_heat(amount)
	_finish_cheat("Heat %s. Current heat: %d." % [_format_signed_amount(amount), GameState.heat])


func _cheat_add_soldiers(count: int) -> void:
	party_panel.add_generic_soldiers(count)
	_finish_cheat("Added %d soldiers. Party soldiers: %d." % [count, party_panel.generic_soldier_count])


func _cheat_add_companion() -> void:
	var character: Dictionary
	if _cheat_companion_index < CHEAT_COMPANIONS.size():
		character = Dictionary(CHEAT_COMPANIONS[_cheat_companion_index]).duplicate(true)
	else:
		var number := _cheat_companion_index - CHEAT_COMPANIONS.size() + 1
		character = {
			"name": "Mighty Man %d" % number,
			"health": 110,
			"max_health": 110
		}
	_cheat_companion_index += 1
	party_panel.add_named_character(character)
	_finish_cheat("Added companion: %s." % String(character.get("name", "Companion")))


func _cheat_heal_party() -> void:
	party_panel.heal_party()
	_finish_cheat("Party healed.")


func _cheat_add_inventory_supplies() -> void:
	var missing := 0
	missing += inventory_panel.add_item("barley_bread", 12)
	missing += inventory_panel.add_item("sling_stones", 30)
	missing += inventory_panel.add_item("olive_oil", 4)
	missing += inventory_panel.add_item("bronze_dagger", 1)
	var message := "Inventory supplies added."
	if missing > 0:
		message = "Inventory filled; %d item(s) did not fit." % missing
	_finish_cheat(message)


func _cheat_show_ai_snapshot() -> void:
	_finish_cheat(_format_ai_debug_snapshot(campaign_map.get_ai_debug_snapshot()))


func _cheat_fake_ai_sighting() -> void:
	campaign_map.force_player_sighting_for_debug(player.global_position)
	campaign_map.update_overworld_ai(0.1, player.global_position, _is_player_in_safe_place())
	_finish_cheat("AI sighting seeded at the player band's current position.\n%s" % _format_ai_debug_snapshot(campaign_map.get_ai_debug_snapshot()))


func _cheat_advance_ai_hours(hours: int) -> void:
	var advanced_minutes := maxi(1, hours) * 60
	GameState.set_game_total_minutes(GameState.get_game_total_minutes() + advanced_minutes)
	var simulated_seconds := float(advanced_minutes) / GameState.GAME_MINUTES_PER_REAL_SECOND
	var result: Dictionary = campaign_map.update_overworld_ai(simulated_seconds, player.global_position, _is_player_in_safe_place())
	_update_time_label()
	var forced_encounter = result.get("forced_encounter", {})
	if forced_encounter is Dictionary and not Dictionary(forced_encounter).is_empty():
		_finish_cheat("Advanced AI %dh. %s caught the player." % [hours, String(Dictionary(forced_encounter).get("name", "A hostile lord"))])
		_force_lord_encounter(Dictionary(forced_encounter))
		return
	_finish_cheat("Advanced AI %dh.\n%s" % [hours, _format_ai_debug_snapshot(campaign_map.get_ai_debug_snapshot())])


func _cheat_break_ai_trail() -> void:
	campaign_map.break_player_trail_at(player.global_position, "dev break trail")
	campaign_map.update_overworld_ai(0.1, player.global_position, true)
	GameState.clear_all_lord_pursuit_states()
	_finish_cheat("Trail broken for hostile lords.\n%s" % _format_ai_debug_snapshot(campaign_map.get_ai_debug_snapshot()))


func _cheat_seed_ai_nemesis() -> void:
	var history: Dictionary = campaign_map.seed_nemesis_for_debug(player.global_position)
	campaign_map.update_overworld_ai(0.1, player.global_position, _is_player_in_safe_place())
	if history.is_empty():
		_finish_cheat("No hostile lord found for nemesis seed.")
		return
	_finish_cheat("Nemesis seeded for %s (%s %d).\n%s" % [
		String(history.get("name", "a hostile lord")),
		String(history.get("rank", "watchful")),
		int(round(float(history.get("nemesis_score", 0.0)))),
		_format_ai_debug_snapshot(campaign_map.get_ai_debug_snapshot())
	])


func _finish_cheat(message: String) -> void:
	GameState.last_campaign_notice = "Dev cheat: %s" % message
	_save_campaign_state()
	_update_status_label()
	if _cheat_notice_label != null:
		_cheat_notice_label.text = message


func _format_ai_debug_snapshot(snapshot: Dictionary) -> String:
	var director := Dictionary(snapshot.get("director", {}))
	var lines := PackedStringArray()
	lines.append("AI minute %d | pressure %d | heat %d | roads %d" % [
		int(snapshot.get("minute", GameState.get_game_total_minutes())),
		int(round(float(director.get("pressure_score", 0.0)))),
		GameState.heat,
		int(snapshot.get("road_graph_nodes", 0))
	])
	for raw_lord in Array(snapshot.get("lords", [])):
		if not (raw_lord is Dictionary):
			continue
		var lord := Dictionary(raw_lord)
		var task := Dictionary(lord.get("task", {}))
		var knowledge := Dictionary(lord.get("knowledge", {}))
		var memory_profile := Dictionary(lord.get("memory_profile", {}))
		var legacy_profile := Dictionary(lord.get("legacy_profile", {}))
		var strength_profile := Dictionary(lord.get("strength_profile", {}))
		var name := String(lord.get("name", "Lord"))
		var short_name := name.split(" ", false)[0]
		var state := String(lord.get("state", ""))
		var task_type := String(task.get("type", "none"))
		var confidence := int(round(float(knowledge.get("confidence", 0.0))))
		var fatigue := int(round(float(lord.get("fatigue", 0.0))))
		var supplies := int(round(float(lord.get("supplies", 0.0))))
		var waiting_at := String(lord.get("waiting_at", ""))
		var coordination_role := String(lord.get("coordination_role", "routine"))
		var memory_label := String(memory_profile.get("label", "normal"))
		var legacy_label := String(legacy_profile.get("label", "unknown"))
		var nemesis_score := int(round(float(legacy_profile.get("nemesis_score", 0.0))))
		var solo_ratio := float(strength_profile.get("solo_ratio", 0.0))
		var effective_ratio := float(strength_profile.get("effective_ratio", solo_ratio))
		var group_ratio := float(strength_profile.get("group_ratio", effective_ratio))
		var place_text := "" if waiting_at.is_empty() else " @%s" % waiting_at
		var layer_text := ""
		if not coordination_role in ["", "routine", "local"]:
			layer_text += " %s" % coordination_role
		if not memory_label in ["", "normal"]:
			layer_text += " %s" % memory_label
		if not legacy_label in ["", "unknown"]:
			layer_text += " %s%d" % [legacy_label, nemesis_score]
		var strength_text := ""
		if not strength_profile.is_empty():
			strength_text = " odds%.2f/%.2f/%.2f" % [solo_ratio, effective_ratio, group_ratio]
		lines.append("%s: %s/%s c%d f%d s%d%s%s%s" % [short_name, state, task_type, confidence, fatigue, supplies, place_text, strength_text, layer_text])
	return "\n".join(lines)


func _format_signed_amount(amount: int) -> String:
	if amount >= 0:
		return "+%d" % amount
	return "%d" % amount


func _show_dialogue(target: Dictionary) -> void:
	_hide_location_tooltip()
	dialogue_title.text = _dialogue_title_for(target)
	_dialogue_target = target.duplicate()
	_maybe_complete_ziklag_objective(_dialogue_target)
	_dialogue_recruit_count = _roll_recruit_count_for(target)
	_dialogue_pages = _dialogue_pages_for(target)
	_dialogue_page_index = 0
	dialogue_panel.visible = true
	_render_dialogue_page()
	_pending_encounter = {}


func _close_dialogue() -> void:
	if _loot_panel_active:
		_close_loot_panel()
		return

	var was_trading := market_panel.visible
	dialogue_panel.visible = false
	market_panel.visible = false
	if was_trading:
		inventory_panel.visible = false
	_dialogue_pages.clear()
	_dialogue_page_index = 0
	_dialogue_target = {}
	_dialogue_recruit_count = 0


func _close_loot_panel() -> void:
	_loot_panel_active = false
	GameState.player_inventory_slots = inventory_panel.get_slots_copy()
	GameState.clear_pending_campaign_loot()
	market_panel.clear_inventory()
	market_panel.set_title_text("Town Market")
	dialogue_panel.visible = false
	market_panel.visible = false
	inventory_panel.visible = false
	if _loot_take_silver_button != null:
		_loot_take_silver_button.visible = false
	_dialogue_pages.clear()
	_dialogue_page_index = 0
	_dialogue_target = {}
	_dialogue_recruit_count = 0
	_update_status_label()


func _advance_dialogue() -> void:
	if not dialogue_panel.visible:
		return
	if _dialogue_page_index >= _dialogue_pages.size() - 1:
		return

	_dialogue_page_index += 1
	_render_dialogue_page()


func _open_trade() -> void:
	if String(_dialogue_target.get("type", "")) != "settlement":
		return

	market_panel.set_title_text("Town Market")
	if GameState.has_market_inventory():
		market_panel.load_slots(GameState.market_inventory_slots)
	market_panel.visible = true
	inventory_panel.visible = true
	party_panel.visible = false
	dialogue_body.text = "The market opens its awnings. For now trade is barter-style: drag goods between the town market on the left and your inventory on the right. Prices and ownership rules come next."
	dialogue_continue_button.visible = false
	dialogue_recruit_button.visible = false
	dialogue_attack_button.visible = false
	dialogue_trade_button.visible = false
	dialogue_rumor_button.visible = false
	dialogue_buy_food_button.visible = false
	dialogue_take_food_button.visible = false
	dialogue_hide_button.visible = false
	dialogue_leave_button.text = "Leave market"


func _recruit_soldiers() -> void:
	if String(_dialogue_target.get("type", "")) != "settlement":
		return

	var settlement_name := String(_dialogue_target.get("name", ""))
	if settlement_name.is_empty() or not GameState.can_recruit_from_settlement(settlement_name):
		_render_dialogue_page()
		return

	var recruit_count := maxi(MIN_RECRUIT_COUNT, _dialogue_recruit_count)
	party_panel.add_generic_soldiers(recruit_count)
	GameState.save_party_data(party_panel.get_party_data())
	GameState.start_settlement_recruit_cooldown(settlement_name)
	GameState.adjust_morale(2)
	_dialogue_recruit_count = 0

	var soldier_word := "soldier" if recruit_count == 1 else "soldiers"
	dialogue_body.text = "%d %s agree to march with you. The town needs time before more men can be spared." % [recruit_count, soldier_word]
	dialogue_continue_button.visible = false
	dialogue_recruit_button.visible = false
	dialogue_attack_button.visible = false
	dialogue_trade_button.visible = true
	dialogue_rumor_button.visible = true
	dialogue_buy_food_button.visible = true
	dialogue_take_food_button.visible = true
	dialogue_hide_button.visible = true
	dialogue_leave_button.text = "Leave"
	_maybe_complete_ziklag_objective(_dialogue_target)
	_update_status_label()


func _ask_for_news() -> void:
	if String(_dialogue_target.get("type", "")) != "settlement":
		return

	dialogue_body.text = _build_rumor_text()
	_hide_settlement_action_buttons()
	dialogue_leave_button.text = "Leave"


func _buy_food() -> void:
	if String(_dialogue_target.get("type", "")) != "settlement":
		return

	if not GameState.spend_silver(FOOD_BUY_SILVER_COST):
		dialogue_body.text = "The merchants fold their hands. Food costs %d silver, and your purse is too light." % FOOD_BUY_SILVER_COST
		_render_dialogue_page()
		_update_status_label()
		return

	GameState.adjust_food(FOOD_BUY_AMOUNT)
	GameState.adjust_morale(1)
	GameState.last_campaign_notice = "Food bought quietly. The band breathes easier."
	dialogue_body.text = "You buy grain, dates, and skins of water from families willing to risk a small kindness. Silver -%d. Food +%d. Morale +1." % [FOOD_BUY_SILVER_COST, FOOD_BUY_AMOUNT]
	_hide_settlement_action_buttons()
	_update_status_label()


func _take_food() -> void:
	if String(_dialogue_target.get("type", "")) != "settlement":
		return

	if not _can_take_food_by_force():
		dialogue_body.text = "Your band is not large enough to make threats stick. Taking food by force needs at least %d men." % FOOD_TAKE_MINIMUM_MEN
		_render_dialogue_page()
		return

	GameState.adjust_food(FOOD_TAKE_AMOUNT)
	GameState.adjust_heat(12)
	GameState.adjust_morale(-4)
	GameState.last_campaign_notice = "Word spreads that David's men took what they needed."
	dialogue_body.text = "Your men take food from guarded store jars and leave angry faces behind them. Food +%d. Heat +12. Morale -4." % FOOD_TAKE_AMOUNT
	_hide_settlement_action_buttons()
	_update_status_label()


func _hide_until_dark() -> void:
	if String(_dialogue_target.get("type", "")) != "settlement":
		return

	campaign_map.break_player_trail_at(player.global_position, "hiding")
	GameState.set_game_total_minutes(GameState.get_game_total_minutes() + HIDE_MINUTES)
	campaign_map.update_overworld_ai(float(HIDE_MINUTES) / GameState.GAME_MINUTES_PER_REAL_SECOND, player.global_position, true)
	GameState.adjust_food(-1)
	GameState.adjust_morale(1)
	GameState.clear_all_lord_pursuit_states()
	GameState.last_campaign_notice = "You lie low until the road quiets."
	dialogue_body.text = "You keep the men under roofs and behind walls until the road has fewer eyes. Time passes. Food -1. Morale +1. Any immediate pursuit is broken."
	_update_time_label()
	campaign_map.queue_redraw()
	_hide_settlement_action_buttons()
	_update_status_label()


func _start_lord_combat() -> void:
	if String(_dialogue_target.get("type", "")) != "lord":
		return

	GameState.save_party_data(party_panel.get_party_data())
	var reinforcements: Array[Dictionary] = campaign_map.get_lord_combat_reinforcements(_dialogue_target)
	var enemy_reinforcements: Array[Dictionary] = campaign_map.get_enemy_lord_combat_reinforcements(_dialogue_target)
	_save_campaign_state()
	GameState.start_lord_combat(_dialogue_target, GameState.get_party_data(), reinforcements, enemy_reinforcements)
	_set_current_combat_map_context()
	get_tree().change_scene_to_file("res://scenes/combat_test.tscn")


func _set_current_combat_map_context() -> void:
	if campaign_map == null or not campaign_map.has_method("get_combat_map_context"):
		GameState.clear_combat_map_context()
		return
	GameState.set_combat_map_context(campaign_map.get_combat_map_context(GameState.campaign_position))


func _dialogue_pages_for(target: Dictionary) -> Array[String]:
	if String(target["type"]) == "npc":
		return _npc_dialogue_pages(target)
	if String(target["type"]) == "lord":
		return _lord_dialogue_pages(target)
	return _settlement_dialogue_pages(target)


func _settlement_dialogue_pages(settlement: Dictionary) -> Array[String]:
	var settlement_name := String(settlement["name"])
	var settlement_kind := String(settlement["kind"]).to_lower()
	if settlement_name == "Ziklag" and GameState.objective_complete:
		return [
			"You reach Ziklag with enough men to be more than a fugitive's shadow. The band has weight now: names, blades, hunger, and loyalty.",
			"For the first time in days, Saul's road is behind you instead of around your throat. This is not a kingdom yet, but it is a foothold."
		]
	return [
		"You arrive at %s, %s. Dust hangs over the road behind you, and the first eyes you meet belong to men on the gate tower." % [settlement_name, settlement_kind],
		"The gate guard lowers his spear, then recognizes that you come openly. Word travels faster than donkeys here; by sunset, half the town will know who entered and from which road.",
		"Inside the gate, merchants call from shaded stalls, elders sit near the threshold, and boys run messages between courtyards. You can trade, listen for news, or leave the town behind."
	]


func _npc_dialogue_pages(target: Dictionary) -> Array[String]:
	var dialogue := String(target.get("dialogue", ""))
	if dialogue.is_empty():
		return ["They wait for you to speak."]

	return [
		dialogue,
		"The exchange is brief. There is no courtly ceremony here, only road dust, caution, and the old habit of weighing every stranger twice."
	]


func _lord_dialogue_pages(target: Dictionary) -> Array[String]:
	var name := String(target.get("name", "Unknown lord"))
	var title := String(target.get("title", "local lord"))
	var faction := String(target.get("faction", "No known faction"))
	var party_size := int(target.get("party_size", 0))
	var dialogue := String(target.get("dialogue", "His party keeps its own counsel and waits to see what you will do."))

	return [
		"%s, %s, rides under %s colors with %d men in his company." % [name, title.to_lower(), faction, party_size],
		dialogue,
		"%s The road keeps pulling both parties onward." % _lord_reinforcement_dialogue_line(target)
	]


func _lord_reinforcement_dialogue_line(target: Dictionary) -> String:
	var reinforcements: Array[Dictionary] = campaign_map.get_lord_combat_reinforcements(target)
	var enemy_reinforcements: Array[Dictionary] = campaign_map.get_enemy_lord_combat_reinforcements(target)
	if reinforcements.is_empty() and enemy_reinforcements.is_empty():
		return "The meeting is brief. Messengers shift in their saddles and guards count your companions."

	var lines := PackedStringArray()
	var names: Array[String] = []
	var men := 0
	for raw_reinforcement in reinforcements:
		var reinforcement := Dictionary(raw_reinforcement)
		names.append(String(reinforcement.get("name", "an ally")))
		men += int(reinforcement.get("party_size", 0))
	if not names.is_empty():
		lines.append("%s can see the same enemy and is close enough to join you with %d men." % [_format_name_list(names, 3), men])

	names.clear()
	men = 0
	for raw_reinforcement in enemy_reinforcements:
		var reinforcement := Dictionary(raw_reinforcement)
		names.append(String(reinforcement.get("name", "another lord")))
		men += int(reinforcement.get("party_size", 0))
	if not names.is_empty():
		lines.append("%s is close enough to answer his call with %d men." % [_format_name_list(names, 3), men])
	return " ".join(lines)


func _dialogue_title_for(target: Dictionary) -> String:
	if String(target.get("type", "")) == "lord":
		return "%s - %s" % [String(target.get("name", "Lord")), String(target.get("title", "lord"))]
	return String(target.get("name", "Encounter"))


func _render_dialogue_page() -> void:
	if _loot_take_silver_button != null:
		_loot_take_silver_button.visible = false

	if _dialogue_pages.is_empty():
		dialogue_body.text = ""
	else:
		dialogue_body.text = _dialogue_pages[_dialogue_page_index]

	var has_next := _dialogue_page_index < _dialogue_pages.size() - 1
	var is_settlement := String(_dialogue_target.get("type", "")) == "settlement"
	var is_lord := String(_dialogue_target.get("type", "")) == "lord"
	dialogue_continue_button.visible = has_next
	dialogue_recruit_button.visible = is_settlement and not has_next and _can_recruit_from_dialogue_town()
	if dialogue_recruit_button.visible:
		dialogue_recruit_button.text = "Recruit (%d)" % _dialogue_recruit_count
	dialogue_attack_button.visible = is_lord and not has_next
	dialogue_trade_button.visible = is_settlement and not has_next
	dialogue_rumor_button.visible = is_settlement and not has_next
	dialogue_buy_food_button.visible = is_settlement and not has_next
	dialogue_take_food_button.visible = is_settlement and not has_next
	dialogue_hide_button.visible = is_settlement and not has_next
	dialogue_buy_food_button.disabled = is_settlement and not GameState.can_spend_silver(FOOD_BUY_SILVER_COST)
	dialogue_take_food_button.disabled = is_settlement and not _can_take_food_by_force()
	dialogue_buy_food_button.text = "Buy Food (%ds)" % FOOD_BUY_SILVER_COST
	dialogue_take_food_button.text = "Take Food" if _can_take_food_by_force() else "Need %d Men" % FOOD_TAKE_MINIMUM_MEN
	dialogue_leave_button.text = "Leave"


func _hide_settlement_action_buttons() -> void:
	dialogue_continue_button.visible = false
	dialogue_recruit_button.visible = false
	dialogue_attack_button.visible = false
	dialogue_trade_button.visible = false
	dialogue_rumor_button.visible = false
	dialogue_buy_food_button.visible = false
	dialogue_take_food_button.visible = false
	dialogue_hide_button.visible = false
	if _loot_take_silver_button != null:
		_loot_take_silver_button.visible = false
	dialogue_buy_food_button.disabled = false
	dialogue_take_food_button.disabled = false


func _force_lord_encounter(target: Dictionary) -> void:
	player.stop_travel()
	_pending_encounter = {}
	GameState.last_campaign_notice = "%s has caught you on the road." % String(target.get("name", "A hostile lord"))
	_show_dialogue(target)


func _is_player_in_safe_place() -> bool:
	var settlement: Dictionary = campaign_map.get_nearest_settlement(player.global_position, 70.0)
	if settlement.is_empty():
		return false
	var settlement_name := String(settlement.get("name", ""))
	return settlement_name in ["Ramah", "Nob", "Bethlehem", "Hebron", "Keilah", "Ziklag", "En-gedi"]


func _maybe_complete_ziklag_objective(target: Dictionary) -> void:
	if GameState.objective_complete:
		return
	if String(target.get("type", "")) != "settlement":
		return
	if String(target.get("name", "")) != "Ziklag":
		return
	if GameState.get_party_men_count() < GameState.get_objective_target_men():
		return

	GameState.objective_complete = true
	GameState.adjust_morale(8)
	GameState.last_campaign_notice = "Ziklag is reached. The first pressure loop is won."
	campaign_map.break_player_trail_at(player.global_position, "Ziklag refuge")
	GameState.clear_all_lord_pursuit_states()


func _can_take_food_by_force() -> bool:
	return GameState.get_party_men_count() >= FOOD_TAKE_MINIMUM_MEN


func _build_rumor_text() -> String:
	var lines := PackedStringArray()
	var rumor_context := _rumor_context_for_dialogue_target()
	var rumor_facts: Array[Dictionary] = campaign_map.get_rumor_facts(player.global_position)
	if rumor_facts.is_empty():
		lines.append(_no_hostile_rumor_text(rumor_context))
	else:
		lines.append(_format_lord_rumor(rumor_facts[0], rumor_context))
		if rumor_facts.size() > 1 and _should_add_second_rumor(rumor_facts[1], rumor_context):
			lines.append(_format_secondary_lord_rumor(rumor_facts[1], rumor_context))

	var highest_fact: Dictionary = rumor_facts[0] if not rumor_facts.is_empty() else {}
	var highest_state := String(highest_fact.get("state", ""))
	if highest_state == "pursuing":
		lines.append("%s is not patrolling now. He is following your trail." % String(highest_fact.get("name", "A hostile lord")))
	elif GameState.heat >= 25:
		lines.append(_heat_rumor_text(rumor_context))
	else:
		lines.append(_routine_rumor_text(rumor_context))

	var recruit_names: Array[String] = campaign_map.get_recruitable_settlement_names()
	if recruit_names.is_empty():
		lines.append("No town nearby can spare more men today.")
	else:
		lines.append("Men can still be found at %s." % _format_name_list(recruit_names, 3))

	var remaining := maxi(0, GameState.get_objective_target_men() - GameState.get_party_men_count())
	if remaining <= 0:
		lines.append("You have enough men. Reach Ziklag and make it count.")
	else:
		lines.append("You still need %d more men before Ziklag is more than a hiding place." % remaining)

	return "\n".join(lines)


func _format_lord_rumor(fact: Dictionary, rumor_context: Dictionary) -> String:
	var lord_name := String(fact.get("name", "a hostile lord"))
	var direction := String(fact.get("direction", "nearby"))
	var distance := int(float(fact.get("distance", 0.0)) / 3.0)
	var state := String(fact.get("state", "patrol"))
	var confidence := float(fact.get("confidence", 0.0))
	var report_strength := _report_strength_text(confidence, rumor_context)
	var history_clause := _history_rumor_clause(fact)

	match state:
		"pursuing":
			return "%s is hunting from %s, roughly %d map-paces to the %s%s." % [lord_name, report_strength, distance, direction, history_clause]
		"search":
			return "%s is searching from %s, roughly %d map-paces to the %s%s." % [lord_name, report_strength, distance, direction, history_clause]
		"retreat":
			return "%s is pulling back from a stronger force, roughly %d map-paces to the %s%s." % [lord_name, distance, direction, history_clause]
		"intercept":
			return "%s has moved to block likely roads, roughly %d map-paces to the %s%s." % [lord_name, distance, direction, history_clause]
		"muster":
			return "%s is gathering support before risking a chase, roughly %d map-paces to the %s%s." % [lord_name, distance, direction, history_clause]
		"recover", "holding":
			return "%s is said to be near town, roughly %d map-paces to the %s%s." % [lord_name, distance, direction, history_clause]
		_:
			return "%s is patrolling roughly %d map-paces to the %s%s." % [lord_name, distance, direction, history_clause]


func _history_rumor_clause(fact: Dictionary) -> String:
	var rank := String(fact.get("history_rank", "unknown"))
	var score := int(round(float(fact.get("nemesis_score", 0.0))))
	match rank:
		"nemesis":
			return "; this has become personal (%d)" % score
		"rival":
			return "; old encounters sharpen his interest"
		"haunted":
			return "; he remembers past defeats too well"
		"watchful":
			return "; he has not forgotten you"
		_:
			return ""


func _format_secondary_lord_rumor(fact: Dictionary, rumor_context: Dictionary) -> String:
	var lord_name := String(fact.get("name", "another hostile lord"))
	var direction := String(fact.get("direction", "nearby"))
	var state := String(fact.get("state", "patrol"))
	var confidence := float(fact.get("confidence", 0.0))
	var context_type := String(rumor_context.get("type", "neutral"))
	if context_type == "hostile" and confidence < 55.0:
		return "Someone mentions %s, then remembers urgent business elsewhere." % lord_name
	if state == "retreat":
		return "%s is said to be backing away from trouble." % lord_name
	if state == "muster":
		return "%s seems to be calling for a stronger hand before moving." % lord_name
	if state == "recover" or state == "holding":
		return "%s seems tied near town for now, if that talk is clean." % lord_name
	return "A second report puts %s somewhere to the %s." % [lord_name, direction]


func _should_add_second_rumor(fact: Dictionary, rumor_context: Dictionary) -> bool:
	var confidence := float(fact.get("confidence", 0.0))
	var context_type := String(rumor_context.get("type", "neutral"))
	if context_type == "friendly":
		return confidence >= 12.0 or GameState.heat >= 20
	if context_type == "hostile":
		return confidence >= 45.0
	return confidence >= 25.0 or GameState.heat >= 35


func _rumor_context_for_dialogue_target() -> Dictionary:
	var settlement_name := String(_dialogue_target.get("name", ""))
	var owner := String(_dialogue_target.get("owner_faction", ""))
	var kind := String(_dialogue_target.get("kind", "")).to_lower()
	var context_type := "neutral"
	var quality := 0.55
	if owner == "Judah" or owner == "David's Band" or settlement_name in ["Bethlehem", "Hebron", "Keilah", "Ziklag", "En-gedi"]:
		context_type = "friendly"
		quality = 0.82
	elif owner == "House of Saul" or owner == "Philistine Lords" or owner == "Edomite Retinue" or settlement_name in ["Gibeah", "Gath", "Ashkelon", "Gaza", "Nob"]:
		context_type = "hostile"
		quality = 0.38
	elif kind.contains("fortress") or kind.contains("court") or kind.contains("port"):
		quality = 0.62
	return {
		"type": context_type,
		"quality": quality,
		"settlement_name": settlement_name
	}


func _report_strength_text(confidence: float, rumor_context: Dictionary) -> String:
	var quality := float(rumor_context.get("quality", 0.55))
	var effective_confidence := confidence * lerpf(0.72, 1.18, quality)
	if effective_confidence >= 70.0:
		return "a hard report"
	if effective_confidence >= 35.0:
		return "usable rumor"
	if String(rumor_context.get("type", "neutral")) == "hostile":
		return "careful half-answers"
	return "thin gossip"


func _no_hostile_rumor_text(rumor_context: Dictionary) -> String:
	match String(rumor_context.get("type", "neutral")):
		"friendly":
			return "No friendly ear has seen a hostile banner close by."
		"hostile":
			return "No one admits to seeing a hostile banner close by."
		_:
			return "No one has seen a hostile banner close by."


func _heat_rumor_text(rumor_context: Dictionary) -> String:
	match String(rumor_context.get("type", "neutral")):
		"friendly":
			return "Friends say gatekeepers are being pressed for your road and your numbers."
		"hostile":
			return "Gatekeepers answer sharply because your name has value here."
		_:
			return "Gatekeepers and traders answer sharper questions because your name is getting hotter."


func _routine_rumor_text(rumor_context: Dictionary) -> String:
	match String(rumor_context.get("type", "neutral")):
		"friendly":
			return "Friendly talk says most hostile riders still work from routine roads and gate gossip."
		"hostile":
			return "The answers are guarded. Routine patrols are easier to confirm than fresh orders."
		_:
			return "Most hostile riders still work from road routine and gate gossip."


func _format_name_list(names: Array[String], limit: int) -> String:
	var shown := PackedStringArray()
	var count := mini(names.size(), limit)
	for index in range(count):
		shown.append(names[index])
	var text := ", ".join(shown)
	if names.size() > limit:
		text += ", and others"
	return text


func _roll_recruit_count_for(target: Dictionary) -> int:
	if String(target.get("type", "")) != "settlement":
		return 0
	if not GameState.can_recruit_from_settlement(String(target.get("name", ""))):
		return 0
	var recruit_bonus := _settlement_recruit_bonus(target)
	return randi_range(MIN_RECRUIT_COUNT + recruit_bonus, MAX_RECRUIT_COUNT + recruit_bonus)


func _settlement_recruit_bonus(settlement: Dictionary) -> int:
	var settlement_class := String(settlement.get("settlement_class", "")).to_lower()
	var kind := String(settlement.get("kind", "")).to_lower()
	var type_label := _location_type_for(settlement).to_lower()
	var density := int(settlement.get("settlement_density", 0))

	if settlement_class.contains("city") or kind.contains("city") or type_label.contains("city") or density >= 5:
		return CITY_RECRUIT_BONUS
	if settlement_class.contains("town") or kind.contains("town") or type_label.contains("town") or density >= 3:
		return TOWN_RECRUIT_BONUS
	return 0


func _can_recruit_from_dialogue_town() -> bool:
	return _dialogue_recruit_count > 0 \
		and GameState.can_recruit_from_settlement(String(_dialogue_target.get("name", "")))


func _is_manual_movement_pressed() -> bool:
	return Input.is_key_pressed(KEY_A) \
		or Input.is_key_pressed(KEY_D) \
		or Input.is_key_pressed(KEY_W) \
		or Input.is_key_pressed(KEY_S) \
		or Input.is_key_pressed(KEY_LEFT) \
		or Input.is_key_pressed(KEY_RIGHT) \
		or Input.is_key_pressed(KEY_UP) \
		or Input.is_key_pressed(KEY_DOWN)


func _should_follow_mouse_pointer() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
		and _pending_encounter.is_empty() \
		and not dialogue_panel.visible \
		and not _is_pointer_over_inventory() \
		and not _is_pointer_over_market() \
		and not _is_pointer_over_party() \
		and not _is_pointer_over_cheat_panel()


func _is_pointer_over_inventory() -> bool:
	var viewport := get_viewport()
	if viewport == null:
		return false
	return inventory_panel.visible \
		and inventory_panel.get_global_rect().has_point(viewport.get_mouse_position())


func _is_pointer_over_market() -> bool:
	var viewport := get_viewport()
	if viewport == null:
		return false
	return market_panel.visible \
		and market_panel.get_global_rect().has_point(viewport.get_mouse_position())


func _is_pointer_over_party() -> bool:
	var viewport := get_viewport()
	if viewport == null:
		return false
	return party_panel.visible \
		and party_panel.get_global_rect().has_point(viewport.get_mouse_position())


func _is_pointer_over_cheat_panel() -> bool:
	var viewport := get_viewport()
	if viewport == null or _cheat_panel == null:
		return false
	return _cheat_panel.visible \
		and _cheat_panel.get_global_rect().has_point(viewport.get_mouse_position())


func _is_dialogue_advance_click(event: InputEvent) -> bool:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null:
		return false
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return false
	if not dialogue_continue_button.visible:
		return false

	var viewport := get_viewport()
	if viewport == null:
		return false

	return dialogue_panel.get_global_rect().has_point(viewport.get_mouse_position())


func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _smooth_zoom(delta: float) -> void:
	if camera == null:
		return
	var current_zoom := camera.zoom.x
	var new_zoom := lerpf(current_zoom, _target_zoom, clampf(ZOOM_LERP_SPEED * delta, 0.0, 1.0))
	camera.zoom = Vector2(new_zoom, new_zoom)
	campaign_map.camera_zoom = new_zoom
	if absf(new_zoom - current_zoom) > 0.001:
		campaign_map.queue_redraw()


func _exit_tree() -> void:
	if is_instance_valid(player) and is_instance_valid(inventory_panel) and is_instance_valid(market_panel) and is_instance_valid(party_panel):
		_save_campaign_state()
