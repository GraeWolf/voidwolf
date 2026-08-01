#!/usr/bin/env bash
# voidwolf — bootstrap entrypoint
# PR2: repository wiring | PR3: packages, services, sudoers, ufw
# Later: suckless (PR4), session/dotfiles (PR5), themes (PR8), NVIDIA deep (PR10)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${REPO_ROOT}/bootstrap"
LOG_FILE="${LOG_DIR}/bootstrap.log"

PROFILE=""
GPU="none"
WITH_32BIT=0
NO_BRAVE=0
XLIBRE_FULL=0
ALLOW_XORG_FALLBACK=0
WITH_PICOM=0
DRY_RUN=0
REPOS_ONLY=0
PACKAGES_ONLY=0
SERVICES_ONLY=0
SKIP_REPOS=0
SKIP_PACKAGES=0
SKIP_SERVICES=0

usage() {
	cat <<'EOF'
Usage: bootstrap.sh [options]

voidwolf bootstrap for an existing Void Linux (glibc x86_64) install.

Options:
  --profile desktop|laptop   Hardware profile (required unless --repos-only)
  --gpu none|nvidia|nvidia-hybrid|nvidia-hybrid-randr
                             GPU profile (default: none)
  --with-32bit               Multilib repos + optional 32-bit NVIDIA libs
  --no-brave                 Skip brave-origin install
  --xlibre-full              Install full xlibre meta (default: xlibre-minimal)
  --allow-xorg-fallback      Documented recovery only (PR10); no auto-fallback
  --with-picom               Install picom (default OFF)
  --repos-only               Only wire repositories (PR2)
  --packages-only            Only install packages (assumes repos already wired)
  --services-only            Only enable services/sudoers/ufw/groups
  --skip-repos               Skip repository wiring
  --skip-packages            Skip package install
  --skip-services            Skip services/sudoers/ufw
  --dry-run                  Print actions without system changes
  -h, --help                 Show this help

Typical:
  ./bootstrap/bootstrap.sh --profile laptop --gpu nvidia-hybrid
  ./bootstrap/bootstrap.sh --repos-only
  ./bootstrap/bootstrap.sh --profile desktop --dry-run
EOF
}

log() {
	local msg="$*"
	printf '==> %s\n' "$msg"
	if [[ -w "${LOG_DIR}" ]] || mkdir -p "${LOG_DIR}" 2>/dev/null; then
		printf '%s %s\n' "$(date -Iseconds 2>/dev/null || date)" "$msg" >>"${LOG_FILE}" 2>/dev/null || true
	fi
}
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

check_void_arch() {
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		return 0
	fi
	if [[ -f /etc/os-release ]]; then
		# shellcheck disable=SC1091
		. /etc/os-release
		[[ "${ID:-}" == "void" ]] || die "voidwolf targets Void Linux (got ID=${ID:-unknown})"
	fi
	local arch
	arch="$(uname -m)"
	[[ "${arch}" == "x86_64" ]] || die "Phase 1–4 target x86_64 only (got ${arch})"
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--profile)
			PROFILE="${2:-}"
			[[ -n "${PROFILE}" ]] || die "--profile needs desktop|laptop"
			shift
			;;
		--gpu)
			GPU="${2:-}"
			[[ -n "${GPU}" ]] || die "--gpu needs a value"
			shift
			;;
		--with-32bit) WITH_32BIT=1 ;;
		--no-brave) NO_BRAVE=1 ;;
		--xlibre-full) XLIBRE_FULL=1 ;;
		--allow-xorg-fallback) ALLOW_XORG_FALLBACK=1 ;;
		--with-picom) WITH_PICOM=1 ;;
		--repos-only) REPOS_ONLY=1 ;;
		--packages-only) PACKAGES_ONLY=1 ;;
		--services-only) SERVICES_ONLY=1 ;;
		--skip-repos) SKIP_REPOS=1 ;;
		--skip-packages) SKIP_PACKAGES=1 ;;
		--skip-services) SKIP_SERVICES=1 ;;
		--dry-run) DRY_RUN=1 ;;
		-h|--help) usage; exit 0 ;;
		*) die "unknown option: $1 (try --help)" ;;
	esac
	shift
done

case "${GPU}" in
	none|nvidia|nvidia-hybrid|nvidia-hybrid-randr) ;;
	*) die "invalid --gpu: ${GPU}" ;;
esac

if [[ -n "${PROFILE}" ]]; then
	case "${PROFILE}" in
		desktop|laptop) ;;
		*) die "invalid --profile: ${PROFILE} (use desktop|laptop)" ;;
	esac
fi

# Scope flags
if [[ "${REPOS_ONLY}" -eq 1 ]]; then
	SKIP_PACKAGES=1
	SKIP_SERVICES=1
fi
if [[ "${PACKAGES_ONLY}" -eq 1 ]]; then
	SKIP_REPOS=1
	SKIP_SERVICES=1
fi
if [[ "${SERVICES_ONLY}" -eq 1 ]]; then
	SKIP_REPOS=1
	SKIP_PACKAGES=1
