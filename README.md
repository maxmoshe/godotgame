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

The combat test now opens in a small Bethlehem-style Judean hill-country pasture with mostly green grass, irregular brown soil patches, uneven hills, stone terraces, olives, figs, sage scrub, wildflowers, a sheepfold, sheep, rocks, and sling targets placed across the slopes.
The ground uses a terrain shader that blends downloaded rocky-grass and gravel textures directly on the terrain surface. Larger dirt depressions are also built into the terrain height, keeping color and relief aligned without slow load-time texture generation. Limestone pebbles are varied flattened faceted 3D meshes.
The terrain shader currently uses downloaded 1K rocky grass and gravel diffuse maps plus PNG displacement maps for bump detail. The downloaded EXR normal/roughness maps are present but not wired because the WSL startup check could not load them.
Generated scenery uses reusable decoration exclusion zones, so stones, grass, and future scatter props can avoid paths or other reserved spaces.

- `WASD`: move
- Mouse: first-person look, clamped only near straight down at the ground and straight up at the sky
- Right mouse: aim without zooming the camera
- Hold and release left mouse: charge and throw a sling stone
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
