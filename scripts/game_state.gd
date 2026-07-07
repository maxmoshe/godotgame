extends Node

const GAME_MINUTES_PER_REAL_SECOND := 10.0
const RECRUIT_COOLDOWN_MINUTES := 4 * 60
const STARTING_POSITION := Vector2(84.0, 774.0)
const STARTING_TOTAL_MINUTES := 6 * 60
const STARTING_FOOD := 18
const STARTING_SILVER := 14
const STARTING_MORALE := 65
const STARTING_HEAT := 0
const OBJECTIVE_TARGET_MEN := 8
const FOOD_TRAVEL_MINUTES_PER_UNIT := 90
const LORD_DEFEAT_RECOVERY_MINUTES := 2 * 24 * 60
const LORD_LOOT_TABLE := [
	{"id": "sling_stones", "min": 6, "max": 18, "weight": 36},
	{"id": "barley_bread", "min": 1, "max": 4, "weight": 28},
	{"id": "wool_cloth", "min": 1, "max": 3, "weight": 16},
	{"id": "olive_oil", "min": 1, "max": 2, "weight": 12},
	{"id": "bronze_dagger", "min": 1, "max": 1, "weight": 8}
]

var campaign_position := STARTING_POSITION
var game_total_minutes := STARTING_TOTAL_MINUTES
var food := STARTING_FOOD
var silver := STARTING_SILVER
var morale := STARTING_MORALE
var heat := STARTING_HEAT
var objective_complete := false
var player_inventory_slots: Array = []
var market_inventory_slots: Array = []
var map_state: Dictionary = {}
var combat_context: Dictionary = {}
var lord_pursuit_states: Dictionary = {}
var defeated_lords: Dictionary = {}
var pending_campaign_loot: Dictionary = {}
var last_campaign_notice := ""
var party_data := {
	"player_name": "David",
	"player_health": 100,
	"player_max_health": 100,
	"leader_intelligence": 50,
	"named_characters": [],
	"generic_soldier_count": 0
}
var settlement_recruit_available_minutes: Dictionary = {}
var _game_minute_fraction := 0.0
var _food_travel_minute_fraction := 0.0


func advance_game_time(real_seconds: float) -> void:
	_game_minute_fraction += real_seconds * GAME_MINUTES_PER_REAL_SECOND
	var whole_minutes := int(floor(_game_minute_fraction))
	if whole_minutes <= 0:
		return

	game_total_minutes += whole_minutes
	_game_minute_fraction -= float(whole_minutes)


func get_game_total_minutes() -> int:
	return game_total_minutes


func sync_game_time() -> void:
	pass


func set_game_total_minutes(total_minutes: int) -> void:
	game_total_minutes = total_minutes
	_game_minute_fraction = 0.0


func advance_travel_survival(real_seconds: float) -> void:
	_food_travel_minute_fraction += real_seconds * GAME_MINUTES_PER_REAL_SECOND
	var spendable_minutes := int(floor(_food_travel_minute_fraction))
	if spendable_minutes < FOOD_TRAVEL_MINUTES_PER_UNIT:
		return

	var food_to_consume := int(spendable_minutes / FOOD_TRAVEL_MINUTES_PER_UNIT)
	_food_travel_minute_fraction -= float(food_to_consume * FOOD_TRAVEL_MINUTES_PER_UNIT)

	if food > 0:
		var eaten := mini(food, food_to_consume)
		food -= eaten
		food_to_consume -= eaten

	if food_to_consume > 0:
		adjust_morale(-food_to_consume * 3)
		last_campaign_notice = "The band is hungry. Morale is slipping."


func adjust_food(amount: int) -> void:
	food = clampi(food + amount, 0, 99)


func adjust_silver(amount: int) -> void:
	silver = maxi(0, silver + amount)


func can_spend_silver(amount: int) -> bool:
	return silver >= amount


func spend_silver(amount: int) -> bool:
	if not can_spend_silver(amount):
		return false
	silver -= amount
	return true


func adjust_morale(amount: int) -> void:
	morale = clampi(morale + amount, 0, 100)


func adjust_heat(amount: int) -> void:
	heat = clampi(heat + amount, 0, 100)


func get_objective_target_men() -> int:
	return OBJECTIVE_TARGET_MEN


func get_party_men_count() -> int:
	return int(party_data.get("generic_soldier_count", 0))


func get_objective_text() -> String:
	var count := get_party_men_count()
	if objective_complete:
		return "Ziklag reached with %d men" % count
	return "Reach Ziklag with %d men: %d/%d" % [OBJECTIVE_TARGET_MEN, count, OBJECTIVE_TARGET_MEN]


func get_survival_text() -> String:
	return "Food %d | Silver %d | Morale %d | Heat %d" % [food, silver, morale, heat]


func set_lord_pursuit_state(lord_name: String, state: Dictionary) -> void:
	lord_pursuit_states[lord_name] = state.duplicate(true)


func get_lord_pursuit_state(lord_name: String) -> Dictionary:
	var state: Variant = lord_pursuit_states.get(lord_name, {})
	if state is Dictionary:
		return Dictionary(state).duplicate(true)
	return {}


