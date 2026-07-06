extends Node2D

const STARTING_DAY := 1
const MINUTES_PER_DAY := 24 * 60
const MOVEMENT_EPSILON := 0.05
const MIN_RECRUIT_COUNT := 1
const MAX_RECRUIT_COUNT := 3
const FOOD_BUY_AMOUNT := 4
const FOOD_BUY_SILVER_COST := 5
const FOOD_TAKE_AMOUNT := 7
const FOOD_TAKE_MINIMUM_MEN := 12
const ZOOM_MIN := 0.18
const ZOOM_MAX := 1.2
const ZOOM_STEP := 0.08
const ZOOM_LERP_SPEED := 8.0
const HIDE_MINUTES := 3 * 60
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


func _ready() -> void:
	player.world_bounds = campaign_map.get_playable_rect()
	_restore_campaign_state()
	_last_player_position = player.global_position
	campaign_map.player_position = player.global_position
	_target_zoom = camera.zoom.x
	dialogue_panel.visible = false
	inventory_panel.visible = false
	market_panel.visible = false
	party_panel.visible = false
	_build_cheat_panel()
	_build_loot_controls()
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
	campaign_map.player_position = player.global_position
	if _advance_time_if_player_moved(delta):
		GameState.advance_travel_survival(delta)
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
	player.global_position = GameState.campaign_position
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
	if total_minutes == _last_shown_game_minute:
		return

	_last_shown_game_minute = total_minutes
	GameState.game_total_minutes = total_minutes
	var day := STARTING_DAY + int(total_minutes / MINUTES_PER_DAY)
	var minute_of_day := total_minutes % MINUTES_PER_DAY
	var hour := int(minute_of_day / 60)
	var minute := minute_of_day % 60
	time_label.text = "Day %d  %02d:%02d" % [day, hour, minute]


func _update_status_label() -> void:
	var status := "%s\n%s" % [GameState.get_survival_text(), GameState.get_objective_text()]
	if not GameState.last_campaign_notice.is_empty():
		status += "\n%s" % GameState.last_campaign_notice
	status_label.text = status
	status_label.modulate = Color("#ffb09c") if GameState.food <= 2 or GameState.morale <= 25 else Color.WHITE


func _build_cheat_panel() -> void:
	_cheat_panel = Panel.new()
	_cheat_panel.name = "CheatPanel"
	_cheat_panel.visible = false
	_cheat_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_cheat_panel.offset_left = 454.0
	_cheat_panel.offset_top = 118.0
	_cheat_panel.offset_right = 826.0
	_cheat_panel.offset_bottom = 456.0
	_cheat_panel.add_theme_stylebox_override("panel", _make_cheat_panel_style())
	hud.add_child(_cheat_panel)

	var layout := VBoxContainer.new()
	layout.position = Vector2(22.0, 18.0)
	layout.size = Vector2(328.0, 300.0)
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

	_cheat_notice_label = Label.new()
	_cheat_notice_label.custom_minimum_size = Vector2(328.0, 44.0)
	_cheat_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cheat_notice_label.add_theme_font_size_override("font_size", 15)
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


func _finish_cheat(message: String) -> void:
	GameState.last_campaign_notice = "Dev cheat: %s" % message
	_save_campaign_state()
	_update_status_label()
	if _cheat_notice_label != null:
		_cheat_notice_label.text = message


func _format_signed_amount(amount: int) -> String:
	if amount >= 0:
		return "+%d" % amount
	return "%d" % amount


func _show_dialogue(target: Dictionary) -> void:
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

	GameState.set_game_total_minutes(GameState.get_game_total_minutes() + HIDE_MINUTES)
	GameState.adjust_food(-1)
	GameState.adjust_morale(1)
	GameState.clear_lord_pursuit_state("Abner ben Ner")
	GameState.last_campaign_notice = "You lie low until the road quiets."
	dialogue_body.text = "You keep the men under roofs and behind walls until the road has fewer eyes. Time passes. Food -1. Morale +1. Any immediate pursuit is broken."
	_update_time_label()
	campaign_map.queue_redraw()
	_hide_settlement_action_buttons()
	_update_status_label()


func _start_lord_combat() -> void:
	if String(_dialogue_target.get("type", "")) != "lord":
		return

	_save_campaign_state()
	GameState.start_lord_combat(_dialogue_target, GameState.get_party_data())
	get_tree().change_scene_to_file("res://scenes/combat_test.tscn")


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
		"The meeting is brief. Messengers shift in their saddles, guards count your companions, and the road keeps pulling both parties onward."
	]


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
	GameState.last_campaign_notice = "Abner has caught you on the road."
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
	GameState.clear_all_lord_pursuit_states()


func _can_take_food_by_force() -> bool:
	return GameState.get_party_men_count() >= FOOD_TAKE_MINIMUM_MEN


func _build_rumor_text() -> String:
	var lines := PackedStringArray()
	var nearest_lord: Dictionary = campaign_map.get_nearest_hostile_lord_info(player.global_position)
	if nearest_lord.is_empty():
		lines.append("No one has seen a hostile banner close by.")
	else:
		var lord_name := String(nearest_lord.get("name", "a hostile lord"))
		var direction := String(nearest_lord.get("direction", "nearby"))
		var distance := int(float(nearest_lord.get("distance", 0.0)) / 3.0)
		lines.append("%s is roughly %d map-paces to the %s." % [lord_name, distance, direction])

	var abner_state := String(GameState.get_lord_pursuit_state("Abner ben Ner").get("state", ""))
	if abner_state == "pursuing":
		lines.append("Abner is not patrolling now. He is following your trail.")
	elif GameState.heat >= 25:
		lines.append("Saul's men ask sharper questions because your name is getting hotter.")
	else:
		lines.append("Abner's riders are still searching by roads and gate gossip.")

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
	return randi_range(MIN_RECRUIT_COUNT, MAX_RECRUIT_COUNT)


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
