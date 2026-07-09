extends Node

const GAME_MINUTES_PER_REAL_SECOND := 10.0
const RECRUIT_COOLDOWN_MINUTES := 4 * 60
const STARTING_POSITION := Vector2(84.0, 774.0)
const STARTING_TOTAL_MINUTES := 6 * 60
const STARTING_FOOD := 18
const STARTING_SILVER := 14
const STARTING_MORALE := 65
const STARTING_HEAT := 0
const PLAYER_SLING_XP_KEY := "player_sling_xp"
const OBJECTIVE_TARGET_MEN := 8
const FOOD_TRAVEL_MINUTES_PER_UNIT := 90
const LORD_DEFEAT_RECOVERY_MINUTES := 2 * 24 * 60
const LORD_HISTORY_LOG_LIMIT := 12
const LORD_RIVAL_THRESHOLD := 35.0
const LORD_NEMESIS_THRESHOLD := 70.0
const MAIN_STORY_QUESTS := [
	{
		"id": "shepherds_teeth",
		"title": "Shepherd's Teeth",
		"objective": "Defend Jesse's flock outside Bethlehem.",
		"target_names": ["Bethlehem"]
	},
	{
		"id": "bread_to_brothers",
		"title": "Bread to the Camp",
		"objective": "Carry food from Bethlehem to the Israelite camp at Socoh.",
		"target_names": ["Socoh"]
	},
	{
		"id": "court_music_bad_spear",
		"title": "Court Music, Bad Spear",
		"objective": "Go to Saul's court at Gibeah and survive the king's favor turning sharp.",
		"target_names": ["Gibeah"]
	},
	{
		"id": "nob_and_the_bread",
		"title": "Nob and the Bread",
		"objective": "Seek priestly help at Nob before Saul's men close the roads.",
		"target_names": ["Nob"]
	},
	{
		"id": "cave_of_adullam",
		"title": "Cave of Adullam",
		"objective": "Gather the distressed, indebted, and bitter-souled into a fighting band.",
		"target_names": ["Adullam"]
	},
	{
		"id": "keilah_border_fire",
		"title": "Keilah Border Fire",
		"objective": "Answer Keilah before raiders strip its threshing floors.",
		"target_names": ["Keilah"]
	},
	{
		"id": "engedi_mercy",
		"title": "En-gedi Mercy",
		"objective": "Lose Saul in the wilderness and choose restraint when you could strike.",
		"target_names": ["En-gedi"]
	},
	{
		"id": "ziklag_refuge",
		"title": "Ziklag Refuge",
		"objective": "Reach Ziklag with enough men to stop being only a fugitive.",
		"target_names": ["Ziklag"]
	}
]
const OPTIONAL_STORY_QUESTS := [
	{
		"id": "champion_in_the_valley",
		"title": "Champion in the Valley",
		"objective": "Optional: face the Philistine champion near Azekah and the Valley of Elah.",
		"target_names": ["Azekah"],
		"unlock_after": "bread_to_brothers"
	}
]
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
var completed_story_quests: Dictionary = {}
var player_inventory_slots: Array = []
var market_inventory_slots: Array = []
var map_state: Dictionary = {}
var combat_context: Dictionary = {}
var combat_map_context: Dictionary = {}
var lord_pursuit_states: Dictionary = {}
var defeated_lords: Dictionary = {}
var lord_histories: Dictionary = {}
var pending_campaign_loot: Dictionary = {}
var last_campaign_notice := ""
var party_data := {
	"player_name": "David",
	"player_health": 100,
	"player_max_health": 100,
	"player_sling_xp": 0,
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
	var active_story := get_active_main_story_quest()
	var count := get_party_men_count()
	if active_story.is_empty():
		return "Chapter complete: Ziklag reached with %d men" % count
	var title := String(active_story.get("title", "Story"))
	var objective := String(active_story.get("objective", "Follow the road."))
	if String(active_story.get("id", "")) == "ziklag_refuge" and count < OBJECTIVE_TARGET_MEN:
		objective = "Gather %d men, then reach Ziklag: %d/%d" % [OBJECTIVE_TARGET_MEN, count, OBJECTIVE_TARGET_MEN]
	return "%s: %s\nBand: %d/%d men" % [title, objective, count, OBJECTIVE_TARGET_MEN]


func is_story_quest_complete(quest_id: String) -> bool:
	return bool(completed_story_quests.get(quest_id, false))


func mark_story_quest_complete(quest_id: String) -> void:
	if quest_id.is_empty():
		return
	completed_story_quests[quest_id] = true


func get_active_main_story_quest() -> Dictionary:
	for quest in MAIN_STORY_QUESTS:
		var quest_dict := Dictionary(quest)
		if not is_story_quest_complete(String(quest_dict.get("id", ""))):
			return quest_dict.duplicate(true)
	return {}


func get_available_optional_story_quests() -> Array[Dictionary]:
	var quests: Array[Dictionary] = []
	for quest in OPTIONAL_STORY_QUESTS:
		var quest_dict := Dictionary(quest)
		var quest_id := String(quest_dict.get("id", ""))
		if is_story_quest_complete(quest_id):
			continue
		var unlock_after := String(quest_dict.get("unlock_after", ""))
		if not unlock_after.is_empty() and not is_story_quest_complete(unlock_after):
			continue
		quests.append(quest_dict.duplicate(true))
	return quests


func get_active_story_location_names() -> Array[String]:
	var names: Array[String] = []
	var active_main := get_active_main_story_quest()
	if not active_main.is_empty():
		_append_story_target_names(names, active_main)
	for quest in get_available_optional_story_quests():
		_append_story_target_names(names, quest)
	return names


func is_active_story_location(location_name: String) -> bool:
	return get_active_story_location_names().has(location_name)


func is_optional_story_location(location_name: String) -> bool:
	for quest in get_available_optional_story_quests():
		if Array(quest.get("target_names", [])).has(location_name):
			return true
	return false


func story_title_for_location(location_name: String) -> String:
	var active_main := get_active_main_story_quest()
	if Array(active_main.get("target_names", [])).has(location_name):
		return String(active_main.get("title", "Story"))
	for quest in get_available_optional_story_quests():
		if Array(quest.get("target_names", [])).has(location_name):
			return String(quest.get("title", "Story"))
	return ""


func _append_story_target_names(names: Array[String], quest: Dictionary) -> void:
	for raw_name in Array(quest.get("target_names", [])):
		var name := String(raw_name)
		if not name.is_empty() and not names.has(name):
			names.append(name)


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


func get_lord_history(lord_name: String) -> Dictionary:
	if lord_name.is_empty():
		return {}
	var history := _normalize_lord_history(lord_name, lord_histories.get(lord_name, {}))
	lord_histories[lord_name] = history
	return history.duplicate(true)


func record_lord_history_event(lord_name: String, event_type: String, details: Dictionary = {}) -> Dictionary:
	if lord_name.is_empty() or event_type.is_empty():
		return {}

	var history := _normalize_lord_history(lord_name, lord_histories.get(lord_name, {}))
	var text := String(details.get("text", ""))
	history["encounters"] = int(history.get("encounters", 0)) + 1
	history["last_event"] = event_type
	history["last_event_minute"] = game_total_minutes

	match event_type:
		"sighting":
			history["sightings"] = int(history.get("sightings", 0)) + 1
			_adjust_lord_history_scores(history, 2.0, 1.0, 0.0, 4.0, 0.0)
		"caught_player":
			history["catches"] = int(history.get("catches", 0)) + 1
			history["victories_against_player"] = int(history.get("victories_against_player", 0)) + 1
			_adjust_lord_history_scores(history, 5.0, 4.0, -4.0, 14.0, 0.0)
		"lost_trail":
			history["escapes"] = int(history.get("escapes", 0)) + 1
			_adjust_lord_history_scores(history, 7.0, 2.0, 0.0, -3.0, 4.0)
		"safe_escape":
			history["escapes"] = int(history.get("escapes", 0)) + 1
			_adjust_lord_history_scores(history, 10.0, 4.0, 1.0, -4.0, 6.0)
		"cold_search":
			history["cold_searches"] = int(history.get("cold_searches", 0)) + 1
			_adjust_lord_history_scores(history, 3.0, 0.0, 0.0, -2.0, 2.0)
		"defeated_by_player":
			history["defeats_by_player"] = int(history.get("defeats_by_player", 0)) + 1
			_adjust_lord_history_scores(history, 18.0, 12.0, 10.0, -7.0, 12.0)
		"player_defeated":
			history["victories_against_player"] = int(history.get("victories_against_player", 0)) + 1
			_adjust_lord_history_scores(history, 6.0, 2.0, -8.0, 16.0, 0.0)
		"inconclusive_battle":
			history["retreats"] = int(history.get("retreats", 0)) + 1
			_adjust_lord_history_scores(history, 5.0, 3.0, 2.0, 1.0, 2.0)
		_:
			_adjust_lord_history_scores(history, 1.0, 0.0, 0.0, 0.0, 0.0)

	_recalculate_lord_history_rank(history)
	_append_lord_history_log(history, event_type, text, details)
	lord_histories[lord_name] = history
	return history.duplicate(true)


func _normalize_lord_history(lord_name: String, raw_history) -> Dictionary:
	var history: Dictionary = {}
	if raw_history is Dictionary:
		history = Dictionary(raw_history).duplicate(true)

	history["name"] = lord_name
	history["encounters"] = int(history.get("encounters", 0))
	history["sightings"] = int(history.get("sightings", 0))
	history["catches"] = int(history.get("catches", 0))
	history["escapes"] = int(history.get("escapes", 0))
	history["cold_searches"] = int(history.get("cold_searches", 0))
	history["defeats_by_player"] = int(history.get("defeats_by_player", 0))
	history["victories_against_player"] = int(history.get("victories_against_player", 0))
	history["retreats"] = int(history.get("retreats", 0))
	history["grudge"] = clampf(float(history.get("grudge", 0.0)), 0.0, 100.0)
	history["respect"] = clampf(float(history.get("respect", 0.0)), 0.0, 100.0)
	history["fear"] = clampf(float(history.get("fear", 0.0)), 0.0, 100.0)
	history["confidence"] = clampf(float(history.get("confidence", 0.0)), 0.0, 100.0)
	history["humiliation"] = clampf(float(history.get("humiliation", 0.0)), 0.0, 100.0)
	history["nemesis_score"] = clampf(float(history.get("nemesis_score", 0.0)), 0.0, 100.0)
	history["rank"] = String(history.get("rank", "unknown"))
	history["last_event"] = String(history.get("last_event", ""))
	history["last_event_minute"] = int(history.get("last_event_minute", -1))

	var event_log: Array = []
	for raw_entry in Array(history.get("event_log", [])):
		if raw_entry is Dictionary:
			event_log.append(Dictionary(raw_entry).duplicate(true))
	var start_index := maxi(0, event_log.size() - LORD_HISTORY_LOG_LIMIT)
	history["event_log"] = event_log.slice(start_index)

	_recalculate_lord_history_rank(history)
	return history


func _adjust_lord_history_scores(history: Dictionary, grudge_delta: float, respect_delta: float, fear_delta: float, confidence_delta: float, humiliation_delta: float) -> void:
	history["grudge"] = clampf(float(history.get("grudge", 0.0)) + grudge_delta, 0.0, 100.0)
	history["respect"] = clampf(float(history.get("respect", 0.0)) + respect_delta, 0.0, 100.0)
	history["fear"] = clampf(float(history.get("fear", 0.0)) + fear_delta, 0.0, 100.0)
	history["confidence"] = clampf(float(history.get("confidence", 0.0)) + confidence_delta, 0.0, 100.0)
	history["humiliation"] = clampf(float(history.get("humiliation", 0.0)) + humiliation_delta, 0.0, 100.0)


func _recalculate_lord_history_rank(history: Dictionary) -> void:
	var grudge := float(history.get("grudge", 0.0))
	var respect := float(history.get("respect", 0.0))
	var fear := float(history.get("fear", 0.0))
	var confidence := float(history.get("confidence", 0.0))
	var humiliation := float(history.get("humiliation", 0.0))
	var encounters := int(history.get("encounters", 0))
	var defeats := int(history.get("defeats_by_player", 0))
	var escapes := int(history.get("escapes", 0))
	var victories := int(history.get("victories_against_player", 0))
	var score := grudge * 0.46 + respect * 0.18 + confidence * 0.22 + humiliation * 0.18 - fear * 0.12
	score += minf(18.0, float(encounters) * 1.8)
	score += minf(10.0, float(escapes + defeats + victories) * 2.0)
	history["nemesis_score"] = clampf(score, 0.0, 100.0)

	if fear >= 58.0 and defeats >= 2 and confidence < grudge:
		history["rank"] = "haunted"
	elif float(history["nemesis_score"]) >= LORD_NEMESIS_THRESHOLD and encounters >= 3:
		history["rank"] = "nemesis"
	elif float(history["nemesis_score"]) >= LORD_RIVAL_THRESHOLD:
		history["rank"] = "rival"
	elif encounters > 0:
		history["rank"] = "watchful"
	else:
		history["rank"] = "unknown"


func _append_lord_history_log(history: Dictionary, event_type: String, text: String, details: Dictionary) -> void:
	var event_log := Array(history.get("event_log", []))
	var entry := {
		"type": event_type,
		"minute": game_total_minutes,
		"text": text
	}
	if details.has("position"):
		entry["position"] = details.get("position")
	event_log.append(entry)
	var start_index := maxi(0, event_log.size() - LORD_HISTORY_LOG_LIMIT)
	history["event_log"] = event_log.slice(start_index)


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
	var previous_sling_xp := get_player_sling_xp()
	party_data = data.duplicate(true)
	if party_data.has(PLAYER_SLING_XP_KEY):
		party_data[PLAYER_SLING_XP_KEY] = maxi(0, int(party_data[PLAYER_SLING_XP_KEY]))
	else:
		party_data[PLAYER_SLING_XP_KEY] = previous_sling_xp


func get_party_data() -> Dictionary:
	var data := party_data.duplicate(true)
	data[PLAYER_SLING_XP_KEY] = get_player_sling_xp()
	return data


func get_player_sling_xp() -> int:
	return maxi(0, int(party_data.get(PLAYER_SLING_XP_KEY, 0)))


func award_player_sling_xp(amount: int) -> int:
	var xp_gain := maxi(0, amount)
	if xp_gain <= 0:
		return 0

	party_data[PLAYER_SLING_XP_KEY] = get_player_sling_xp() + xp_gain
	return xp_gain


func start_lord_combat(lord: Dictionary, player_party: Dictionary, friendly_reinforcements: Array = [], enemy_reinforcements: Array = []) -> void:
	var lord_name := String(lord.get("lord_id", lord.get("name", "Enemy lord")))
	combat_context = {
		"type": "lord",
		"enemy_lord_id": lord_name,
		"enemy_name": String(lord.get("name", lord_name)),
		"enemy_title": String(lord.get("title", "lord")),
		"enemy_faction": String(lord.get("faction", "Enemy party")),
		"enemy_party_size": int(lord.get("party_size", 0)),
		"friendly_reinforcements": friendly_reinforcements.duplicate(true),
		"enemy_reinforcements": enemy_reinforcements.duplicate(true),
		"player_party": player_party.duplicate(true)
	}


func set_combat_map_context(context: Dictionary) -> void:
	combat_map_context = context.duplicate(true)
	if not combat_map_context.has("campaign_position"):
		combat_map_context["campaign_position"] = campaign_position
	if not combat_map_context.has("biome_id"):
		combat_map_context["biome_id"] = 3
	if not combat_map_context.has("biome_key"):
		combat_map_context["biome_key"] = "biome_central_highlands"
	if not combat_map_context.has("biome_name"):
		combat_map_context["biome_name"] = "Central highlands"
	if not combat_map_context.has("biome_properties"):
		combat_map_context["biome_properties"] = {}


func get_combat_map_context() -> Dictionary:
	if combat_map_context.is_empty():
		return {
			"campaign_position": campaign_position,
			"biome_id": 3,
			"biome_key": "biome_central_highlands",
			"biome_name": "Central highlands",
			"biome_properties": {}
		}
	return combat_map_context.duplicate(true)


func clear_combat_map_context() -> void:
	combat_map_context = {}


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
	var friendly_source_losses := Array(result.get("friendly_source_losses", []))
	var enemy_source_losses := Array(result.get("enemy_source_losses", []))
	var player_dead := _player_source_dead_count(friendly_source_losses, friendly_dead)
	var player_health := maxi(0, int(result.get("player_health", 0)))
	var player_max_health := maxi(1, int(result.get("player_max_health", 1)))

	_apply_party_combat_losses(player_dead, player_health, player_max_health)
	if enemy_source_losses.is_empty():
		_apply_lord_party_combat_losses(lord_name, enemy_survivors, outcome == "victory")
	else:
		_apply_enemy_source_losses(enemy_source_losses, outcome == "victory")
	_apply_friendly_reinforcement_losses(friendly_source_losses)
	_record_lord_combat_history(lord_name, String(result.get("enemy_name", lord_name)), outcome, enemy_dead, enemy_fled, friendly_dead, friendly_fled)
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


func _player_source_dead_count(source_losses: Array, fallback_dead: int) -> int:
	if source_losses.is_empty():
		return fallback_dead
	for raw_source in source_losses:
		if not (raw_source is Dictionary):
			continue
		var source := Dictionary(raw_source)
		if String(source.get("source_id", "")) == "player":
			return maxi(0, int(source.get("dead", 0)))
	return 0


func _apply_friendly_reinforcement_losses(source_losses: Array) -> void:
	for raw_source in source_losses:
		if not (raw_source is Dictionary):
			continue
		var source := Dictionary(raw_source)
		if String(source.get("source_type", "")) != "lord":
			continue
		var lord_name := String(source.get("lord_id", source.get("name", "")))
		if lord_name.is_empty():
			continue
		var start_count := maxi(0, int(source.get("start", 0)))
		var dead_count := clampi(int(source.get("dead", 0)), 0, start_count)
		_apply_reinforcing_lord_losses(lord_name, dead_count)


func _apply_enemy_source_losses(source_losses: Array, defeated: bool) -> void:
	for raw_source in source_losses:
		if not (raw_source is Dictionary):
			continue
		var source := Dictionary(raw_source)
		var lord_name := String(source.get("lord_id", source.get("name", "")))
		if lord_name.is_empty():
			continue
		var start_count := maxi(0, int(source.get("start", 0)))
		var dead_count := clampi(int(source.get("dead", 0)), 0, start_count)
		var survivors := maxi(0, start_count - dead_count)
		_apply_lord_party_combat_losses(lord_name, survivors, defeated or survivors <= 0)


func _apply_reinforcing_lord_losses(lord_name: String, dead_count: int) -> void:
	if lord_name.is_empty() or dead_count <= 0:
		return

	var saved_parties := Array(map_state.get("lord_parties", []))
	var updated_parties: Array = []
	var found_lord := false
	for saved in saved_parties:
		if not (saved is Dictionary):
			continue
		var saved_lord := Dictionary(saved).duplicate(true)
		if String(saved_lord.get("name", "")) == lord_name:
			found_lord = true
			var survivors := maxi(0, int(saved_lord.get("party_size", 0)) - dead_count)
			if survivors <= 0:
				mark_lord_defeated(lord_name)
				continue
			saved_lord["party_size"] = survivors
		updated_parties.append(saved_lord)

	if not found_lord:
		return
	map_state["lord_parties"] = updated_parties


func _record_lord_combat_history(lord_name: String, enemy_name: String, outcome: String, enemy_dead: int, enemy_fled: int, friendly_dead: int, friendly_fled: int) -> void:
	if lord_name.is_empty():
		return

	var event_type := "inconclusive_battle"
	var text := "The battle ended without a clean decision."
	if outcome == "victory":
		event_type = "defeated_by_player"
		text = "%s was beaten by David's band." % enemy_name
	elif outcome == "defeat":
		event_type = "player_defeated"
		text = "%s drove David's band from the field." % enemy_name

	record_lord_history_event(lord_name, event_type, {
		"text": text,
		"position": campaign_position,
		"enemy_dead": enemy_dead,
		"enemy_fled": enemy_fled,
		"friendly_dead": friendly_dead,
		"friendly_fled": friendly_fled
	})


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

	var reinforcement_text := _combat_reinforcement_notice()

	if outcome == "victory":
		var loot := _roll_lord_victory_loot(enemy_name, enemy_army_size)
		pending_campaign_loot = loot
		var silver_gain := int(loot.get("silver", 0))
		adjust_morale(5)
		last_campaign_notice = "%s is defeated. %s Loot found: %d silver, %s. %s%s" % [
			enemy_name,
			enemy_result_text,
			silver_gain,
			_format_loot_items(Array(loot.get("items", []))),
			casualty_text,
			reinforcement_text
		]
	elif outcome == "defeat":
		adjust_morale(-8)
		last_campaign_notice = "You are driven from the field by %s. %s %s%s" % [enemy_name, enemy_result_text, casualty_text, reinforcement_text]
	else:
		adjust_morale(-2 if friendly_dead > 0 else 0)
		last_campaign_notice = "You break off from %s. %s %s%s" % [enemy_name, enemy_result_text, casualty_text, reinforcement_text]


func _combat_reinforcement_notice() -> String:
	var reinforcements := Array(combat_context.get("friendly_reinforcements", []))
	var enemy_reinforcements := Array(combat_context.get("enemy_reinforcements", []))
	var pieces := PackedStringArray()
	var names: Array[String] = []
	var men := 0
	for raw_reinforcement in reinforcements:
		if not (raw_reinforcement is Dictionary):
			continue
		var reinforcement := Dictionary(raw_reinforcement)
		names.append(String(reinforcement.get("name", "an ally")))
		men += int(reinforcement.get("party_size", 0))
	if not names.is_empty():
		pieces.append("%s joined the fight with %d men." % [_format_limited_name_list(names, 3), men])

	names.clear()
	men = 0
	for raw_reinforcement in enemy_reinforcements:
		if not (raw_reinforcement is Dictionary):
			continue
		var reinforcement := Dictionary(raw_reinforcement)
		names.append(String(reinforcement.get("name", "another lord")))
		men += int(reinforcement.get("party_size", 0))
	if not names.is_empty():
		pieces.append("%s joined the enemy with %d men." % [_format_limited_name_list(names, 3), men])
	if pieces.is_empty():
		return ""
	return " %s" % " ".join(pieces)


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


func _format_limited_name_list(names: Array[String], limit: int) -> String:
	var shown := PackedStringArray()
	var count := mini(names.size(), limit)
	for index in range(count):
		shown.append(names[index])
	var text := ", ".join(shown)
	if names.size() > limit:
		text += ", and others"
	return text


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
