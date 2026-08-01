#!/usr/bin/env bash
# voidwolf PR15 — build meta packages into a personal local XBPS repo
# Requires: xbps-create, xbps-rindex (Void base / xbps)
# Does NOT require xbps-src or root for building into packages/repo/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=../bootstrap/lib.sh
source "${REPO_ROOT}/bootstrap/lib.sh"

# shellcheck source=version.conf
# version.conf is KEY=val, not shell functions
VOIDWOLF_PKGVER=0.1.0
VOIDWOLF_PKGREVISION=1
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/version.conf"

OUT_REPO="${VOIDWOLF_LOCAL_REPO:-${SCRIPT_DIR}/repo}"
WORK="${SCRIPT_DIR}/.build"
ARCH="noarch"
BUILT_WITH="voidwolf-packages/build-local-repo.sh"
HOMEPAGE="https://github.com/GraeWolf/voidwolf"
LICENSE="MIT"
MAINTAINER="voidwolf <voidwolf@localhost>"

ONLY=""
DRY_RUN=0
CLEAN=0

usage() {
	cat <<'EOF'
Usage: packages/build-local-repo.sh [options]

Build voidwolf meta packages (noarch) into a local XBPS repository directory.

Options:
  --repo DIR       Output repo (default: packages/repo)
  --only NAME      Build one: voidwolf-base|desktop|themes|laptop|helpers
  --clean          Remove packages/.build and rebuild
  --dry-run        Print xbps-create lines only
  -h, --help

After build:
  # optional: point XBPS at the repo (absolute path)
  printf 'repository=%s\n' "$PWD/packages/repo" | sudo tee /etc/xbps.d/98-voidwolf-local.conf
  sudo xbps-install -S
  sudo xbps-install -y voidwolf-desktop voidwolf-themes voidwolf-helpers

See docs/packaging.md
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--repo) OUT_REPO="${2:-}"; shift ;;
		--only) ONLY="${2:-}"; shift ;;
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
		"voidwolf helper scripts (/usr/bin/voidwolf-*)"
}

create_pkg() {
	local name="$1" dest="$2" deps="$3" summary="$4"
	local pkgver="${name}-${PKGVER_FULL}"
	local out_xbps="${OUT_REPO}/${pkgver}.${ARCH}.xbps"
	local desc
	desc="$(tr '\n' ' ' <"${SCRIPT_DIR}/${name}/DESCRIPTION" | sed 's/[[:space:]]\+/ /g' | cut -c1-180)"

	voidwolf_log "Package ${pkgver} (${ARCH})"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[dry-run] xbps-create -A %s -n %s -s %q -S %q -D %q -m %q -H %q -l %s %s\n' \
			"$ARCH" "$pkgver" "$summary" "$desc" "${deps:-}" "$MAINTAINER" "$HOMEPAGE" "$LICENSE" "$dest"
		return 0
	fi

	mkdir -p "$OUT_REPO"
	local -a cmd=(
		xbps-create
		-A "$ARCH"
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

# --- main ---
if [[ "${CLEAN}" -eq 1 ]]; then
	voidwolf_log "Clean ${WORK}"
	rm -rf "$WORK"
fi
mkdir -p "$WORK" "$OUT_REPO"

pkgs=(voidwolf-base voidwolf-themes voidwolf-desktop voidwolf-laptop voidwolf-helpers)
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
		*) voidwolf_die "unknown package: $p" ;;
	esac
done

if [[ "${DRY_RUN}" -eq 0 ]]; then
	voidwolf_log "Indexing repo ${OUT_REPO}"
	# force re-add
	xbps-rindex -f -a "${OUT_REPO}"/*.xbps
	voidwolf_log "Local repo ready: ${OUT_REPO}"
	voidwolf_log "Packages:"
	ls -1 "${OUT_REPO}"/*.xbps 2>/dev/null || true
	voidwolf_log "Next: see docs/packaging.md"
else
	voidwolf_log "[dry-run] skip xbps-rindex"
fi
