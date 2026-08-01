#!/usr/bin/env bash
# voidwolf — enable runit services, groups, sudoers, ufw (PR3)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

DRY_RUN=0
SKIP_UFW=0
SKIP_SUDOERS=0
PROFILE=""
TARGET_USER="${VOIDWOLF_TARGET_USER:-}"

# Runit service directory names on Void
SERVICES=(
	dbus
	elogind
	NetworkManager
	bluetoothd
	polkitd
	ufw
)

# Groups for a typical desktop user
USER_GROUPS=(
	wheel
	network
	bluetooth
	video
	audio
	input
	storage
)

usage() {
	cat <<'EOF'
Usage: enable-services.sh [options]

Enable voidwolf system services (runit), install wheel sudoers, configure ufw,
and add the target user to desktop groups.

Options:
  --profile desktop|laptop  Laptop enables tlp when present (PR11)
  --user NAME     Target user for groups (default: SUDO_USER or VOIDWOLF_TARGET_USER or $USER if not root)
  --skip-ufw      Do not enable/configure ufw
  --skip-sudoers  Do not install voidwolf-wheel sudoers drop-in
  --dry-run
  -h, --help
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--profile) PROFILE="${2:-}"; shift ;;
		--user) TARGET_USER="${2:-}"; shift ;;
		--skip-ufw) SKIP_UFW=1 ;;
		--skip-sudoers) SKIP_SUDOERS=1 ;;
		--dry-run) DRY_RUN=1 ;;
		-h|--help) usage; exit 0 ;;
		*) voidwolf_die "unknown option: $1" ;;
	esac
	shift
done

export DRY_RUN

resolve_target_user() {
	if [[ -n "${TARGET_USER}" ]]; then
		printf '%s\n' "${TARGET_USER}"
		return
	fi
	if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
		printf '%s\n' "${SUDO_USER}"
		return
	fi
	if [[ "${EUID}" -ne 0 && -n "${USER:-}" && "${USER}" != "root" ]]; then
		printf '%s\n' "${USER}"
		return
	fi
	printf '\n'
}

enable_sv() {
	local name="$1"
	local src="/etc/sv/${name}"
	local dst="/var/service/${name}"

	if [[ ! -d "$src" ]]; then
		voidwolf_warn "runit service not present (package missing?): ${src}"
		return 0
	fi
	if [[ -e "$dst" || -L "$dst" ]]; then
		voidwolf_log "Service already enabled: ${name}"
		return 0
	fi
	voidwolf_log "Enable service: ${name}"
	voidwolf_run_as_root ln -s "$src" "$dst"
}

install_sudoers() {
	local src="${SCRIPT_DIR}/sudoers.d/voidwolf-wheel"
	local dest="/etc/sudoers.d/voidwolf-wheel"
	[[ -f "$src" ]] || voidwolf_die "missing ${src}"

	voidwolf_log "Install sudoers drop-in → ${dest}"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[dry-run] install %s → %s (0440)\n' "$src" "$dest"
		if command -v visudo >/dev/null 2>&1; then
			visudo -cf "$src" || voidwolf_die "visudo -cf failed on ${src}"
			voidwolf_log "visudo syntax OK (source file)"
		fi
		return 0
	fi

	# Validate source before install
	if command -v visudo >/dev/null 2>&1; then
		visudo -cf "$src" || voidwolf_die "visudo rejected ${src}"
	fi

	voidwolf_run_as_root install -m 0440 -o root -g root "$src" "$dest"
	if command -v visudo >/dev/null 2>&1; then
		voidwolf_run_as_root visudo -cf "$dest" || {
			voidwolf_run_as_root rm -f "$dest"
			voidwolf_die "visudo rejected installed ${dest}; removed"
		}
	fi
}

configure_ufw() {
	voidwolf_log "Configure ufw: default deny incoming, allow outgoing; --force enable"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[dry-run] ufw default deny incoming\n'
		printf '[dry-run] ufw default allow outgoing\n'
		printf '[dry-run] ufw --force enable\n'
		return 0
	fi
	if ! command -v ufw >/dev/null 2>&1; then
		voidwolf_warn "ufw not installed; skip firewall"
		return 0
	fi
	voidwolf_run_as_root ufw default deny incoming
	voidwolf_run_as_root ufw default allow outgoing
	voidwolf_run_as_root ufw --force enable
}

add_user_groups() {
	local user="$1"
	local g
	if ! id "$user" >/dev/null 2>&1; then
		voidwolf_warn "user ${user} does not exist; skip groups"
		return 0
	fi
	for g in "${USER_GROUPS[@]}"; do
		if getent group "$g" >/dev/null 2>&1; then
			voidwolf_log "Add ${user} to group ${g}"
			voidwolf_run_as_root usermod -aG "$g" "$user" || \
				voidwolf_warn "usermod failed for group ${g}"
		else
			voidwolf_warn "group ${g} does not exist; skipping"
		fi
	done
}

# --- main ---
voidwolf_log "Enable services / sudoers / ufw / groups"

for svc in "${SERVICES[@]}"; do
	if [[ "${SKIP_UFW}" -eq 1 && "${svc}" == "ufw" ]]; then
		continue
	fi
	enable_sv "$svc"
done

# PR11: laptop power management (optional package)
if [[ "${PROFILE}" == "laptop" ]]; then
	if [[ -d /etc/sv/tlp ]]; then
		enable_sv tlp
	else
		voidwolf_log "tlp service not installed yet (packages-laptop / brightnessctl + tlp)"
	fi
fi

if [[ "${SKIP_SUDOERS}" -eq 0 ]]; then
	install_sudoers
else
	voidwolf_log "Skipping sudoers"
fi

if [[ "${SKIP_UFW}" -eq 0 ]]; then
	configure_ufw
else
	voidwolf_log "Skipping ufw"
fi

tu="$(resolve_target_user)"
if [[ -n "$tu" ]]; then
	add_user_groups "$tu"
	voidwolf_log "Target user: ${tu} (re-login for group membership)"
else
	voidwolf_warn "No target user resolved; skip group membership.
Set --user NAME or run via sudo from a login user."
fi

voidwolf_log "Services / security baseline complete."
if [[ "${DRY_RUN}" -eq 0 ]]; then
	voidwolf_log "Check: sv status dbus elogind NetworkManager bluetoothd polkitd ufw"
fi
