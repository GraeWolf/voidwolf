#!/usr/bin/env bash
# voidwolf — install package lists (PR3)
# Order: base → desktop-required → optional → build-suckless → profile → gpu → browser
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

PROFILE=""
GPU="none"
NO_BRAVE=0
XLIBRE_FULL=0
WITH_PICOM=0
WITH_32BIT=0
DRY_RUN=0
# Override NVIDIA family package, e.g. nvidia580
NVIDIA_PKG="${VOIDWOLF_NVIDIA_PKG:-}"

usage() {
	cat <<'EOF'
Usage: install-packages.sh [options]

Options:
  --profile desktop|laptop
  --gpu none|nvidia|nvidia-hybrid|nvidia-hybrid-randr
  --no-brave
  --xlibre-full          Install meta 'xlibre' instead of 'xlibre-minimal'
  --with-picom           Include picom from optional set
  --with-32bit           Also try nvidia-libs-32bit when GPU != none
  --dry-run
  -h, --help

Environment:
  VOIDWOLF_NVIDIA_PKG    Force NVIDIA package name (nvidia, nvidia580, …)
  DRY_RUN=1              Same as --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--profile) PROFILE="${2:-}"; shift ;;
		--gpu) GPU="${2:-}"; shift ;;
		--no-brave) NO_BRAVE=1 ;;
		--xlibre-full) XLIBRE_FULL=1 ;;
		--with-picom) WITH_PICOM=1 ;;
		--with-32bit) WITH_32BIT=1 ;;
		--dry-run) DRY_RUN=1 ;;
		-h|--help) usage; exit 0 ;;
		*) voidwolf_die "unknown option: $1" ;;
	esac
	shift
done

export DRY_RUN

mapfile -t BASE_PKGS < <(voidwolf_read_pkg_list "${SCRIPT_DIR}/packages-base.txt")
mapfile -t DESKTOP_REQ < <(voidwolf_read_pkg_list "${SCRIPT_DIR}/packages-desktop-required.txt")
mapfile -t DESKTOP_OPT < <(voidwolf_read_pkg_list "${SCRIPT_DIR}/packages-desktop-optional.txt")
mapfile -t BUILD_PKGS < <(voidwolf_read_pkg_list "${SCRIPT_DIR}/packages-build-suckless.txt")

# XLibre meta
if [[ "${XLIBRE_FULL}" -eq 1 ]]; then
	XLIBRE_META="xlibre"
else
	XLIBRE_META="xlibre-minimal"
fi
if ! voidwolf_pkg_available "${XLIBRE_META}" && [[ "${DRY_RUN}" -eq 0 ]]; then
	voidwolf_die "XLibre package '${XLIBRE_META}' not found in repos.
Run bootstrap/repos.sh first, then: xbps-query -Rs xlibre"
fi

voidwolf_log "Package install (profile=${PROFILE:-none} gpu=${GPU} xlibre=${XLIBRE_META})"

voidwolf_install_required "${BASE_PKGS[@]}"
voidwolf_install_required "${XLIBRE_META}" "${DESKTOP_REQ[@]}"
voidwolf_install_optional "${DESKTOP_OPT[@]}"
voidwolf_install_required "${BUILD_PKGS[@]}"

if [[ "${WITH_PICOM}" -eq 1 ]]; then
	voidwolf_install_optional picom
fi

if [[ "${PROFILE}" == "laptop" ]]; then
	mapfile -t LAPTOP_PKGS < <(voidwolf_read_pkg_list "${SCRIPT_DIR}/packages-laptop.txt")
	voidwolf_install_required "${LAPTOP_PKGS[@]}"
fi

# NVIDIA common + family package
if [[ "${GPU}" != "none" ]]; then
	mapfile -t NVIDIA_COMMON < <(voidwolf_read_pkg_list "${SCRIPT_DIR}/packages-nvidia.txt")
	voidwolf_install_required "${NVIDIA_COMMON[@]}"

	if [[ -z "${NVIDIA_PKG}" ]]; then
		# Default family pick for PR3; voidwolf-gpu-check (PR10) will refine.
		case "${GPU}" in
			nvidia|nvidia-hybrid|nvidia-hybrid-randr)
				NVIDIA_PKG="nvidia"
				;;
		esac
	fi
	voidwolf_log "NVIDIA driver package: ${NVIDIA_PKG} (override with VOIDWOLF_NVIDIA_PKG)"
	if voidwolf_pkg_available "${NVIDIA_PKG}" || [[ "${DRY_RUN}" -eq 1 ]]; then
		voidwolf_install_required "${NVIDIA_PKG}"
	else
		voidwolf_die "NVIDIA package '${NVIDIA_PKG}' not available (nonfree enabled?)"
	fi

	if [[ "${WITH_32BIT}" -eq 1 ]]; then
		# Best-effort; exact 32-bit package names vary by driver family
		voidwolf_install_optional nvidia-libs-32bit
		voidwolf_install_optional "${NVIDIA_PKG}-libs-32bit"
	fi
fi

# Browser from vw-repo
if [[ "${NO_BRAVE}" -eq 0 ]]; then
	browser=""
	for candidate in brave-origin brave-origin-bin; do
		if voidwolf_pkg_available "$candidate" || [[ "${DRY_RUN}" -eq 1 && "$candidate" == "brave-origin" ]]; then
			browser="$candidate"
			break
		fi
	done
	if [[ -n "${browser}" ]]; then
		voidwolf_install_required "${browser}"
	elif [[ "${DRY_RUN}" -eq 1 ]]; then
		voidwolf_log "[dry-run] would install brave-origin or brave-origin-bin"
	else
		voidwolf_die "brave-origin not found in repos (vw-repo enabled? use --no-brave to skip)"
	fi
else
	voidwolf_log "Skipping browser (--no-brave)"
fi

voidwolf_log "Package install complete."
