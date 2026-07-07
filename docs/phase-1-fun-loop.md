# Phase 1 Fun Loop Implementation Plan

## Summary

Phase 1 turns the current campaign-map prototype into a playable pressure loop: David's band must recruit enough men and reach Ziklag while hostile lords, especially Abner, can detect, pursue, and catch the player.

The goal is not to make a large strategy game yet. The goal is to make the road feel dangerous, choices feel consequential, and the map feel like a living problem the player is trying to survive.

Status note: the first overworld AI pass is now broader than this original Phase 1 plan. Hostile lords use confidence, rumors, search, pursuit, intercept, recovery, and pressure relief instead of an Abner-only detection rule. See `docs/overworld-ai.md` for the current system.

## Player Objective

The Phase 1 objective is:

> Recruit at least 8 men and reach Ziklag before hostile pursuit breaks David's band.

The player starts with David, limited food, ordinary morale, and little map control. Towns can provide recruits and rumors. Hostile lords move on the map, detect the player inside a visible threat radius, and may pursue until the player escapes, reaches temporary safety, or is caught.

Reaching Ziklag with enough men produces a clear success dialogue. Being caught by a hostile lord starts combat through the existing lord-combat flow.

## Core Loop

Phase 1 should repeatedly push the player through this loop:

1. Travel across the campaign map.
2. Notice danger or opportunity: lord patrols, settlement recruits, rumors, food pressure, or road choices.
3. Choose a response: flee, recruit, trade, ask for news, help, take supplies, ambush, or hide.
4. Resolve the choice through dialogue, state changes, or combat.
5. Update the map state: time passes, food drops, morale shifts, lords continue moving, and pursuit pressure changes.

If this loop works, the player should feel hunted but not helpless. Every trip should carry a question: is this detour worth the time, food, and risk?

## Minimum Gameplay Systems

### Lord Detection And Pursuit

- Give hostile lords detection radii drawn directly on the campaign map.
- Abner is still the clearest Phase 1 hunter, but other hostile lords can also search, intercept, or pursue when they have enough evidence.
- When a hostile lord gains a strong direct sighting or reliable report, that lord can enter a pursuing state and move toward the player instead of following his route.
- If a hostile lord reaches catch distance, stop player travel and open a forced lord encounter with the existing attack/combat option.
- The player can escape pursuit by increasing distance beyond an escape radius or reaching a settlement/wilderness safe condition.
- Pursuit state should persist through ordinary campaign updates and scene returns using `GameState`.

### Food, Morale, And Heat

- Add simple campaign survival stats to `GameState`:
- `food`: consumed as campaign time advances while the player travels.
- `silver`: spent on clean food purchases and simple settlement support.
- `morale`: rises from successful recruitment and victory, falls from hunger, losses, and being hunted.
- `heat`: a simple reputation-pressure value that rises after hostile actions and makes pursuit more likely or more severe.
- Food should only drop when campaign time advances, not while dialogue panels are open or the player is idle.
- Low food should damage morale before causing more punishing outcomes.
- Keep values readable and visible in the HUD.

### Recruitment Objective

- Reuse existing settlement recruitment and cooldown behavior.
- Each successful recruitment increases the party count and advances objective progress.
- The HUD should show objective progress, for example: `Reach Ziklag with 8 men: 5/8`.
- Ziklag should check success when the player arrives or opens its settlement dialogue.

### Rumors

Settlements and scouts should provide practical, state-based information instead of flavor-only text.

Rumors should be generated from live campaign state:

- nearest hostile lord and approximate direction
- whether hostile lords are searching, pursuing, intercepting, recovering, or distant
- which nearby settlements can currently recruit
- dangerous roads or regions based on lord positions
- whether Ziklag is reachable and what the player still lacks

Rumors do not need a complex quest system. They should be clear enough to change the player's next decision.

### Small Consequential Choices

Add a few low-cost encounter choices before building a full quest framework:

- Ask for news: gives a useful rumor.
- Request recruits: uses the existing recruit cooldown and party flow.
- Buy food: spends silver, increases food, and keeps heat low.
- Take supplies by force: requires a large enough band to intimidate a town, increases food, raises heat, and lowers morale or local trust.
- Hide until dark: advances time, may break pursuit, consumes food.

These choices can live in existing dialogue panels and should update `GameState` immediately.

### Combat Outcomes

Lord combat should continue to use the existing `GameState.start_lord_combat()` path and `res://scenes/combat_test.tscn`.

Phase 1 only needs basic post-combat campaign consequences:

- victory raises morale and may lower immediate pursuit pressure
- defeat or escape lowers morale and may reduce party size
- combat may grant a small food or loot reward
- heat may rise after fighting Saul's men or Philistine parties

Do not build a full battle result screen unless needed for clarity. A simple return dialogue or campaign notification is enough.

## Implementation Notes

### `GameState`

Add persistent campaign loop state:

- food
- morale
- heat
- objective target count
- objective completion flag
- lord pursuit states keyed by lord name
- last generated combat outcome, if needed for return-to-map messaging

Keep this data plain and beginner-readable. Use dictionaries where they match existing project style.

### `campaign_map.gd`

Expose live lord information needed by `main.gd`:

- current lord positions
- faction/hostility data
- detection radius and catch radius
- helpers to set a lord to pursuing, escaped, or route-following

Draw simple threat circles in code. Use translucent color so they communicate danger without hiding roads and settlements.

### `main.gd`

Own the campaign loop:

- advance food/morale pressure only when campaign time advances
- ask `campaign_map.gd` to update overworld AI
- trigger forced encounters when caught
- refresh HUD text for food, morale, heat, and objective progress
- add settlement dialogue branches for rumors, food, hiding, and objective completion

Guard viewport access in any new input handling, matching the project guidance.

### HUD And Dialogue

Reuse existing HUD and dialogue panels. Prefer adding compact labels or reusing existing text areas over creating a new UI system.

The player should always be able to answer:

- How many men do I have?
- How much food remains?
- Is morale healthy?
- Is someone hunting me?
- What do I need before Ziklag?

## Deferred Work

Do not include these in Phase 1 unless they become necessary to prove the loop:

- kingdom management
- deep diplomacy
- complex trade prices or ownership rules
- painted map art or tile replacement
- full quest framework
- large inventory economy
- named companion progression
- additional playable scenes

## Acceptance Criteria

Phase 1 is playable when these scenarios work:

- A hostile lord detects the player inside a visible radius and can begin pursuit.
- The player can escape pursuit by distance or a safe settlement/wilderness action.
- If a hostile lord catches the player, a forced encounter opens and can enter combat.
- Recruitment advances the Ziklag objective and still respects settlement cooldowns.
- Food decreases only when campaign time advances.
- Low food reduces morale.
- Successful recruitment or victory improves morale.
- Rumors reflect current lord, recruit, threat, or objective state.
- Reaching Ziklag with at least 8 men produces success text.

## Validation

After implementing gameplay changes, run:

```bash
tools/validate-startup.sh
```

The check must still load:

- `res://scenes/main.tscn`
- `res://scenes/combat_test.tscn`

If Phase 1 adds another playable scene, update `tools/validate-startup.sh` in the same change.

For this planning document alone, no Godot startup validation is required because no scenes, scripts, project settings, or resources changed.
