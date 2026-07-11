extends SceneTree

const SIM_DAYS := 7
const STEP_MINUTES := 30
const EXPECTED_MIN_LORDS := 4
const VALID_LORD_STATES := ["holding", "patrol", "search", "pursuing", "retreat", "intercept", "muster", "recover"]
const GAME_MINUTES_PER_REAL_SECOND := 10.0
const STARTING_POSITION := Vector2(84.0, 774.0)
const STARTING_TOTAL_MINUTES := 6 * 60
const STARTING_FOOD := 18
const STARTING_SILVER := 14
const STARTING_MORALE := 65

var _errors := PackedStringArray()
var _game_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_game_state = _get_or_create_game_state()
	_reset_game_state_for_sim()
	_validate_reinforcement_loss_accounting()
	_reset_game_state_for_sim()
	seed(12345)

	var campaign_map_script: Script = load("res://scripts/campaign_map.gd")
	var campaign_map: Node = campaign_map_script.new()
	root.add_child(campaign_map)
	await process_frame
	_validate_selective_lord_engagement(campaign_map)
	_validate_lord_absorption_hover(campaign_map)
	_validate_muster_tracks_live_support(campaign_map)
	_validate_hiding_fast_forward_breaks_pursuit(campaign_map)
	_reset_game_state_for_sim()
	campaign_map.call("_initialize_lord_parties")
	seed(12345)

	var player_position := STARTING_POSITION
	var step_count := int(SIM_DAYS * 24 * 60 / STEP_MINUTES)
	for step in range(step_count):
		player_position = _next_player_position(campaign_map, player_position, step)
		_game_state.set("campaign_position", player_position)
		_game_state.call("set_game_total_minutes", int(_game_state.call("get_game_total_minutes")) + STEP_MINUTES)

		var result: Dictionary = campaign_map.call(
			"update_overworld_ai",
			float(STEP_MINUTES) / GAME_MINUTES_PER_REAL_SECOND,
			player_position,
			false
		)
		_validate_update_result(result, step)
		_validate_snapshot(campaign_map, step)

		var forced_encounter = result.get("forced_encounter", {})
		if forced_encounter is Dictionary and not Dictionary(forced_encounter).is_empty():
			campaign_map.call("break_player_trail_at", player_position, "simulation reset")
			_game_state.call("clear_all_lord_pursuit_states")

	if _errors.is_empty():
		print("Overworld AI simulation passed: %d days, %d steps." % [SIM_DAYS, step_count])
		quit(0)
		return

	for error in _errors:
		push_error(error)
	quit(1)


func _get_or_create_game_state() -> Node:
	var existing := root.get_node_or_null("GameState")
	if existing != null:
		return existing

	var game_state_script: Script = load("res://scripts/game_state.gd")
	var game_state: Node = game_state_script.new()
	game_state.name = "GameState"
	root.add_child(game_state)
	return game_state


func _reset_game_state_for_sim() -> void:
	_game_state.set("campaign_position", STARTING_POSITION)
	_game_state.set("game_total_minutes", STARTING_TOTAL_MINUTES)
	_game_state.set("food", STARTING_FOOD)
	_game_state.set("silver", STARTING_SILVER)
	_game_state.set("morale", STARTING_MORALE)
	_game_state.set("heat", 35)
	_game_state.set("objective_complete", false)
	_game_state.set("player_inventory_slots", [])
	_game_state.set("market_inventory_slots", [])
	_game_state.set("map_state", {})
	_game_state.set("combat_context", {})
	_game_state.set("lord_pursuit_states", {})
	_game_state.set("defeated_lords", {})
	_game_state.set("lord_histories", {})
	_game_state.set("pending_campaign_loot", {})
	_game_state.set("last_campaign_notice", "")
	_game_state.call("set_game_total_minutes", STARTING_TOTAL_MINUTES)


