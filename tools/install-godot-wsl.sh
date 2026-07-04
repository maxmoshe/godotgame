#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
VERSION="4.7-stable"
ZIP_NAME="Godot_v4.7-stable_linux.x86_64.zip"
URL="https://github.com/godotengine/godot/releases/download/${VERSION}/${ZIP_NAME}"
EXPECTED_SHA512="b639ca9c1ddea39bb3df89bd5283a51ca6047467abe6b25e9436566f2b2082ede633025073989ecf39c7d5d3c2493d80ea13e3af6dd5e261bbf89e462d6d2214"
INSTALL_DIR="${ROOT}/.tools/godot/${VERSION}"
BIN="${INSTALL_DIR}/Godot_v4.7-stable_linux.x86_64"
ZIP_PATH="${TMPDIR:-/tmp}/${ZIP_NAME}"

if [[ -x "${BIN}" ]]; then
	"${BIN}" --version
	exit 0
fi

command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
command -v unzip >/dev/null || { echo "unzip is required" >&2; exit 1; }
command -v sha512sum >/dev/null || { echo "sha512sum is required" >&2; exit 1; }

mkdir -p "${INSTALL_DIR}"
curl -L "${URL}" -o "${ZIP_PATH}"

actual_sha512="$(sha512sum "${ZIP_PATH}" | awk '{print $1}')"
if [[ "${actual_sha512}" != "${EXPECTED_SHA512}" ]]; then
	echo "Checksum mismatch for ${ZIP_NAME}" >&2
	echo "Expected: ${EXPECTED_SHA512}" >&2
	echo "Actual:   ${actual_sha512}" >&2
	exit 1
fi

unzip -q -o "${ZIP_PATH}" -d "${INSTALL_DIR}"
chmod +x "${BIN}"
"${BIN}" --version
