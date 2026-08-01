# Keybindings

Omarchy-inspired Super/Mod4 map for voidwolf (dwm).

> **Status:** Phase 1 core lives in `suckless/dwm/config.h` (PR4).  
> Full Omarchy parity table: [design.md](design.md). Remainder polish: **PR6 / PR6b**.

## Locked focus / Super+K policy

| Bind | Action |
|------|--------|
| Super+H / Super+L / Super+J | focusdir left / right / down |
| Super+Arrows | focusdir in that direction |
| Super+K | keybind cheatsheet only (not focus) |
| Super+Shift+L | layout toggle (`setlayout {0}`) |
| Super+Shift+H/J (+ arrows) | movestack / swap |

## Core binds (implemented in config.h)

| Bind | Action |
|------|--------|
| Super+Return | Terminal (st) |
| Super+Shift+Return | Browser (`voidwolf-browser`) |
| Super+Space | Launcher (`voidwolf-launcher` → dmenu_run) |
| Super+Alt+Space | voidwolf control menu |
| Super+Escape | System menu |
| Super+Ctrl+L | Lock |
| Super+W | Close window |
| Super+T | Toggle floating |
| Super+F | Fullscreen (actualfullscreen) |
| Super+1–9 | Tags |
| Super+Shift+1–9 | Move client to tag |
| Super+Ctrl+Shift+Space | Theme picker (stub PR8) |
| Super+Ctrl+Space | Wallpaper picker (stub PR8) |
| Super+Shift+Q | Quit dwm |
| Super+Ctrl+Shift+Q | Restart dwm (restartsig) |
| Super+Shift+N | neovim in st |
| Super+Ctrl+A/B/W/T | audio / BT / wifi / btop |

## Unsupported Omarchy binds

Documented in design Appendix C (e.g. Super+C/V universal clipboard, Hyprland groups).
