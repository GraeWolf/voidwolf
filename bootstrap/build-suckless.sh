#!/usr/bin/env bash
# voidwolf — build and install vendored dwm/st/dmenu to PREFIX (default ~/.local)
# NEVER uses sudo. Fails if PREFIX is not writable.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

PREFIX="${PREFIX:-$HOME/.local}"
BUILD_ALL=1
BUILD_DWM=0
BUILD_ST=0
BUILD_DMENU=0
CLEAN=1
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"

usage() {
	cat <<'EOF'
Usage: build-suckless.sh [options]

Build and install voidwolf suckless tools to PREFIX (default: $HOME/.local).
Never escalates to root/sudo.

Options:
  --prefix DIR     Install prefix (default: $HOME/.local)
  --dwm-only       Only build dwm
  --st-only        Only build st
  --dmenu-only     Only build dmenu
  --no-clean       Skip make clean
  -j N             Parallel jobs for make (default: nproc)
  -h, --help

Environment:
  PREFIX           Same as --prefix
  CC / CFLAGS      Passed through to make
  Use ccache by putting it first on PATH or CC="ccache gcc"
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--prefix) PREFIX="${2:-}"; shift ;;
		--dwm-only) BUILD_ALL=0; BUILD_DWM=1 ;;
		--st-only) BUILD_ALL=0; BUILD_ST=1 ;;
		--dmenu-only) BUILD_ALL=0; BUILD_DMENU=1 ;;
		--no-clean) CLEAN=0 ;;
		-j) JOBS="${2:-2}"; shift ;;
		-h|--help) usage; exit 0 ;;
		*) voidwolf_die "unknown option: $1" ;;
	esac
	shift
done

if [[ "${BUILD_ALL}" -eq 1 ]]; then
	BUILD_DWM=1
	BUILD_ST=1
	BUILD_DMENU=1
fi

[[ -n "${PREFIX}" ]] || voidwolf_die "PREFIX is empty"
if [[ ! -d "${PREFIX}" ]]; then
	mkdir -p "${PREFIX}/bin" || voidwolf_die "cannot create PREFIX=${PREFIX} (no sudo; fix permissions)"
fi
if [[ ! -w "${PREFIX}" ]]; then
	voidwolf_die "PREFIX not writable: ${PREFIX}
voidwolf installs suckless tools as the user only (design: no sudo).
Fix ownership or set PREFIX to a writable path."
fi
mkdir -p "${PREFIX}/bin" "${PREFIX}/share/man/man1" 2>/dev/null || true

# Prefer ccache when available and CC not already set
if [[ -z "${CC:-}" ]] && command -v ccache >/dev/null 2>&1; then
	export CC="ccache gcc"
	voidwolf_log "Using CC=${CC}"
fi

build_one() {
	local name="$1"
	local dir="${REPO_ROOT}/suckless/${name}"
	[[ -d "$dir" ]] || voidwolf_die "missing source tree: $dir"
	[[ -f "${dir}/config.h" ]] || voidwolf_die "missing ${dir}/config.h"

	voidwolf_log "Building ${name} → PREFIX=${PREFIX}"
	(
		cd "$dir"
		if [[ "${CLEAN}" -eq 1 ]]; then
			make clean >/dev/null 2>&1 || true
		fi
		make -j"${JOBS}" PREFIX="${PREFIX}"
		make install PREFIX="${PREFIX}"
	)
	voidwolf_log "Installed ${name}"
}

[[ "${BUILD_DMENU}" -eq 1 ]] && build_one dmenu
[[ "${BUILD_ST}" -eq 1 ]] && build_one st
[[ "${BUILD_DWM}" -eq 1 ]] && build_one dwm

voidwolf_log "Done. Ensure PATH has ${PREFIX}/bin first:"
voidwolf_log "  export PATH=\"${PREFIX}/bin:\$PATH\""
voidwolf_log "Binaries:"
for b in dwm st dmenu dmenu_run; do
	if [[ -x "${PREFIX}/bin/${b}" ]]; then
		printf '  %s\n' "${PREFIX}/bin/${b}"
	fi
done