func clear_lord_pursuit_state(lord_name: String) -> void:
	lord_pursuit_states.erase(lord_name)


func clear_all_lord_pursuit_states() -> void:
	lord_pursuit_states.clear()


func mark_lord_defeated(lord_name: String) -> void:
	if lord_name.is_empty():
		return
	defeated_lords[lord_name] = game_total_minutes + LORD_DEFEAT_RECOVERY_MINUTES
	clear_lord_pursuit_state(lord_name)


func is_lord_defeated(lord_name: String) -> bool:
	var defeat_entry = defeated_lords.get(lord_name, false)
	if defeat_entry is bool:
		return bool(defeat_entry)
	var recovery_minute := int(defeat_entry)
	if recovery_minute <= 0:
		return false
	if game_total_minutes < recovery_minute:
		return true
	defeated_lords.erase(lord_name)
	return false


func get_lord_defeat_minutes_remaining(lord_name: String) -> int:
	var defeat_entry = defeated_lords.get(lord_name, false)
	if defeat_entry is bool:
		return LORD_DEFEAT_RECOVERY_MINUTES if bool(defeat_entry) else 0
	return maxi(0, int(defeat_entry) - game_total_minutes)


func can_recruit_from_settlement(settlement_name: String) -> bool:
	return get_settlement_recruit_minutes_remaining(settlement_name) <= 0


func start_settlement_recruit_cooldown(settlement_name: String) -> void:
	settlement_recruit_available_minutes[settlement_name] = game_total_minutes + RECRUIT_COOLDOWN_MINUTES


func get_settlement_recruit_minutes_remaining(settlement_name: String) -> int:
	var available_minute := int(settlement_recruit_available_minutes.get(settlement_name, 0))
	return maxi(0, available_minute - game_total_minutes)


func has_player_inventory() -> bool:
	return not player_inventory_slots.is_empty()


func has_market_inventory() -> bool:
	return not market_inventory_slots.is_empty()


func save_party_data(data: Dictionary) -> void:
	party_data = data.duplicate(true)


func get_party_data() -> Dictionary:
	return party_data.duplicate(true)


func start_lord_combat(lord: Dictionary, player_party: Dictionary) -> void:
	var lord_name := String(lord.get("lord_id", lord.get("name", "Enemy lord")))
	combat_context = {
		"type": "lord",
		"enemy_lord_id": lord_name,
		"enemy_name": String(lord.get("name", lord_name)),
		"enemy_title": String(lord.get("title", "lord")),
		"enemy_faction": String(lord.get("faction", "Enemy party")),
		"enemy_party_size": int(lord.get("party_size", 0)),
		"player_party": player_party.duplicate(true)
	}


func clear_combat_context() -> void:
	combat_context = {}


func has_combat_context() -> bool:
	return not combat_context.is_empty()


func get_combat_context() -> Dictionary:
	return combat_context.duplicate(true)


func has_pending_campaign_loot() -> bool:
	return not pending_campaign_loot.is_empty()


func get_pending_campaign_loot() -> Dictionary:
	return pending_campaign_loot.duplicate(true)


func clear_pending_campaign_loot() -> void:
	pending_campaign_loot = {}


func get_pending_campaign_loot_silver() -> int:
	return int(pending_campaign_loot.get("silver", 0))


func claim_pending_campaign_loot_silver() -> int:
	var silver_gain := get_pending_campaign_loot_silver()
	if silver_gain <= 0:
		return 0
	adjust_silver(silver_gain)
	pending_campaign_loot["silver"] = 0
	return silver_gain


func apply_lord_combat_result(result: Dictionary) -> void:
	var lord_name := String(result.get("enemy_lord_id", result.get("enemy_name", "")))
	var outcome := String(result.get("outcome", "retreat"))
	var enemy_start := maxi(0, int(result.get("enemy_start_count", 0)))
	var enemy_dead := clampi(int(result.get("enemy_dead_count", 0)), 0, enemy_start)
	var enemy_fled := clampi(int(result.get("enemy_fled_count", 0)), 0, maxi(0, enemy_start - enemy_dead))
	var enemy_survivors := maxi(0, enemy_start - enemy_dead)
	var friendly_dead := maxi(0, int(result.get("friendly_dead_count", 0)))
	var friendly_fled := maxi(0, int(result.get("friendly_fled_count", 0)))
	var player_health := maxi(0, int(result.get("player_health", 0)))
	var player_max_health := maxi(1, int(result.get("player_max_health", 1)))

	_apply_party_combat_losses(friendly_dead, player_health, player_max_health)
	_apply_lord_party_combat_losses(lord_name, enemy_survivors, outcome == "victory")
	_apply_combat_campaign_notice(String(result.get("enemy_name", lord_name)), outcome, enemy_start, enemy_dead, enemy_fled, friendly_dead, friendly_fled)
	clear_combat_context()


