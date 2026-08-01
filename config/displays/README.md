# Display presets (PR13)

User scripts live in **`~/.config/voidwolf/displays/*.sh`**.

Each script is a small shell program that runs `xrandr` (and optionally restores wallpaper). Pick them via:

```bash
voidwolf-displays          # dmenu picker
# Super+Alt+Space → Displays
```

## Install examples into your home

```bash
voidwolf-displays pick
# → "Install example presets"
# or:
cp config/displays/examples/*.sh.example ~/.config/voidwolf/displays/
# rename: strip .example, chmod +x
```

`install-dotfiles.sh` creates the empty `displays/` directory; it does **not** overwrite your presets.

## Script contract

```bash
#!/bin/sh
# Optional: set -e
xrandr --output … --mode … --pos …
# optional:
# command -v voidwolf-wallpaper >/dev/null && voidwolf-wallpaper restore
```

- Prefer **connected** output names from `xrandr --query` (e.g. `HDMI-0`, `eDP-1`).
- NVIDIA discrete often uses `HDMI-0` / `DP-0`; Intel laptops use `eDP-1` + `HDMI-1`.
- After mode changes, re-apply wallpaper (voidwolf-displays does this on success).

## Related

- [docs/displays.md](../../docs/displays.md) — multi-monitor & HiDPI notes  
- Optional GUI: `arandr` (packages-desktop-optional)
