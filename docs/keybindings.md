# Keybindings (core — PR6)

Omarchy-inspired **Super (Mod4)** map for voidwolf dwm.

| | |
|---|---|
| **Source of truth (code)** | `suckless/dwm/config.h` |
| **Lint** | `./tests/keybind-lint.sh` / `make test` |
| **Scope** | **Core** binds only — remainder in PR6b |
| **Full Omarchy table** | [design.md](design.md) |

## Policy locks

| Rule | voidwolf |
|------|----------|
| Mod key | **Super** (`Mod4Mask`) only for WM binds |
| Super+K | **Cheatsheet** — never focus up |
| Super+L | **focusdir right** — never layout cycle |
| Super+Shift+L | Layout toggle (`setlayout {0}`) |
| Super+J | focusdir **down** (not Omarchy layout-flip) |
| Universal Super+C/V | **Unsupported** (X11; see design Appendix C) |

Lint enforces these. Changing them requires updating `tests/keybind-lint.sh`.

## Launch

| Bind | Action | Command |
|------|--------|---------|
| Super+Return | Terminal | `st` |
| Super+Shift+Return | Browser | `voidwolf-browser` |
| Super+Space | App launcher | `voidwolf-launcher` |
| Super+Alt+Space | Control menu | `voidwolf-menu` |
| Super+Escape | System menu | `voidwolf-system-menu` |
| Super+Ctrl+L | Lock | `voidwolf-lock` |
| Super+Shift+N | Neovim | `st -e nvim` |
| Super+K | Keybind cheatsheet | `voidwolf-cheatsheet` |
| Super+Ctrl+Shift+Space | Theme pick (stub PR8) | `voidwolf-theme pick` |
| Super+Ctrl+Space | Wallpaper pick (stub PR8) | `voidwolf-wallpaper pick` |

## Window / client

| Bind | Action |
|------|--------|
| Super+W | Close window (`killclient`) |
| Super+T | Toggle floating |
| Super+F | Fullscreen (`togglefullscr` / actualfullscreen) |
| Super+B | Toggle bar |
| Super+Shift+Q | Quit dwm |
| Super+Ctrl+Shift+Q | Restart dwm (restartsig) |

## Focus (focusdir)

| Bind | Direction |
|------|-----------|
| Super+H / Super+Left | Left |
| Super+L / Super+Right | Right |
| Super+Up | Up |
| Super+J / Super+Down | Down |

Super+K is **not** focus.

### Alt+Tab (window cycle)

| Bind | Action |
|------|--------|
| Alt+Tab | Focus next in stack |
| Alt+Shift+Tab | Focus previous in stack |

## Move stack (movestack)

| Bind | Action |
|------|--------|
| Super+Shift+H / Left | Move client up the stack |
| Super+Shift+J / Down | Move client down the stack |
| Super+Shift+Up / Right | Move client (stack order) |

Super+Shift+L is **layout**, not movestack.

## Layout / master

| Bind | Action |
|------|--------|
| Super+Shift+L | Toggle previous layout |
| Super+M | Monocle |
| Super+Shift+T | Tile layout |
| Super+I / Super+D | ± masters |
| Super+= / Super+- | ± master factor |
| Super+Tab | Toggle last tags |

## Tags (workspaces)

| Bind | Action |
|------|--------|
| Super+1 … Super+9 | View tag |
| Super+Shift+1 … 9 | Move client to tag |
| Super+Ctrl+1 … 9 | Toggle view tag |
| Super+Ctrl+Shift+1 … 9 | Toggle client tag |
| Super+0 | View all |
| Super+Shift+0 | Tag all |

## Monitors (minimal core)

| Bind | Action |
|------|--------|
| Super+. | Focus next monitor |
| Super+Shift+. | Send client to next monitor |

Broader mon cycling lands in PR6b if needed.

## System TUIs

| Bind | Action |
|------|--------|
| Super+Ctrl+A | Audio (`voidwolf-audio-tui`) |
| Super+Ctrl+B | Bluetooth |
| Super+Ctrl+W | Wi‑Fi / NetworkManager |
| Super+Ctrl+T | btop |

## Notifications (core)

| Bind | Action |
|------|--------|
| Super+, | Dismiss latest (`dunstctl close`) |
| Super+Shift+, | Dismiss all |

Further notification binds (history, silence) → PR6b / design table.

## Intentionally incomplete (PR6b+)

Not required for PR6 “core” exit criteria; may already exist partially:

- Screenshot / capture menu (`voidwolf-screenshot`, Print)
- Full Omarchy omission list polish
- Phase 3: scratchpad, sticky, vanitygaps binds

## Mouse (stock-style)

| Bind | Action |
|------|--------|
| Super+Btn1 | Move window |
| Super+Btn3 | Resize window |
| Super+Btn2 | Toggle floating |

## Cheatsheet

```bash
voidwolf-cheatsheet    # Super+K — opens this file in less via st
./tests/keybind-lint.sh
```
