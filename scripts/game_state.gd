extends Node

const GAME_MINUTES_PER_REAL_SECOND := 2.0
const RECRUIT_COOLDOWN_MINUTES := 4 * 60
const STARTING_POSITION := Vector2(84.0, 774.0)
const STARTING_TOTAL_MINUTES := 6 * 60

var campaign_position := STARTING_POSITION
var game_total_minutes := STARTING_TOTAL_MINUTES
var player_inventory_slots: Array = []
var market_inventory_slots: Array = []
var map_state: Dictionary = {}
var combat_context: Dictionary = {}
var party_data := {
	"player_name": "David",
	"player_health": 100,
	"player_max_health": 100,
	"named_characters": [],
	"generic_soldier_count": 0
}
var settlement_recruit_available_minutes: Dictionary = {}
var _game_minute_fraction := 0.0


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