func _validate_reinforcement_loss_accounting() -> void:
	_game_state.set("party_data", {
		"player_name": "David",
		"player_health": 100,
		"player_max_health": 100,
		"leader_intelligence": 50,
		"named_characters": [],
		"generic_soldier_count": 10
	})
	_game_state.set("map_state", {
		"lord_parties": [
			{"name": "Abner ben Ner", "party_size": 86, "route_index": 1, "pos": Vector2.ZERO},
			{"name": "Doeg the Edomite", "party_size": 22, "route_index": 1, "pos": Vector2.ZERO},
			{"name": "Abishai son of Zeruiah", "party_size": 39, "route_index": 1, "pos": Vector2.ZERO}
		]
	})
	_game_state.call("start_lord_combat", {
		"lord_id": "Abner ben Ner",
		"name": "Abner ben Ner",
		"title": "Commander of Saul's host",
		"faction": "House of Saul",
		"party_size": 86
	}, _game_state.call("get_party_data"), [
		{"lord_id": "Abishai son of Zeruiah", "name": "Abishai son of Zeruiah", "faction": "David's Band", "party_size": 39}
	], [
		{"lord_id": "Doeg the Edomite", "name": "Doeg the Edomite", "faction": "Edomite Retinue", "party_size": 22}
	])
	_game_state.call("apply_lord_combat_result", {
		"outcome": "retreat",
		"enemy_lord_id": "Abner ben Ner",
		"enemy_name": "Abner ben Ner",
		"enemy_start_count": 108,
		"enemy_dead_count": 6,
		"enemy_fled_count": 2,
		"enemy_source_losses": [
			{"source_id": "enemy_lord:Abner ben Ner", "source_type": "lord", "lord_id": "Abner ben Ner", "name": "Abner ben Ner", "start": 86, "dead": 2, "fled": 1},
			{"source_id": "enemy_lord:Doeg the Edomite", "source_type": "lord", "lord_id": "Doeg the Edomite", "name": "Doeg the Edomite", "start": 22, "dead": 4, "fled": 1}
		],
		"friendly_start_count": 49,
		"friendly_dead_count": 7,
		"friendly_fled_count": 3,
		"friendly_source_losses": [
			{"source_id": "player", "source_type": "player", "name": "David's Band", "start": 10, "dead": 2, "fled": 1},
			{"source_id": "lord:Abishai son of Zeruiah", "source_type": "lord", "lord_id": "Abishai son of Zeruiah", "name": "Abishai son of Zeruiah", "start": 39, "dead": 5, "fled": 2}
		],
		"player_health": 75,
		"player_max_health": 100
	})

	var party_data := Dictionary(_game_state.call("get_party_data"))
	if int(party_data.get("generic_soldier_count", 0)) != 8:
		_errors.append("Reinforcement loss check: player soldiers should lose only player-source dead.")

	var found_abishai := false
	var found_abner := false
	var found_doeg := false
	for raw_lord in Array(Dictionary(_game_state.get("map_state")).get("lord_parties", [])):
		var lord := Dictionary(raw_lord)
		var lord_name := String(lord.get("name", ""))
		if lord_name == "Abishai son of Zeruiah":
			found_abishai = true
			if int(lord.get("party_size", 0)) != 34:
				_errors.append("Reinforcement loss check: Abishai should have 34 survivors.")
		if lord_name == "Abner ben Ner":
			found_abner = true
			if int(lord.get("party_size", 0)) != 84:
				_errors.append("Reinforcement loss check: Abner should have 84 survivors.")
		if lord_name == "Doeg the Edomite":
			found_doeg = true
			if int(lord.get("party_size", 0)) != 18:
				_errors.append("Reinforcement loss check: Doeg should have 18 survivors.")
	if not found_abishai:
		_errors.append("Reinforcement loss check: Abishai missing after combat result.")
	if not found_abner:
		_errors.append("Reinforcement loss check: Abner missing after combat result.")
	if not found_doeg:
		_errors.append("Reinforcement loss check: Doeg missing after combat result.")


