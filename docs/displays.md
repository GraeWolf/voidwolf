# Displays & HiDPI (PR13)

Multi-monitor layouts for voidwolf are **scripts + dmenu**, not a full display manager panel.

## Quick use

```bash
voidwolf-displays              # picker
voidwolf-displays list
voidwolf-displays apply dual-left
voidwolf-displays set-default dual-left   # persist for startx
voidwolf-displays restore                 # used by .xinitrc at session start
voidwolf-displays query                   # xrandr in st
voidwolf-displays arandr                  # if arandr installed

# Menu: Super+Alt+Space → Displays
```

**Important:** quitting/restarting **dwm** does **not** re-run display scripts. Layout is applied by `voidwolf-displays restore` at **startx** (or when you run apply manually). NVIDIA often defaults to “primary at 0,0 / second to the right” until a preset runs.

Prefer **absolute `--pos`** in scripts; `--left-of` / `--right-of` can be flaky with the proprietary driver.

## Preset format

Scripts under **`~/.config/voidwolf/displays/*.sh`**:

| Rule | Detail |
|------|--------|
| Language | `sh` / bash; run with `sh path` |
| Tool | `xrandr` (required package via desktop list) |
| Naming | `something.sh` → menu label `something` |
| Side effects | optional wallpaper restore (picker does this on success) |

Repo examples: `config/displays/examples/*.sh.example`  
Copy via menu **Install example presets** or manually (see `config/displays/README.md`).

### Dual head on this project’s dogfood host

Physical desk (common): **HDMI-1 secondary on the left**, **HDMI-0 primary on the right**.

```text
HDMI-1  1920x1080  +0+0
HDMI-0  2560x1440  primary  +1920+0
```

```bash
voidwolf-displays apply dual-left
voidwolf-displays set-default dual-left
```

If primary is on the left instead, use `dual-right`.

### Laptop + external

Typical names: `eDP-1` (internal), `HDMI-1` / `DP-1` (dock). Use **primary-only** for lid-only, **dual-right** after plugging in. Hybrid NVIDIA external ports may hang off the dGPU — see [nvidia.md](nvidia.md) and `xrandr --listproviders`.

## WM binds (already in dwm)

| Bind | Action |
|------|--------|
| Super+. | Focus next monitor |
| Super+Shift+. | Send client to next monitor |
| Super+Ctrl+. / Super+Ctrl+Shift+. | Focus / send previous |

Super+, remains **dunst** (not monitor).

## HiDPI / DPI

X11 does **integer `Xft.dpi`** only (no fractional scale). Base session uses `Xft.dpi: 96` in `config/X11/.Xresources`.

| Snippet | DPI | When |
|---------|-----|------|
| `config/X11/dpi-96.Xresources` | 96 | Default / large monitors |
| `config/X11/dpi-120.Xresources` | 120 | Slightly dense 1080p |
| `config/X11/dpi-144.Xresources` | 144 | HiDPI laptop panels |

```bash
xrdb -merge /path/to/voidwolf/config/X11/dpi-144.Xresources
# restart st / apps to pick up; dwm bar font is in config.h (rebuild if needed)
```

Fonts for suckless are in `suckless/*/config.h` (not theme TOML). After a big DPI jump, bump `size=` in `config.h` and `make build-suckless`.

## Optional packages

From `packages-desktop-optional.txt`:

- **arandr** — GUI layout editor (`voidwolf-displays arandr`)
- **pulsemixer**, **bluetuith** — nicer Super+Ctrl+A/B TUIs

## Session verify

```bash
voidwolf-about           # PipeWire / BT / NM / GPU snapshot
voidwolf-dogfood-check   # broader readiness
```

## Related

- [hardware-profiles.md](hardware-profiles.md)  
- [nvidia.md](nvidia.md)  
- [helpers.md](helpers.md)  
- [session.md](session.md)
