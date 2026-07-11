# Terrain Texture Generation

Use this workflow when generating or refreshing terrain textures for combat biomes.

## Goals

- Keep terrain readable from the combat camera.
- Match the real biome first, then stylize for gameplay.
- Keep each generated texture project-bound under `assets/textures/terrain/`.
- Pair every albedo with a simple height/displacement map so stones, scrub, and paths do not read as flat decals.

## Research First

Before generating a biome texture, gather a few concrete cues:

- terrain type: coastal sand, terra rossa, limestone, basalt, mud, cracked desert soil
- vegetation: dry grass, garrigue scrub, olive/vine fragments, forest litter, reeds
- relief: rolling foothills, ridge country, wadis, terraces, cliffs, floodplain
- season/mood: summer dry, winter green, spring scrub, arid wilderness

For the Bethlehem/Battir edge, useful cues were Judean hill country, pale limestone, terra rossa soil, seasonal green grass/scrub, dry-stone agricultural terraces, and wadis. Avoid turning this into desert sand.

## Generate Albedo

Use the built-in image generation path for normal texture work. Prompt for:

- `square seamless terrain albedo texture`
- `orthographic top-down`
- `no horizon, no perspective`
- `designed to repeat as a tile`
- exact biome materials and vegetation
- constraints: no roads, footprints, large plants, objects, text, borders, watermark, cast shadows, or obvious repetition

Example prompt shape:

```text
Use case: stylized-concept
Asset type: square seamless terrain albedo texture for a Godot 4 combat biome
Primary request: Generate a Bethlehem-area Judean highland ground texture.
View and composition: orthographic top-down, flat square texture, no horizon, no perspective, designed to repeat as a tile.
Surface details: terra rossa soil, seasonal green grass, low Mediterranean scrub, thyme-like gray-green flecks, pale chalky limestone chips, dry straw/rootlets.
Style: realistic but game-readable, dry Mediterranean highland, matte, medium contrast.
Constraints: no large bushes, trees, flowers, roads, footprints, wet mud, beach sand, objects, text, border, watermark, cast shadows, or obvious repeated pattern.
Output intent: primary ground layer for a 3D terrain shader.
```

The built-in image tool saves generated files under `$CODEX_HOME/generated_images/`. Keep that original file in place and create a project copy.

## Siege And Castle Stone

Castle, fortress, keep, tower, wall, stair, and gatehouse stone should use one shared siege texture instead of biome-specific rock textures. This keeps built structures visually consistent across combat biomes.

Current shared castle stone:

```text
assets/textures/siege/jerusalem_limestone_blocks_diff_1k.jpg
assets/textures/siege/jerusalem_limestone_blocks_disp_1k.png
```

Use this prompt shape when refreshing it:

```text
Use case: stylized-concept
Asset type: square seamless masonry albedo texture for a Godot 4 ancient fortress/castle wall material
Primary request: Generate a Jerusalem limestone block wall texture for all castle and siege stone surfaces.
View and composition: orthographic straight-on wall texture, flat square tile, no perspective, no horizon, designed to repeat seamlessly on vertical and horizontal surfaces.
Surface details: pale warm cream Jerusalem limestone, hand-cut rectangular ashlar blocks, uneven block sizes, thin recessed mortar seams, chipped edges, subtle pitting, weathered chalky stone grain, faint tan dust in crevices.
Style: realistic but game-readable, matte, medium contrast, ancient Levant fortress masonry.
Constraints: no windows, doors, plants, large cracks, graffiti, text, border, watermark, cast shadows, dramatic lighting, or obvious repeated pattern.
Output intent: shared albedo texture for 3D fortress walls, towers, stairs, gatehouse, keep, and storehouse.
```

Derive the displacement map like a rock texture:

```bash
convert assets/textures/siege/jerusalem_limestone_blocks_diff_1k.jpg -colorspace Gray -auto-level -blur 0x0.45 -sigmoidal-contrast 5x48% -level 9%,96% -strip assets/textures/siege/jerusalem_limestone_blocks_disp_1k.png
```

Do not wire castle stone through biome profile `rock_*` keys. Terrain rocks can vary by biome; built masonry should not.

## Prompt Sets

Keep the final prompt set in this doc when a biome graduates into the project.

Coastal Plain:

