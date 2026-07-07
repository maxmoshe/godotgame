# Overworld AI

## Current State

The campaign map now uses a lightweight layered AI for lord parties instead of a single Abner-only pursuit rule.

The implementation lives mainly in `scripts/campaign_map.gd`, with player-facing integration in `scripts/main.gd` and recovery state in `scripts/game_state.gd`.

The public campaign-map interface is:

- `update_overworld_ai(real_seconds, player_position, player_is_safe)`: advances perception, planning, movement, and forced encounters.
- `update_lord_pressure(real_seconds, player_position, player_is_safe)`: compatibility wrapper for older callers.
- `get_rumor_facts(world_position)`: returns live lord facts for settlement rumor text.
- `get_lord_combat_reinforcements(target_lord)`: returns nearby friendly lords who will join against a common hostile enemy.
- `get_enemy_lord_combat_reinforcements(target_lord)`: returns nearby hostile lords who can support a compatible lord in battle.
- `get_ai_debug_snapshot()`: returns a debug dictionary of lord state, tasks, knowledge, memory, strength, and director state.
- `force_player_sighting_for_debug(world_position, confidence)`: gives hostile lords a debug sighting.
- `seed_nemesis_for_debug(world_position)`: gives the nearest hostile lord enough history to test long-term nemesis behavior.
- `break_player_trail_at(world_position, reason)`: lowers hostile confidence and creates a relief window after hiding or refuge.

The in-game dev panel opens with `H` and exposes the main AI debugging actions:

- `AI Snapshot`: prints the current director pressure plus each lord's state, task, confidence, fatigue, supplies, waiting town, and strength odds.
- `Fake Sighting`: seeds a hostile sighting at the player band's current position.
- `Advance 6h`: advances campaign AI by six hours.
- `Break Trail`: forces a pursuit-relief state around the player.
- `Seed Nemesis`: pushes the nearest hostile lord into long-memory rivalry for testing.

The snapshot also reports the road graph node count plus per-lord coordination, short-memory, and long-memory labels when they matter.

There is also a headless simulation check:

```bash
tools/validate-overworld-ai.sh
```

It advances seven simulated campaign days and fails if lord state, task, position, confidence, fatigue, supplies, or pressure output becomes invalid.

## AI Model

Each lord party keeps plain dictionary state so the prototype stays readable:

- `role`: marshal, border lord, informer, ally, local elder, and similar.
- `state`: holding, patrol, search, pursuing, retreat, intercept, muster, or recover.
- `task`: structured dictionary with `type`, `target_name`, `target_pos`, `priority`, `reason`, and `confidence`.
- `standing_order`: the lord's ordinary job when no urgent task overrides it.
- `supplies`, `morale`, `fatigue`: simple campaign needs.
- `boldness`, `caution`, `ambition`, `loyalty`: temperament used by task scoring.
- `local_knowledge`: last known player position, confidence, source, and minute.
- `memory`: recent notable events such as sightings or catching the player.
- `memory_profile`: short-lived behavioral pressure from recent memories.
- `legacy_profile`: long-term grudge, respect, fear, confidence, and nemesis pressure from campaign history.
- `coordination_role`: current tactical role such as pursuer, blocker, sweeper, relay, or net.

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
- long-term rivalry, which can increase detection and rumor reach

## Task Scoring

When a lord replans, the AI scores simple task candidates:

- `stay_home`: strong for taskless, cautious, tired, undersupplied, or non-hostile lords.
- `patrol`: follows standing orders and normal routes.
- `search`: moves toward a last known position or related route point.
- `pursue`: hard chase when confidence is high and the pressure director allows it.
- `retreat`: pulls away from a stronger war target when the force is much weaker and danger closes distance.
- `intercept`: covers likely future destinations such as Bethlehem, Nob, or Ziklag.
- `muster`: gathers near a nearby allied/supporting lord when a solo chase would be too weak.
- `recover`: returns home to rest and resupply after fatigue, losses, or stale pursuit.

The highest scoring task becomes the current task. This makes lords feel purposeful without needing a full strategy-game simulation.

Task scoring now also includes a small faction-strategy layer:

- House of Saul tightens the hill-road net as heat and pressure rise.
- Philistine lords bias toward guarding the lowland and Ziklag routes.
- Doeg's retinue favors search, rumor, and interception over hard pursuit.
- Allied captains and local elders are more willing to hold or recover near friendly towns.
- When another lord is already pursuing, non-pursuers take support roles instead of piling into the same chase.

Support roles are deliberately simple:

