#!/usr/bin/env bash
# Validate shipped third-party key plists against pins.conf (no root).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEYS="${ROOT}/bootstrap/keys"
# shellcheck disable=SC1091
source "${KEYS}/pins.conf"

sha256_file() {
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$1" | awk '{print $1}'
	else
		shasum -a 256 "$1" | awk '{print $1}'
	fi
}

fail=0
check() {
	local label="$1" file="$2" fp="$3" expected="$4"
	local path="${KEYS}/${file}"
	if [[ ! -f "$path" ]]; then
		echo "FAIL ${label}: missing ${path}"
		fail=1
		return
	fi
	if [[ "$(basename "$path")" != "${fp}.plist" ]]; then
		echo "FAIL ${label}: basename != ${fp}.plist"
		fail=1
	fi
	local got
	got="$(sha256_file "$path")"
	if [[ "$got" != "$expected" ]]; then
		echo "FAIL ${label}: SHA256 mismatch"
		echo "  expected ${expected}"
		echo "  got      ${got}"
		fail=1
	else
		echo "OK   ${label}: ${fp}.plist"
	fi
}

check "XLibre"  "${XLIBRE_KEY_FILE}" "${XLIBRE_KEY_FP}" "${XLIBRE_KEY_SHA256}"
check "vw-repo" "${VW_KEY_FILE}"     "${VW_KEY_FP}"     "${VW_KEY_SHA256}"

if [[ "$fail" -ne 0 ]]; then
	echo "repos-pins-validate: FAILED"
	exit 1
fi
echo "repos-pins-validate: all pins OK"