func _apply_party_combat_losses(friendly_dead: int, combat_player_health: int, combat_player_max_health: int) -> void:
	var generic_count := maxi(0, int(party_data.get("generic_soldier_count", 0)))
	party_data["generic_soldier_count"] = maxi(0, generic_count - friendly_dead)

	var party_max_health := maxi(1, int(party_data.get("player_max_health", 100)))
	var health_ratio := clampf(float(combat_player_health) / float(combat_player_max_health), 0.0, 1.0)
	party_data["player_health"] = int(round(float(party_max_health) * health_ratio))


func _apply_lord_party_combat_losses(lord_name: String, enemy_survivors: int, defeated: bool) -> void:
	if lord_name.is_empty():
		return

	if defeated:
		mark_lord_defeated(lord_name)

	var saved_parties := Array(map_state.get("lord_parties", []))
	var updated_parties: Array = []
	var found_lord := false
	for saved in saved_parties:
		if not (saved is Dictionary):
			continue
		var saved_lord := Dictionary(saved).duplicate(true)
		if String(saved_lord.get("name", "")) == lord_name:
			found_lord = true
			if defeated:
				continue
			saved_lord["party_size"] = enemy_survivors
		updated_parties.append(saved_lord)

	if not found_lord and not defeated:
		updated_parties.append({
			"name": lord_name,
			"pos": campaign_position,
			"route_index": 1,
			"party_size": enemy_survivors
		})

	map_state["lord_parties"] = updated_parties


func _apply_combat_campaign_notice(enemy_name: String, outcome: String, enemy_army_size: int, enemy_dead: int, enemy_fled: int, friendly_dead: int, friendly_fled: int) -> void:
	var casualty_text := "No men lost."
	if friendly_dead == 1:
		casualty_text = "1 of your men is dead."
	elif friendly_dead > 1:
		casualty_text = "%d of your men are dead." % friendly_dead
	if friendly_fled == 1:
		casualty_text += " 1 man fled the field."
	elif friendly_fled > 1:
		casualty_text += " %d men fled the field." % friendly_fled

	var enemy_result_text := "Enemy dead: %d." % enemy_dead
	if enemy_fled == 1:
		enemy_result_text += " 1 enemy fled."
	elif enemy_fled > 1:
		enemy_result_text += " %d enemies fled." % enemy_fled

	if outcome == "victory":
		var loot := _roll_lord_victory_loot(enemy_name, enemy_army_size)
		pending_campaign_loot = loot
		var silver_gain := int(loot.get("silver", 0))
		adjust_morale(5)
		last_campaign_notice = "%s is defeated. %s Loot found: %d silver, %s. %s" % [
			enemy_name,
			enemy_result_text,
			silver_gain,
			_format_loot_items(Array(loot.get("items", []))),
			casualty_text
		]
	elif outcome == "defeat":
		adjust_morale(-8)
		last_campaign_notice = "You are driven from the field by %s. %s %s" % [enemy_name, enemy_result_text, casualty_text]
	else:
		adjust_morale(-2 if friendly_dead > 0 else 0)
		last_campaign_notice = "You break off from %s. %s %s" % [enemy_name, enemy_result_text, casualty_text]


func _roll_lord_victory_loot(enemy_name: String, enemy_army_size: int) -> Dictionary:
	var silver_gain := maxi(1, int(round(float(maxi(1, enemy_army_size)) * randf_range(0.75, 1.25))))
	var item_count := randi_range(2, 3)
	var items: Array = []
	for _index in range(item_count):
		items.append(_roll_lord_loot_item())
	return {
		"source": enemy_name,
		"silver": silver_gain,
		"items": items
	}


func _roll_lord_loot_item() -> Dictionary:
	var total_weight := 0
	for entry in LORD_LOOT_TABLE:
		total_weight += int(entry["weight"])

	var roll := randi_range(1, total_weight)
	var cursor := 0
	for entry in LORD_LOOT_TABLE:
		cursor += int(entry["weight"])
		if roll <= cursor:
			return {
				"id": String(entry["id"]),
				"amount": randi_range(int(entry["min"]), int(entry["max"]))
			}

	var fallback: Dictionary = LORD_LOOT_TABLE[0]
	return {
		"id": String(fallback["id"]),
		"amount": randi_range(int(fallback["min"]), int(fallback["max"]))
	}


func _format_loot_items(items: Array) -> String:
	var parts := PackedStringArray()
	for item in items:
		if not (item is Dictionary):
			continue
		var loot_item := Dictionary(item)
		var amount := int(loot_item.get("amount", 0))
		var item_id := String(loot_item.get("id", "loot"))
		if amount <= 0:
			continue
		parts.append("%dx %s" % [amount, _loot_item_name(item_id)])
	if parts.is_empty():
		return "no items"
	return ", ".join(parts)


func _loot_item_name(item_id: String) -> String:
	match item_id:
		"sling_stones":
			return "sling stones"
		"barley_bread":
			return "barley bread"
		"wool_cloth":
			return "wool cloth"
		"olive_oil":
			return "olive oil"
		"bronze_dagger":
			return "bronze dagger"
		_:
			return item_id.replace("_", " ")
