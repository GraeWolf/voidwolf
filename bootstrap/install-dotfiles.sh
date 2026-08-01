#!/usr/bin/env bash
# voidwolf — install session dotfiles (PR5 + PR12 bash/nvim)
# Backs up existing files with .voidwolf-bak.<timestamp> before overwrite.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

DRY_RUN=0
TARGET_HOME="${HOME}"
SKIP_PIPEWIRE=0
SKIP_BASH=0
SKIP_NVIM=0

usage() {
	cat <<'EOF'
Usage: install-dotfiles.sh [options]

Install voidwolf session files into the target home directory:
  ~/.xinitrc, .Xresources, bash snippets, voidwolf-nvim, PipeWire conf.d, helpers

Options:
  --home DIR       Target home (default: $HOME)
  --skip-pipewire  Do not run setup-pipewire.sh
  --skip-bash      Do not touch bashrc / bash snippets
  --skip-nvim      Do not install ~/.config/voidwolf-nvim
  --dry-run
  -h, --help
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--home) TARGET_HOME="${2:-}"; shift ;;
		--skip-pipewire) SKIP_PIPEWIRE=1 ;;
		--skip-bash) SKIP_BASH=1 ;;
		--skip-nvim) SKIP_NVIM=1 ;;
		--dry-run) DRY_RUN=1 ;;
		-h|--help) usage; exit 0 ;;
		*) voidwolf_die "unknown option: $1" ;;
	esac
	shift
done

export DRY_RUN
STAMP="$(date +%Y%m%d%H%M%S)"
PREFIX="${PREFIX:-${TARGET_HOME}/.local}"

backup_if_exists() {
	local dest="$1"
	if [[ -e "$dest" || -L "$dest" ]]; then
		local bak="${dest}.voidwolf-bak.${STAMP}"
		voidwolf_log "Backup ${dest} → ${bak}"
		if [[ "${DRY_RUN}" -eq 1 ]]; then
			printf '[dry-run] mv %s %s\n' "$dest" "$bak"
		else
			mv "$dest" "$bak"
		fi
	fi
}

install_file() {
	local src="$1" dest="$2" mode="${3:-0644}"
	[[ -f "$src" ]] || voidwolf_die "missing source: $src"
	voidwolf_log "Install ${dest}"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[dry-run] install -m %s %s → %s\n' "$mode" "$src" "$dest"
		return 0
	fi
	mkdir -p "$(dirname "$dest")"
	backup_if_exists "$dest"
	install -m "$mode" "$src" "$dest"
}

# --- X session ---
install_file "${REPO_ROOT}/config/X11/.xinitrc" "${TARGET_HOME}/.xinitrc" 0755
install_file "${REPO_ROOT}/config/X11/.Xresources" "${TARGET_HOME}/.Xresources" 0644

# picom (light defaults; keep user edits if no voidwolf marker)
picom_src="${REPO_ROOT}/config/picom/picom.conf"
picom_dest="${TARGET_HOME}/.config/picom/picom.conf"
if [[ -f "$picom_src" ]]; then
	if [[ ! -f "$picom_dest" ]] || grep -q 'voidwolf picom' "$picom_dest" 2>/dev/null; then
		install_file "$picom_src" "$picom_dest" 0644
	else
		voidwolf_log "picom.conf present (not voidwolf-marked) — leaving in place"
	fi
fi

# XDG user dirs (Desktop, Documents, Pictures/Screenshots, …)
if [[ "${DRY_RUN}" -eq 0 ]] && command -v xdg-user-dirs-update >/dev/null 2>&1; then
	voidwolf_log "xdg-user-dirs-update"
	HOME="${TARGET_HOME}" xdg-user-dirs-update || true
elif [[ "${DRY_RUN}" -eq 1 ]]; then
	printf '[dry-run] xdg-user-dirs-update\n'
fi

# --- voidwolf config dirs ---
voidwolf_log "Create ~/.config/voidwolf structure"
if [[ "${DRY_RUN}" -eq 0 ]]; then
	mkdir -p \
		"${TARGET_HOME}/.config/voidwolf/current" \
		"${TARGET_HOME}/.config/voidwolf/generated" \
		"${TARGET_HOME}/.config/voidwolf/themes" \
		"${TARGET_HOME}/.config/voidwolf/displays" \
		"${TARGET_HOME}/.config/voidwolf/logs"
	# record repo root for helpers that resolve docs
	printf '%s\n' "${REPO_ROOT}" > "${TARGET_HOME}/.config/voidwolf/repo-root"
	# PR13: leave a pointer README for display presets (never overwrite user scripts)
	if [[ ! -f "${TARGET_HOME}/.config/voidwolf/displays/README" ]]; then
		printf '%s\n' \
			"Place xrandr preset scripts here as *.sh" \
			"Examples: voidwolf-displays pick → Install example presets" \
			"Docs: docs/displays.md" \
			> "${TARGET_HOME}/.config/voidwolf/displays/README"
	fi
else
	printf '[dry-run] mkdir voidwolf config dirs under %s\n' "${TARGET_HOME}/.config/voidwolf"
fi

# --- helpers + suckless on PATH target ---
if [[ "${DRY_RUN}" -eq 0 ]]; then
	PREFIX="${PREFIX}" bash "${REPO_ROOT}/bin/install-user-bin.sh" || true
