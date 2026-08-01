#!/usr/bin/env bash
# voidwolf PR17 — orchestrate a void-mklive build (scaffold)
# Does not vendor void-mklive; points at an external clone.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_DIR="$SCRIPT_DIR"
REPO_ROOT="$(cd "${ISO_DIR}/.." && pwd)"
# shellcheck source=../bootstrap/lib.sh
source "${REPO_ROOT}/bootstrap/lib.sh"

# Defaults
VOIDWOLF_ISO_ARCH="${VOIDWOLF_ISO_ARCH:-x86_64}"
VOIDWOLF_ISO_BASE="${VOIDWOLF_ISO_BASE:-voidwolf}"
VOIDWOLF_HOSTNAME="${VOIDWOLF_HOSTNAME:-voidwolf}"
VOIDWOLF_LIVE_USER="${VOIDWOLF_LIVE_USER:-voidwolf}"
VOIDWOLF_ISO_INCLUDE_LOCAL_REPO="${VOIDWOLF_ISO_INCLUDE_LOCAL_REPO:-1}"
VOIDWOLF_ISO_OUT="${VOIDWOLF_ISO_OUT:-${ISO_DIR}/out}"
VOID_MKLIVE_DIR="${VOID_MKLIVE_DIR:-}"

DRY_RUN=0
SKIP_PKG_BUILD=0

usage() {
	cat <<'EOF'
Usage: iso/build-iso.sh [options]

Scaffolded void-mklive driver for voidwolf live/install images.

Options:
  --mklive-dir DIR   Path to void-mklive checkout (or set VOID_MKLIVE_DIR)
  --arch ARCH        Default x86_64
  --out DIR          Output directory (default: iso/out)
  --skip-pkg-build   Do not run packages/build-local-repo.sh
  --dry-run          Print the mklive command; do not execute
  -h, --help

Environment: see iso/mklive.env.example (copy to iso/mklive.env).

Prerequisites:
  1. Clone void-mklive: https://github.com/void-linux/void-mklive
  2. Build host with root/sudo for mklive (loop mounts, etc.)
  3. Optional local packages: ./packages/build-local-repo.sh

Decisions (PR17):
  - Hostname: voidwolf
  - No display manager — startx session story
  - No FDE in installer
  - Live user name default: voidwolf (password: set via mklive -u / docs)
  - glibc x86_64 first

See docs/iso.md
EOF
}

# Load optional env file
if [[ -f "${ISO_DIR}/mklive.env" ]]; then
	# shellcheck disable=SC1091
	set -a
	source "${ISO_DIR}/mklive.env"
	set +a
fi

while [[ $# -gt 0 ]]; do
	case "$1" in
		--mklive-dir) VOID_MKLIVE_DIR="${2:-}"; shift ;;
		--arch) VOIDWOLF_ISO_ARCH="${2:-}"; shift ;;
		--out) VOIDWOLF_ISO_OUT="${2:-}"; shift ;;
		--skip-pkg-build) SKIP_PKG_BUILD=1 ;;
		--dry-run) DRY_RUN=1 ;;
		-h|--help) usage; exit 0 ;;
		*) voidwolf_die "unknown option: $1" ;;
	esac
	shift
done

export VOIDWOLF_ISO_INCLUDE_LOCAL_REPO

mkdir -p "${VOIDWOLF_ISO_OUT}"

# Hostname in overlay (re-write if env overrides)
printf '%s\n' "${VOIDWOLF_HOSTNAME}" >"${ISO_DIR}/overlay/etc/hostname"

# Package list
PKGLIST="$("${ISO_DIR}/scripts/assemble-pkglist.sh")"
voidwolf_log "Package list: ${PKGLIST}"