func _validate_selective_lord_engagement(campaign_map: Node) -> void:
	var far_safe_player := Vector2(1800.0, 1800.0)
	_game_state.call("clear_all_lord_pursuit_states")
	_game_state.set("heat", 35)

	campaign_map.call("_debug_replace_lord_parties_for_sim", [
		_sim_lord("Saulite Patrol", "House of Saul", "retainer", 34, Vector2(0.0, 0.0), "Gibeah"),
		_sim_lord("Judean Patrol", "Judah", "ally", 31, Vector2(220.0, 0.0), "Bethlehem")
	])
	_game_state.call("set_game_total_minutes", STARTING_TOTAL_MINUTES + 10)
	campaign_map.call("update_overworld_ai", 2.0, far_safe_player, true)
	var ordinary_lord := _snapshot_lord(campaign_map, "Saulite Patrol")
	var ordinary_state := String(ordinary_lord.get("state", ""))
	if ordinary_state == "muster" or ordinary_state == "pursuing":
		_errors.append("Selective engagement: ordinary unsupported war target should not force %s." % ordinary_state)

	campaign_map.call("_debug_replace_lord_parties_for_sim", [
		_sim_lord("Saulite Skirmishers", "House of Saul", "retainer", 18, Vector2(0.0, 0.0), "Gibeah"),
		_sim_lord("Saulite Support", "House of Saul", "retainer", 58, Vector2(-760.0, 0.0), "Gibeah"),
		_sim_lord("Judean Marshal", "Judah", "marshal", 55, Vector2(500.0, 0.0), "Bethlehem")
	])
	_game_state.call("clear_all_lord_pursuit_states")
	_game_state.call("set_game_total_minutes", STARTING_TOTAL_MINUTES + 20)
	campaign_map.call("update_overworld_ai", 2.0, far_safe_player, true)
	var supported_lord := _snapshot_lord(campaign_map, "Saulite Skirmishers")
	var supported_state := String(supported_lord.get("state", ""))
	var supported_task := Dictionary(supported_lord.get("task", {}))
	if supported_state != "muster":
		_errors.append("Selective engagement: weak lord seeing a leader with nearby support should muster, got '%s'." % supported_state)
	elif String(supported_task.get("target_name", "")) != "Saulite Support":
		_errors.append("Selective engagement: muster should target nearby allied support, got '%s'." % String(supported_task.get("target_name", "")))

	_game_state.call("clear_all_lord_pursuit_states")


func _validate_lord_absorption_hover(campaign_map: Node) -> void:
	_game_state.call("clear_all_lord_pursuit_states")
	_game_state.set("heat", 20)

	var gibeah_position = campaign_map.call("_position_for_named_settlement", "Gibeah", Vector2.INF)
	if not (gibeah_position is Vector2) or Vector2(gibeah_position) == Vector2.INF:
		_errors.append("Lord absorption: could not resolve Gibeah position.")
		return
	var town_lord := _sim_lord("Town Captain", "House of Saul", "retainer", 42, Vector2(gibeah_position), "Gibeah")
	town_lord["state"] = "holding"
	town_lord["task"] = {"type": "stay_home", "target_name": "Gibeah", "target_pos": Vector2(gibeah_position)}
	town_lord["waiting_at"] = "Gibeah"
	town_lord["hold_minutes"] = 180.0
	campaign_map.call("_debug_replace_lord_parties_for_sim", [town_lord])

	var town_hover := Dictionary(campaign_map.call("get_hovered_location", Vector2(gibeah_position)))
	var town_lords := Array(town_hover.get("grouped_lords", []))
	if String(town_hover.get("type", "")) != "settlement" or town_lords.size() != 1:
		_errors.append("Lord absorption: hovered town should list one absorbed lord.")
	var town_click := Dictionary(campaign_map.call("get_click_target", Vector2(gibeah_position)))
	if String(town_click.get("type", "")) != "settlement":
		_errors.append("Lord absorption: clicking an absorbed town lord should select the settlement, got '%s'." % String(town_click.get("type", "")))

	var group_position := _open_group_position(campaign_map, Vector2(gibeah_position))
	var anchor := _sim_lord("Saulite Support", "House of Saul", "retainer", 62, group_position, "Gibeah")
	anchor["state"] = "patrol"
	anchor["task"] = {"type": "patrol"}
	var mustering := _sim_lord("Saulite Skirmishers", "House of Saul", "retainer", 22, group_position + Vector2(12.0, 0.0), "Gibeah")
	mustering["state"] = "muster"
	mustering["task"] = {
		"type": "muster",
		"target_name": "Saulite Support",
		"target_pos": group_position,
		"priority": 80.0,
		"reason": "Simulation open-field muster.",
		"confidence": 80.0
	}
	mustering["waiting_at"] = "Saulite Support"
	mustering["hold_minutes"] = 120.0
	campaign_map.call("_debug_replace_lord_parties_for_sim", [anchor, mustering])

	var group_hover := Dictionary(campaign_map.call("get_hovered_location", group_position))
	if String(group_hover.get("type", "")) == "lord_group":
		_errors.append("Lord absorption: open-field muster should not create a hidden lord group hover target.")
	var mustering_target := Dictionary(campaign_map.call("get_lord_target", "Saulite Skirmishers"))
	if mustering_target.is_empty():
		_errors.append("Lord absorption: open-field mustering lords should remain visible targets.")
	var mustering_click := Dictionary(campaign_map.call("get_click_target", group_position + Vector2(12.0, 0.0)))
	if String(mustering_click.get("name", "")) != "Saulite Skirmishers":
		_errors.append("Lord absorption: clicking a visible mustering lord should select it, got '%s'." % String(mustering_click.get("name", "")))

	_game_state.call("clear_all_lord_pursuit_states")


