#!/usr/bin/env bash
# Validate PR13 displays + TUI polish.
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

need_x() {
	if [[ -x "$1" ]]; then
		echo "OK   executable $(basename "$1")"
	else
		echo "FAIL not executable $1"
		fail=1
	fi
}

need_pat() {
	local file="$1" pat="$2" desc="$3"
	if rg -q "$pat" "$file"; then
		echo "OK   $desc"
	else
		echo "FAIL $desc"
		fail=1
	fi
}

need "${ROOT}/bin/voidwolf-displays"
need "${ROOT}/bin/voidwolf-about"
need "${ROOT}/docs/displays.md"
need "${ROOT}/config/displays/README.md"
need "${ROOT}/config/displays/examples/primary-only.sh.example"
need "${ROOT}/config/displays/examples/dual-right.sh.example"
need "${ROOT}/config/displays/examples/mirror.sh.example"
need "${ROOT}/config/X11/dpi-96.Xresources"
need "${ROOT}/config/X11/dpi-120.Xresources"
need "${ROOT}/config/X11/dpi-144.Xresources"

need_x "${ROOT}/bin/voidwolf-displays"
need_x "${ROOT}/bin/voidwolf-about"
need_x "${ROOT}/bin/voidwolf-audio-tui"
need_x "${ROOT}/bin/voidwolf-bluetooth-tui"
need_x "${ROOT}/bin/voidwolf-wifi-tui"
need_x "${ROOT}/bin/voidwolf-menu"

need_pat "${ROOT}/bin/voidwolf-menu" 'Displays' "menu has Displays"
need_pat "${ROOT}/bin/voidwolf-menu" 'About' "menu has About"
need_pat "${ROOT}/bin/voidwolf-menu" 'voidwolf-displays' "menu calls voidwolf-displays"
need_pat "${ROOT}/bin/voidwolf-audio-tui" 'voidwolf-volume|pulsemixer|wpctl' "audio TUI fallbacks"
need_pat "${ROOT}/bin/voidwolf-bluetooth-tui" 'bluetuith|bluetoothctl' "bt TUI fallbacks"
need_pat "${ROOT}/bin/voidwolf-wifi-tui" 'nmtui|nmcli' "wifi TUI fallbacks"
need_pat "${ROOT}/bin/voidwolf-displays" 'xrandr' "displays uses xrandr"
need_pat "${ROOT}/bin/voidwolf-displays" 'VOIDWOLF_HOME|displays' "displays looks in VOIDWOLF_HOME"
need_pat "${ROOT}/docs/displays.md" 'HiDPI|Xft.dpi' "docs mention HiDPI"
need_pat "${ROOT}/bootstrap/install-dotfiles.sh" 'displays' "install-dotfiles creates displays dir"
need_pat "${ROOT}/bootstrap/packages-desktop-optional.txt" 'arandr' "optional arandr"

# help / list without DISPLAY ok
if bash "${ROOT}/bin/voidwolf-displays" help >/dev/null; then
	echo "OK   voidwolf-displays help"
else
	echo "FAIL voidwolf-displays help"
	fail=1
fi

if bash "${ROOT}/bin/voidwolf-about" --stdout >/dev/null; then
	echo "OK   voidwolf-about --stdout"
else
	echo "FAIL voidwolf-about --stdout"
	fail=1
fi

# example scripts are valid shell
for f in "${ROOT}/config/displays/examples"/*.example; do
	if sh -n "$f" 2>/dev/null; then
		echo "OK   shell syntax $(basename "$f")"
	else
		echo "FAIL shell syntax $f"
		fail=1
	fi
done

if [[ "$fail" -ne 0 ]]; then
	echo "displays-tui-validate: FAILED"
	exit 1
fi
echo "displays-tui-validate: all OK"