- `pursuer`: owns the hard chase.
- `blocker`: moves to likely roadblocks and refuges.
- `sweeper`: searches nearby roads around the known trail.
- `relay`: informers spread and price the news instead of charging.
- `net`: loose high-pressure coverage when the map is hot.

Recent memories now adjust task scores. A lord who repeatedly loses the player band becomes more cagey and favors roadblocks. A lord who caught the player becomes more willing to press a hard chase. Repeated sightings keep a lord alert.

Lords now estimate campaign strength before committing to a chase. The same comparison is used for the player band and for other lord parties they are at war with. The estimate compares the target's strength against:

- the lord alone
- the lord plus nearby allied/supporting lords who could join the fight immediately
- the lord plus potential allied/supporting lords inside a wider group-up radius

If the lord is too weak alone, direct sightings and high-confidence reports create a `muster` task only when real allied/supporting lords are nearby. A mustering lord tracks the live support lord, not just the support lord's last known coordinate, and waits long enough for the map to feel like men are gathering. If no support is close enough, the lord falls back to search, patrol, recover, or retreat logic instead of inventing a rally at home. Old town idle timers are cleared when a movement task starts, so lords do not freeze in place while supposedly mustering. Once enough support is actually close, the same strength check can allow pursuit again; mustered groups recheck those odds quickly instead of waiting hours on stale weakness.

Not every lord-vs-lord sighting becomes a chase. The AI now treats the player band and faction leaders as strategic targets, while ordinary enemy parties require close range, favorable odds, or nearby support before a lord commits. This keeps war bands from trying to kill every enemy banner they glimpse across the map.

If a stronger war target gets close to a much weaker force, the lord can switch to `retreat`. Retreat tries to move toward useful support that is not also exposed to the threat, then toward home, then toward open ground away from danger. This keeps weak enemies cautious without making them passive.

When a lord is waiting inside a settlement, its separate map marker is temporarily absorbed into that settlement. Open-field mustering lords stay visible: they track their support lord and loiter beside it instead of stacking on the exact same point. The lord is still simulated and saved normally; only town representation changes for readability.

## Long-Term Memory

Longer memory lives in `GameState.lord_histories`, not on the moving lord party. That lets a defeated lord leave the map, recover later, and still remember the history.

Tracked values include:

- `grudge`: how personally invested the lord is.
- `respect`: how seriously he takes the player band.
- `fear`: how much past defeat makes him cautious.
- `confidence`: how bold he feels against the player band.
- `humiliation`: how much public defeat still stings.
- `nemesis_score`: combined pressure used for rank and behavior.

History ranks are:

- `watchful`: has meaningful history, but not obsession.
- `rival`: reads the player band's roads more carefully.
- `nemesis`: presses pursuit harder, hears rumors farther, and forgets trails more slowly.
- `haunted`: remembers defeats too well, favors roadblocks and caution over blind pursuit.

Long memory is fed by campaign events:

- direct sightings
- catching the player
- losing the trail
- safe-place escapes
- cold searches
- lord-combat victory, defeat, or inconclusive retreat

The result affects task scoring, detection radius, rumor radius, and confidence decay. Rumors can mention when old history is shaping a lord's behavior.

Long-distance pursuit, search, intercept, recovery, and return-home movement now use a small road graph built from the same route lines the map draws. Lords pick a road-network waypoint with a detour limit, then fall back to their personal route waypoints or direct travel if the graph path is not useful.

## Campaign Director

The director keeps the player from being crushed by every hostile party at once.

It tracks a `pressure_score` from heat, hostile proximity, lord knowledge, and active hunts. It also creates temporary relief windows after hiding, losing a pursuer, or reaching refuge.

Current cap:

- Only one active pursuer is normally allowed.
- During relief, direct sightings must be close before a new hard chase starts.

This keeps the map dangerous but still playable.

## Player-Facing Behavior

Rumors now use `get_rumor_facts()` instead of fixed Abner text. Settlements can describe whether a hostile lord is patrolling, searching, pursuing, retreating, intercepting, mustering, recovering, or holding near town.

Hiding until dark now calls `break_player_trail_at()` and advances the AI under a safe-place assumption. It reduces hostile confidence instead of merely clearing one hard-coded pursuit flag.

Forced encounters use the actual catching lord's name.

If the player fights a hostile lord and a friendly lord is close enough, that friendly lord joins the battle. The combat scene spawns the reinforcing lord's men on the player side, and post-battle losses are split by source so the player party only loses its own men while allied lords lose their own dead.

If a combat starts while compatible hostile support is close, those enemy reinforcements join the hostile side. The combat scene also tracks enemy losses by source, so the lead lord and each supporting lord lose their own men after the battle.

