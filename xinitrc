#!/bin/sh

# === Source system xinitrc.d scripts FIRST (critical for proper D-Bus) ===
if [ -d /etc/X11/xinit/xinitrc.d ]; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

# Your XDG session exports (good — keep these)
export XDG_SESSION_TYPE=x11
export DESKTOP_SESSION=bspwm
export XDG_CURRENT_DESKTOP=bspwm

# Update D-Bus activation environment so graphical components (keyring, polkit, etc.) work
dbus-update-activation-environment --all

# GNOME Keyring — now started after proper D-Bus setup
eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
export SSH_AUTH_SOCK

# start polkit agent for GUI privilege prompts
/usr/libexec/polkit-gnome-authentication-agent-1 &

# starting pipewire
/usr/bin/pipewire &
# /usr/bin/pipewire-pulse &
# /usr/bin/wireplumber &

# start xss-lock with xsecurelock
xss-lock --transfer-sleep-lock -- xsecurelock &

# Restore display settings after resume
xrandr --auto &

# finally, exec bspwm
exec bspwm
