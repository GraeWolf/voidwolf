#!/usr/bin/env bash
# Shared helpers for voidwolf bootstrap scripts.
# shellcheck shell=bash

voidwolf_log()  { printf '==> %s\n' "$*"; }
voidwolf_warn() { printf 'warning: %s\n' "$*" >&2; }
voidwolf_die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

voidwolf_run_as_root() {
	if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
		printf '[dry-run] %s\n' "$*"
		return 0
	fi
	if [[ "${EUID}" -eq 0 ]]; then
		"$@"
	elif command -v sudo >/dev/null 2>&1; then
		sudo "$@"
	else
		voidwolf_die "root or sudo required: $*"
	fi
}

# Read package list file → stdout one package per line (no comments/blanks).
voidwolf_read_pkg_list() {
	local file="$1"
	[[ -f "$file" ]] || voidwolf_die "package list not found: $file"
	# strip comments and blank lines; trim whitespace
	sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$file" | sed '/^$/d'
}

# True if package is known to xbps (installed or available in repos).
voidwolf_pkg_available() {
	local pkg="$1"
	xbps-query -R "$pkg" >/dev/null 2>&1 || xbps-query "$pkg" >/dev/null 2>&1
}

# Install packages (required). Fails if any cannot be installed.
voidwolf_install_required() {
	local -a pkgs=("$@")
	[[ ${#pkgs[@]} -eq 0 ]] && return 0
	voidwolf_log "Install required (${#pkgs[@]} packages): ${pkgs[*]}"
	if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
		printf '[dry-run] xbps-install -y %s\n' "${pkgs[*]}"
		return 0
	fi
	voidwolf_run_as_root xbps-install -y "${pkgs[@]}"
}

# Best-effort install: skip packages not in repos.
voidwolf_install_optional() {
	local pkg
	local -a found=()
	for pkg in "$@"; do
		if voidwolf_pkg_available "$pkg"; then
			found+=("$pkg")
		else
			voidwolf_warn "optional package not available, skipping: $pkg"
		fi
	done
	[[ ${#found[@]} -eq 0 ]] && return 0
	voidwolf_log "Install optional (${#found[@]} packages): ${found[*]}"
	if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
		printf '[dry-run] xbps-install -y %s\n' "${found[*]}"
		return 0
	fi
	voidwolf_run_as_root xbps-install -y "${found[@]}" || \
		voidwolf_warn "some optional packages failed to install (continuing)"
}