# Local repo
LOCAL_REPO="${REPO_ROOT}/packages/repo"
if [[ "${VOIDWOLF_ISO_INCLUDE_LOCAL_REPO}" == "1" ]]; then
	if [[ "${SKIP_PKG_BUILD}" -eq 0 && "${DRY_RUN}" -eq 0 ]]; then
		if [[ -x "${REPO_ROOT}/packages/build-local-repo.sh" ]]; then
			voidwolf_log "Building local XBPS repo for image inclusion"
			bash "${REPO_ROOT}/packages/build-local-repo.sh"
		fi
	fi
	if [[ ! -d "${LOCAL_REPO}" ]] || ! ls "${LOCAL_REPO}"/*.xbps >/dev/null 2>&1; then
		voidwolf_warn "packages/repo empty — voidwolf-* packages will not install on image unless repos exist"
	fi
fi

# Locate mklive
MKLIVE_SH=""
if [[ -n "${VOID_MKLIVE_DIR}" && -x "${VOID_MKLIVE_DIR}/mklive.sh" ]]; then
	MKLIVE_SH="${VOID_MKLIVE_DIR}/mklive.sh"
elif [[ -x "${ISO_DIR}/void-mklive/mklive.sh" ]]; then
	MKLIVE_SH="${ISO_DIR}/void-mklive/mklive.sh"
elif command -v mklive.sh >/dev/null 2>&1; then
	MKLIVE_SH="$(command -v mklive.sh)"
fi

if [[ -z "${MKLIVE_SH}" ]]; then
	voidwolf_log "void-mklive not found (expected)."
	voidwolf_log "Scaffold is ready. To build a real ISO:"
	voidwolf_log "  git clone https://github.com/void-linux/void-mklive"
	voidwolf_log "  export VOID_MKLIVE_DIR=/path/to/void-mklive"
	voidwolf_log "  ./iso/build-iso.sh"
	voidwolf_log "Docs: docs/iso.md"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		voidwolf_log "[dry-run] would invoke mklive with overlay + packages"
		exit 0
	fi
	# Non-zero so CI can distinguish "scaffold only" vs successful ISO
	# but design is scaffold-first: exit 0 with message is friendlier for `make iso-scaffold`
	exit 0
fi

# void-mklive argument conventions (see upstream mklive.sh -h; may evolve)
# Common flags used across recent void-mklive:
#   -a arch
#   -p "pkg pkg …"
#   -T "title"
#   -o outfile
#   -I includedir   (rootfs overlay)
#   -r repo_url     (extra repository; may be file:// for local)
#
# User creation (-u) is upstream-dependent; we document defaults in docs/iso.md
# rather than assuming a single -u syntax forever.

OUT_ISO="${VOIDWOLF_ISO_OUT}/${VOIDWOLF_ISO_BASE}-${VOIDWOLF_ISO_ARCH}.iso"
OVERLAY="${ISO_DIR}/overlay"

cmd=(
	bash "${MKLIVE_SH}"
	-a "${VOIDWOLF_ISO_ARCH}"
	-p "${PKGLIST}"
	-T "voidwolf"
	-o "${OUT_ISO}"
	-I "${OVERLAY}"
)

# Local file repo for voidwolf packages
if [[ "${VOIDWOLF_ISO_INCLUDE_LOCAL_REPO}" == "1" && -d "${LOCAL_REPO}" ]]; then
	# file:// URL form preferred for local paths
	cmd+=(-r "file://${LOCAL_REPO}")
fi

# Extra repos from env
if [[ -n "${VOIDWOLF_ISO_EXTRA_REPOS:-}" ]]; then
	# shellcheck disable=SC2206
	extra=(${VOIDWOLF_ISO_EXTRA_REPOS})
	for r in "${extra[@]}"; do
		cmd+=(-r "$r")
	done
fi

if [[ -n "${VOIDWOLF_MKLIVE_EXTRA_ARGS:-}" ]]; then
	# shellcheck disable=SC2206
	cmd+=(${VOIDWOLF_MKLIVE_EXTRA_ARGS})
fi

voidwolf_log "Hostname: ${VOIDWOLF_HOSTNAME}"
voidwolf_log "Live user (docs): ${VOIDWOLF_LIVE_USER}"
voidwolf_log "Command:"
printf '  %q' "${cmd[@]}"
printf '\n'

if [[ "${DRY_RUN}" -eq 1 ]]; then
	voidwolf_log "[dry-run] not executing mklive"
	exit 0
fi

voidwolf_log "Running void-mklive (requires privileges for loop/mount)…"
"${cmd[@]}"
voidwolf_log "ISO build finished → ${OUT_ISO}"
