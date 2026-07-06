extends Node2D

const STARTING_DAY := 1
const MINUTES_PER_DAY := 24 * 60
const MOVEMENT_EPSILON := 0.05
const MIN_RECRUIT_COUNT := 1
const MAX_RECRUIT_COUNT := 3

@onready var campaign_map = $CampaignMap
@onready var player: CharacterBody2D = $Player
@onready var location_label: Label = $HUD/LocationLabel
@onready var time_label: Label = $HUD/TimeLabel
@onready var dialogue_panel: Panel = $HUD/DialoguePanel
@onready var dialogue_title: Label = $HUD/DialoguePanel/TitleLabel
@onready var dialogue_body: Label = $HUD/DialoguePanel/BodyLabel
@onready var dialogue_continue_button: Button = $HUD/DialoguePanel/ContinueButton
@onready var dialogue_recruit_button: Button = $HUD/DialoguePanel/RecruitButton
@onready var dialogue_attack_button: Button = $HUD/DialoguePanel/AttackButton
@onready var dialogue_trade_button: Button = $HUD/DialoguePanel/TradeButton
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


func _ready() -> void:
	player.world_bounds = campaign_map.get_playable_rect()
	_restore_campaign_state()
	_last_player_position = player.global_position
	dialogue_panel.visible = false
	inventory_panel.visible = false
	market_panel.visible = false
	party_panel.visible = false
	dialogue_continue_button.pressed.connect(_advance_dialogue)
	dialogue_recruit_button.pressed.connect(_recruit_soldiers)
	dialogue_attack_button.pressed.connect(_start_lord_combat)
	dialogue_trade_button.pressed.connect(_open_trade)
	dialogue_leave_button.pressed.connect(_close_dialogue)
	_update_location_label(true)
	_update_time_label()


func _process(delta: float) -> void:
	if _advance_time_if_player_moved(delta):
		campaign_map.advance_lord_parties_for_real_seconds(delta)
	_update_time_label()
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
	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_I:
		inventory_panel.visible = not inventory_panel.visible
		if inventory_panel.visible:
			party_panel.visible = false
		if not inventory_panel.visible:
			market_panel.visible = false
		_mark_input_handled()
		return

	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_P:
		party_panel.visible = not party_panel.visible
		if party_panel.visible:
			inventory_panel.visible = false
			market_panel.visible = false
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

	if _is_pointer_over_inventory() or _is_pointer_over_market() or _is_pointer_over_party():
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event == null:
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


func _save_campaign_state() -> void:
	GameState.campaign_position = player.global_position
	GameState.player_inventory_slots = inventory_panel.get_slots_copy()
	GameState.market_inventory_slots = market_panel.get_slots_copy()
	GameState.save_party_data(party_panel.get_party_data())


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


func _show_dialogue(target: Dictionary) -> void:
	dialogue_title.text = _dialogue_title_for(target)
	_dialogue_target = target.duplicate()
	_dialogue_recruit_count = _roll_recruit_count_for(target)
	_dialogue_pages = _dialogue_pages_for(target)
	_dialogue_page_index = 0
	dialogue_panel.visible = true
	_render_dialogue_page()
	_pending_encounter = {}


func _close_dialogue() -> void:
	var was_trading := market_panel.visible
	dialogue_panel.visible = false
	market_panel.visible = false
	if was_trading:
		inventory_panel.visible = false
	_dialogue_pages.clear()
	_dialogue_page_index = 0
	_dialogue_target = {}
	_dialogue_recruit_count = 0


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

	market_panel.visible = true
	inventory_panel.visible = true
	party_panel.visible = false
	dialogue_body.text = "The market opens its awnings. For now trade is barter-style: drag goods between the town market on the left and your inventory on the right. Prices and ownership rules come next."
	dialogue_continue_button.visible = false
	dialogue_recruit_button.visible = false
	dialogue_attack_button.visible = false
	dialogue_trade_button.visible = false
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
	_dialogue_recruit_count = 0

	var soldier_word := "soldier" if recruit_count == 1 else "soldiers"
	dialogue_body.text = "%d %s agree to march with you. The town needs time before more men can be spared." % [recruit_count, soldier_word]
	dialogue_continue_button.visible = false
	dialogue_recruit_button.visible = false
	dialogue_attack_button.visible = false
	dialogue_trade_button.visible = true
	dialogue_leave_button.text = "Leave"


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
	dialogue_leave_button.text = "Leave"


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
		and not _is_pointer_over_party()


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


func _exit_tree() -> void:
	if is_instance_valid(player) and is_instance_valid(inventory_panel) and is_instance_valid(market_panel) and is_instance_valid(party_panel):
		_save_campaign_state()
