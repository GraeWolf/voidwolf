#!/usr/bin/env bash
# voidwolf — PipeWire handbook conf.d + ALSA drop-in (PR5)
# Creates user-level conf so `pipewire` alone starts WirePlumber + pipewire-pulse.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

DRY_RUN=0
TARGET_HOME="${HOME}"

usage() {
	cat <<'EOF'
Usage: setup-pipewire.sh [options]

Options:
  --home DIR   Target home (default: $HOME)
  --dry-run
  -h, --help
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--home) TARGET_HOME="${2:-}"; shift ;;
		--dry-run) DRY_RUN=1 ;;
		-h|--help) usage; exit 0 ;;
		*) voidwolf_die "unknown option: $1" ;;
	esac
	shift
done

export DRY_RUN

find_example() {
	local name="$1"
	local p
	local candidates=(
		"/usr/share/examples/pipewire/${name}"
		"/usr/share/examples/wireplumber/${name}"
		"/usr/share/pipewire/${name}"
		"/usr/share/wireplumber/${name}"
	)
	for p in "${candidates[@]}"; do
		if [[ -f "$p" ]]; then
			printf '%s\n' "$p"
			return 0
		fi
	done
	return 1
}

link_user_conf() {
	local src="$1" dest="$2"
	voidwolf_log "Link ${dest} → ${src}"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[dry-run] ln -sfn %s %s\n' "$src" "$dest"
		return 0
	fi
	mkdir -p "$(dirname "$dest")"
	ln -sfn "$src" "$dest"
}

CONF_D="${TARGET_HOME}/.config/pipewire/pipewire.conf.d"
WP_NAME="10-wireplumber.conf"
PULSE_NAME="20-pipewire-pulse.conf"

WP_SRC="$(find_example "${WP_NAME}" || true)"
# pulse example is under pipewire examples on Void
PULSE_SRC="$(find_example "${PULSE_NAME}" || true)"
# also try explicit known Void paths
[[ -z "${WP_SRC}" && -f /usr/share/examples/wireplumber/10-wireplumber.conf ]] \
	&& WP_SRC=/usr/share/examples/wireplumber/10-wireplumber.conf
[[ -z "${PULSE_SRC}" && -f /usr/share/examples/pipewire/20-pipewire-pulse.conf ]] \
	&& PULSE_SRC=/usr/share/examples/pipewire/20-pipewire-pulse.conf

if [[ -z "${WP_SRC}" ]]; then
	voidwolf_warn "could not find ${WP_NAME} example; install wireplumber package"
else
	link_user_conf "${WP_SRC}" "${CONF_D}/${WP_NAME}"
fi

if [[ -z "${PULSE_SRC}" ]]; then
	voidwolf_warn "could not find ${PULSE_NAME} example; install pipewire package"
else
	link_user_conf "${PULSE_SRC}" "${CONF_D}/${PULSE_NAME}"
fi

# ALSA → PipeWire drop-in (system-wide examples; user link when possible)
# Void ships /usr/share/alsa/alsa.conf.d/50-pipewire.conf and 99-pipewire-default.conf
ALSA_USER="${TARGET_HOME}/.asoundrc"
if [[ ! -f "${ALSA_USER}" ]] && [[ ! -f "${TARGET_HOME}/.config/alsa/asoundrc" ]]; then
	voidwolf_log "ALSA: system alsa-pipewire conf.d should apply when package installed"
	voidwolf_log "  (see /usr/share/alsa/alsa.conf.d/*pipewire*)"
else
	voidwolf_log "ALSA: user asoundrc already present — leaving alone"
fi

voidwolf_log "PipeWire setup complete for ${TARGET_HOME}"
voidwolf_log "Session starts only: pipewire &  (do not start wireplumber/pipewire-pulse separately)"
if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
	voidwolf_log "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}"
else
	voidwolf_warn "XDG_RUNTIME_DIR unset in this shell — re-login after elogind enable"
fi
