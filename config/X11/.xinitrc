#!/bin/sh
# voidwolf X session — startx entrypoint
# Owns: root refuse, session D-Bus, xrdb, pipewire (conf.d), dunst, status, dwm loop
# See docs/session.md and docs/design.md

export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=voidwolf

# Prefer user-local suckless + helpers
export PATH="${HOME}/.local/bin:${PATH}"

# Safety: never start graphical session as root
if [ "$(id -u)" -eq 0 ]; then
	echo "voidwolf: refusing to start X session as root" >&2
	exit 1
fi

# elogind should set XDG_RUNTIME_DIR on login; warn loudly if missing
if [ -z "${XDG_RUNTIME_DIR:-}" ]; then
	echo "voidwolf: XDG_RUNTIME_DIR is unset — re-login after enabling elogind" >&2
	echo "voidwolf: expected /run/user/$(id -u)" >&2
fi

# Session D-Bus (Void bare-WM pattern)
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
	if command -v dbus-launch >/dev/null 2>&1; then
		eval "$(dbus-launch --sh-syntax --exit-with-session)"
	fi
fi
# Export X vars for activation (ignore failure if no --systemd support)
if command -v dbus-update-activation-environment >/dev/null 2>&1; then
	dbus-update-activation-environment --all 2>/dev/null \
		|| dbus-update-activation-environment DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP 2>/dev/null \
		|| true
fi

# Xresources: base + generated theme (PR8)
[ -f "${HOME}/.Xresources" ] && xrdb -merge "${HOME}/.Xresources"
[ -f "${HOME}/.config/voidwolf/generated/theme.Xresources" ] \
	&& xrdb -merge "${HOME}/.config/voidwolf/generated/theme.Xresources"

# Cursor theme from voidwolf-theme (PR9a)
if [ -f "${HOME}/.config/voidwolf/generated/xcursor.env" ]; then
	# shellcheck disable=SC1091
	. "${HOME}/.config/voidwolf/generated/xcursor.env"
fi

# GTK dark theme env (Yaru-dark on Void; helps Brave/file choosers)
if [ -f "${HOME}/.config/voidwolf/gtk.env" ]; then
	# shellcheck disable=SC1091
	. "${HOME}/.config/voidwolf/gtk.env"
elif [ -f "${HOME}/.config/voidwolf/generated/gtk.env" ]; then
	# shellcheck disable=SC1091
	. "${HOME}/.config/voidwolf/generated/gtk.env"
fi

# Keyboard (optional user override)
[ -f "${HOME}/.config/voidwolf/xkb" ] && . "${HOME}/.config/voidwolf/xkb"

# XDG user directories (Desktop, Documents, Pictures, …)
if command -v xdg-user-dirs-update >/dev/null 2>&1; then
	xdg-user-dirs-update
fi

# PipeWire only — wireplumber + pipewire-pulse via conf.d (setup-pipewire.sh)
if command -v pipewire >/dev/null 2>&1; then
	pipewire &
fi

# Notifications
command -v dunst >/dev/null 2>&1 && dunst &

# Idle lock: MIT-SCREEN-SAVER → voidwolf-lock (xss-lock)
# Timeout: 5 minutes blank, then lock. Override with ~/.config/voidwolf/xidle
if [ -f "${HOME}/.config/voidwolf/xidle" ]; then
	# shellcheck disable=SC1091
	. "${HOME}/.config/voidwolf/xidle"
else
	# xset s <timeout> <cycle> — blank after 300s
	xset s 300 300 2>/dev/null || true
	# DPMS: standby/suspend/off (seconds)
	xset dpms 600 600 900 2>/dev/null || true
fi
if command -v xss-lock >/dev/null 2>&1 && command -v voidwolf-lock >/dev/null 2>&1; then
	xss-lock --transfer-sleep-lock -- voidwolf-lock &
fi

# Status bar → xsetroot -name
command -v voidwolf-status >/dev/null 2>&1 && voidwolf-status &

# Multi-monitor layout (before wallpaper so feh sizes correctly)
# Uses ~/.config/voidwolf/displays/default.sh or last applied preset
command -v voidwolf-displays >/dev/null 2>&1 && voidwolf-displays restore

# Wallpaper (after displays so background covers full virtual screen)
command -v voidwolf-wallpaper >/dev/null 2>&1 && voidwolf-wallpaper restore &

# Compositor (light config from install-dotfiles → ~/.config/picom/picom.conf)
if command -v picom >/dev/null 2>&1; then
	if [ -f "${HOME}/.config/picom/picom.conf" ]; then
		picom --config "${HOME}/.config/picom/picom.conf" -b
	else
		picom -b
	fi
fi

# dwm loop:
#   exit 0  (Super+Shift+Q / clean logout) → break → end X session
#   non-zero (crash) → restart dwm, keep X alive
# Theme rebuild uses restartsig (SIGHUP / Super+Ctrl+Shift+Q) which exec's
# inside dwm and never returns here. Inverted shell logic (OR-break on dwm)
# restarts after a clean quit and looks like Super+Shift+Q "does nothing".
while true; do
	if command -v dwm >/dev/null 2>&1; then
		dwm && break
	else
		echo "voidwolf: dwm not found on PATH (run ./bootstrap/build-suckless.sh)" >&2
		break
	fi
done
