# Status bar (status2d + voidwolf-status)

voidwolf uses the **vanilla dwm bar** (like [ChadWM](https://github.com/siduck/chadwm)): tags · layout · title on the left, **colored modules + systray** on the right.

| Piece | Role |
|-------|------|
| **status2d** patch | Multi-color status text (`^c#hex^`, `^b#hex^`, `^d^`) |
| **systray** patch | Tray icons (right edge) |
| **voidwolf-status** | Module loop → `xsetroot -name` |
| **voidwolf-theme** | Writes `~/.config/voidwolf/generated/status.env` + bar colors in `colors.h` |

## Layout

| Region | Content |
|--------|---------|
| **Left** | Tags + layout symbol |
| **Center** | Clock (status2d colored text) |
| **Middle fill** | Empty — same `SchemeNorm` bar bg (**no window title**) |
| **Right** | Modules + systray |

`voidwolf-status` sets `xsetroot -name` as:  
`right-modules` + `\x1f` + `center-clock` so dwm can place the clock independently.

## Modules

**Right** (ChadWM-inspired), colored **text** icons (no chip backgrounds):

1. **Updates** — `xbps-install -Mun` count (cached ~5 min)  
   - **Click (Btn1):** floating TUI (`voidwolf-updates-tui`) lists packages; optional `sudo xbps-install -Su`
2. **Power** — battery % / AC
3. **CPU** — load average
4. **RAM** — used memory
5. **Network** — SSID / eth / Disconnected
6. **Volume** — wpctl %  
   - **Scroll wheel** on the module: volume up/down  
   - **Click:** audio TUI

**Center:**

7. **Clock** — `Day YYYY-MM-DD HH:MM:SS` (accent-colored text)

Click regions use **statuscmd** control bytes (`\001` updates, `\002` volume) in the status string. Handler: `voidwolf-status-click`.

Icons need a Nerd Font (`Symbols Nerd Font Mono`). Package: `nerd-fonts-symbols-ttf`.

## Per-monitor tags (dual desk)

| Xinerama mon index | Tags shown / Super+N |
|--------------------|----------------------|
| **0** (usually first / often primary HDMI-0) | **1–6** |
| **1** (second head, often HDMI-1) | **7–9** |

`Super+7` focuses the monitor that owns tag 7 and views that tag.  
`Super+Shift+7` moves the focused client there and shows the tag.

Configured in `suckless/dwm/config.h` as `mon_tagmask[]`. **If 1–6 appear on the wrong physical screen, swap the two `mon_tagmask` entries** and rebuild dwm.

```c
static const unsigned int mon_tagmask[] = {
	(1u<<0)|(1u<<1)|(1u<<2)|(1u<<3)|(1u<<4)|(1u<<5), /* mon0: 1-6 */
	(1u<<6)|(1u<<7)|(1u<<8),                           /* mon1: 7-9 */
};
```

## Theme colors

On `voidwolf-theme set …`:

| Variable | Source |
|----------|--------|
| `status_bg` / bar chrome | `palette.bar_bg` |
| `status_fg` | `palette.bar_fg` |
| `status_accent` | `palette.bar_selected_bg` / `accent` |
| `status_urgent` | `palette.urgent` |
| `status_muted` | `palette.color8` |
| `status_ok` | `palette.color2` |
| `status_warn` | `palette.color3` |

`voidwolf-status` re-sources `status.env` every tick — no restart required after a theme change (bar **chrome** still needs dwm rebuild when `colors.h` changes).

## Systray (left-ish icons in screenshots)

Tray clients are **apps**, not dwm drawing. Examples:

```bash
# optional applets
nm-applet &          # NetworkManager (package: NetworkManager-openvpn or nm-applet)
# blueman-applet &
```

voidwolf does not autostart random applets; add what you want to `~/.xinitrc` or a small user script.

## Tuning

```bash
export VOIDWOLF_STATUS_INTERVAL=1          # refresh seconds (1 for live clock)
export VOIDWOLF_STATUS_UPDATE_EVERY=300    # xbps check period
```

Restart status after edits:

```bash
pkill -x voidwolf-status
voidwolf-status &
# or Super+Ctrl+Shift+Q to re-exec dwm (session keeps status if still running)
```

## Related

- [theming.md](theming.md)
- [keybindings.md](keybindings.md)
- ChadWM reference: https://github.com/siduck/chadwm (status2d bar, not polybar)
