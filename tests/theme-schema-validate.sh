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

# wallpaper asset
if [[ -f "$ROOT/wallpapers/voidwolf-default.png" ]]; then
	echo "OK   default wallpaper png"
else
	echo "FAIL missing wallpapers/voidwolf-default.png"
	fail=1
fi

# set without DISPLAY should still write files
# Skip dwm rebuild in tests (speed + avoid heavy compile in CI)
export VOIDWOLF_HOME="${TMPDIR:-/tmp}/voidwolf-theme-test-$$"
export VOIDWOLF_THEME_SKIP_REBUILD=1
rm -rf "$VOIDWOLF_HOME"
mkdir -p "$VOIDWOLF_HOME"
if "$THEME" set voidwolf-dark; then
	echo "OK   set voidwolf-dark"
else
	echo "FAIL set voidwolf-dark"
	fail=1
fi

for f in generated/colors.h generated/theme.Xresources generated/dmenu.env current/name; do
	if [[ -f "$VOIDWOLF_HOME/$f" ]]; then
		echo "OK   $f"
	else
		echo "FAIL missing $VOIDWOLF_HOME/$f"
		fail=1
	fi
done

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

rm -rf "$VOIDWOLF_HOME"

if [[ "$fail" -ne 0 ]]; then
	echo "theme-schema-validate: FAILED"
	exit 1
fi
echo "theme-schema-validate: all OK"
