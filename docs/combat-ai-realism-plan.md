# Combat AI Realism Design Plan

## Summary

The current combat prototype already has the bones of a Mount & Blade-style fight: campaign parties enter `res://scenes/combat_test.tscn`, soldiers have factions, simple weapon roles, attack timing, hold/charge orders, target refresh intervals, stat-scaled damage/timing, archer lead calculation, and a friendly-fire lane check.

The next step should not be "make every soldier smarter." That usually creates perfect, robotic enemies. The better target is believable human behavior: limited perception, imperfect courage, formation pressure, crowding, fatigue, self-preservation, and role-specific decisions that are readable to the player.

This doc proposes a staged plan for making combat feel more realistic while keeping the prototype beginner-readable.

## Design Goal

Combat should feel like frightened, trained men fighting in rough hill country:

- Soldiers should not know everything.
- Squads should try to keep useful shapes before contact.
- Melee fighters should care about reach, crowding, flanks, and support.
- Archers should seek lines of fire, hold distance, and avoid shooting through allies.
- Morale should matter before health reaches zero.
- Bad soldiers should make bad decisions slowly, not simply deal less damage.
- Good soldiers should look disciplined, not psychic.

The player should be able to read why an enemy acted: he saw an opening, lost nerve, held rank, protected an archer, chased too far, or backed away from a sling.

## Current State

Relevant files:

- `scripts/soldier_enemy.gd`
- `scripts/combat_test.gd`
- `scripts/combat_player.gd`
- `scripts/sling_stone.gd`
- `scripts/human_projectile.gd`

Current strengths:

- `soldier_enemy.gd` already supports enemy/friendly factions through groups.
- Sword and bow soldiers share the same soldier body and damage pipeline.
- Bows lead moving targets and add dexterity-based spread.
- Bows score friendly-fire risk before firing.
- Friendly soldiers accept `hold` and `charge` orders.
- `combat_test.gd` already spawns test squads and campaign-derived lord-combat squads.
- Soldier stats already include `power`, `speed`, and `dexterity`.

Current limits:

- Soldiers mostly act as individuals, not as squads.
- Targeting is mostly nearest-valid-target selection.
- Enemies do not have orders, formation anchors, or squad-level plans.
- Movement is direct velocity steering, so units can clump and dogpile.
- Perception is omniscient within aggro/leash ranges.
- There is no morale, fatigue, fear, reaction delay, or target memory.
- Melee has no block, parry, shield use, reach difference, guard state, or attack commitment beyond a simple strike timing.
- `WEAPON_SPEAR` and `WEAPON_SLING` constants exist, but soldier equipment and tactics currently fall back to sword or bow behavior.

## Research Takeaways

These sources are design references, not claims that we should clone their private implementations.

### Bannerlord

`Mount & Blade II: Bannerlord` combines a campaign map with real-time battlefields where the player fights alongside troops. Its multiplayer classes are grouped into infantry, ranged, and cavalry, and faction identity is tied to weapon/role tendencies such as cavalry, archers, ambushes, and mounted archery. Recent reporting on the War Sails-era update also notes improved army/party AI and role-specific refinements across melee, ranged, and cavalry behavior.

Useful takeaway: realism comes from layered role behavior. The army or formation has intent, while each soldier still fights locally. For this prototype, that means a small squad layer should sit above `soldier_enemy.gd`.

Sources:

