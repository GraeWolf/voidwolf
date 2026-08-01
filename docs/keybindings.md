# Keybindings

Omarchy-inspired **Super (Mod4)** map for voidwolf dwm.

| | |
|---|---|
| **Source of truth (code)** | `suckless/dwm/config.h` |
| **Lint** | `./tests/keybind-lint.sh` / `make test` |
| **Scope** | **PR6–PR6b + PR11 media + PR13b gaps/scratch/sticky** |
| **Full Omarchy comparison** | [design.md](design.md) |

## Policy locks

| Rule | voidwolf |
|------|----------|
| Mod key | **Super** (`Mod4Mask`) only for WM binds |
| Super+K | **Cheatsheet** — never focus up |
| Super+L | **focusdir right** — never layout cycle |
| Super+Shift+L | **cyclelayout** forward (not movestack) |
| Super+, | **dunst** dismiss — monitors use **Super+.** family |
| Super+J | focusdir **down** (not Omarchy layout-flip) |
| Universal Super+C/V | **Unsupported** (X11; see design Appendix C) |

## Launch

| Bind | Action | Command |
|------|--------|---------|
| Super+Return | Terminal | `st` |
| Super+Shift+B | Browser | `voidwolf-browser` |
| Super+Space | App launcher | `voidwolf-launcher` |
| Super+Alt+Space | Control menu | `voidwolf-menu` |
| Super+Escape | System menu | `voidwolf-system-menu` |
| Super+Ctrl+L | Lock | `voidwolf-lock` |
| Super+Shift+N | Neovim | `st -e nvim` |
| Super+Shift+F | File manager | `voidwolf-filemanager` |
| Super+K | Keybind cheatsheet | `voidwolf-cheatsheet` |
| Super+Ctrl+Shift+Space | Theme pick (stub PR8) | `voidwolf-theme pick` |
| Super+Ctrl+Space | Wallpaper pick (stub PR8) | `voidwolf-wallpaper pick` |

## Window / client

| Bind | Action |
|------|--------|
| Super+W | Close window |
| Super+T | Toggle floating |
| Super+F | Fullscreen |
| Super+B | Toggle bar |
| Super+Shift+Space | Toggle bar (Omarchy-like) |
| Super+Z | Zoom (swap master) |
| Super+Shift+Q | Quit dwm |
| Super+Ctrl+Shift+Q | Restart dwm |

## Focus (focusdir)

| Bind | Direction |
|------|-----------|
| Super+H / Super+Left | Left |
| Super+L / Super+Right | Right |
| Super+Up | Up |
| Super+J / Super+Down | Down |

| Bind | Action |
|------|--------|
| Alt+Tab | Focus next in stack |
| Alt+Shift+Tab | Focus previous in stack |

## Move stack (movestack)

| Bind | Action |
|------|--------|
| Super+Shift+H / Left | Move client in stack |
| Super+Shift+J / Down | Move client in stack |
| Super+Shift+Up / Right | Move client in stack |

## Layout / master

| Bind | Action |
|------|--------|
| Super+Shift+L | Cycle layouts forward |
| Super+Ctrl+Shift+L | Cycle layouts reverse |
| Super+M | Monocle |
| Super+Shift+T | Tile |
| Super+I / Super+D | ± masters |
| Super+= / Super+- | ± master factor (`setmfact`) |

## Scratchpad / sticky / gaps (PR13b)

| Bind | Action |
|------|--------|
| Super+S | Toggle scratchpad terminal (`st` titled `scratchpad`) |
| Super+O | Toggle sticky (client visible on all tags) |
| Super+G | Toggle gaps on/off |
| Super+Shift+G | Reset gaps to defaults |
| Super+Ctrl+= | Increase gaps |
| Super+Ctrl+- | Decrease gaps |

**attachaside:** new tiled clients join the stack after the master (not as the new master). No keybind.

## Tags

| Bind | Action |
|------|--------|
| Super+1 … Super+9 | View tag |
| Super+Shift+1 … 9 | Move client to tag |
| Super+Ctrl+1 … 9 | Toggle view tag |
| Super+Ctrl+Shift+1 … 9 | Toggle client tag |
| Super+0 | View all |
| Super+Shift+0 | Tag all |
| Super+Tab | Next tag set (`shiftview +1`) |
| Super+Shift+Tab | Previous tag set (`shiftview -1`) |
| Super+Ctrl+Tab | Toggle last tagset (`view {0}`) |

## Monitors

Super+, is reserved for notifications — monitors use **period**:

| Bind | Action |
|------|--------|
| Super+. | Focus next monitor |
| Super+Ctrl+. | Focus previous monitor |
| Super+Shift+. | Send client to next monitor |
| Super+Ctrl+Shift+. | Send client to previous monitor |

## Media / brightness (PR11)

No Super modifier — hardware XF86 keys:

| Key | Action | Command |
|-----|--------|---------|
| XF86 AudioRaiseVolume | Volume up | `voidwolf-volume up` |
| XF86 AudioLowerVolume | Volume down | `voidwolf-volume down` |
| XF86 AudioMute | Mute toggle | `voidwolf-volume mute` |
| XF86 MonBrightnessUp | Brightness + | `voidwolf-brightness up` |
| XF86 MonBrightnessDown | Brightness − | `voidwolf-brightness down` |

Laptop packages (`--profile laptop`) install `brightnessctl`. Desktop still gets volume binds; brightness is a no-op without a backlight.

## Capture (PR6b)

| Bind | Action |
|------|--------|
| Print | Full screenshot → `~/Pictures/Screenshots` + clipboard |
| Shift+Print | Region screenshot |
| Super+Ctrl+C | Capture menu (full / region / window) |
| Super+Ctrl+V | Clipboard helper (`clipmenu` if installed) |

Requires `maim` and `xclip` (PR3 package lists).

## Notifications

| Bind | Action |
|------|--------|
| Super+, | Dismiss latest (`dunstctl close`) |
| Super+Shift+, | Dismiss all |
| Super+Ctrl+, | Toggle silence (`set-paused toggle`) |
| Super+Alt+, | History pop (`history-pop`) |

## System TUIs

| Bind | Action |
|------|--------|
| Super+Ctrl+A | Audio |
| Super+Ctrl+B | Bluetooth |
| Super+Ctrl+W | Wi‑Fi |
| Super+Ctrl+T | btop |

## Mouse

| Bind | Action |
|------|--------|
| Super+Btn1 | Move window |
| Super+Btn3 | Resize window |
| Super+Btn2 | Toggle floating |

## Intentionally unsupported / later

| Bind / feature | Status |
|----------------|--------|
| Super+C/V universal clipboard | Unsupported on X11 (see design Appendix C) |
| Systray | Not in Phase 1–3 defaults |

## Cheatsheet

```bash
voidwolf-cheatsheet    # Super+K
./tests/keybind-lint.sh
```
