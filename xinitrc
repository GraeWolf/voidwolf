
# ~/.xinitrc
# start dbus if not running
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  eval "$(dbus-launch --sh-syntax --exit-with-session)"
fi

# Required so polkit knows this is a real session
export XDG_SESSION_TYPE=x11
export DESKTOP_SESSION=bspwm
export XDG_CURRENT_DESKTOP=bspwm

# start polkit agent for GUI privilege prompts
/usr/libexec/polkit-gnome-authentication-agent-1 &

# GNOME Keyring
eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
export SSH_AUTH_SOCK
export GNOME_KEYRING_CONTROL=$(echo $GNOME_KEYRING_CONTROL)

# start xss-lock with xsecurelock
xss-lock --transfer-sleep-lock -- xsecurelock &

# Restore display settings after resume
xrandr --auto &

# finally, exec bspwm
exec bspwm
