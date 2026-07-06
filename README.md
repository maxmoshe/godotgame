# Dav

A tiny Godot 4 top-down campaign-map prototype for a Mount & Blade-style game set around Saul's kingdom and the territories that later gather under David.

## Run It

1. Open Godot.
2. Import `project.godot`.
3. Press `F5` or click Play.

## WSL Startup Check

Godot `4.7-stable` is installed locally for WSL under `.tools/godot/`.

To verify that the project starts without parser or startup errors:

```bash
tools/validate-startup.sh
```

If the local Godot binary is missing, reinstall it with:

```bash
tools/install-godot-wsl.sh
```

## Map Data

The campaign map now renders from engine-agnostic WGS84 data under:

```text
data/maps/southern_levant/
```

The layer manifest is `data/maps/southern_levant/map_manifest.json`. Physical geography, biome/relief abstractions, settlements, routes, passes, fords, chokepoints, and dormant historical overlays are kept as separate GeoJSON/JSON layers so later engines or time periods can reuse or replace them without touching Godot-specific drawing code. The current Godot map renders biome colors, relief texture, roads, water, and faction-colored settlements; ancient influence zones are not drawn.

## Controls

- Click a city or NPC party: travel there and open an encounter dialogue on arrival
- Click Continue or the dialogue panel: advance multi-page encounter text
- Choose Trade in a city: open the town market on the left and your inventory on the right
- Click open country: travel freely
- Hold left mouse: keep traveling toward the pointer
- `WASD` or arrow keys: move manually and interrupt automatic travel
- `Shift`: move faster
- `I`: toggle inventory
- `F`: enter the 3D sling combat test
- Drag inventory items between squares to move, swap, or combine stackable items

## 3D Sling Test

The combat test is currently stripped back to a Bethlehem-style Judean hill-country terrain, a dirt path, sling targets, and scattered stones. Earlier placeholder sheep, grass tufts, trees, terraces, blocks, clouds, and other props were removed until better art is ready.
The ground uses a terrain shader that blends downloaded rocky-grass and gravel textures directly on the terrain surface. Larger dirt depressions are also built into the terrain height, keeping color and relief aligned without slow load-time texture generation.
Pebbles and larger rocks use reusable scatter logic with path exclusion zones, so stones and future props can avoid paths or other reserved spaces. The stones use the marble diffuse and displacement textures from `assets/textures/terrain/marble`; the EXR normal/roughness maps are present but not wired because the WSL startup check could not load EXR resources.

- `WASD`: move
- `Space`: jump
- Mouse: first-person look, clamped only near straight down at the ground and straight up at the sky
- Right mouse: aim without zooming the camera
- Hold left mouse: charge the sling, slowing movement and disabling sprint
- Release left mouse: throw a sling stone
- Impacts on targets or terrain spawn a bright stone-spark burst and fading surface heat mark
- `Esc`: return to the campaign map

## First Files To Edit

- `scenes/main.tscn`: the main scene that Godot launches
- `scripts/campaign_map.gd`: map drawing, roads, settlements, and region labels
- `scripts/player.gd`: movement and the player marker
- `scripts/main.gd`: connects the player, map, camera, and location label
- `scripts/inventory_panel.gd`: inventory slots, item stacks, item weight, and starter items
- `scripts/inventory_slot.gd`: drag and drop behavior for inventory squares
- `scenes/combat_test.tscn`: 3D sling combat test arena
- `scripts/combat_player.gd`: first-person movement and sling throwing
- `scripts/impact_sparks.gd`: short-lived impact particles for sling stones
- `scripts/sling_stone.gd`: sling projectile lifetime and hit detection
- `scripts/target_dummy.gd`: simple target hit counter

## Good Next Steps

- Add faction ownership to settlements: Saul, Judah, Philistines, neutral clans.
- Add party encounters as moving markers on the road network.
- Add prices, ownership checks, and buy/sell confirmation to city trade.
- Add faction-specific settlement screens for Gibeah, Bethlehem, Hebron, Gath, and Ziklag.
- Replace the drawn map with painted tiles or a real historical map texture once the gameplay loop feels good.
