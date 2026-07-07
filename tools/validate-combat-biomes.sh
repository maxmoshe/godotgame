#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

"${ROOT}/tools/godot-wsl.sh" --headless --path "${ROOT}" "res://tools/validate-combat-biomes.tscn" --quit-after 5
