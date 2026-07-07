# Overworld AI

## Current State

The campaign map now uses a lightweight layered AI for lord parties instead of a single Abner-only pursuit rule.

The implementation lives mainly in `scripts/campaign_map.gd`, with player-facing integration in `scripts/main.gd` and recovery state in `scripts/game_state.gd`.

The public campaign-map interface is:

- `update_overworld_ai(real_seconds, player_position, player_is_safe)`: advances perception, planning, movement, and forced encounters.
- `update_lord_pressure(real_seconds, player_position, player_is_safe)`: compatibility wrapper for older callers.
- `get_rumor_facts(world_position)`: returns live lord facts for settlement rumor text.
- `get_ai_debug_snapshot()`: returns a debug dictionary of lord state, tasks, knowledge, memory, and director state.
- `force_player_sighting_for_debug(world_position, confidence)`: gives hostile lords a debug sighting.
- `break_player_trail_at(world_position, reason)`: lowers hostile confidence and creates a relief window after hiding or refuge.

The in-game dev panel opens with `H` and exposes the main AI debugging actions:

- `AI Snapshot`: prints the current director pressure plus each lord's state, task, confidence, fatigue, supplies, and waiting town.
- `Fake Sighting`: seeds a hostile sighting at David's current position.
- `Advance 6h`: advances campaign AI by six hours.
- `Break Trail`: forces a pursuit-relief state around the player.

## AI Model

Each lord party keeps plain dictionary state so the prototype stays readable:

- `role`: marshal, border lord, informer, ally, local elder, and similar.
- `state`: holding, patrol, search, pursuing, intercept, or recover.
- `task`: structured dictionary with `type`, `target_name`, `target_pos`, `priority`, `reason`, and `confidence`.
- `standing_order`: the lord's ordinary job when no urgent task overrides it.
- `supplies`, `morale`, `fatigue`: simple campaign needs.
- `boldness`, `caution`, `ambition`, `loyalty`: temperament used by task scoring.
- `local_knowledge`: last known player position, confidence, source, and minute.
- `memory`: recent notable events such as sightings or catching the player.

The AI runs in three rough layers:

- Fast update: every moving frame where campaign time advances, lords move and perception is checked.
- Planning update: roughly every 15 campaign minutes per lord, tasks are rescored.
- Strategy/director update: roughly every 6 campaign hours, pressure and relief state are refreshed.

## Perception

Hostile lords are no longer omniscient.

They gain knowledge from:

- Direct sighting inside their detection radius.
- Gate rumors when the player is near settlements or heat is high.
- Existing knowledge that decays over time.

Knowledge has confidence. High confidence can trigger pursuit. Lower confidence causes search or intercept behavior. Safe places and hiding reduce confidence and can break active pursuit.

Detection radius is affected by:

- lord intelligence
- player heat
- lord role
- current state, especially search and pursuit

## Task Scoring

When a lord replans, the AI scores simple task candidates:

- `stay_home`: strong for taskless, cautious, tired, undersupplied, or non-hostile lords.
- `patrol`: follows standing orders and normal routes.
- `search`: moves toward a last known position or related route point.
- `pursue`: hard chase when confidence is high and the pressure director allows it.
- `intercept`: covers likely future destinations such as Bethlehem, Nob, or Ziklag.
- `recover`: returns home to rest and resupply after fatigue, losses, or stale pursuit.

The highest scoring task becomes the current task. This makes lords feel purposeful without needing a full strategy-game simulation.

## Campaign Director

The director keeps the player from being crushed by every hostile party at once.

It tracks a `pressure_score` from heat, hostile proximity, lord knowledge, and active hunts. It also creates temporary relief windows after hiding, losing a pursuer, or reaching refuge.

Current cap:

- Only one active pursuer is normally allowed.
- During relief, direct sightings must be close before a new hard chase starts.

This keeps the map dangerous but still playable.

## Player-Facing Behavior

Rumors now use `get_rumor_facts()` instead of fixed Abner text. Settlements can describe whether a hostile lord is patrolling, searching, pursuing, intercepting, recovering, or holding near town.

Hiding until dark now calls `break_player_trail_at()` and advances the AI under a safe-place assumption. It reduces hostile confidence instead of merely clearing one hard-coded pursuit flag.

Forced encounters use the actual catching lord's name.

Defeated lords now recover after two campaign days rather than being erased forever.

## Tuning Anchors

Most important constants are near the top of `scripts/campaign_map.gd`:

- `OVERWORLD_AI_PLAN_INTERVAL_MINUTES`
- `OVERWORLD_AI_MAX_PURSUERS`
- `OVERWORLD_AI_HIGH_PRESSURE_SCORE`
- `OVERWORLD_AI_RELIEF_AFTER_ESCAPE_MINUTES`
- `LORD_BASE_DETECTION_RADIUS`
- `LORD_RUMOR_RADIUS`
- `LORD_DIRECT_SIGHT_CONFIDENCE`
- `LORD_RUMOR_CONFIDENCE`
- `LORD_PURSUIT_CONFIDENCE_MIN`
- `LORD_SEARCH_CONFIDENCE_MIN`
- `LORD_CONFIDENCE_DECAY_PER_HOUR`

Lord personality and standing jobs are in `LORD_PARTIES`.

## Implemented From The Research Plan

- Layered AI update shape.
- Plain saveable lord state.
- Structured tasks.
- Utility-style task scoring.
- Non-omniscient knowledge and confidence.
- Search, pursuit, intercept, recovery, and holding states.
- Campaign pressure director with relief windows and pursuit caps.
- Rumor facts based on live AI state.
- Memory entries for key lord events.
- Debug snapshot and fake-sighting hooks.
- Dev-panel buttons for snapshot, fake sighting, 6-hour advance, and breaking trail.
- Defeated lord recovery timer.

## Still Not Implemented

These were in the larger plan but are not done yet:

- A headless simulation test scene or script that advances several campaign days and asserts no lord gets stuck.
- Real faction strategy goals beyond per-lord utility scoring and the pressure director.
- True road-network pathfinding for searches and interceptions. Lords still mostly move directly while constrained to land.
- Multi-lord coordination beyond the active-pursuer cap.
- Deeper memory consequences, such as a lord changing temperament after repeated defeats.
- Rumor variety by settlement allegiance, informant quality, and distance from the event.
- A proper UI signal for pressure score or "how hunted am I?" beyond threat circles and rumor text.

Those are good next layers, but the current system should already feel much less mechanical than fixed route dots.

## Validation

After the implementation, startup validation passed with:

```bash
tools/validate-startup.sh
```

The check loaded both required playable modes:

- `res://scenes/main.tscn`
- `res://scenes/combat_test.tscn`
