extends Node

const GAME_MINUTES_PER_REAL_SECOND := 2.0
const RECRUIT_COOLDOWN_MINUTES := 4 * 60
const STARTING_POSITION := Vector2(84.0, 774.0)
const STARTING_TOTAL_MINUTES := 6 * 60
const STARTING_FOOD := 18
const STARTING_SILVER := 14
const STARTING_MORALE := 65
const STARTING_HEAT := 0
const OBJECTIVE_TARGET_MEN := 8
const FOOD_TRAVEL_MINUTES_PER_UNIT := 90

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
var last_campaign_notice := ""
var party_data := {
	"player_name": "David",
	"player_health": 100,
	"player_max_health": 100,
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
	combat_context = {
		"type": "lord",
		"enemy_name": String(lord.get("name", "Enemy lord")),
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
