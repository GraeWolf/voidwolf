#!/usr/bin/env bash
# voidwolf PR15/PR16 — build meta + suckless packages into a personal local XBPS repo
# Requires: xbps-create, xbps-rindex; for suckless: gcc, make, X11/freetype headers
# Does NOT require xbps-src or root for building into packages/repo/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=../bootstrap/lib.sh
source "${REPO_ROOT}/bootstrap/lib.sh"

# shellcheck source=version.conf
VOIDWOLF_PKGVER=0.1.0
VOIDWOLF_PKGREVISION=1
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/version.conf"

OUT_REPO="${VOIDWOLF_LOCAL_REPO:-${SCRIPT_DIR}/repo}"
WORK="${SCRIPT_DIR}/.build"
ARCH_NOARCH="noarch"
ARCH_NATIVE="$(uname -m)"
# Void uses x86_64 not amd64
[[ "${ARCH_NATIVE}" == "amd64" ]] && ARCH_NATIVE="x86_64"
BUILT_WITH="voidwolf-packages/build-local-repo.sh"
HOMEPAGE="https://github.com/GraeWolf/voidwolf"
LICENSE="MIT"
MAINTAINER="voidwolf <voidwolf@localhost>"

ONLY=""
DRY_RUN=0
CLEAN=0
SKIP_SUCKLESS=0

usage() {
	cat <<'EOF'
Usage: packages/build-local-repo.sh [options]

Build voidwolf packages into a local XBPS repository directory.

Meta (noarch):  voidwolf-base|desktop|themes|laptop|helpers
Suckless (native arch): voidwolf-dwm|st|dmenu|suckless

Options:
  --repo DIR         Output repo (default: packages/repo)
  --only NAME        Build one package name
  --skip-suckless    Only meta packages (PR15 set)
  --clean            Remove packages/.build and rebuild
  --dry-run          Print xbps-create lines only
  -h, --help

After build:
  printf 'repository=%s\n' "$PWD/packages/repo" | sudo tee /etc/xbps.d/98-voidwolf-local.conf
  sudo xbps-install -S
  sudo xbps-install -y voidwolf-desktop voidwolf-helpers voidwolf-suckless

See docs/packaging.md
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--repo) OUT_REPO="${2:-}"; shift ;;
		--only) ONLY="${2:-}"; shift ;;
		--skip-suckless) SKIP_SUCKLESS=1 ;;
		--clean) CLEAN=1 ;;
		--dry-run) DRY_RUN=1 ;;
		-h|--help) usage; exit 0 ;;
		*) voidwolf_die "unknown option: $1" ;;
	esac
	shift
done

command -v xbps-create >/dev/null 2>&1 || voidwolf_die "xbps-create not found (install xbps)"
command -v xbps-rindex >/dev/null 2>&1 || voidwolf_die "xbps-rindex not found (install xbps)"

PKGVER_FULL="${VOIDWOLF_PKGVER}_${VOIDWOLF_PKGREVISION}"
[[ -n "${OUT_REPO}" ]] || voidwolf_die "empty --repo"

deps_from_list() {
	local listf="$1"
	voidwolf_read_pkg_list "$listf" | tr '\n' ' ' | sed 's/[[:space:]]*$//'
}

stage_doc() {
	local dest="$1" name="$2" descf="$3"
	mkdir -p "${dest}/usr/share/doc/${name}"
	if [[ -f "$descf" ]]; then
		install -m 0644 "$descf" "${dest}/usr/share/doc/${name}/DESCRIPTION"
	fi
	{
		echo "voidwolf ${name} ${PKGVER_FULL}"
		echo "Built: $(date -u +%Y-%m-%dT%H:%MZ 2>/dev/null || date)"
		echo "Source: ${REPO_ROOT}"
		echo "See: docs/packaging.md"
	} >"${dest}/usr/share/doc/${name}/README"
}

# --- package: voidwolf-base ---
build_base() {
	local name="voidwolf-base"
	local dest="${WORK}/${name}"
	local deps
	deps="$(deps_from_list "${REPO_ROOT}/bootstrap/packages-base.txt")"
	rm -rf "$dest"
	mkdir -p "$dest"
	stage_doc "$dest" "$name" "${SCRIPT_DIR}/${name}/DESCRIPTION"
	# tiny marker so package is non-empty
	mkdir -p "${dest}/usr/share/voidwolf"
	printf '%s\n' "${PKGVER_FULL}" >"${dest}/usr/share/voidwolf/base-version"
	create_pkg "$name" "$dest" "$deps" "voidwolf base meta (CLI tools)"
}

