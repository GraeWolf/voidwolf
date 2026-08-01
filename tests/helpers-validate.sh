#!/usr/bin/env bash
# Validate PR7 helper scripts exist, are executable, and have basic usage.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${ROOT}/bin"
fail=0

required=(
	voidwolf-dmenu
	voidwolf-launcher
	voidwolf-menu
	voidwolf-system-menu
	voidwolf-lock
	voidwolf-screenshot
	voidwolf-cheatsheet
	voidwolf-browser
	voidwolf-filemanager
	voidwolf-clipboard
	voidwolf-audio-tui
	voidwolf-bluetooth-tui
	voidwolf-wifi-tui
	voidwolf-float-term
	voidwolf-status
	voidwolf-wallpaper
	voidwolf-theme
	voidwolf-gpu-check
	voidwolf-prime
	voidwolf-volume
	voidwolf-brightness
	voidwolf-dogfood-check
	voidwolf-displays
	voidwolf-about
	install-user-bin.sh
)

for s in "${required[@]}"; do
	path="${BIN}/${s}"
	if [[ ! -f "$path" ]]; then
		echo "FAIL missing $path"
		fail=1
		continue
	fi
	if [[ ! -x "$path" ]]; then
		echo "FAIL not executable $path"
		fail=1
		continue
	fi
	echo "OK   $s"
done

# system menu must mention lock-then-suspend path
if rg -q 'Lock & suspend' "${BIN}/voidwolf-system-menu"; then
	echo "OK   system-menu has Lock & suspend"
else
	echo "FAIL system-menu missing Lock & suspend"
	fail=1
fi

# lock refuses root
if rg -q 'refusing to lock as root' "${BIN}/voidwolf-lock"; then
	echo "OK   lock refuses root"
else
	echo "FAIL lock should refuse root"
	fail=1
fi

# screenshot modes
if rg -q 'do_full|do_region|do_window|do_menu' "${BIN}/voidwolf-screenshot"; then
	echo "OK   screenshot modes"
else
	echo "FAIL screenshot modes incomplete"
	fail=1
fi

# launcher uses dmenu_run
if rg -q 'dmenu_run' "${BIN}/voidwolf-launcher"; then
	echo "OK   launcher uses dmenu_run"
else
	echo "FAIL launcher should use dmenu_run"
	fail=1
fi

# browser resolves multiple Brave binary names (dogfood: brave-origin-nightly)
if rg -q 'brave-origin-nightly' "${BIN}/voidwolf-browser"; then
	echo "OK   browser knows brave-origin-nightly"
else
	echo "FAIL voidwolf-browser should resolve brave-origin-nightly"
	fail=1
fi

# TUI float helper
if rg -q 'voidwolf-tui' "${BIN}/voidwolf-float-term"; then
	echo "OK   float-term titles voidwolf-tui"
else
	echo "FAIL voidwolf-float-term should set voidwolf-tui title"
	fail=1
fi

# file manager prefers Nemo
if rg -q 'nemo' "${BIN}/voidwolf-filemanager"; then
	echo "OK   filemanager prefers nemo"
else
	echo "FAIL voidwolf-filemanager should prefer nemo"
	fail=1
fi

# cheatsheet searchable (fzf/dmenu) not raw markdown pager only
if rg -q 'fzf' "${BIN}/voidwolf-cheatsheet" && rg -q 'Super\+Return' "${BIN}/voidwolf-cheatsheet"; then
	echo "OK   cheatsheet fzf + human key list"
else
	echo "FAIL voidwolf-cheatsheet should use fzf and simple key list"
	fail=1
fi

# volume / brightness usage strings
if rg -q 'wpctl' "${BIN}/voidwolf-volume"; then
	echo "OK   volume uses wpctl"
else
	echo "FAIL voidwolf-volume should use wpctl"
	fail=1
fi
if rg -q 'brightnessctl' "${BIN}/voidwolf-brightness"; then
	echo "OK   brightness prefers brightnessctl"
else
	echo "FAIL voidwolf-brightness should prefer brightnessctl"
	fail=1
fi

if rg -q 'Displays' "${BIN}/voidwolf-menu"; then
	echo "OK   menu has Displays entry"
else
	echo "FAIL voidwolf-menu should list Displays"
	fail=1
fi

need_docs="${ROOT}/docs/helpers.md"
if [[ -f "$need_docs" ]]; then
	echo "OK   docs/helpers.md"
else
	echo "FAIL missing docs/helpers.md"
	fail=1
fi

if [[ "$fail" -ne 0 ]]; then
	echo "helpers-validate: FAILED"
	exit 1
fi
echo "helpers-validate: all OK"
