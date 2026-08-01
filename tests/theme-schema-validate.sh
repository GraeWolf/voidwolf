#!/usr/bin/env bash
# Validate shipped themes and voidwolf-theme CLI (PR8).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export VOIDWOLF_ROOT="$ROOT"
export PATH="$ROOT/bin:$PATH"
THEME="$ROOT/bin/voidwolf-theme"
fail=0

if [[ ! -x "$THEME" ]]; then
	echo "FAIL voidwolf-theme not executable"
	exit 1
fi

# schema validate all
if ! "$THEME" validate; then
	echo "FAIL voidwolf-theme validate"
	fail=1
else
	echo "OK   voidwolf-theme validate"
fi

# list non-empty
n=$("$THEME" list | wc -l)
if [[ "$n" -lt 5 ]]; then
	echo "FAIL expected >=5 themes, got $n"
	fail=1
else
	echo "OK   list ($n themes)"
fi

# wallpaper assets (PR8 default + PR14 presets)
if [[ -f "$ROOT/wallpapers/voidwolf-default.png" ]]; then
	echo "OK   default wallpaper png"
else
	echo "FAIL missing wallpapers/voidwolf-default.png"
	fail=1
fi
for w in gruvbox catppuccin-mocha nord rose-pine; do
	if [[ -f "$ROOT/wallpapers/${w}.png" ]]; then
		echo "OK   wallpaper ${w}.png"
	else
		echo "FAIL missing wallpapers/${w}.png"
		fail=1
	fi
done
# each preset theme wallpaper field resolves to an existing file
for t in gruvbox catppuccin-mocha nord rose-pine voidwolf-dark; do
	rel=$(rg -o 'wallpaper\s*=\s*"[^"]+"' "$ROOT/themes/${t}.toml" | head -1 | sed 's/.*"\(.*\)"/\1/')
	if [[ -n "$rel" && -f "$ROOT/$rel" ]]; then
		echo "OK   theme $t wallpaper → $rel"
	else
		echo "FAIL theme $t wallpaper missing or unreadable (got: ${rel:-empty})"
		fail=1
	fi
done

# set without DISPLAY should still write files
# Skip dwm rebuild + user gtk/dunst install in tests
export VOIDWOLF_HOME="${TMPDIR:-/tmp}/voidwolf-theme-test-$$"
export VOIDWOLF_THEME_SKIP_REBUILD=1
export VOIDWOLF_THEME_SKIP_USER_CONFIG=1
rm -rf "$VOIDWOLF_HOME"
mkdir -p "$VOIDWOLF_HOME"
if "$THEME" set voidwolf-dark; then
	echo "OK   set voidwolf-dark"
else
	echo "FAIL set voidwolf-dark"
	fail=1
fi

for f in \
	generated/colors.h \
	generated/theme.Xresources \
	generated/dmenu.env \
	generated/dunstrc.colors \
	generated/gtk-3.0.settings.ini \
	generated/gtk-3.0.css \
	generated/gtk-4.0.settings.ini \
	generated/gtk-4.0.css \
	generated/xcursor.env \
	current/name
do
	if [[ -f "$VOIDWOLF_HOME/$f" ]]; then
		echo "OK   $f"
	else
		echo "FAIL missing $VOIDWOLF_HOME/$f"
		fail=1
	fi
done

# PR9a content checks
if rg -q 'urgency_critical' "$VOIDWOLF_HOME/generated/dunstrc.colors" \
	&& rg -q 'frame_color' "$VOIDWOLF_HOME/generated/dunstrc.colors"; then
	echo "OK   dunst colors content"
else
	echo "FAIL dunst colors incomplete"
	fail=1
fi
if rg -q 'gtk-theme-name=' "$VOIDWOLF_HOME/generated/gtk-3.0.settings.ini" \
	&& rg -q 'accent_bg_color' "$VOIDWOLF_HOME/generated/gtk-3.0.css" \
	&& rg -q 'gtk-application-prefer-dark-theme=1' "$VOIDWOLF_HOME/generated/gtk-3.0.settings.ini"; then
	echo "OK   gtk adapter content"
else
	echo "FAIL gtk adapter incomplete"
	fail=1
