#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

run_godot_check() {
	local label="$1"
	shift

	set +e
	local output
	output="$("${ROOT}/tools/godot-wsl.sh" --headless --path "${ROOT}" "$@" --quit-after 2 2>&1)"
	local status=$?
	set -e

	printf '%s\n' "== ${label} =="
	printf '%s\n' "${output}"

	if [[ ${status} -ne 0 ]]; then
		exit "${status}"
	fi

	if [[ "${output}" == *"SCRIPT ERROR"* || "${output}" == *"ERROR:"* ]]; then
		exit 1
	fi
}

run_godot_check "campaign startup"
run_godot_check "combat test startup" "res://scenes/combat_test.tscn"
