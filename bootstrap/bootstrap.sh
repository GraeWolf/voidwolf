#!/usr/bin/env bash
# voidwolf — bootstrap entrypoint
# PR2 repos | PR3 packages/services | PR4 suckless | PR5 session/dotfiles
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
DOTFILES_ONLY=0
SKIP_REPOS=0
SKIP_PACKAGES=0
SKIP_SERVICES=0
SKIP_SUCKLESS=0
SKIP_DOTFILES=0
WITH_SUCKLESS=0

usage() {
	cat <<'EOF'
Usage: bootstrap.sh [options]

voidwolf bootstrap for an existing Void Linux (glibc x86_64) install.

Options:
  --profile desktop|laptop   Hardware profile (required unless --repos-only/--services-only/--dotfiles-only)
  --gpu none|nvidia|nvidia-hybrid|nvidia-hybrid-randr
                             GPU profile (default: none)
  --with-32bit               Multilib repos + optional 32-bit NVIDIA libs
  --no-brave                 Skip brave-origin install
  --xlibre-full              Install full xlibre meta (default: xlibre-minimal)
  --allow-xorg-fallback      Documented recovery only (PR10); no auto-fallback
  --with-picom               Install picom (default OFF)
  --with-suckless            Also run build-suckless.sh (user PREFIX; no sudo)
  --repos-only               Only wire repositories (PR2)
  --packages-only            Only install packages
  --services-only            Only enable services/sudoers/ufw/groups
  --dotfiles-only            Only install session dotfiles / PipeWire conf.d
  --skip-repos               Skip repository wiring
  --skip-packages            Skip package install
  --skip-services            Skip services/sudoers/ufw
  --skip-suckless            Skip suckless build (default skips unless --with-suckless)
  --skip-dotfiles            Skip session/dotfiles install
  --dry-run                  Print actions without system changes
  -h, --help                 Show this help

Typical:
  ./bootstrap/bootstrap.sh --profile laptop --gpu nvidia-hybrid --with-suckless
  ./bootstrap/bootstrap.sh --dotfiles-only
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

# Default: do not build suckless unless asked (needs user toolchain + can take time)
SKIP_SUCKLESS=1

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
		--with-suckless) WITH_SUCKLESS=1; SKIP_SUCKLESS=0 ;;
		--repos-only) REPOS_ONLY=1 ;;
		--packages-only) PACKAGES_ONLY=1 ;;
		--services-only) SERVICES_ONLY=1 ;;
		--dotfiles-only) DOTFILES_ONLY=1 ;;
		--skip-repos) SKIP_REPOS=1 ;;
		--skip-packages) SKIP_PACKAGES=1 ;;
		--skip-services) SKIP_SERVICES=1 ;;
		--skip-suckless) SKIP_SUCKLESS=1 ;;
		--skip-dotfiles) SKIP_DOTFILES=1 ;;
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
	SKIP_SUCKLESS=1
	SKIP_DOTFILES=1
fi
if [[ "${PACKAGES_ONLY}" -eq 1 ]]; then
	SKIP_REPOS=1
	SKIP_SERVICES=1
	SKIP_SUCKLESS=1
	SKIP_DOTFILES=1
fi
if [[ "${SERVICES_ONLY}" -eq 1 ]]; then
	SKIP_REPOS=1
	SKIP_PACKAGES=1
	SKIP_SUCKLESS=1
	SKIP_DOTFILES=1
fi
if [[ "${DOTFILES_ONLY}" -eq 1 ]]; then
	SKIP_REPOS=1
	SKIP_PACKAGES=1
	SKIP_SERVICES=1
	SKIP_SUCKLESS=1
	SKIP_DOTFILES=0
fi

if [[ "${SKIP_PACKAGES}" -eq 0 && -z "${PROFILE}" ]]; then
	die "--profile desktop|laptop is required (or use --repos-only / --services-only / --dotfiles-only)"
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
	echo "SKIP_SUCKLESS=${SKIP_SUCKLESS} SKIP_DOTFILES=${SKIP_DOTFILES}"
} >>"${LOG_FILE}" 2>/dev/null || true

