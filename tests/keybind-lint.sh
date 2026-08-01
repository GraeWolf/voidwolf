#!/usr/bin/env bash
# keybind-lint — enforce voidwolf core dwm keybind policy (PR6)
# Parses suckless/dwm/config.h for required binds and forbidden collisions.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CFG="${ROOT}/suckless/dwm/config.h"
fail=0

if [[ ! -f "$CFG" ]]; then
	echo "FAIL missing $CFG"
	exit 1
fi

echo "Linting $CFG"

need_re() {
	local desc="$1" re="$2"
	if rg -q "$re" "$CFG"; then
		echo "OK   $desc"
	else
		echo "FAIL missing: $desc"
		echo "     pattern: $re"
		fail=1
	fi
}

forbid_re() {
	local desc="$1" re="$2"
	if rg -q "$re" "$CFG"; then
		echo "FAIL forbidden: $desc"
		echo "     pattern: $re"
		fail=1
	else
		echo "OK   not present: $desc"
	fi
}

# --- policy locks ---
need_re "MODKEY is Mod4Mask (Super)" \
	'^#define MODKEY Mod4Mask'

# Super+K must be cheatsheet spawn, never focusdir/focusstack
need_re "Super+K cheatsheet (spawn cheatcmd)" \
	'MODKEY,\s+XK_k,\s+spawn,.*cheatcmd|MODKEY,\s+XK_k,\s+spawn,.*voidwolf-cheatsheet|MODKEY,\s+XK_k,\s+spawn,.*\{\.v = cheatcmd'
# Also accept XK_k with cheatcmd nearby - our config uses cheatcmd
if ! rg -n 'XK_k' "$CFG" | rg -q 'spawn'; then
	echo "FAIL Super+K must spawn (cheatsheet), not focus"
	fail=1
fi
# Ensure no focusdir/focusstack on bare MODKEY XK_k
if rg -n 'MODKEY,\s+XK_k,' "$CFG" | rg -q 'focusdir|focusstack'; then
	echo "FAIL Super+K must not call focusdir/focusstack"
	fail=1
else
	echo "OK   Super+K is not focusdir/focusstack"
fi

# Super+L is focusdir right only — must be focusdir, not setlayout
need_re "Super+L focusdir" \
	'MODKEY,\s+XK_l,\s+focusdir'
if rg -n 'MODKEY,\s+XK_l,' "$CFG" | rg -q 'setlayout'; then
	echo "FAIL Super+L must not be setlayout (layout is Super+Shift+L)"
	fail=1
else
	echo "OK   Super+L is not setlayout"
fi

# Super+Shift+L is layout cycle (cyclelayout or setlayout — never focusdir)
need_re "Super+Shift+L layout cycle" \
	'MODKEY\|ShiftMask,\s+XK_l,\s+(cyclelayout|setlayout)'
if rg -n 'MODKEY\|ShiftMask,\s+XK_l,' "$CFG" | rg -q 'focusdir|movestack'; then
	echo "FAIL Super+Shift+L must not be focusdir/movestack"
	fail=1
else
	echo "OK   Super+Shift+L is not focusdir/movestack"
fi

# Core launch family
need_re "Super+Return terminal" 'MODKEY,\s+XK_Return,\s+spawn,.*termcmd'
need_re "Super+Shift+B browser" 'MODKEY\|ShiftMask,\s+XK_b,\s+spawn,.*browser'
need_re "Super+Space launcher" 'MODKEY,\s+XK_space,\s+spawn,.*launcher'
need_re "Super+Alt+Space menu" 'MODKEY\|Mod1Mask,\s+XK_space,\s+spawn,.*vwmenu'
need_re "Super+Escape system menu" 'MODKEY,\s+XK_Escape,\s+spawn,.*sysmenu'
need_re "Super+Ctrl+L lock" 'MODKEY\|ControlMask,\s+XK_l,\s+spawn,.*lockcmd'

# Client
need_re "Super+W killclient" 'MODKEY,\s+XK_w,\s+killclient'
need_re "Super+T togglefloating" 'MODKEY,\s+XK_t,\s+togglefloating'
need_re "Super+F togglefullscr" 'MODKEY,\s+XK_f,\s+togglefullscr'