# --- package: voidwolf-desktop ---
build_desktop() {
	local name="voidwolf-desktop"
	local dest="${WORK}/${name}"
	local deps_list deps
	# Meta depends on voidwolf-base + desktop-required + xlibre-minimal (name only)
	mapfile -t deps_list < <(voidwolf_read_pkg_list "${REPO_ROOT}/bootstrap/packages-desktop-required.txt")
	deps="voidwolf-base>=${VOIDWOLF_PKGVER} voidwolf-themes>=${VOIDWOLF_PKGVER} xlibre-minimal"
	local p
	for p in "${deps_list[@]}"; do
		deps+=" ${p}"
	done
	rm -rf "$dest"
	mkdir -p "$dest"
	stage_doc "$dest" "$name" "${SCRIPT_DIR}/${name}/DESCRIPTION"
	mkdir -p "${dest}/usr/share/voidwolf"
	printf '%s\n' "${PKGVER_FULL}" >"${dest}/usr/share/voidwolf/desktop-version"
	# install bootstrap package lists for reference
	mkdir -p "${dest}/usr/share/voidwolf/bootstrap"
	install -m 0644 \
		"${REPO_ROOT}/bootstrap/packages-base.txt" \
		"${REPO_ROOT}/bootstrap/packages-desktop-required.txt" \
		"${REPO_ROOT}/bootstrap/packages-desktop-optional.txt" \
		"${dest}/usr/share/voidwolf/bootstrap/" 2>/dev/null || true
	create_pkg "$name" "$dest" "$deps" "voidwolf desktop meta (session deps)"
}

# --- package: voidwolf-themes ---
build_themes() {
	local name="voidwolf-themes"
	local dest="${WORK}/${name}"
	rm -rf "$dest"
	mkdir -p "$dest"
	stage_doc "$dest" "$name" "${SCRIPT_DIR}/${name}/DESCRIPTION"
	mkdir -p "${dest}/usr/share/voidwolf/themes" "${dest}/usr/share/voidwolf/wallpapers"
	# themes
	local f
	for f in "${REPO_ROOT}/themes/"*.toml; do
		[[ -f "$f" ]] || continue
		install -m 0644 "$f" "${dest}/usr/share/voidwolf/themes/"
	done
	[[ -f "${REPO_ROOT}/themes/README.md" ]] && \
		install -m 0644 "${REPO_ROOT}/themes/README.md" "${dest}/usr/share/voidwolf/themes/"
	# wallpapers (real files only; recreate symlinks in package)
	for f in "${REPO_ROOT}/wallpapers/"*.png; do
		[[ -f "$f" ]] || continue
		install -m 0644 "$f" "${dest}/usr/share/voidwolf/wallpapers/"
	done
	# jpg aliases → png when both names match
	(
		cd "${dest}/usr/share/voidwolf/wallpapers"
		for png in *.png; do
			[[ -f "$png" ]] || continue
			base="${png%.png}"
			ln -sfn "$png" "${base}.jpg"
		done
	)
	[[ -f "${REPO_ROOT}/wallpapers/README.md" ]] && \
		install -m 0644 "${REPO_ROOT}/wallpapers/README.md" "${dest}/usr/share/voidwolf/wallpapers/"
	printf '%s\n' "${PKGVER_FULL}" >"${dest}/usr/share/voidwolf/themes-version"
	create_pkg "$name" "$dest" "" "voidwolf themes + wallpapers (/usr/share/voidwolf)"
}

# --- package: voidwolf-laptop ---
build_laptop() {
	local name="voidwolf-laptop"
	local dest="${WORK}/${name}"
	local deps
	deps="voidwolf-desktop>=${VOIDWOLF_PKGVER} $(deps_from_list "${REPO_ROOT}/bootstrap/packages-laptop.txt")"
	rm -rf "$dest"
	mkdir -p "$dest"
	stage_doc "$dest" "$name" "${SCRIPT_DIR}/${name}/DESCRIPTION"
	mkdir -p "${dest}/usr/share/voidwolf"
	printf '%s\n' "${PKGVER_FULL}" >"${dest}/usr/share/voidwolf/laptop-version"
	create_pkg "$name" "$dest" "$deps" "voidwolf laptop meta (brightnessctl, tlp)"
}