- [Mount & Blade II: Bannerlord overview](https://en.wikipedia.org/wiki/Mount_%26_Blade_II:_Bannerlord)
- [PC Gamer on Bannerlord's War Sails update and AI improvements](https://www.pcgamer.com/games/rpg/mount-and-blade-2-bannerlord-gets-free-patch-alongside-war-sails-dlc-thats-so-big-the-17000-word-update-run-more-than-twice-the-length-of-age-of-empires-2s-legendarily-long-patch-notes/)

### Total War

`Total War` battles lean heavily on formation, terrain, morale, flanks, routing, and rallying. Units can break before they are annihilated, and tactical conditions such as heavy casualties, being flanked, losing support, or losing a general matter.

Useful takeaway: morale is one of the cheapest ways to make battle behavior feel alive. It changes movement and intent without needing complex animation or expensive planning.

Source:

- [Empire: Total War battle and morale systems](https://en.wikipedia.org/wiki/Empire:_Total_War)

### F.E.A.R.

`F.E.A.R.` is a strong reference for readable tactical AI. It used Goal-Oriented Action Planning, local world knowledge, sensors, team behaviors, cover, flanking, retreating under pressure, and verbalized squad behavior. The important lesson is not "build GOAP now"; the lesson is that AI feels smart when it reacts through local knowledge and visible tactical motives.

Useful takeaway: use a simple utility scorer and local memory first. Add planning later only if the action set becomes too tangled.

Source:

- [F.E.A.R. AI and GOAP overview](https://en.wikipedia.org/wiki/F.E.A.R._%28video_game%29)

### Kingdom Come: Deliverance

`Kingdom Come: Deliverance` emphasizes weapon differences, armor interaction, stamina-like constraints, and physical reactions based on blow speed/weight.

Useful takeaway: melee realism should come from commitment, stamina, reach, facing, shield/parry decisions, and weapon matchups, not just more health or damage.

Source:

- [Kingdom Come: Deliverance combat overview](https://en.wikipedia.org/wiki/Kingdom_Come:_Deliverance)

### Utility AI

Utility AI scores possible actions numerically and chooses the best action, or a weighted action, for the current context. It is a good fit here because the prototype is small, decisions can stay readable, and we can avoid a heavy behavior tree or planner.

Useful takeaway: score actions like `hold_slot`, `attack`, `back_up`, `flank`, `guard`, `rout`, and `find_archer_lane`, then execute one clear action at a time.

Source:

- [Utility system overview](https://en.wikipedia.org/wiki/Utility_system)

## Proposed Architecture

Use three layers:

1. Squad layer
2. Soldier brain layer
3. Motor/combat layer

### Squad Layer

Add a small squad controller for each faction in `combat_test.gd`, or as a new `scripts/combat_squad.gd` if it stays readable.

Responsibilities:

- Track living soldiers by faction and role.
- Maintain a formation anchor, facing direction, and slots.
- Decide broad intent: `deploy`, `advance`, `hold`, `press`, `fallback`, `rout`.
- Share known enemy positions.
- Track casualties and morale pressure.
- Assign formation slots to soldiers.
- Tell archers where the main line is so they can avoid standing inside it.

This should be deliberately simple. The squad is not a chess engine. It answers: "What are we trying to do right now?"

Suggested squad data:

```gdscript
var squad_state := "advance"
var faction := "enemy"
var anchor := Vector3.ZERO
var facing := Vector3.FORWARD
var formation := "line"
var known_enemy_position := Vector3.ZERO
var known_enemy_time := 0.0
var starting_count := 0
var dead_count := 0
var morale := 70.0
var soldiers: Array[Node3D] = []
```

Initial formation types:

- `line`: default infantry frontage.
- `loose`: archer/skirmisher spacing.
- `cluster`: low-discipline fallback for small groups.
- `rout`: no formation; each soldier flees away from threat.

Defer complex formations such as wedge, shield wall, cavalry screen, and reserve until the basic line holds.

### Soldier Brain Layer

Keep the first implementation inside `soldier_enemy.gd` unless the file becomes painful. The current file is large, but a premature extraction could make the prototype harder to understand.

Each soldier gets a small "brain" section:

- Perception
- Memory
- Utility scoring
- Chosen action
- Reaction delay
- Morale/fatigue updates

Suggested soldier variables:

```gdscript
var _ai_action := "idle"
var _ai_action_time := 0.0
var _reaction_time := 0.0
var _morale := 70.0
var _fatigue := 0.0
var _last_seen_target: Node3D
var _last_seen_target_position := Vector3.ZERO
var _last_seen_target_time := 0.0
var _personal_space_radius := 0.9
var _squad: Node
var _formation_slot := Vector3.ZERO
var _has_formation_slot := false
```

Core update flow:

```gdscript
func _physics_process(delta: float) -> void:
	_update_body_timers(delta)
	_update_senses(delta)
	_update_morale_and_fatigue(delta)
	_update_active_target(delta)
	_update_ai_action(delta)
	var flat_speed := _execute_ai_action(delta)
	move_and_slide()
	_animate_soldier(delta, flat_speed)
```

The exact function names can match the existing style, but the shape matters: sense first, decide second, move/attack third.

### Motor And Combat Layer

The motor should execute chosen intents without knowing why they were chosen.

Motor responsibilities:

- Move toward formation slot.
- Move toward attack target.
- Back up from danger.
- Strafe/flank around an engaged enemy.
- Keep archer standoff distance.
- Apply ally separation.
- Apply terrain/slope penalty.
- Face movement or combat target.

Combat responsibilities:

- Start attacks.
- Resolve strike timing.
- Block/guard/parry later.
- Fire projectiles.
- Apply weapon reach, cooldown, damage, fatigue, and reaction modifiers.

The current `_think_and_move()` mixes decision and movement. It can be gradually replaced by `_choose_ai_action()` plus action-specific movement helpers.

## Perception And Memory

Replace omniscient aggro with believable sensing.

Soldier perception should consider:

- Sight radius.
- Field of view.
- Line of sight raycast.
- Hearing radius for recent hits, deaths, and nearby melee.
- Shared squad sightings.
- Last known target position.

Suggested defaults:

```gdscript
const SIGHT_RANGE := 34.0
const SIGHT_FOV_DEGREES := 130.0
const MEMORY_SECONDS := 4.0
const HEARING_RANGE := 12.0
```

Implementation steps:

1. Add `_can_see_target(candidate: Node3D) -> bool`.
2. Add a raycast from soldier head height to target center.
3. If visible, set `_last_seen_target`, `_last_seen_target_position`, and `_last_seen_target_time`.
4. Let squad remember recently seen enemy positions.
5. Let soldiers use last-known positions for a few seconds, then lose confidence.

Design rule:

- If a soldier cannot see the player, he can move toward the last known position or follow the squad, but he should not perfectly track the player forever.

## Utility Action Scoring

The first action set should be small:

- `hold_slot`
- `advance`
- `attack_melee`
- `guard`
- `back_up`
- `flank`
- `find_archer_lane`
- `fire_ranged`
- `regroup`
- `rout`

Example scoring:

```gdscript
func _score_attack_melee(distance: float, has_target: bool) -> float:
	if not has_target:
		return 0.0
	var range_score := 1.0 - clampf(distance / SWORD_ATTACK_RANGE, 0.0, 1.0)
	return 20.0 + range_score * 70.0 + _morale_ratio() * 10.0
```

```gdscript
func _score_rout() -> float:
	var health_pressure := 1.0 - float(health) / float(max_health)
	var morale_pressure := 1.0 - _morale_ratio()
	var isolation_pressure := 0.35 if _is_outnumbered_nearby() else 0.0
	return (health_pressure * 45.0) + (morale_pressure * 65.0) + (isolation_pressure * 40.0)
```

```gdscript
func _score_flank(target: Node3D) -> float:
	if target == null or weapon_type == WEAPON_BOW:
		return 0.0
	if not _target_is_engaged_by_ally(target):
		return 0.0
	return 35.0 + _morale_ratio() * 25.0 + randf_range(-8.0, 8.0)
```

Use light randomness and reaction delay so soldiers do not switch actions every frame.

Suggested decision interval:

- Disciplined/high-speed soldiers: 0.18 to 0.35 seconds.
- Ordinary soldiers: 0.35 to 0.65 seconds.
- Panicked soldiers: 0.12 to 0.25 seconds, but with worse decisions.

## Movement And Spacing

First priority: stop dogpiles.

Add simple steering before navmesh/pathfinding:

```gdscript
var desired := Vector3.ZERO
desired += _goal_direction() * 1.0
desired += _ally_separation_direction() * 1.35
desired += _enemy_spacing_direction() * 0.45
desired += _formation_correction_direction() * 0.75
```

Rules:

- Soldiers should avoid standing inside allies.
- Melee soldiers should try to attack from front/side arcs, not stack in one point.
- Archers should prefer lateral spacing and clear lanes.
- A soldier moving to a formation slot should slow down as he arrives.
- A soldier in melee can leave his slot if survival or attack utility is high enough.

Keep this local at first. Godot navigation can come later if the arena gains walls, cliffs, gates, or town streets.

## Morale

Morale is the main realism multiplier.

Morale inputs:

- Base from campaign morale for friendly soldiers.
- Starting confidence from party size ratio.
- Nearby allies.
- Nearby enemies.
- Health ratio.
- Recent damage.
- Ally death nearby.
- Enemy death nearby.
- Being surrounded.
- Being flanked or attacked from behind.
- Commander/player proximity.
- Squad casualties.
- Projectile near miss or sling impact nearby.
- Holding higher ground.

Morale states:

- `steady`: normal behavior.
- `shaken`: slower reactions, more guarding, worse aim.
- `wavering`: more backing up, less chasing.
- `routing`: flee from enemies and ignore ordinary orders.
- `rallying`: return to squad if safe and allies are nearby.

Suggested thresholds:

```gdscript
const MORALE_STEADY := 60.0
const MORALE_SHAKEN := 40.0
const MORALE_WAVERING := 22.0
const MORALE_ROUTING := 10.0
```

Rout behavior:

- Move away from nearest visible threat.
- Prefer moving toward friendly map edge or squad rear.
- Drop attack intent.
- If no enemy is near and allies are close, slowly rally.

This will make battles end naturally without requiring every unit to be killed.

## Fatigue

Fatigue should be simple and visible in behavior.

Fatigue increases when:

- Sprinting or charging.
- Attacking.
- Blocking heavy hits.
- Climbing/rough slope later.
- Holding a drawn bow.

Fatigue decreases when:

- Standing, walking, guarding lightly.
- Not actively fighting.

Effects:

- Reduce move speed slightly.
- Increase attack cooldown.
- Increase bow spread.
- Reduce morale recovery.
- Make retreat/guard more likely.

Suggested formula:

```gdscript
var fatigue_ratio := clampf(_fatigue / 100.0, 0.0, 1.0)
var effective_speed := move_speed * lerpf(1.0, 0.78, fatigue_ratio)
var cooldown_multiplier := lerpf(1.0, 1.35, fatigue_ratio)
```

Do not add a HUD for every soldier yet. The behavior should communicate enough.

## Melee Improvements

Current melee is a timed strike if the target is in range. Improve it in layers.

### Layer 1: Reach And Commitment

Add weapon reach:

- Sword: short, faster recovery.
- Spear: longer reach, worse at point-blank range.
- Club/axe later: short, high shock.

During attack windup, soldiers should commit. They can rotate a little, but not instantly snap to a dodging target.

### Layer 2: Guard And Shield

Add `guard` as an action:

- Raises shield if `has_shield`.
- Reduces incoming frontal melee/projectile damage.
- Slows movement.
- Costs fatigue if held too long.

Use facing arcs:

- Front arc: can block/guard.
- Side arc: partial defense.
- Rear arc: no defense and morale hit.

### Layer 3: Support And Crowding

Spears should be useful from second rank:

- Spear soldiers can attack past one nearby ally if line of attack is clear enough.
- Sword soldiers should avoid attacking through allies.

Crowding penalty:

- Too many allies near the same target should reduce attack score.
- A soldier should prefer a side step or flank if the front is full.

### Layer 4: Wounds

Do not add body-part simulation yet. Add simple wound flags:

- `leg_wounded`: lower speed.
- `arm_wounded`: slower attack or worse bow aim.
- `head_wounded`: morale shock and brief stun.

Use existing headshot shape as the first hook.

## Ranged Improvements

Archers currently have useful basics. Extend them into believable skirmishers.

### Line Of Fire

Keep the current friendly-fire lane check, but use it earlier:

- If no safe shot, score `find_archer_lane`.
- Move laterally until a safe lane opens.
- Prefer slightly elevated positions when available.

### Aim And Suppression

Archers should not fire with machine certainty:

- Aim confidence rises while the target remains visible.
- Moving reduces confidence.
- Being threatened or damaged reduces confidence.
- High dexterity raises confidence faster.

Suggested variables:

```gdscript
var _aim_confidence := 0.0
const AIM_CONFIDENCE_REQUIRED := 0.75
```

### Sling Awareness

The player's sling is central to the prototype, so enemies should react to it.

Short-term behavior:

- If a sling stone hits nearby terrain or an ally, nearby soldiers lose morale.
- Shielded soldiers may guard when the player is visibly charging.
- Archers may spread out if repeated sling hits land near them.

Later:

- Add AI slingers as light skirmishers.
- Slings have longer windup and lower armor penetration than bows, but high morale shock on head/body hits.

## Terrain Awareness

The combat arena is rough hill country. AI should care.

Add simple terrain sampling through existing `_terrain_height(x, z)` in `combat_test.gd`:

- High ground bonus for archers and morale.
- Slope penalty for charging uphill.
- Avoid steep local height changes.
- Prefer paths/open ground for formation movement.

Implementation:

- Expose `get_combat_terrain_height(position: Vector3) -> float`.
- Expose `get_combat_terrain_slope(position: Vector3) -> float`.
- Soldiers ask `terrain_owner` for terrain info if available.

Do not build a complex terrain planner yet. Sample nearby candidate points and score them.

## Enemy Squad Tactics

Enemy AI should use a small state machine at squad level.

Suggested enemy states:

- `deploy`: move into starting formation.
- `advance`: move toward the player/friendly squad while keeping shape.
- `skirmish`: archers shoot while infantry screens.
- `engage`: melee line closes.
- `press`: enemy morale/strength is high, push harder.
- `fallback`: squad backs toward better ground or archers.
- `rout`: squad cohesion breaks.

State transitions:

```text
deploy -> advance when formation is roughly ready
advance -> skirmish if archers have range and melee can screen
advance -> engage if melee is close
engage -> press if enemy morale is low or numbers advantage is high
engage -> fallback if casualties are high or archers are exposed
any -> rout if squad morale collapses
fallback -> engage if allies regroup and enemies overextend
```

Tactics by role mix:

- Mostly melee: advance in line, avoid trickling in, press when close.
- Mixed melee/bow: infantry screens, archers stay behind or to the side.
- Mostly bow: loose formation, kite backward, avoid melee.
- Future spears: hold longer, punish charges, protect archers.
- Future slingers: harass, spread out, avoid direct melee.

## Player Commands

Current commands:

- `F1`: hold position
- `F3`: charge

Near-term additions:

- `F2`: advance to cursor while keeping formation.
- `F4`: fall back toward player.
- `F5`: toggle loose/line formation.

Do not add a complex command menu yet. More buttons will not fix unreadable AI. The AI should be useful with the existing two commands first.

Hold behavior should improve:

- Friendly infantry should hold a line around assigned slots.
- Friendly archers should hold near the line but seek safe lanes.
- Soldiers may leave formation briefly if attacked, then return.

Charge behavior should improve:

- Charge should mean "press enemy as a squad," not "each soldier picks a nearest target and dogpiles."
- Low-morale soldiers may hesitate before charging.

## Implementation Milestones

### Milestone 1: Stop The Dogpile

Goal: soldiers maintain rough spacing and formation slots.

Tasks:

- Add ally separation steering in `soldier_enemy.gd`.
- Add enemy squad slot assignment for spawned enemy parties.
- Keep friendly hold slots, but add slot correction while fighting.
- Add simple debug labels for AI action and morale behind a constant or debug toggle.

Acceptance:

- Six soldiers charging one target do not all occupy the same point.
- Friendly hold order forms a readable line.
- Enemy lord-combat parties start and advance as a rough line instead of a loose crowd.

### Milestone 2: Perception And Memory

Goal: soldiers stop acting omniscient.

Tasks:

- Add sight range and FOV checks.
- Add line-of-sight raycast.
- Add last-known target memory.
- Add squad shared sighting.
- Add reaction delay based on stats.

Acceptance:

- Soldiers briefly search or move to last-known positions after losing sight.
- Soldiers do not perfectly chase unseen targets around terrain or future obstacles.
- Better soldiers react faster without becoming psychic.

### Milestone 3: Utility Decisions

Goal: soldiers choose between a few readable actions.

Tasks:

- Add utility scoring for melee soldiers: attack, guard, back up, flank, regroup, rout.
- Add utility scoring for archers: fire, find lane, back up, regroup, rout.
- Add action lock timers to avoid twitchy switching.
- Keep existing attack and bow mechanics as action execution.

Acceptance:

- Melee soldiers sometimes back up or flank instead of always moving straight in.
- Archers move laterally when friendly-fire risk blocks the shot.
- Wounded or isolated soldiers become less aggressive.

### Milestone 4: Morale And Fatigue

Goal: combat has human breaking points.

Tasks:

- Add soldier morale and fatigue variables.
- Add morale events for damage, ally death, enemy death, being surrounded, and rout.
- Add fatigue from movement/attacks/aiming.
- Add rout and rally behavior.
- Feed friendly starting morale from `GameState.morale` during lord combat.

Acceptance:

- Battles can end with enemies routing before total annihilation.
- Casualties produce visible shifts in aggression.
- Exhausted soldiers slow down and attack less cleanly.

### Milestone 5: Melee Roles

Goal: weapon choice changes behavior.

Tasks:

- Implement spear equipment and reach.
- Add too-close penalty for spears.
- Add guard/shield behavior.
- Add front/side/rear arc checks for defense and morale.
- Add crowding penalty around targets.

Acceptance:

- Spearmen hold distance and support from behind allies.
- Sword soldiers try to close past spear range.
- Shielded soldiers visibly guard under ranged pressure.
- Rear attacks are more dangerous and more frightening.

### Milestone 6: Ranged And Sling Reactions

Goal: ranged combat reshapes the fight.

Tasks:

- Add aim confidence.
- Add archer lane seeking.
- Add high-ground preference.
- Add morale shock from nearby projectile impacts.
- Add shield response to visible sling charge.
- Later: add AI slingers.

Acceptance:

- Archers do not stand calmly in a blocked lane.
- Repeated sling hits make nearby enemies hesitate, spread, guard, or rout.
- High ground becomes tactically valuable without hard scripting.

## Proposed File Changes

Likely files:

- `scripts/soldier_enemy.gd`
  - Add perception, memory, morale, fatigue, utility action selection, separation steering, and role-specific movement.
- `scripts/combat_test.gd`
  - Add squad setup, enemy orders, terrain query helpers, debug toggle, and maybe more command keys.
- `scripts/human_projectile.gd`
  - Later: broadcast near-miss or impact events for morale.
- `scripts/sling_stone.gd`
  - Later: broadcast sling impact shock radius.
- `scripts/game_state.gd`
  - Later: pass campaign morale into friendly combat morale.

Optional new files:

- `scripts/combat_squad.gd`
  - Use only if squad logic becomes too large for `combat_test.gd`.
- `scripts/combat_ai_debug.gd`
  - Use only if debug drawing becomes noisy.

Avoid adding external AI plugins. The prototype is small enough for hand-authored utility logic.

## Debugging Tools

Add a debug mode early. Without it, AI tuning becomes superstition.

Debug display:

- Soldier action.
- Morale.
- Fatigue.
- Target name.
- Formation slot marker.
- Last-known target marker.
- Squad state.

Debug controls:

- Toggle AI labels.
- Toggle formation slot markers.
- Freeze squad state if needed later.
- Spawn a small test wave if useful later.

This should be development-only and easy to remove or hide.

## Validation Plan

After code changes, run:

```bash
tools/validate-startup.sh
```

The wrapper must still load:

- `res://scenes/main.tscn`
- `res://scenes/combat_test.tscn`

For this design document alone, no Godot startup validation is required because no scenes, scripts, project settings, or resources changed.

Manual checks after each milestone:

- Test combat scene from the map through `F`.
- Test direct lord-combat entry from campaign encounter.
- Test friendly `F1` hold and `F3` charge.
- Test player death/retreat/victory return paths.
- Test small and larger party sizes.
- Watch for soldiers vibrating, stalling, spinning, clumping, or ignoring enemies.

## Tuning Principles

- Prefer visible flaws over hidden perfection.
- Make good decisions slow enough to read.
- Use stats to change temperament, timing, discipline, and recovery, not only damage.
- Let morale end fights.
- Let terrain and formation create tactical differences before adding new weapons.
- Keep random variation small and bounded.
- Avoid per-frame full scans when squad caches can provide local lists.
- Do not make the player feel cheated. If the AI knows something, it should have seen, heard, inferred, or been told it.

## Open Questions

- Should friendly troops obey the player absolutely, or should low-morale soldiers sometimes ignore suicidal orders?
- Should David/the player act as a morale anchor for nearby allies in combat?
- Do we want historically flavored roles soon, such as shieldmen, spearmen, archers, and slingers, or should we deepen sword/bow first?
- Should rout count as defeat for lord combat, or should routed enemies remain alive on the campaign map?
- Should campaign morale and food fatigue influence combat starting morale/stamina?

## Recommended First Implementation

Start with Milestone 1 and half of Milestone 3:

1. Add ally separation.
2. Add enemy formation anchors and slots.
3. Add basic action labels: `hold_slot`, `advance`, `attack_melee`, `fire_ranged`, `back_up`.
4. Add archer lane movement when friendly-fire risk blocks a shot.

This will produce the biggest immediate realism gain with the least risk. Morale and perception should come next, once the units are no longer physically behaving like a crowd of magnets.