Defeated lords now recover after two campaign days rather than being erased forever.

The HUD shows a pursuit-pressure band and score:

- `Quiet`
- `Wary`
- `Dangerous`
- `Hunted`

Settlement rumors vary by local context. Friendly places speak more plainly, hostile places give guarded or distorted answers, and neutral places sit between the two. Rumors can also report when a hostile lord is gathering support before risking a chase.

Hovering a settlement shows which lords are currently represented there, including their party sizes. Hidden absorbed lords are not independently clickable until they leave the town.

## Tuning Anchors

Most important campaign-map constants are near the top of `scripts/campaign_map.gd`:

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
- `LORD_COMBAT_REINFORCE_RADIUS`
- `LORD_COMBAT_REINFORCE_LIMIT`
- `LORD_GROUP_UP_RADIUS`
- `LORD_GROUP_UP_ARRIVAL_RADIUS`
- `LORD_WEAK_SOLO_RATIO`
- `LORD_CAUTIOUS_SOLO_RATIO`
- `LORD_CONFIDENT_GROUP_RATIO`
- `LORD_ORDINARY_TARGET_NOTICE_MULTIPLIER`
- `LORD_OPPORTUNISTIC_SOLO_RATIO`
- `LORD_OPPORTUNISTIC_SUPPORTED_RATIO`
- `LORD_WEAK_FLEE_RADIUS`
- `LORD_WEAK_FLEE_CLEAR_RADIUS`
- `LORD_FLEE_TARGET_DISTANCE`
- `LORD_FLEE_SPEED_MULTIPLIER`
- `LORD_ABSORBED_TOWN_RADIUS`
- `LORD_MUSTER_LOITER_RADIUS`
- `LORD_CONFIDENCE_DECAY_PER_HOUR`
- `LORD_MEMORY_EFFECT_DAYS`

Long-memory rank thresholds are near the top of `scripts/game_state.gd`:

- `LORD_RIVAL_THRESHOLD`
- `LORD_NEMESIS_THRESHOLD`

Lord personality and standing jobs are in `LORD_PARTIES`.

## Implemented From The Research Plan

- Layered AI update shape.
- Plain saveable lord state.
- Structured tasks.
- Utility-style task scoring.
- Non-omniscient knowledge and confidence.
- Search, pursuit, retreat, intercept, muster, recovery, and holding states.
- Campaign pressure director with relief windows and pursuit caps.
- Rumor facts based on live AI state.
- Settlement-context rumor wording.
- HUD pursuit-pressure signal.
- Faction-strategy task modifiers.
- Non-pursuer coordination roles: pursuer, blocker, sweeper, relay, net.
- Nearby friendly-lord reinforcements in common-enemy combats.
- Nearby hostile-lord reinforcements when a compatible enemy force is close.
- Per-source combat casualty accounting for player, allied lord, lead enemy lord, and supporting enemy lord forces.
- Road-network waypoint pathfinding for long-distance AI movement.
- Memory entries and memory-based task modifiers for key lord events.
- Long-term lord histories with grudge, respect, fear, confidence, humiliation, ranks, and nemesis score.
- Strength-aware pursuit gating, support-required muster behavior, close-threat retreat, and selective engagement logic for the player and lord-vs-lord war targets.
- Bannerlord-style temporary absorption of waiting lords into settlements, while open-field mustering lords remain visible and loiter near support.
- Long-term memory effects on scoring, perception, rumor reach, and confidence decay.
- Debug snapshot and fake-sighting hooks.
- Dev-panel buttons for snapshot, fake sighting, 6-hour advance, breaking trail, and seeding a nemesis.
- Headless seven-day AI simulation check.
- Lord AI save-data persistence.
- Defeated lord recovery timer.

## Still Not Implemented

These were in the larger plan but are not done yet:

- More elaborate multi-lord coordination, such as explicit scout screens, relays, and pincers.
- More authored nemesis moments, such as named boasts, revenge missions, or negotiated mercy after repeated defeats.
- Faction strategy that changes over several days rather than only per-task scoring.
- More mechanical rumor accuracy by exact distance from the event.
- Three-way politics for cases where factions are not simply friendly or hostile.

Those are good next layers, but the current system should already feel much less mechanical than fixed route dots.

## Validation

After the implementation, AI simulation and startup validation passed with:

```bash
tools/validate-overworld-ai.sh
tools/validate-startup.sh
```

The startup check loaded both required playable modes:

- `res://scenes/main.tscn`
- `res://scenes/combat_test.tscn`
