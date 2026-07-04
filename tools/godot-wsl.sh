#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
GODOT_BIN="${GODOT_BIN:-${ROOT}/.tools/godot/4.7-stable/Godot_v4.7-stable_linux.x86_64}"

if [[ ! -x "${GODOT_BIN}" ]]; then
	echo "Godot binary not found at: ${GODOT_BIN}" >&2
	echo "Run: ${ROOT}/tools/install-godot-wsl.sh" >&2
	exit 127
fi

mkdir -p \
	"${ROOT}/.godot-user/share" \
	"${ROOT}/.godot-user/config" \
	"${ROOT}/.godot-user/cache"

export XDG_DATA_HOME="${ROOT}/.godot-user/share"
export XDG_CONFIG_HOME="${ROOT}/.godot-user/config"
export XDG_CACHE_HOME="${ROOT}/.godot-user/cache"

exec "${GODOT_BIN}" "$@"