func _validate_muster_tracks_live_support(campaign_map: Node) -> void:
	_game_state.call("clear_all_lord_pursuit_states")
	_game_state.set("heat", 20)
	var base_position := _open_group_position(campaign_map, Vector2(84.0, 774.0))
	var support_position := _separated_land_position(campaign_map, base_position)
	if support_position == Vector2.INF:
		_errors.append("Muster support tracking: could not place support lord.")
		return
	var support := _sim_lord("Moving Support", "House of Saul", "retainer", 70, support_position, "Gibeah")
	support["state"] = "patrol"
	support["task"] = {"type": "patrol"}
	var mustering := _sim_lord("Following Muster", "House of Saul", "retainer", 20, base_position, "Gibeah")
	mustering["state"] = "muster"
	mustering["task"] = {
		"type": "muster",
		"target_name": "Moving Support",
		"target_kind": "lord",
		"target_lord_id": "Moving Support",
		"target_pos": base_position,
		"priority": 80.0,
		"reason": "Follow live support.",
		"confidence": 80.0
	}
	mustering["next_plan_minute"] = int(_game_state.call("get_game_total_minutes")) + 120
	campaign_map.call("_debug_replace_lord_parties_for_sim", [support, mustering])
	campaign_map.call("update_overworld_ai", 2.0, Vector2(1800.0, 1800.0), true)
	var moved_lord := _snapshot_lord(campaign_map, "Following Muster")
	var moved_position := Vector2(moved_lord.get("position", base_position))
	if moved_position.distance_to(support_position) >= base_position.distance_to(support_position) - 20.0:
		_errors.append("Muster support tracking: mustering lord did not move toward the live support lord.")

	var stack_position := _open_group_position(campaign_map, Vector2(84.0, 774.0))
	var static_support := _sim_lord("Static Support", "House of Saul", "retainer", 70, stack_position, "Gibeah")
	static_support["state"] = "patrol"
	static_support["task"] = {"type": "patrol"}
	var loitering := _sim_lord("Loitering Muster", "House of Saul", "retainer", 20, stack_position, "Gibeah")
	loitering["state"] = "muster"
	loitering["task"] = {
		"type": "muster",
		"target_name": "Static Support",
		"target_kind": "lord",
		"target_lord_id": "Static Support",
		"target_pos": stack_position,
		"priority": 80.0,
		"reason": "Loiter near support.",
		"confidence": 80.0
	}
	loitering["next_plan_minute"] = int(_game_state.call("get_game_total_minutes")) + 120
	campaign_map.call("_debug_replace_lord_parties_for_sim", [static_support, loitering])
	campaign_map.call("update_overworld_ai", 2.0, Vector2(1800.0, 1800.0), true)
	var loitered_lord := _snapshot_lord(campaign_map, "Loitering Muster")
	var loitered_position := Vector2(loitered_lord.get("position", stack_position))
	if loitered_position.distance_to(stack_position) < 28.0:
		_errors.append("Muster support tracking: mustering lord should loiter beside support instead of stacking on top.")
	_game_state.call("clear_all_lord_pursuit_states")


