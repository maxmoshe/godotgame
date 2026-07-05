# AGENTS.md

## Project

This is a Godot 4 project for a top-down campaign-map prototype set around Saul's kingdom and the territories later associated with David.

The main scene is:

```text
res://scenes/main.tscn
```

## Startup Validation

After changing Godot scenes, scripts, project settings, or resources, verify that the game starts without parser/runtime errors.

From WSL in this repo, use the checked-in wrapper:

```bash
tools/validate-startup.sh
```

This script must load every playable mode directly, not only the default project scene. Current required checks:

- campaign map: `res://scenes/main.tscn`
- 3D sling combat test: `res://scenes/combat_test.tscn`

When adding a new mode, combat scene, town scene, menu scene, or any other scene that can be entered through gameplay, update `tools/validate-startup.sh` in the same change so the new scene is loaded headlessly too.

This wrapper uses the repo-local Godot binary at:

```text
.tools/godot/4.7-stable/Godot_v4.7-stable_linux.x86_64
```

It also redirects Godot's XDG data/config/cache directories into `.godot-user/`, because this environment may not allow writes under `/home/moshe`.

Expected result:

- The command exits cleanly.
- There are no GDScript parse errors in any playable mode.
- There are no missing scene/resource errors in any playable mode.
- There are no startup runtime errors from `scenes/main.tscn`, `scenes/combat_test.tscn`, or any future playable scene.

`tools/validate-startup.sh` treats `SCRIPT ERROR` and `ERROR:` output as failure even if Godot exits with status `0`. Warnings are acceptable only if they are unrelated to the changed code and do not stop startup. Mention them in the final response.

For input and scene transitions, do not assume `get_viewport()` is always non-null inside `_unhandled_input()`. Guard viewport calls before `set_input_as_handled()` or mouse-position reads, especially around `change_scene_to_file()`.

## WSL Godot Install

If the repo-local Godot binary is missing, install it with:

```bash
tools/install-godot-wsl.sh
```

This downloads Godot `4.7-stable` for Linux x86_64 from the official `godotengine/godot` GitHub release, verifies its SHA-512 checksum, and extracts it under `.tools/godot/`. The `.tools/godot/` directory is intentionally ignored by git.

## Other Fallbacks

If the wrapper is not usable but a Godot binary is on PATH, try:

```bash
godot --headless --path . --quit-after 2
```

or:

```bash
godot4 --headless --path . --quit-after 2
```

This repo may be edited from WSL while Godot is installed on Windows. If `godot` and `godot4` are not on PATH, look for a Windows executable and run it headless against the Windows path:

```bash
find /mnt/c/Users/Moshe -iname 'Godot*.exe' -o -iname 'godot*.exe'
```

Then run the discovered executable through PowerShell, replacing the path as needed:

```bash
/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -Command "& 'C:\Path\To\Godot.exe' --headless --path 'C:\Users\Moshe\git\dav' --quit-after 2"
```

If sandbox permissions block this, request escalation for that exact validation command. Do not claim the game was run unless the command actually executed.

## If Godot Is Unavailable

If no Godot executable is available, do a structural check instead:

```bash
rg -n "run/main_scene|res://|script =" project.godot scenes scripts
```

Also inspect any touched `.gd` and `.tscn` files manually for:

- broken `res://` paths
- missing `ExtResource` references
- duplicate config sections in `project.godot`
- typed variables calling methods that only exist on attached scripts
- Dictionary dot-access that could be brittle across Godot parser settings
- playable scenes missing from `tools/validate-startup.sh`

In the final response, say plainly that Godot could not be run and list the structural checks performed.

## Editing Style

- Keep the prototype beginner-readable.
- Prefer small scenes and scripts over clever abstractions.
- Draw temporary map art in code until gameplay direction is clearer.
- Avoid adding external assets or plugins unless the user asks.
