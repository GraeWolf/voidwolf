
# ~/.xinitrc
# start dbus if not running
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  eval "$(dbus-launch --sh-syntax --exit-with-session)"
fi

# Required so polkit knows this is a real session
#export XDG_SESSION_TYPE=x11
#export DESKTOP_SESSION=bspwm
#export XDG_CURRENT_DESKTOP=bspwm

# start polkit agent for GUI privilege prompts
#/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# start xss-lock with xsecurelock
xss-lock --transfer-sleep-lock -- xsecurelock &

# finally, exec bspwm
exec bspwm