check_void_arch

log "voidwolf bootstrap starting"
log "See docs/design.md, docs/bootstrap.md, docs/session.md"

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

# --- PR3: services ---
if [[ "${SKIP_SERVICES}" -eq 0 ]]; then
	log "Step: services, sudoers, ufw, groups"
	svc_args=()
	[[ -n "${PROFILE}" ]] && svc_args+=(--profile "${PROFILE}")
	[[ "${DRY_RUN}" -eq 1 ]] && svc_args+=(--dry-run)
	bash "${SCRIPT_DIR}/enable-services.sh" "${svc_args[@]+"${svc_args[@]}"}"
else
	log "Skipping services"
fi

if [[ "${ALLOW_XORG_FALLBACK}" -eq 1 ]]; then
	log "Note: --allow-xorg-fallback is recorded; use bootstrap/nvidia-fallback-xorg.sh --yes for recovery (never automatic)."
fi

# --- PR10: NVIDIA system conf (modprobe + xorg) when --gpu is set ---
if [[ "${GPU}" != "none" && "${SKIP_PACKAGES}" -eq 0 ]]; then
	log "Step: NVIDIA setup snippets (profile=${GPU})"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		log "[dry-run] nvidia-setup.sh --profile ${GPU}"
	else
		# May need sudo; non-fatal if user skips
		if bash "${SCRIPT_DIR}/nvidia-setup.sh" --profile "${GPU}" 2>/dev/null; then
			log "nvidia-setup.sh completed"
		else
			log "nvidia-setup.sh needs root — run: sudo ./bootstrap/nvidia-setup.sh --profile ${GPU}"
		fi
	fi
	log "GPU report: voidwolf-gpu-check (after reboot if modules just built)"
fi

# --- PR4: suckless (opt-in) ---
if [[ "${SKIP_SUCKLESS}" -eq 0 ]]; then
	log "Step: build suckless (PREFIX=\$HOME/.local, no sudo)"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		log "[dry-run] ./bootstrap/build-suckless.sh && ./bin/install-user-bin.sh"
	else
		bash "${SCRIPT_DIR}/build-suckless.sh"
		bash "${REPO_ROOT}/bin/install-user-bin.sh"
	fi
else
	log "Skipping suckless build (pass --with-suckless to enable)"
fi

# --- PR5: session / dotfiles ---
if [[ "${SKIP_DOTFILES}" -eq 0 ]]; then
	log "Step: session dotfiles + PipeWire conf.d"
	df_args=()
	[[ "${DRY_RUN}" -eq 1 ]] && df_args+=(--dry-run)
	# When bootstrap was run via sudo, install into the invoking user home
	if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
		tu_home=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
		[[ -n "${tu_home}" ]] && df_args+=(--home "${tu_home}")
	fi
	bash "${SCRIPT_DIR}/install-dotfiles.sh" "${df_args[@]+"${df_args[@]}"}"
else
	log "Skipping session/dotfiles"
fi

cat <<EOF

========================================
voidwolf bootstrap finished
========================================

Completed stages (unless skipped):
  - Repositories (XLibre, vw-repo, nonfree)
  - Packages + services (elogind, NM, BT, ufw, sudoers)
  - Suckless build (if --with-suckless)
  - Session: .xinitrc, .Xresources, PipeWire conf.d, voidwolf-status

Next steps:
  1. Re-login so elogind sets XDG_RUNTIME_DIR and groups apply
  2. echo \$XDG_RUNTIME_DIR   # expect /run/user/\$(id -u)
  3. export PATH="\$HOME/.local/bin:\$PATH"
  4. If you skipped suckless: ./bootstrap/build-suckless.sh && ./bin/install-user-bin.sh
  5. startx

Docs: docs/session.md  docs/bootstrap.md
Log:  ${LOG_FILE}
EOF

exit 0