# --- package: voidwolf-helpers ---
build_helpers() {
	local name="voidwolf-helpers"
	local dest="${WORK}/${name}"
	rm -rf "$dest"
	mkdir -p "${dest}/usr/bin" "${dest}/usr/share/voidwolf/bin"
	stage_doc "$dest" "$name" "${SCRIPT_DIR}/${name}/DESCRIPTION"
	local f base
	for f in "${REPO_ROOT}/bin"/voidwolf-*; do
		[[ -f "$f" && -x "$f" ]] || continue
		base=$(basename "$f")
		install -m 0755 "$f" "${dest}/usr/bin/${base}"
	done
	# install-user-bin helper for reference
	if [[ -x "${REPO_ROOT}/bin/install-user-bin.sh" ]]; then
		install -m 0755 "${REPO_ROOT}/bin/install-user-bin.sh" \
			"${dest}/usr/share/voidwolf/bin/install-user-bin.sh"
	fi
	printf '%s\n' "${PKGVER_FULL}" >"${dest}/usr/share/voidwolf/helpers-version"
	# soft dep: voidwolf-themes for /usr/share themes; scripts still work from git
	create_pkg "$name" "$dest" "voidwolf-themes>=${VOIDWOLF_PKGVER}" \
		"voidwolf helper scripts (/usr/bin/voidwolf-*)" "$ARCH_NOARCH"
}

# Runtime deps for X11 suckless tools (Void package names; devel only needed at build host)
SUCKLESS_RUN_DEPS="libX11 libXft libXinerama fontconfig freetype"

# --- PR16: voidwolf-dwm ---
build_dwm() {
	local name="voidwolf-dwm"
	local dest="${WORK}/${name}"
	local src="${REPO_ROOT}/suckless/dwm"
	[[ -d "$src" ]] || voidwolf_die "missing $src"
	[[ -f "${src}/config.h" ]] || voidwolf_die "missing ${src}/config.h"
	[[ -f "${src}/colors.h" ]] || voidwolf_die "missing ${src}/colors.h (run voidwolf-theme once)"

	rm -rf "$dest"
	mkdir -p "$dest"
	stage_doc "$dest" "$name" "${SCRIPT_DIR}/${name}/DESCRIPTION"

	if [[ "${DRY_RUN}" -eq 1 ]]; then
		voidwolf_log "[dry-run] make -C suckless/dwm install PREFIX=/usr DESTDIR=..."
		create_pkg "$name" "$dest" "${SUCKLESS_RUN_DEPS}" \
			"voidwolf dwm (patched) → /usr/bin/dwm" "$ARCH_NATIVE"
		return 0
	fi

	voidwolf_log "Compile dwm (PREFIX=/usr DESTDIR staging)"
	(
		cd "$src"
		make clean >/dev/null 2>&1 || true
		make -j"$(nproc 2>/dev/null || echo 2)" PREFIX=/usr
		make install PREFIX=/usr DESTDIR="$dest"
		make clean >/dev/null 2>&1 || true
	)
	# Example configs for user rebuild to ~/.local (theme engine)
	mkdir -p "${dest}/usr/share/voidwolf/examples/dwm"
	install -m 0644 "${src}/config.h" "${dest}/usr/share/voidwolf/examples/dwm/config.h"
	install -m 0644 "${src}/colors.h" "${dest}/usr/share/voidwolf/examples/dwm/colors.h"
	printf '%s\n' "${PKGVER_FULL}" >"${dest}/usr/share/voidwolf/dwm-version"
	# PATH note
	{
		echo "System binary: /usr/bin/dwm"
		echo "Themed rebuilds: ./bootstrap/build-suckless.sh → ~/.local/bin/dwm (preferred on PATH)"
	} >"${dest}/usr/share/doc/${name}/PATH.txt"

	create_pkg "$name" "$dest" "${SUCKLESS_RUN_DEPS}" \
		"voidwolf dwm (patched Phase 1+3) → /usr/bin/dwm" "$ARCH_NATIVE"
}

