#!/usr/bin/env bash
# voidwolf — recovery: leave XLibre community repo and restore stock Xorg (PR10)
# Explicit only — bootstrap never falls back silently.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

DRY_RUN=0
YES=0

usage() {
	cat <<'EOF'
Usage: nvidia-fallback-xorg.sh [--yes] [--dry-run]

Recovery path when XLibre + NVIDIA is broken:
  1. Disable 99-repository-xlibre.conf
  2. Remove xlibre-minimal / xlibre meta (best-effort)
  3. Install xorg-minimal xorg-server
  4. xbps-install -S

Keeps proprietary nvidia packages. Confirm with --yes.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--yes|-y) YES=1 ;;
		--dry-run) DRY_RUN=1 ;;
		-h|--help) usage; exit 0 ;;
		*) voidwolf_die "unknown option: $1" ;;
	esac
	shift
done

if [[ "${YES}" -ne 1 && "${DRY_RUN}" -ne 1 ]]; then
	voidwolf_die "refusing to run without --yes (this changes display server packages)"
fi

export DRY_RUN

voidwolf_log "Disable XLibre repo conf"
if [[ -f /etc/xbps.d/99-repository-xlibre.conf ]]; then
	voidwolf_run_as_root mv -f /etc/xbps.d/99-repository-xlibre.conf \
		/etc/xbps.d/99-repository-xlibre.conf.disabled
fi

voidwolf_log "Remove xlibre packages (best-effort)"
if [[ "${DRY_RUN}" -eq 1 ]]; then
	printf '[dry-run] xbps-remove -Ry xlibre-minimal xlibre 2>/dev/null; xbps-install -Sy xorg-minimal xorg-server\n'
else
	voidwolf_run_as_root xbps-remove -Ry xlibre-minimal 2>/dev/null || true
	voidwolf_run_as_root xbps-remove -Ry xlibre 2>/dev/null || true
	# remove other xlibre-* that conflict — user may need manual cleanup
	voidwolf_run_as_root xbps-install -Sy
	voidwolf_run_as_root xbps-install -y xorg-minimal xorg-server || \
		voidwolf_run_as_root xbps-install -yf xorg-minimal xorg-server
fi

voidwolf_log "Fallback attempted. Reboot, then startx. Re-enable XLibre via bootstrap/repos.sh when ready."
voidwolf_log "See docs/nvidia.md"
