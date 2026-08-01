#!/usr/bin/env bash
# Validate package list files parse cleanly and lists are non-empty where required.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOT="${ROOT}/bootstrap"
# shellcheck source=../bootstrap/lib.sh
source "${BOOT}/lib.sh"

fail=0
check_list() {
	local file="$1" min="$2"
	local -a pkgs
	mapfile -t pkgs < <(voidwolf_read_pkg_list "$file")
	local n="${#pkgs[@]}"
	if [[ "$n" -lt "$min" ]]; then
		echo "FAIL $(basename "$file"): expected >= ${min} packages, got ${n}"
		fail=1
	else
		echo "OK   $(basename "$file"): ${n} packages"
	fi
	# no whitespace in names
	local p
	for p in "${pkgs[@]}"; do
		if [[ "$p" =~ [[:space:]] ]]; then
			echo "FAIL whitespace in package name: '$p' ($file)"
			fail=1
		fi
	done
}

check_list "${BOOT}/packages-base.txt" 3
check_list "${BOOT}/packages-desktop-required.txt" 10
check_list "${BOOT}/packages-desktop-optional.txt" 3
check_list "${BOOT}/packages-build-suckless.txt" 4
check_list "${BOOT}/packages-laptop.txt" 1
check_list "${BOOT}/packages-nvidia.txt" 2

# sudoers syntax if visudo present
if command -v visudo >/dev/null 2>&1; then
	if visudo -cf "${BOOT}/sudoers.d/voidwolf-wheel"; then
		echo "OK   sudoers.d/voidwolf-wheel (visudo)"
	else
		echo "FAIL sudoers.d/voidwolf-wheel"
		fail=1
	fi
else
	echo "SKIP visudo not installed"
fi

# scripts executable
for s in repos.sh bootstrap.sh install-packages.sh enable-services.sh; do
	if [[ -x "${BOOT}/$s" ]]; then
		echo "OK   executable $s"
	else
		echo "FAIL not executable: $s"
		fail=1
	fi
done

if [[ "$fail" -ne 0 ]]; then
	echo "package-lists-validate: FAILED"
	exit 1
fi
echo "package-lists-validate: all OK"