# --- PR16: voidwolf-st ---
build_st() {
	local name="voidwolf-st"
	local dest="${WORK}/${name}"
	local src="${REPO_ROOT}/suckless/st"
	[[ -d "$src" ]] || voidwolf_die "missing $src"
	[[ -f "${src}/config.h" ]] || voidwolf_die "missing ${src}/config.h"

	rm -rf "$dest"
	mkdir -p "$dest"
	stage_doc "$dest" "$name" "${SCRIPT_DIR}/${name}/DESCRIPTION"

	if [[ "${DRY_RUN}" -eq 1 ]]; then
		voidwolf_log "[dry-run] make -C suckless/st + package terminfo"
		create_pkg "$name" "$dest" "${SUCKLESS_RUN_DEPS}" \
			"voidwolf st (xresources+scrollback) → /usr/bin/st" "$ARCH_NATIVE"
		return 0
	fi

	voidwolf_log "Compile st (PREFIX=/usr DESTDIR staging)"
	(
		cd "$src"
		make clean >/dev/null 2>&1 || true
		make -j"$(nproc 2>/dev/null || echo 2)" PREFIX=/usr
		# Manual install: avoid bare `tic` writing outside DESTDIR
		mkdir -p "${dest}/usr/bin" "${dest}/usr/share/man/man1" "${dest}/usr/share/terminfo"
		install -m 0755 st "${dest}/usr/bin/st"
		sed "s/VERSION/$(cat VERSION 2>/dev/null || echo 0.9.2)/g" <st.1 \
			>"${dest}/usr/share/man/man1/st.1"
		chmod 644 "${dest}/usr/share/man/man1/st.1"
		# compile terminfo into package
		if command -v tic >/dev/null 2>&1; then
			tic -o "${dest}/usr/share/terminfo" -x st.info 2>/dev/null \
				|| tic -o "${dest}/usr/share/terminfo" st.info 2>/dev/null \
				|| voidwolf_warn "tic failed; st terminfo not packaged"
		fi
		make clean >/dev/null 2>&1 || true
	)
	mkdir -p "${dest}/usr/share/voidwolf/examples/st"
	install -m 0644 "${src}/config.h" "${dest}/usr/share/voidwolf/examples/st/config.h"
	printf '%s\n' "${PKGVER_FULL}" >"${dest}/usr/share/voidwolf/st-version"

	create_pkg "$name" "$dest" "${SUCKLESS_RUN_DEPS}" \
		"voidwolf st (xresources+scrollback) → /usr/bin/st" "$ARCH_NATIVE"
}

# --- PR16: voidwolf-dmenu ---
build_dmenu() {
	local name="voidwolf-dmenu"
	local dest="${WORK}/${name}"
	local src="${REPO_ROOT}/suckless/dmenu"
	[[ -d "$src" ]] || voidwolf_die "missing $src"
	[[ -f "${src}/config.h" ]] || voidwolf_die "missing ${src}/config.h"

	rm -rf "$dest"
	mkdir -p "$dest"
	stage_doc "$dest" "$name" "${SCRIPT_DIR}/${name}/DESCRIPTION"

	if [[ "${DRY_RUN}" -eq 1 ]]; then
		voidwolf_log "[dry-run] make -C suckless/dmenu install PREFIX=/usr DESTDIR=..."
		create_pkg "$name" "$dest" "${SUCKLESS_RUN_DEPS}" \
			"voidwolf dmenu → /usr/bin/dmenu" "$ARCH_NATIVE"
		return 0
	fi

	voidwolf_log "Compile dmenu (PREFIX=/usr DESTDIR staging)"
	(
		cd "$src"
		make clean >/dev/null 2>&1 || true
		make -j"$(nproc 2>/dev/null || echo 2)" PREFIX=/usr
		make install PREFIX=/usr DESTDIR="$dest"
		make clean >/dev/null 2>&1 || true
	)
	mkdir -p "${dest}/usr/share/voidwolf/examples/dmenu"
	install -m 0644 "${src}/config.h" "${dest}/usr/share/voidwolf/examples/dmenu/config.h"
	printf '%s\n' "${PKGVER_FULL}" >"${dest}/usr/share/voidwolf/dmenu-version"

	create_pkg "$name" "$dest" "${SUCKLESS_RUN_DEPS}" \
		"voidwolf dmenu (+ dmenu_run/path, stest) → /usr/bin" "$ARCH_NATIVE"
}

