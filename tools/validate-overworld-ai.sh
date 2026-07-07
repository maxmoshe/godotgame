#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

set +e
output="$("${ROOT}/tools/godot-wsl.sh" --headless --path "${ROOT}" --script "res://scripts/overworld_ai_sim.gd" 2>&1)"
status=$?
set -e

printf '%s\n' "== overworld AI simulation =="
printf '%s\n' "${output}"

if [[ ${status} -ne 0 ]]; then
	exit "${status}"
fi

if [[ "${output}" == *"SCRIPT ERROR"* || "${output}" == *"ERROR:"* ]]; then
	exit 1
fi