func _validate_hiding_fast_forward_breaks_pursuit(campaign_map: Node) -> void:
	_game_state.call("clear_all_lord_pursuit_states")
	_game_state.set("heat", 35)

	var hiding_position = campaign_map.call("_position_for_named_settlement", "Bethlehem", STARTING_POSITION)
	if not (hiding_position is Vector2) or Vector2(hiding_position) == Vector2.INF:
		_errors.append("Hiding fast-forward: could not resolve Bethlehem position.")
		return

	var pursuer_position := _separated_land_position(campaign_map, Vector2(hiding_position))
	if pursuer_position == Vector2.INF:
		_errors.append("Hiding fast-forward: could not place pursuing lord.")
		return

	var pursuer := _sim_lord("Hiding Pursuer", "House of Saul", "retainer", 46, pursuer_position, "Gibeah")
	pursuer["state"] = "pursuing"
	pursuer["task"] = {
		"type": "pursue",
		"target_kind": "player",
		"target_name": "your band",
		"target_pos": Vector2(hiding_position),
		"priority": 90.0,
		"confidence": 90.0
	}
	pursuer["local_knowledge"] = {
		"position": Vector2(hiding_position),
		"confidence": 90.0,
		"minute": int(_game_state.call("get_game_total_minutes")),
		"source": "test pursuit"
	}
	campaign_map.call("_debug_replace_lord_parties_for_sim", [pursuer])
	_game_state.call("set_lord_pursuit_state", "Hiding Pursuer", {
		"state": "pursuing",
		"started_minute": int(_game_state.call("get_game_total_minutes")),
		"confidence": 90.0
	})

	campaign_map.call("break_player_trail_at", Vector2(hiding_position), "hiding")
	_game_state.call("set_game_total_minutes", int(_game_state.call("get_game_total_minutes")) + 60)
	campaign_map.call("update_overworld_ai", float(60) / GAME_MINUTES_PER_REAL_SECOND, Vector2(hiding_position), true)

	var pursuit_state := Dictionary(_game_state.call("get_lord_pursuit_state", "Hiding Pursuer"))
	if not pursuit_state.is_empty():
		_errors.append("Hiding fast-forward: pursuit state should be cleared while hiding.")

	var hidden_lord := _snapshot_lord(campaign_map, "Hiding Pursuer")
	var hidden_state := String(hidden_lord.get("state", ""))
	if hidden_state == "pursuing":
		_errors.append("Hiding fast-forward: pursuing lord should lose the active chase.")

	var knowledge := Dictionary(hidden_lord.get("knowledge", {}))
	var confidence := float(knowledge.get("confidence", 100.0))
	if confidence >= 90.0:
		_errors.append("Hiding fast-forward: hostile confidence should drop while hiding, got %.1f." % confidence)
	_game_state.call("clear_all_lord_pursuit_states")


func _separated_land_position(campaign_map: Node, base_position: Vector2) -> Vector2:
	var offsets := [
		Vector2(420.0, 0.0),
		Vector2(-420.0, 0.0),
		Vector2(0.0, 420.0),
		Vector2(0.0, -420.0),
		Vector2(300.0, 300.0),
		Vector2(-300.0, 300.0),
		Vector2(300.0, -300.0),
		Vector2(-300.0, -300.0)
	]
	for offset in offsets:
		var constrained = campaign_map.call("constrain_land_position", base_position + offset, base_position)
		if constrained is Vector2 and Vector2(constrained).distance_to(base_position) >= 180.0:
			return Vector2(constrained)
	return Vector2.INF


