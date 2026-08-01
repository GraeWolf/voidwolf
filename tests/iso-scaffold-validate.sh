#!/usr/bin/env bash
# Validate PR17 ISO scaffolding (does not require void-mklive).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO="${ROOT}/iso"
fail=0

need() {
	if [[ -e "$1" ]]; then
		echo "OK   $1"
	else
		echo "FAIL missing $1"
		fail=1
	fi
}

need_x() {
	if [[ -x "$1" ]]; then
		echo "OK   executable $(basename "$1")"
	else
		echo "FAIL not executable $1"
		fail=1
	fi
}

need_pat() {
	local f="$1" pat="$2" desc="$3"
	if rg -q "$pat" "$f"; then
		echo "OK   $desc"
	else
		echo "FAIL $desc"
		fail=1
	fi
}

need "$ISO/README.md"
need "$ISO/build-iso.sh"
need "$ISO/mklive.env.example"
need "$ISO/package-lists/live-base.txt"
need "$ISO/package-lists/voidwolf.txt"
need "$ISO/package-lists/README.md"
need "$ISO/scripts/assemble-pkglist.sh"
need "$ISO/overlay/etc/hostname"
need "$ISO/overlay/etc/motd"
need "$ISO/overlay/etc/issue"
need "$ISO/overlay/usr/share/voidwolf/ISO-README"
need "$ROOT/docs/iso.md"
need_x "$ISO/build-iso.sh"
need_x "$ISO/scripts/assemble-pkglist.sh"

# hostname decision
if [[ "$(tr -d ' \n' <"$ISO/overlay/etc/hostname")" == "voidwolf" ]]; then
	echo "OK   hostname is voidwolf"
else
	echo "FAIL hostname must be voidwolf"
	fail=1
fi

need_pat "$ISO/overlay/etc/motd" 'startx' "motd mentions startx"
need_pat "$ISO/overlay/usr/share/voidwolf/ISO-README" 'startx' "ISO-README mentions startx"
need_pat "$ISO/overlay/usr/share/voidwolf/ISO-README" 'FDE|encryption|LUKS' "ISO-README mentions no FDE / encryption note"
need_pat "$ISO/package-lists/voidwolf.txt" 'voidwolf-desktop' "voidwolf pkg list has desktop"
need_pat "$ISO/package-lists/voidwolf.txt" 'voidwolf-suckless' "voidwolf pkg list has suckless"
need_pat "$ISO/build-iso.sh" 'VOIDWOLF_HOSTNAME|void-mklive|overlay' "build-iso has mklive wiring"
need_pat "$ROOT/docs/iso.md" 'No display manager|startx|void-mklive|no FDE|hostname' "docs/iso.md decisions"

# assemble pkglist runs
if pkgs=$(bash "$ISO/scripts/assemble-pkglist.sh"); then
	echo "OK   assemble-pkglist: $pkgs"
	echo "$pkgs" | rg -q 'bash|voidwolf-desktop' && echo "OK   pkglist contains expected names" || {
		echo "FAIL pkglist missing expected names"
		fail=1
	}
else
	echo "FAIL assemble-pkglist.sh"
	fail=1
fi

# dry-run build-iso (no mklive required)
if bash "$ISO/build-iso.sh" --dry-run >/tmp/voidwolf-iso-dry.$$.log 2>&1; then
	echo "OK   build-iso.sh --dry-run"
else
	echo "FAIL build-iso.sh --dry-run"
	cat /tmp/voidwolf-iso-dry.$$.log || true
	fail=1
fi
rm -f /tmp/voidwolf-iso-dry.$$.log

# gitignore out/
if rg -q 'iso/out' "$ROOT/.gitignore"; then
	echo "OK   gitignore iso/out"
else
	echo "FAIL .gitignore should ignore iso/out"
	fail=1
fi

if [[ "$fail" -ne 0 ]]; then
	echo "iso-scaffold-validate: FAILED"
	exit 1
fi
echo "iso-scaffold-validate: all OK"