else
	voidwolf_log "[dry-run] install-user-bin.sh → ${PREFIX}/bin"
fi

# Ensure a line exists in a file (append once). Follows symlinks via >> to target.
ensure_source_line() {
	local file="$1" marker="$2" line="$3"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		voidwolf_log "[dry-run] ensure ${file} has: ${marker}"
		return 0
	fi
	mkdir -p "$(dirname "$file")"
	if [[ -f "$file" ]] && grep -qF "$marker" "$file" 2>/dev/null; then
		voidwolf_log "Already present (${marker}): ${file}"
		return 0
	fi
	# If file is a broken symlink or missing, create real file
	if [[ ! -e "$file" && ! -L "$file" ]]; then
		: >"$file"
	fi
	voidwolf_log "Append ${marker} → ${file}"
	{
		echo ""
		echo "${marker}"
		echo "${line}"
	} >>"$file"
}

# --- bash PATH + rc + profile (PR12) ---
if [[ "${SKIP_BASH}" -eq 0 ]]; then
	install_file \
		"${REPO_ROOT}/config/bash/voidwolf-path.sh" \
		"${TARGET_HOME}/.config/voidwolf/voidwolf-path.sh" 0644
	install_file \
		"${REPO_ROOT}/config/bash/voidwolf-rc.sh" \
		"${TARGET_HOME}/.config/voidwolf/voidwolf-rc.sh" 0644
	install_file \
		"${REPO_ROOT}/config/bash/voidwolf-profile.sh" \
		"${TARGET_HOME}/.config/voidwolf/voidwolf-profile.sh" 0644

	bashrc="${TARGET_HOME}/.bashrc"
	ensure_source_line "$bashrc" "# voidwolf PATH" \
		'[ -f "${HOME}/.config/voidwolf/voidwolf-path.sh" ] && . "${HOME}/.config/voidwolf/voidwolf-path.sh"'
	ensure_source_line "$bashrc" "# voidwolf bash rc" \
		'[ -f "${HOME}/.config/voidwolf/voidwolf-rc.sh" ] && . "${HOME}/.config/voidwolf/voidwolf-rc.sh"'

	# Login shell: prefer .bash_profile, else .profile
	bash_profile="${TARGET_HOME}/.bash_profile"
	profile="${TARGET_HOME}/.profile"
	if [[ -e "$bash_profile" || -L "$bash_profile" || ! -e "$profile" ]]; then
		ensure_source_line "$bash_profile" "# voidwolf bash profile" \
			'[ -f "${HOME}/.config/voidwolf/voidwolf-profile.sh" ] && . "${HOME}/.config/voidwolf/voidwolf-profile.sh"'
	else
		ensure_source_line "$profile" "# voidwolf bash profile" \
			'[ -f "${HOME}/.config/voidwolf/voidwolf-profile.sh" ] && . "${HOME}/.config/voidwolf/voidwolf-profile.sh"'
	fi
fi

# --- neovim (PR12): parallel config, never clobber ~/.config/nvim ---
install_nvim_tree() {
	local src="${REPO_ROOT}/config/neovim"
	local dest="${TARGET_HOME}/.config/voidwolf-nvim"
	[[ -f "${src}/init.lua" ]] || voidwolf_die "missing ${src}/init.lua"

	voidwolf_log "Install neovim config → ${dest} (NVIM_APPNAME=voidwolf-nvim)"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[dry-run] install nvim tree %s → %s\n' "$src" "$dest"
		return 0
	fi
	mkdir -p "${dest}/lua/voidwolf"
	install -m 0644 "${src}/init.lua" "${dest}/init.lua"
	# install every module under lua/voidwolf/ (options, keymaps, autocmds, colors, …)
	local f
	for f in "${src}/lua/voidwolf/"*.lua; do
		[[ -f "$f" ]] || continue
		install -m 0644 "$f" "${dest}/lua/voidwolf/$(basename "$f")"
	done
}

if [[ "${SKIP_NVIM}" -eq 0 ]]; then
	install_nvim_tree
fi

# --- PipeWire ---
if [[ "${SKIP_PIPEWIRE}" -eq 0 ]]; then
	pw_args=(--home "${TARGET_HOME}")
	[[ "${DRY_RUN}" -eq 1 ]] && pw_args+=(--dry-run)
	bash "${SCRIPT_DIR}/setup-pipewire.sh" "${pw_args[@]}"
fi

# --- dunst config (includes theme colors from voidwolf-theme PR9a) ---
dunst_src="${REPO_ROOT}/config/dunst/dunstrc"
dunst_dest="${TARGET_HOME}/.config/dunst/dunstrc"
if [[ -f "$dunst_src" ]]; then
	if [[ ! -f "$dunst_dest" ]] || ! grep -q 'voidwolf-dunst-v1' "$dunst_dest" 2>/dev/null; then
		install_file "$dunst_src" "$dunst_dest" 0644
	else
		voidwolf_log "dunst config already voidwolf-managed"
	fi
fi

voidwolf_log "Dotfiles install complete for ${TARGET_HOME}"
voidwolf_log "Next: ensure elogind session (re-login), then: startx"
voidwolf_log "Check: echo \$XDG_RUNTIME_DIR  # expect /run/user/\$(id -u)"
