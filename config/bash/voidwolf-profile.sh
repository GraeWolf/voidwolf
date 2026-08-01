# voidwolf login-shell snippet (PR12)
# Sourced from ~/.bash_profile / ~/.profile. Marker: voidwolf-bash-profile-v1
#
# Does NOT re-source ~/.bashrc (your profile usually already does that).
# Ensures voidwolf snippets exist for minimal login profiles, then optional startx.

# Ensure PATH + interactive defaults even if bashrc was not loaded yet
if [[ -f "${HOME}/.config/voidwolf/voidwolf-path.sh" ]]; then
	# shellcheck disable=SC1091
	. "${HOME}/.config/voidwolf/voidwolf-path.sh"
fi
if [[ -f "${HOME}/.config/voidwolf/voidwolf-rc.sh" ]]; then
	# shellcheck disable=SC1091
	. "${HOME}/.config/voidwolf/voidwolf-rc.sh"
fi

# --- optional auto-startx on tty1 (DEFAULT OFF) ---
# Uncomment to start X on first VT login only:
#
# if [ -z "${DISPLAY:-}" ] && [ "$(tty)" = /dev/tty1 ]; then
#   exec startx
# fi
