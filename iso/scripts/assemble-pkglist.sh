#!/usr/bin/env bash
# Merge iso/package-lists into a single space-separated list for void-mklive -p
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
LIST_DIR="${ISO_DIR}/package-lists"

read_list() {
	local f="$1"
	[[ -f "$f" ]] || return 0
	sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$f" | sed '/^$/d'
}

pkgs=()
while IFS= read -r p; do
	pkgs+=("$p")
done < <(read_list "${LIST_DIR}/live-base.txt")

if [[ "${VOIDWOLF_ISO_INCLUDE_LOCAL_REPO:-1}" == "1" ]]; then
	while IFS= read -r p; do
		pkgs+=("$p")
	done < <(read_list "${LIST_DIR}/voidwolf.txt")
fi

# unique preserve order
declare -A seen=()
out=()
for p in "${pkgs[@]}"; do
	[[ -n "${seen[$p]:-}" ]] && continue
	seen[$p]=1
	out+=("$p")
done

printf '%s\n' "${out[*]}"