# --- PR16: voidwolf-suckless meta ---
build_suckless_meta() {
	local name="voidwolf-suckless"
	local dest="${WORK}/${name}"
	local deps="voidwolf-dwm>=${VOIDWOLF_PKGVER} voidwolf-st>=${VOIDWOLF_PKGVER} voidwolf-dmenu>=${VOIDWOLF_PKGVER}"
	rm -rf "$dest"
	mkdir -p "$dest"
	stage_doc "$dest" "$name" "${SCRIPT_DIR}/${name}/DESCRIPTION"
	mkdir -p "${dest}/usr/share/voidwolf"
	printf '%s\n' "${PKGVER_FULL}" >"${dest}/usr/share/voidwolf/suckless-version"
	{
		echo "Pulls voidwolf-dwm, voidwolf-st, voidwolf-dmenu."
		echo "User-themed rebuilds still install to ~/.local/bin (PATH preference)."
	} >"${dest}/usr/share/doc/${name}/PATH.txt"
	create_pkg "$name" "$dest" "$deps" "voidwolf suckless set (dwm+st+dmenu)" "$ARCH_NOARCH"
}

create_pkg() {
	local name="$1" dest="$2" deps="$3" summary="$4"
	local arch="${5:-$ARCH_NOARCH}"
	local pkgver="${name}-${PKGVER_FULL}"
	local out_xbps="${OUT_REPO}/${pkgver}.${arch}.xbps"
	local desc
	desc="$(tr '\n' ' ' <"${SCRIPT_DIR}/${name}/DESCRIPTION" | sed 's/[[:space:]]\+/ /g' | cut -c1-180)"

	voidwolf_log "Package ${pkgver} (${arch})"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[dry-run] xbps-create -A %s -n %s -s %q -S %q -D %q … %s\n' \
			"$arch" "$pkgver" "$summary" "$desc" "${deps:-}" "$dest"
		return 0
	fi

	mkdir -p "$OUT_REPO"
	local -a cmd=(
		xbps-create
		-A "$arch"
		-n "$pkgver"
		-s "$summary"
		-S "$desc"
		-m "$MAINTAINER"
		-H "$HOMEPAGE"
		-l "$LICENSE"
		-B "$BUILT_WITH"
	)
	if [[ -n "${deps// }" ]]; then
		cmd+=(-D "$deps")
	fi
	cmd+=("$dest")

	(
		cd "$OUT_REPO"
		"${cmd[@]}"
	)
	voidwolf_log "Created ${out_xbps}"
}

# Fix meta packages to pass ARCH_NOARCH explicitly (updated create_pkg signature)
# --- main ---
if [[ "${CLEAN}" -eq 1 ]]; then
	voidwolf_log "Clean ${WORK}"
	rm -rf "$WORK"
fi
mkdir -p "$WORK" "$OUT_REPO"

pkgs=(
	voidwolf-base
	voidwolf-themes
	voidwolf-desktop
	voidwolf-laptop
	voidwolf-helpers
	voidwolf-dwm
	voidwolf-st
	voidwolf-dmenu
	voidwolf-suckless
)
if [[ "${SKIP_SUCKLESS}" -eq 1 ]]; then
	pkgs=(voidwolf-base voidwolf-themes voidwolf-desktop voidwolf-laptop voidwolf-helpers)
fi
if [[ -n "$ONLY" ]]; then
	pkgs=("$ONLY")
fi

for p in "${pkgs[@]}"; do
	case "$p" in
		voidwolf-base) build_base ;;
		voidwolf-themes) build_themes ;;
		voidwolf-desktop) build_desktop ;;
		voidwolf-laptop) build_laptop ;;
		voidwolf-helpers) build_helpers ;;
		voidwolf-dwm) build_dwm ;;
		voidwolf-st) build_st ;;
		voidwolf-dmenu) build_dmenu ;;
		voidwolf-suckless) build_suckless_meta ;;
		*) voidwolf_die "unknown package: $p" ;;
	esac
done

if [[ "${DRY_RUN}" -eq 0 ]]; then
	voidwolf_log "Indexing repo ${OUT_REPO}"
	xbps-rindex -f -a "${OUT_REPO}"/*.xbps
	voidwolf_log "Local repo ready: ${OUT_REPO}"
	voidwolf_log "Packages:"
	ls -1 "${OUT_REPO}"/*.xbps 2>/dev/null || true
	voidwolf_log "Next: see docs/packaging.md"
else
	voidwolf_log "[dry-run] skip xbps-rindex"
fi
