#!/usr/bin/env bash
# voidwolf — install NVIDIA modprobe + Xorg conf for a --gpu profile (PR10)
# Requires root for /etc writes. Does not install packages (use bootstrap/install-packages).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

PROFILE=""
DRY_RUN=0
FORCE=0

usage() {
	cat <<'EOF'
Usage: nvidia-setup.sh --profile nvidia|nvidia-hybrid|nvidia-hybrid-randr [options]

Install modprobe.d modeset and Xorg OutputClass snippets for the profile.
Package install is separate (bootstrap.sh --gpu …).

Options:
  --profile NAME   Required
  --force          Overwrite existing voidwolf NVIDIA confs
  --dry-run
  -h, --help

Examples:
  sudo ./bootstrap/nvidia-setup.sh --profile nvidia
  sudo ./bootstrap/nvidia-setup.sh --profile nvidia-hybrid
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--profile) PROFILE="${2:-}"; shift ;;
		--force) FORCE=1 ;;
		--dry-run) DRY_RUN=1 ;;
		-h|--help) usage; exit 0 ;;
		*) voidwolf_die "unknown option: $1" ;;
	esac
	shift
done

case "${PROFILE}" in
	nvidia|nvidia-hybrid|nvidia-hybrid-randr) ;;
	none|"")
		voidwolf_die "need --profile nvidia|nvidia-hybrid|nvidia-hybrid-randr"
		;;
	*)
		voidwolf_die "invalid profile: ${PROFILE}"
		;;
esac

export DRY_RUN

install_conf() {
	local src="$1" dest="$2"
	[[ -f "$src" ]] || voidwolf_die "missing $src"
	if [[ -e "$dest" && "${FORCE}" -ne 1 ]]; then
		voidwolf_log "exists (use --force): $dest"
		return 0
	fi
	voidwolf_log "Install $dest"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[dry-run] install %s → %s\n' "$src" "$dest"
		return 0
	fi
	voidwolf_run_as_root install -D -m 0644 "$src" "$dest"
}

# Remove other voidwolf nvidia xorg snippets to avoid conflicts
cleanup_other() {
	local keep="$1"
	local d="/etc/X11/xorg.conf.d"
	local f
	for f in 20-nvidia-discrete.conf 20-nvidia-hybrid-prime.conf 20-nvidia-hybrid-randr.conf; do
		[[ "$f" == "$keep" ]] && continue
		if [[ -f "$d/$f" ]]; then
			voidwolf_log "Remove conflicting $d/$f"
			if [[ "${DRY_RUN}" -eq 0 ]]; then
				voidwolf_run_as_root rm -f "$d/$f"
			fi
		fi
	done
}

XORG_SRC=""
case "${PROFILE}" in
	nvidia)
		XORG_SRC="${REPO_ROOT}/config/X11/xorg.conf.d/20-nvidia-discrete.conf"
		XORG_NAME="20-nvidia-discrete.conf"
		;;
	nvidia-hybrid)
		XORG_SRC="${REPO_ROOT}/config/X11/xorg.conf.d/20-nvidia-hybrid-prime.conf"
		XORG_NAME="20-nvidia-hybrid-prime.conf"
		;;
	nvidia-hybrid-randr)
		XORG_SRC="${REPO_ROOT}/config/X11/xorg.conf.d/20-nvidia-hybrid-randr.conf"
		XORG_NAME="20-nvidia-hybrid-randr.conf"
		;;
esac

install_conf \
	"${REPO_ROOT}/config/X11/modprobe.d/voidwolf-nvidia.conf" \
	"/etc/modprobe.d/voidwolf-nvidia.conf"

cleanup_other "${XORG_NAME}"
install_conf "${XORG_SRC}" "/etc/X11/xorg.conf.d/${XORG_NAME}"

voidwolf_log "NVIDIA setup for profile=${PROFILE} complete"
voidwolf_log "Reboot recommended after first driver install, then:"
voidwolf_log "  voidwolf-gpu-check"
voidwolf_log "  nvidia-smi"
voidwolf_log "  startx"
if [[ "${PROFILE}" == "nvidia-hybrid" ]]; then
	voidwolf_log "  voidwolf-prime glxinfo | grep renderer"
fi