- primary ground: southern Levant coastal plain, sandy loam, pale calcareous soil, small kurkar sandstone chips, dry yellow grass, sparse low coastal scrub, tiny shell fragments at low density, not a beach scene.
- scrub spots: pale kurkar gravel, sandy loam pockets, denser dry coastal grass, gray-green scrub flecks, shell grit, small rounded calcareous stones.
- paths: compacted sandy loam, pale calcareous dust, tiny kurkar pebbles, fine straw, shell grit, very sparse dry grass fibers.
- rocks: honey-beige porous kurkar sandstone, shell inclusions, small pits, weathered surface, faint tan soil stains.

Central Highlands:

- primary ground: Judean/central highlands ridge-country ground, pale gray-beige limestone chips, terra rossa pockets, dry yellow grass, sparse gray-green Mediterranean scrub, oak/pistacia leaf fragments, stonier and less lush than Bethlehem, orthographic seamless tile.
- rocky spots: exposed limestone and scrub patches with denser pale gravel, chalky stones, darker terra rossa pockets, sparse thorny gray-green garrigue, no large bushes or shadows.
- paths: worn highland footpath with compacted terra rossa, dusty tan soil, crushed pale limestone powder, tiny embedded pebbles, sparse straw, matte and repeatable.
- rocks: pale Judean highland limestone for triplanar procedural rocks, beige-gray hard limestone, chalky grain, pits, fractures, light terra rossa staining.

Galilee Hills:

- primary ground: northern Galilee Mediterranean woodland floor, terra rossa soil, pale limestone/dolomite chips, dry oak and pistacia leaf litter, gray-green maquis flecks, fresh seasonal grass, tiny twigs and straw.
- maquis spots: darker leaf-litter and scrub patches with dense oak/pistacia fragments, mossy grass tufts, thorny gray-green maquis, embedded limestone chips.
- paths: compacted reddish terra rossa, dusty limestone powder, embedded pale pebbles, crushed dry leaves, fine roots, sparse grass.
- rocks: pale beige-gray Galilee limestone/dolomite, chalky grain, pits, fine fractures, tan soil stains, subtle gray-green lichen speckles.

Jordan Rift:

- primary ground: Jericho/Dead Sea-margin alluvial silt, pale marl/chalk flecks, light mineral crust speckles, dry reed fragments, sparse tamarisk/acacia litter, tiny rounded wadi pebbles.
- marl spots: chalky pale marl crust, white salt/mineral speckles, compact tan silt, scattered wadi pebbles, dry reed splinters, muted desert shrub flecks.
- paths: smooth dusty tan alluvial silt, pale marl dust, fine mineral speckles, sparse tiny rounded pebbles, dry reed fibers.
- rocks: pale chalky marl and tan limestone, powdery grain, erosion pits, dusty cracks, white mineral/salt stains, rounded pebble inclusions.

Transjordan Plateau:

- primary ground: tan limestone gravel, red-brown dusty soil pockets, dark chert/flint chips, sparse dry steppe grass, gray-green scrub flecks, straw fragments.
- chert spots: dense tan limestone chips, dark flint/chert fragments, reddish dusty soil between stones, sparse wiry steppe grass.
- paths: hard-packed tan dust, red-brown soil, crushed limestone powder, small chert/flint chips, fine gravel, sparse straw fibers.
- rocks: tan weathered limestone with dark gray-brown chert/flint veins, pits, fractured grain, reddish dust stains, subtle desert varnish.

Negev / Arabah Wilderness:

- primary ground: orange-tan loess dust, angular limestone gravel, dark flint pebbles, dry cracked clay flecks, desert-varnish stones, sparse dead thorn fragments.
- wadi-fan spots: dense angular limestone gravel, dark flint pebbles, orange-tan loess dust, cracked dry clay pockets, desert-varnished stones, dead thorn fragments.
- paths: hard-packed orange-tan loess dust, crushed limestone powder, dark flint chips, fine desert gravel, faint cracked dry clay, sparse twig fibers.
- rocks: tan limestone, dark flint nodules/chips, fractured grain, erosion pits, orange loess dust stains, subtle desert varnish, chalky dry edges.
- terrain relief: use `terrain_vertical_relief_*` profile keys for Negev-style makhtesh and wadi-cut heightmap relief. Keep this as terrain height, not separate cliff props, so collision and visuals stay aligned.

## Naming

Use lowercase role-based names:

```text
assets/textures/terrain/<biome>/<biome>_<role>_diff_1k.jpg
assets/textures/terrain/<biome>/<biome>_<role>_disp_1k.png
```

Common roles:

- `primary` or a location name, for the base ground layer
- `scrub_spots`, for darker/greener broken ground patches
- `compacted_path`, for road/path shader blending
- `limestone_rock`, for procedural triplanar rocks