# focusdir arrows + hjkl (j down, h left, l right; k reserved)
need_re "Super+H focusdir" 'MODKEY,\s+XK_h,\s+focusdir'
need_re "Super+J focusdir" 'MODKEY,\s+XK_j,\s+focusdir'
need_re "Super+Left focusdir" 'MODKEY,\s+XK_Left,\s+focusdir'
need_re "Super+Right focusdir" 'MODKEY,\s+XK_Right,\s+focusdir'
need_re "Super+Up focusdir" 'MODKEY,\s+XK_Up,\s+focusdir'
need_re "Super+Down focusdir" 'MODKEY,\s+XK_Down,\s+focusdir'

# Tags 1-9 via TAGKEYS
need_re "TAGKEYS 1" 'TAGKEYS\(\s*XK_1,'
need_re "TAGKEYS 9" 'TAGKEYS\(\s*XK_9,'

# Theme / wallpaper stubs
need_re "theme pick bind" 'themecmd|voidwolf-theme'
need_re "wallpaper pick bind" 'wallcmd|voidwolf-wallpaper'

# PR6b remainder
need_re "Super+Tab shiftview (tag cycle)" 'MODKEY,\s+XK_Tab,\s+shiftview'
need_re "Super+Shift+Tab shiftview reverse" 'MODKEY\|ShiftMask,\s+XK_Tab,\s+shiftview'
need_re "Print screenshot" 'XK_Print.*scrot|voidwolf-screenshot'
need_re "Super+Ctrl+C capture menu" 'MODKEY\|ControlMask,\s+XK_c,\s+spawn'
need_re "dunst silence Super+Ctrl+comma" 'set-paused|dunstpause'
need_re "togglebar Super+Shift+space" 'MODKEY\|ShiftMask,\s+XK_space,\s+togglebar'
need_re "focusmon Super+period" 'MODKEY,\s+XK_period,\s+focusmon'
need_re "tagmon Super+Shift+period" 'MODKEY\|ShiftMask,\s+XK_period,\s+tagmon'
need_re "setmfact Super+equal" 'MODKEY,\s+XK_equal,\s+setmfact'

# Commands array must reference helpers
for cmd in termcmd browser launcher vwmenu sysmenu lockcmd cheatcmd; do
	need_re "command $cmd defined" "static const char \*${cmd}\["
done

# No stock Mod1 as MODKEY
forbid_re "MODKEY must not be Mod1Mask" '^#define MODKEY Mod1Mask'

# PR11 media / brightness
need_re "XF86 AudioRaiseVolume" 'XF86XK_AudioRaiseVolume'
need_re "XF86 AudioLowerVolume" 'XF86XK_AudioLowerVolume'
need_re "XF86 AudioMute" 'XF86XK_AudioMute'
need_re "XF86 MonBrightnessUp" 'XF86XK_MonBrightnessUp'
need_re "XF86 MonBrightnessDown" 'XF86XK_MonBrightnessDown'
need_re "volume helper commands" 'voidwolf-volume'
need_re "brightness helper commands" 'voidwolf-brightness'
need_re "XF86keysym include" 'XF86keysym'

# PR13b
need_re "Super+S scratchpad" 'MODKEY,\s+XK_s,\s+togglescratch'
need_re "Super+O sticky" 'MODKEY,\s+XK_o,\s+togglesticky'
need_re "Super+G togglegaps" 'MODKEY,\s+XK_g,\s+togglegaps'
need_re "Super+Shift+G defaultgaps" 'MODKEY\|ShiftMask,\s+XK_g,\s+defaultgaps'
need_re "vanitygaps include" 'vanitygaps\.c'
need_re "scratchpadcmd defined" 'scratchpadcmd'
need_re "attachaside present in tree" 'attachaside'

# attachaside lives in dwm.c
if rg -q 'attachaside' "${ROOT}/suckless/dwm/dwm.c"; then
	echo "OK   attachaside in dwm.c"
else
	echo "FAIL attachaside missing from dwm.c"
	fail=1
fi

if [[ "$fail" -ne 0 ]]; then
	echo "keybind-lint: FAILED"
	exit 1
fi
echo "keybind-lint: all OK (PR6 + PR11 + PR13b policy)"
