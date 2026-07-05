extends Node2D

@onready var campaign_map = $CampaignMap
@onready var player = $Player
@onready var location_label: Label = $HUD/LocationLabel
@onready var dialogue_panel: Panel = $HUD/DialoguePanel
@onready var dialogue_title: Label = $HUD/DialoguePanel/TitleLabel
@onready var dialogue_body: Label = $HUD/DialoguePanel/BodyLabel
@onready var dialogue_continue_button: Button = $HUD/DialoguePanel/ContinueButton
@onready var dialogue_trade_button: Button = $HUD/DialoguePanel/TradeButton
@onready var dialogue_leave_button: Button = $HUD/DialoguePanel/LeaveButton
@onready var inventory_panel: Panel = $HUD/InventoryPanel
@onready var market_panel: Panel = $HUD/MarketPanel

var _last_location := ""
var _pending_encounter: Dictionary = {}
var _dialogue_pages: Array[String] = []
var _dialogue_page_index := 0
var _dialogue_target: Dictionary = {}


func _ready() -> void:
	player.world_bounds = campaign_map.get_playable_rect()
	dialogue_panel.visible = false
	inventory_panel.visible = false
	market_panel.visible = false
	dialogue_continue_button.pressed.connect(_advance_dialogue)
	dialogue_trade_button.pressed.connect(_open_trade)
	dialogue_leave_button.pressed.connect(_close_dialogue)
	_update_location_label(true)


func _process(_delta: float) -> void:
	if _is_manual_movement_pressed() and not _pending_encounter.is_empty():
		_pending_encounter = {}

	if _should_follow_mouse_pointer():
		player.travel_to(get_global_mouse_position())

	if not _pending_encounter.is_empty() and not dialogue_panel.visible:
		var target_position: Vector2 = _pending_encounter["pos"]
		if player.global_position.distance_to(target_position) <= 34.0:
			player.stop_travel()
			_show_dialogue(_pending_encounter)

	_update_location_label(false)


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_I:
		inventory_panel.visible = not inventory_panel.visible
		if not inventory_panel.visible:
			market_panel.visible = false
		_mark_input_handled()
		return

	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_F:
		_mark_input_handled()
		get_tree().change_scene_to_file("res://scenes/combat_test.tscn")
		return

	if dialogue_panel.visible:
		if _is_dialogue_advance_click(event):
			_advance_dialogue()
			_mark_input_handled()
		return

	if _is_pointer_over_inventory() or _is_pointer_over_market():
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


func _update_location_label(force: bool) -> void:
	var settlement: Dictionary = campaign_map.get_nearest_settlement(player.global_position)
	var label := "Open country"

	if not settlement.is_empty():
		label = "%s - %s" % [String(settlement["name"]), String(settlement["kind"])]

	if force or label != _last_location:
		_last_location = label
		location_label.text = label


func _show_dialogue(target: Dictionary) -> void:
	dialogue_title.text = String(target["name"])
	_dialogue_target = target.duplicate()
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
	dialogue_body.text = "The market opens its awnings. For now trade is barter-style: drag goods between the town market on the left and your inventory on the right. Prices and ownership rules come next."
	dialogue_continue_button.visible = false
	dialogue_trade_button.visible = false
	dialogue_leave_button.text = "Leave market"


func _dialogue_pages_for(target: Dictionary) -> Array[String]:
	if String(target["type"]) == "npc":
		return _npc_dialogue_pages(target)
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


func _render_dialogue_page() -> void:
	if _dialogue_pages.is_empty():
		dialogue_body.text = ""
	else:
		dialogue_body.text = _dialogue_pages[_dialogue_page_index]

	var has_next := _dialogue_page_index < _dialogue_pages.size() - 1
	var is_settlement := String(_dialogue_target.get("type", "")) == "settlement"
	dialogue_continue_button.visible = has_next
	dialogue_trade_button.visible = is_settlement and not has_next
	dialogue_leave_button.text = "Leave"


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
		and not _is_pointer_over_market()


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