Current biome examples live in:

```text
assets/textures/terrain/shephelah_mediterranean/
assets/textures/terrain/coastal_plain/
assets/textures/terrain/central_highlands/
assets/textures/terrain/galilee_northern_hills/
assets/textures/terrain/jordan_rift/
assets/textures/terrain/transjordan_plateau/
assets/textures/terrain/negev_arabah_wilderness/
```

## Create Height Maps

Use ImageMagick `convert` for quick derived displacement maps. Keep them shallow; harsh height maps make the terrain noisy.

Primary ground with green/scrub:

```bash
convert <source.png> -resize 1024x1024! -strip -quality 92 <name>_diff_1k.jpg
convert <source.png> -resize 1024x1024! -colorspace Gray -auto-level -blur 0x0.55 -sigmoidal-contrast 4x48% -level 11%,94% /tmp/<name>_luma.png
convert <source.png> -resize 1024x1024! -colorspace HSL -channel G -separate +channel -auto-level -blur 0x0.45 /tmp/<name>_sat.png
convert /tmp/<name>_luma.png /tmp/<name>_sat.png -compose blend -define compose:args=72,28 -composite -blur 0x0.25 -level 12%,94% -strip <name>_disp_1k.png
```

Compacted paths:

```bash
convert <name>_diff_1k.jpg -colorspace Gray -auto-level -blur 0x0.95 -sigmoidal-contrast 3x50% -level 18%,92% -strip <name>_disp_1k.png
```

Rock textures:

```bash
convert <name>_diff_1k.jpg -colorspace Gray -auto-level -blur 0x0.45 -sigmoidal-contrast 5x48% -level 8%,96% -strip <name>_disp_1k.png
```

Scrub spot layers:

```bash
convert <name>_diff_1k.jpg -colorspace Gray -auto-level -blur 0x0.55 -sigmoidal-contrast 4x48% -level 12%,94% -strip /tmp/<name>_luma.png
convert <name>_diff_1k.jpg -colorspace HSL -channel G -separate +channel -auto-level -blur 0x0.4 -strip /tmp/<name>_sat.png
convert /tmp/<name>_luma.png /tmp/<name>_sat.png -compose blend -define compose:args=68,32 -composite -blur 0x0.25 -level 10%,94% -strip <name>_disp_1k.png
```

## Import Into Godot

After adding or changing texture files:

```bash
tools/godot-wsl.sh --headless --path . --import --quit
```

Godot should create `.import` sidecars for every new `.jpg` and `.png`. The import command may print unrelated editor-layout noise if a dev scene references a missing script, but the startup wrapper below is the source of truth.

## Wire The Biome

Add texture constants in `scripts/combat_biome_profiles.gd`, then set the profile keys:

```gdscript
"primary_albedo_path": MY_GROUND_ALBEDO,
"primary_height_path": MY_GROUND_HEIGHT,
"secondary_albedo_path": MY_SPOTS_ALBEDO,
"secondary_height_path": MY_SPOTS_HEIGHT,
"path_albedo_path": MY_PATH_ALBEDO,
"path_height_path": MY_PATH_HEIGHT,
"rock_albedo_path": MY_ROCK_ALBEDO,
"rock_height_path": MY_ROCK_HEIGHT,
```

Tune nearby shader/profile values:

- `primary_tint`, `secondary_tint`, `path_tint`
- `detail_tile`, `secondary_tile_scale`, `path_tile_scale`
- `secondary_mask_strength`
- `normal_depth`
- `spot_edge_raggedness`, `spot_breakup_strength`, `spot_grain_strength`, `spot_core_strength`
- `rock_count`, `rock_scale`, `rock_color`, `rock_texture_tile`
- macro terrain values like `terrain_height_scale`, `terrain_ridge_strength`, `terrain_wadi_strength`
- Negev-style vertical relief values like `terrain_vertical_relief_strength`, `terrain_vertical_basin_drop`, `terrain_vertical_rim_height`, and `terrain_vertical_wadi_depth`

Avoid adding large procedural ledges or walls until the gameplay/art direction asks for them. They can overpower the terrain fast.

## Validate

Run both checks after changing textures, profile paths, shaders, or terrain scripts:

```bash
tools/validate-combat-biomes.sh
tools/validate-startup.sh
```

Expected result:

- no missing resource paths
- no GDScript parse errors
- no startup runtime errors
- all playable scenes load headlessly
