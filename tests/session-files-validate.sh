#!/usr/bin/env bash
# Validate PR5 session files exist and .xinitrc has required patterns.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0

need() {
	if [[ -f "$1" ]]; then
		echo "OK   $1"
	else
		echo "FAIL missing $1"
		fail=1
	fi
}

need "${ROOT}/config/X11/.xinitrc"
need "${ROOT}/config/X11/.Xresources"
need "${ROOT}/bootstrap/setup-pipewire.sh"
need "${ROOT}/bootstrap/install-dotfiles.sh"
need "${ROOT}/bin/voidwolf-status"
need "${ROOT}/docs/session.md"

xinit="${ROOT}/config/X11/.xinitrc"
for pat in 'refusing to start X session as root' 'pipewire &' 'while true' 'dwm' 'voidwolf-status' 'XDG_RUNTIME_DIR' 'dbus' 'voidwolf-displays restore' 'gtk.env'; do
	if grep -qF "$pat" "$xinit"; then
		echo "OK   .xinitrc contains: $pat"
	else
		echo "FAIL .xinitrc missing: $pat"
		fail=1
	fi
done

# Clean quit must end X (dwm && break), not restart (dwm || break)
if grep -qE 'dwm[[:space:]]+&&[[:space:]]+break' "$xinit"; then
	echo "OK   .xinitrc clean-quit loop (dwm && break)"
else
	echo "FAIL .xinitrc must use 'dwm && break' so Super+Shift+Q ends the session"
	fail=1
fi
if grep -vE '^[[:space:]]*#' "$xinit" | grep -qE 'dwm[[:space:]]+\|\|[[:space:]]+break'; then
	echo "FAIL .xinitrc must not use 'dwm || break' (restarts on clean quit)"
	fail=1
fi

# Must not start wireplumber/pipewire-pulse as siblings
if grep -E '^\s*(wireplumber|pipewire-pulse)\s+&' "$xinit"; then
	echo "FAIL .xinitrc must not start wireplumber/pipewire-pulse as siblings"
	fail=1
else
	echo "OK   .xinitrc does not double-start pipewire children"
fi

if [[ -x "${ROOT}/bootstrap/setup-pipewire.sh" && -x "${ROOT}/bootstrap/install-dotfiles.sh" && -x "${ROOT}/bin/voidwolf-status" ]]; then
	echo "OK   session scripts executable"
else
	echo "FAIL session scripts not executable"
	fail=1
fi

# dry-run install should work without root
if bash "${ROOT}/bootstrap/install-dotfiles.sh" --dry-run --home /tmp/voidwolf-dot-test.$$ >/dev/null 2>&1; then
	echo "OK   install-dotfiles.sh --dry-run"
else
	echo "FAIL install-dotfiles.sh --dry-run"
	fail=1
fi

if [[ "$fail" -ne 0 ]]; then
	echo "session-files-validate: FAILED"
	exit 1
fi
echo "session-files-validate: all OK"