fi

need_profile=0
if [[ "${SKIP_PACKAGES}" -eq 0 || "${SKIP_SERVICES}" -eq 0 ]]; then
	# services don't strictly need profile, but packages/laptop list does
	if [[ "${SKIP_PACKAGES}" -eq 0 ]]; then
		need_profile=1
	fi
fi
if [[ "${need_profile}" -eq 1 && -z "${PROFILE}" ]]; then
	die "--profile desktop|laptop is required (or use --repos-only / --services-only)"
fi

mkdir -p "${LOG_DIR}"
: >>"${LOG_FILE}" 2>/dev/null || true
{
	echo "---- voidwolf bootstrap $(date -Iseconds 2>/dev/null || date) ----"
	echo "REPO_ROOT=${REPO_ROOT}"
	echo "PROFILE=${PROFILE:-} GPU=${GPU} WITH_32BIT=${WITH_32BIT}"
	echo "NO_BRAVE=${NO_BRAVE} XLIBRE_FULL=${XLIBRE_FULL} WITH_PICOM=${WITH_PICOM}"
	echo "ALLOW_XORG_FALLBACK=${ALLOW_XORG_FALLBACK} DRY_RUN=${DRY_RUN}"
	echo "SKIP_REPOS=${SKIP_REPOS} SKIP_PACKAGES=${SKIP_PACKAGES} SKIP_SERVICES=${SKIP_SERVICES}"
} >>"${LOG_FILE}" 2>/dev/null || true

check_void_arch

log "voidwolf bootstrap starting"
log "See docs/design.md, docs/repos.md"

# --- PR2: repos ---
if [[ "${SKIP_REPOS}" -eq 0 ]]; then
	log "Step: repository wiring"
	repos_args=()
	[[ "${WITH_32BIT}" -eq 1 ]] && repos_args+=(--with-32bit)
	[[ "${DRY_RUN}" -eq 1 ]] && repos_args+=(--dry-run)
	bash "${SCRIPT_DIR}/repos.sh" "${repos_args[@]+"${repos_args[@]}"}"
else
	log "Skipping repository wiring"
fi

if [[ "${REPOS_ONLY}" -eq 1 ]]; then
	log "Repos-only done."
	exit 0
fi

# --- PR3: packages ---
if [[ "${SKIP_PACKAGES}" -eq 0 ]]; then
	log "Step: package install"
	pkg_args=(--profile "${PROFILE}" --gpu "${GPU}")
	[[ "${NO_BRAVE}" -eq 1 ]] && pkg_args+=(--no-brave)
	[[ "${XLIBRE_FULL}" -eq 1 ]] && pkg_args+=(--xlibre-full)
	[[ "${WITH_PICOM}" -eq 1 ]] && pkg_args+=(--with-picom)
	[[ "${WITH_32BIT}" -eq 1 ]] && pkg_args+=(--with-32bit)
	[[ "${DRY_RUN}" -eq 1 ]] && pkg_args+=(--dry-run)
	bash "${SCRIPT_DIR}/install-packages.sh" "${pkg_args[@]}"
else
	log "Skipping package install"
fi

# --- PR3: services / sudoers / ufw / groups ---
if [[ "${SKIP_SERVICES}" -eq 0 ]]; then
	log "Step: services, sudoers, ufw, groups"
	svc_args=()
	[[ "${DRY_RUN}" -eq 1 ]] && svc_args+=(--dry-run)
	bash "${SCRIPT_DIR}/enable-services.sh" "${svc_args[@]+"${svc_args[@]}"}"
else
	log "Skipping services"
fi

if [[ "${ALLOW_XORG_FALLBACK}" -eq 1 ]]; then
	log "Note: --allow-xorg-fallback is recorded; recovery procedure is in docs/nvidia.md (PR10). Bootstrap never falls back silently."
fi

# --- later PRs ---
cat <<EOF

========================================
voidwolf bootstrap (PR3) finished
========================================

Completed:
  - Repositories (unless skipped)
  - Packages (base, desktop, build-suckless, profile, gpu, browser)
  - Services: dbus, elogind, NetworkManager, bluetoothd, polkitd, ufw
  - sudoers: /etc/sudoers.d/voidwolf-wheel
  - ufw: deny in / allow out / force enable
  - User groups: wheel network bluetooth video audio input storage

Next optional step (PR4 — suckless):
  ./bootstrap/build-suckless.sh
  ./bin/install-user-bin.sh
  source config/bash/voidwolf-path.sh   # or add to ~/.bashrc

Still later:
  - PR5: PipeWire conf.d, .xinitrc, voidwolf-status, install-dotfiles
  - PR8: voidwolf-theme
  - PR10: NVIDIA PRIME/xorg deep config

Next steps for you:
  1. Re-login (or reboot) so elogind session + groups apply
  2. Verify: sv status dbus elogind NetworkManager
  3. Build suckless (above), then after PR5: startx

Log: ${LOG_FILE}
EOF

exit 0
