#!/usr/bin/env bash
# voidwolf — bootstrap entrypoint (partial: PR2 wires repos only)
# Later PRs extend package install, services, suckless, session, themes.
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

usage() {
	cat <<'EOF'
Usage: bootstrap.sh [options]

voidwolf bootstrap for an existing Void Linux (glibc x86_64) install.

Options:
  --profile desktop|laptop   Hardware profile (required for full bootstrap; optional with --repos-only)
  --gpu none|nvidia|nvidia-hybrid|nvidia-hybrid-randr
                             GPU profile (default: none)
  --with-32bit               Enable multilib repos (for 32-bit NVIDIA libs / gaming)
  --no-brave                 Skip brave-origin install (PR3+; repos still get vw-repo unless skipped later)
  --xlibre-full              Prefer full xlibre meta over xlibre-minimal (PR3+)
  --allow-xorg-fallback      Recovery path only; never silent (PR10 docs)
  --with-picom               Opt-in picom (default OFF)
  --repos-only               Only run repository wiring (PR2 scope)
  --dry-run                  Dry-run repos.sh (no system writes)
  -h, --help                 Show this help

PR2 implements --repos-only (and default path currently stops after repos).
Package install, services, suckless, and session land in PR3+.
EOF
}

log()  { printf '==> %s\n' "$*" | tee -a "${LOG_FILE}" 2>/dev/null || printf '==> %s\n' "$*"; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

require_not_root_user_confusion() {
	# Running the whole bootstrap as root is OK for package/repo steps, but
	# later session/dotfile steps must target a normal user. PR2 only wires repos.
	if [[ "${EUID}" -eq 0 && -z "${SUDO_USER:-}" && "${REPOS_ONLY}" -eq 0 ]]; then
		log "Running as root. Prefer: sudo -u \$USER for session steps (PR5+)."
	fi
}

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
elif [[ "${REPOS_ONLY}" -eq 0 ]]; then
	# Full bootstrap will require profile once PR3 lands; PR2 allows repos-only.
	:
fi

mkdir -p "${LOG_DIR}"
: >>"${LOG_FILE}" 2>/dev/null || true
{
	echo "---- voidwolf bootstrap $(date -Iseconds 2>/dev/null || date) ----"
	echo "REPO_ROOT=${REPO_ROOT}"
	echo "PROFILE=${PROFILE:-} GPU=${GPU} WITH_32BIT=${WITH_32BIT} REPOS_ONLY=${REPOS_ONLY}"
	echo "NO_BRAVE=${NO_BRAVE} XLIBRE_FULL=${XLIBRE_FULL} WITH_PICOM=${WITH_PICOM}"
	echo "ALLOW_XORG_FALLBACK=${ALLOW_XORG_FALLBACK}"
} >>"${LOG_FILE}" 2>/dev/null || true

require_not_root_user_confusion
check_void_arch

log "voidwolf bootstrap (PR2: repository wiring)"
log "See docs/design.md and docs/repos.md"

repos_args=()
[[ "${WITH_32BIT}" -eq 1 ]] && repos_args+=(--with-32bit)
[[ "${DRY_RUN}" -eq 1 ]] && repos_args+=(--dry-run)

# shellcheck disable=SC2086
bash "${SCRIPT_DIR}/repos.sh" "${repos_args[@]+"${repos_args[@]}"}"

if [[ "${REPOS_ONLY}" -eq 1 ]]; then
	log "Repos-only done. Remaining bootstrap steps: PR3+."
	exit 0
fi

# --- PR3+ placeholders ---
cat <<EOF

Repository wiring finished.

Not yet implemented (later PRs):
  - package install (profile=${PROFILE:-unset}, gpu=${GPU})
  - enable-services.sh (dbus, elogind, NetworkManager, …)
  - suckless build (PREFIX=\$HOME/.local)
  - install-dotfiles / PipeWire session
  - brave-origin install (NO_BRAVE=${NO_BRAVE})
  - xlibre-minimal vs full (XLIBRE_FULL=${XLIBRE_FULL})
  - NVIDIA profiles (ALLOW_XORG_FALLBACK=${ALLOW_XORG_FALLBACK})
  - picom (WITH_PICOM=${WITH_PICOM})

Re-run with --repos-only to only wire repos.
See docs/design.md PR Plan for next steps (PR3).
EOF

exit 0