func _open_group_position(campaign_map: Node, fallback_position: Vector2) -> Vector2:
	var candidates := [
		Vector2(860.0, 940.0),
		Vector2(740.0, 1260.0),
		Vector2(420.0, 1120.0),
		Vector2(980.0, 420.0),
		Vector2(640.0, 620.0)
	]
	for candidate in candidates:
		var constrained = campaign_map.call("constrain_land_position", candidate, fallback_position)
		if not (constrained is Vector2):
			continue
		var position := Vector2(constrained)
		var settlement := Dictionary(campaign_map.call("get_nearest_settlement", position, 170.0))
		if settlement.is_empty():
			return position
	return fallback_position + Vector2(180.0, 120.0)


func _sim_lord(lord_name: String, faction: String, role: String, party_size: int, position: Vector2, home_name: String) -> Dictionary:
	return {
		"name": lord_name,
		"title": role.capitalize(),
		"faction": faction,
		"party_size": party_size,
		"pos": position,
		"start": position,
		"start_name": home_name,
		"home_name": home_name,
		"role": role,
		"task": {},
		"route": [position],
		"route_names": [home_name],
		"speed": 44.0,
		"intelligence": 38,
		"boldness": 50.0,
		"caution": 56.0,
		"ambition": 50.0,
		"loyalty": 66.0,
		"supplies": 100.0,
		"morale": 65.0,
		"fatigue": 0.0
	}


func _snapshot_lord(campaign_map: Node, lord_name: String) -> Dictionary:
	var snapshot: Dictionary = campaign_map.call("get_ai_debug_snapshot")
	for raw_lord in Array(snapshot.get("lords", [])):
		if not (raw_lord is Dictionary):
			continue
		var lord := Dictionary(raw_lord)
		if String(lord.get("name", "")) == lord_name:
			return lord
	return {}


func _next_player_position(campaign_map: Node, current_position: Vector2, step: int) -> Vector2:
	var angle := float(step) * 0.37
	var stride := 190.0 + 45.0 * sin(float(step) * 0.11)
	var desired := current_position + Vector2(cos(angle), sin(angle * 0.73)) * stride
	var constrained = campaign_map.call("constrain_land_position", desired, current_position)
	if constrained is Vector2:
		return Vector2(constrained)
	return current_position


func _validate_update_result(result: Dictionary, step: int) -> void:
	if not result.has("forced_encounter"):
		_errors.append("Step %d: AI result missing forced_encounter." % step)
	if not result.has("notices"):
		_errors.append("Step %d: AI result missing notices." % step)
	if not result.has("pressure_score"):
		_errors.append("Step %d: AI result missing pressure_score." % step)
	var pressure := float(result.get("pressure_score", 0.0))
	if is_nan(pressure) or pressure < 0.0 or pressure > 100.0:
		_errors.append("Step %d: invalid pressure score %s." % [step, str(pressure)])


