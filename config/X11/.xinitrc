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

# Keyboard (optional user override)
[ -f "${HOME}/.config/voidwolf/xkb" ] && . "${HOME}/.config/voidwolf/xkb"

# PipeWire only — wireplumber + pipewire-pulse via conf.d (setup-pipewire.sh)
if command -v pipewire >/dev/null 2>&1; then
	pipewire &
fi

# Notifications
command -v dunst >/dev/null 2>&1 && dunst &

# Status bar → xsetroot -name
command -v voidwolf-status >/dev/null 2>&1 && voidwolf-status &

# Wallpaper (no-op stub until themes ship assets)
command -v voidwolf-wallpaper >/dev/null 2>&1 && voidwolf-wallpaper restore &

# Optional compositor (default OFF — design)
# command -v picom >/dev/null 2>&1 && picom -b

# dwm loop: re-exec (restartsig / theme rebuild) continues; hard failure ends X
while true; do
	if command -v dwm >/dev/null 2>&1; then
		dwm || break
	else
		echo "voidwolf: dwm not found on PATH (run ./bootstrap/build-suckless.sh)" >&2
		break
	fi
done
