extends Node2D

@onready var campaign_map = $CampaignMap
@onready var player = $Player
@onready var location_label: Label = $HUD/LocationLabel
@onready var dialogue_panel: Panel = $HUD/DialoguePanel
@onready var dialogue_title: Label = $HUD/DialoguePanel/TitleLabel
@onready var dialogue_body: Label = $HUD/DialoguePanel/BodyLabel
@onready var dialogue_leave_button: Button = $HUD/DialoguePanel/LeaveButton

var _last_location := ""
var _pending_encounter: Dictionary = {}


func _ready() -> void:
	player.world_bounds = campaign_map.get_playable_rect()
	dialogue_panel.visible = false
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
	if dialogue_panel.visible:
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
	var target_type := String(target["type"])
	dialogue_title.text = String(target["name"])

	if target_type == "npc":
		dialogue_body.text = String(target["dialogue"])
	else:
		dialogue_body.text = _settlement_dialogue(target)

	dialogue_panel.visible = true
	_pending_encounter = {}


func _close_dialogue() -> void:
	dialogue_panel.visible = false


func _settlement_dialogue(settlement: Dictionary) -> String:
	return "You arrive at %s, %s. The gate guard lowers his spear, then recognizes that you come openly. For now this is only the town encounter screen: later it can hold taverns, markets, recruitment, rumors, and faction business." % [
		String(settlement["name"]),
		String(settlement["kind"]).to_lower()
	]


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
		and not dialogue_panel.visible