func _validate_snapshot(campaign_map: Node, step: int) -> void:
	var snapshot: Dictionary = campaign_map.call("get_ai_debug_snapshot")
	var road_graph_nodes := int(snapshot.get("road_graph_nodes", 0))
	if road_graph_nodes < 2:
		_errors.append("Step %d: road graph was not built." % step)

	var lords := Array(snapshot.get("lords", []))
	if lords.size() < EXPECTED_MIN_LORDS:
		_errors.append("Step %d: expected at least %d lords, got %d." % [step, EXPECTED_MIN_LORDS, lords.size()])
		return

	for raw_lord in lords:
		if not (raw_lord is Dictionary):
			_errors.append("Step %d: lord snapshot is not a Dictionary." % step)
			continue

		var lord := Dictionary(raw_lord)
		var lord_name := String(lord.get("name", "Unknown lord"))
		var state := String(lord.get("state", ""))
		if not state in VALID_LORD_STATES:
			_errors.append("Step %d: %s has invalid state '%s'." % [step, lord_name, state])

		var position := Vector2(lord.get("position", Vector2.INF))
		if position == Vector2.INF:
			_errors.append("Step %d: %s has no valid position." % [step, lord_name])
		else:
			var constrained = campaign_map.call("constrain_land_position", position, position)
			if constrained is Vector2 and position.distance_to(Vector2(constrained)) > 2.0:
				_errors.append("Step %d: %s drifted off land at %s." % [step, lord_name, str(position)])

		var task := Dictionary(lord.get("task", {}))
		if state != "holding" and task.is_empty():
			_errors.append("Step %d: %s has state '%s' with no task." % [step, lord_name, state])
		_validate_lord_not_stuck_in_travel_hold(lord, step)

		var knowledge := Dictionary(lord.get("knowledge", {}))
		var confidence := float(knowledge.get("confidence", 0.0))
		if is_nan(confidence) or confidence < 0.0 or confidence > 100.0:
			_errors.append("Step %d: %s has invalid confidence %s." % [step, lord_name, str(confidence)])

		var memory_profile := Dictionary(lord.get("memory_profile", {}))
		var memory_label := String(memory_profile.get("label", ""))
		if memory_label.is_empty():
			_errors.append("Step %d: %s has no memory profile label." % [step, lord_name])

		var legacy_profile := Dictionary(lord.get("legacy_profile", {}))
		var legacy_label := String(legacy_profile.get("label", ""))
		if legacy_label.is_empty():
			_errors.append("Step %d: %s has no legacy profile label." % [step, lord_name])
		var nemesis_score := float(legacy_profile.get("nemesis_score", 0.0))
		if is_nan(nemesis_score) or nemesis_score < 0.0 or nemesis_score > 100.0:
			_errors.append("Step %d: %s has invalid nemesis score %s." % [step, lord_name, str(nemesis_score)])

		var coordination_role := String(lord.get("coordination_role", ""))
		if coordination_role.is_empty():
			_errors.append("Step %d: %s has no coordination role." % [step, lord_name])

		var strength_profile := Dictionary(lord.get("strength_profile", {}))
		if strength_profile.is_empty():
			_errors.append("Step %d: %s has no strength profile." % [step, lord_name])
		else:
			var solo_ratio := float(strength_profile.get("solo_ratio", -1.0))
			var effective_ratio := float(strength_profile.get("effective_ratio", -1.0))
			if is_nan(solo_ratio) or solo_ratio < 0.0:
				_errors.append("Step %d: %s has invalid solo strength ratio %s." % [step, lord_name, str(solo_ratio)])
			if is_nan(effective_ratio) or effective_ratio < 0.0:
				_errors.append("Step %d: %s has invalid effective strength ratio %s." % [step, lord_name, str(effective_ratio)])

		var fatigue := float(lord.get("fatigue", 0.0))
		var supplies := float(lord.get("supplies", 0.0))
		if is_nan(fatigue) or fatigue < 0.0 or fatigue > 100.0:
			_errors.append("Step %d: %s has invalid fatigue %s." % [step, lord_name, str(fatigue)])
		if is_nan(supplies) or supplies < 0.0 or supplies > 100.0:
			_errors.append("Step %d: %s has invalid supplies %s." % [step, lord_name, str(supplies)])


func _validate_lord_not_stuck_in_travel_hold(lord: Dictionary, step: int) -> void:
	var state := String(lord.get("state", ""))
	if not state in ["muster", "retreat"]:
		return
	var hold_minutes := float(lord.get("hold_minutes", 0.0))
	if hold_minutes <= 0.0:
		return
	var task := Dictionary(lord.get("task", {}))
	var target_position := Vector2.INF
	if task.get("target_pos", null) is Vector2:
		target_position = Vector2(task.get("target_pos", Vector2.INF))
	if target_position == Vector2.INF:
		return
	var position := Vector2(lord.get("position", Vector2.INF))
	if position == Vector2.INF:
		return
	if position.distance_to(target_position) > 96.0:
		_errors.append("Step %d: %s is stuck in %s hold %.1f away from target." % [
			step,
			String(lord.get("name", "Unknown lord")),
			state,
			hold_minutes
		])
