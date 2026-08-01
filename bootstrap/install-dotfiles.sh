#!/usr/bin/env bash
# voidwolf — install session dotfiles (PR5)
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

usage() {
	cat <<'EOF'
Usage: install-dotfiles.sh [options]

Install voidwolf session files into the target home directory:
  ~/.xinitrc, ~/.Xresources, PATH snippet, PipeWire conf.d, helpers

Options:
  --home DIR       Target home (default: $HOME)
  --skip-pipewire  Do not run setup-pipewire.sh
  --skip-bash      Do not touch bashrc / path snippet
  --dry-run
  -h, --help
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--home) TARGET_HOME="${2:-}"; shift ;;
		--skip-pipewire) SKIP_PIPEWIRE=1 ;;
		--skip-bash) SKIP_BASH=1 ;;
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
else
	printf '[dry-run] mkdir voidwolf config dirs under %s\n' "${TARGET_HOME}/.config/voidwolf"
fi

# --- helpers + suckless on PATH target ---
if [[ "${DRY_RUN}" -eq 0 ]]; then
	PREFIX="${PREFIX}" bash "${REPO_ROOT}/bin/install-user-bin.sh" || true
else
	voidwolf_log "[dry-run] install-user-bin.sh → ${PREFIX}/bin"
fi

# --- bash PATH ---
if [[ "${SKIP_BASH}" -eq 0 ]]; then
	path_snippet="${REPO_ROOT}/config/bash/voidwolf-path.sh"
	dest_snippet="${TARGET_HOME}/.config/voidwolf/voidwolf-path.sh"
	install_file "$path_snippet" "$dest_snippet" 0644

	bashrc="${TARGET_HOME}/.bashrc"
	marker="# voidwolf PATH"
	line="[ -f \"\${HOME}/.config/voidwolf/voidwolf-path.sh\" ] && . \"\${HOME}/.config/voidwolf/voidwolf-path.sh\""
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		voidwolf_log "[dry-run] ensure bashrc sources voidwolf-path.sh"
	else
		if [[ -f "$bashrc" ]] && grep -qF "voidwolf-path.sh" "$bashrc" 2>/dev/null; then
			voidwolf_log "bashrc already sources voidwolf-path"
		else
			voidwolf_log "Append PATH source to ${bashrc}"
			{
				echo ""
				echo "${marker}"
				echo "${line}"
			} >>"$bashrc"
		fi
	fi
fi

# --- PipeWire ---
if [[ "${SKIP_PIPEWIRE}" -eq 0 ]]; then
	pw_args=(--home "${TARGET_HOME}")
	[[ "${DRY_RUN}" -eq 1 ]] && pw_args+=(--dry-run)
	bash "${SCRIPT_DIR}/setup-pipewire.sh" "${pw_args[@]}"
fi

# --- dunst minimal config if missing ---
dunst_dir="${TARGET_HOME}/.config/dunst"
if [[ ! -f "${dunst_dir}/dunstrc" ]]; then
	voidwolf_log "Install minimal dunst config"
	if [[ "${DRY_RUN}" -eq 0 ]]; then
		mkdir -p "$dunst_dir"
		cat >"${dunst_dir}/dunstrc" <<'EOF'
[global]
    font = Fira Code 11
    frame_width = 2
    padding = 8
    horizontal_padding = 8
    separator_height = 2
    sort = yes
    idle_threshold = 120
    alignment = left
    word_wrap = yes

[urgency_low]
    background = "#1d2021"
    foreground = "#ebdbb2"
    timeout = 5

[urgency_normal]
    background = "#1d2021"
    foreground = "#ebdbb2"
    frame_color = "#458588"
    timeout = 10

[urgency_critical]
    background = "#1d2021"
    foreground = "#fb4934"
    frame_color = "#cc241d"
    timeout = 0
EOF
	fi
fi

voidwolf_log "Dotfiles install complete for ${TARGET_HOME}"
voidwolf_log "Next: ensure elogind session (re-login), then: startx"
voidwolf_log "Check: echo \$XDG_RUNTIME_DIR  # expect /run/user/\$(id -u)"