fi
# Void-friendly default: themes request Yaru-dark (not only Adwaita-dark)
if rg -q 'gtk_theme = "Yaru-dark"' "$ROOT/themes/voidwolf-dark.toml"; then
	echo "OK   default theme prefers Yaru-dark"
else
	echo "FAIL voidwolf-dark should set gtk_theme Yaru-dark for Void"
	fail=1
fi
if rg -q 'resolve_gtk_theme|Yaru-dark' "$ROOT/bin/voidwolf-theme"; then
	echo "OK   theme engine resolves GTK theme on host"
else
	echo "FAIL voidwolf-theme missing GTK theme resolver"
	fail=1
fi
if rg -q '^yaru$' "$ROOT/bootstrap/packages-desktop-required.txt"; then
	echo "OK   yaru in desktop required packages"
else
	echo "FAIL yaru should be in packages-desktop-required.txt"
	fail=1
fi
if [[ -f "$ROOT/config/dunst/dunstrc" ]] && rg -q 'voidwolf-dunst-v1' "$ROOT/config/dunst/dunstrc"; then
	echo "OK   config/dunst/dunstrc template"
else
	echo "FAIL missing dunst template"
	fail=1
fi

cur=$("$THEME" current)
if [[ "$cur" == "voidwolf-dark" ]]; then
	echo "OK   current is voidwolf-dark"
else
	echo "FAIL current=$cur"
	fail=1
fi

# invalid theme
if "$THEME" set no-such-theme 2>/dev/null; then
	echo "FAIL set unknown should fail"
	fail=1
else
	echo "OK   unknown theme fails"
fi

# colors.h contains hex from voidwolf-dark
if rg -q '#0b0c0e' "$ROOT/suckless/dwm/colors.h" 2>/dev/null || rg -q '#0b0c0e' "$VOIDWOLF_HOME/generated/colors.h"; then
	echo "OK   colors.h has theme bg"
else
	echo "FAIL colors.h missing expected bg"
	fail=1
fi

# PR9b: from-wallpaper via builtin (no external deps)
wall="$ROOT/wallpapers/voidwolf-default.png"
if [[ -f "$wall" ]]; then
	export VOIDWOLF_HOME="${TMPDIR:-/tmp}/voidwolf-theme-test-fw-$$"
	export VOIDWOLF_THEME_SKIP_REBUILD=1
	export VOIDWOLF_THEME_SKIP_USER_CONFIG=1
	rm -rf "$VOIDWOLF_HOME"
	mkdir -p "$VOIDWOLF_HOME"
	if "$THEME" from-wallpaper "$wall" --backend builtin --name derived-testwall --no-apply; then
		echo "OK   from-wallpaper --no-apply"
	else
		echo "FAIL from-wallpaper --no-apply"
		fail=1
	fi
	if [[ -f "$VOIDWOLF_HOME/themes/derived-testwall.toml" ]]; then
		echo "OK   derived theme written"
		if "$THEME" validate "$VOIDWOLF_HOME/themes/derived-testwall.toml"; then
			echo "OK   derived theme validates"
		else
			echo "FAIL derived theme validate"
			fail=1
		fi
	else
		echo "FAIL missing derived-testwall.toml"
		fail=1
	fi
	# apply path
	if "$THEME" from-wallpaper "$wall" --backend builtin --name derived-testwall2; then
		echo "OK   from-wallpaper apply"
		if [[ -f "$VOIDWOLF_HOME/generated/colors.h" ]] && [[ "$(cat "$VOIDWOLF_HOME/current/name")" == "derived-testwall2" ]]; then
			echo "OK   derived theme applied as current"
		else
			echo "FAIL derived apply state"
			fail=1
		fi
	else
		echo "FAIL from-wallpaper apply"
		fail=1
	fi
	rm -rf "$VOIDWOLF_HOME"
else
	echo "FAIL no default wallpaper for from-wallpaper test"
	fail=1
fi

rm -rf "${TMPDIR:-/tmp}/voidwolf-theme-test-$$" 2>/dev/null || true

if [[ "$fail" -ne 0 ]]; then
	echo "theme-schema-validate: FAILED"
	exit 1
fi
echo "theme-schema-validate: all OK"
