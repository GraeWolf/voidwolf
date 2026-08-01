# Helper scripts (PR7)

User-facing voidwolf commands installed to `~/.local/bin` via
`./bin/install-user-bin.sh` (also run from `install-dotfiles.sh`).

```bash
export PATH="$HOME/.local/bin:$PATH"
./bin/install-user-bin.sh
```

## Catalog

| Command | Bind | Role |
|---------|------|------|
| `voidwolf-dmenu` | (internal) | Themed dmenu wrapper |
| `voidwolf-launcher` | Super+Space | `dmenu_run` + colors |
| `voidwolf-menu` | Super+Alt+Space | Control menu |
| `voidwolf-system-menu` | Super+Escape | Lock / suspend / power |
| `voidwolf-lock` | Super+Ctrl+L | xsecurelock → slock → i3lock |
| `voidwolf-screenshot` | Print / Super+Ctrl+C | maim + xclip |
| `voidwolf-cheatsheet` | Super+K | Open keybindings.md |
| `voidwolf-browser` | Super+Shift+Return | brave-origin* / brave-origin-nightly |
| `voidwolf-filemanager` | Super+Shift+F | lf / ranger / thunar |
| `voidwolf-clipboard` | Super+Ctrl+V | clipmenu / xclip |
| `voidwolf-audio-tui` | Super+Ctrl+A | pulsemixer / wpctl |
| `voidwolf-bluetooth-tui` | Super+Ctrl+B | bluetuith / bluetoothctl |
| `voidwolf-wifi-tui` | Super+Ctrl+W | nmtui |
| `voidwolf-status` | (autostart) | dwm bar via xsetroot |
| `voidwolf-wallpaper` | Super+Ctrl+Space | restore / set / pick |
| `voidwolf-theme` | Super+Ctrl+Shift+Space | set/list/pick/validate (PR8) |
| `voidwolf-gpu-check` | (manual) | GPU detect / `--gpu` recommendation (PR10) |
| `voidwolf-prime` | (manual / menus) | PRIME offload wrapper (PR10) |
| `voidwolf-volume` | XF86 volume keys | `wpctl` up/down/mute (PR11) |
| `voidwolf-brightness` | XF86 brightness keys | backlight control (PR11) |
| `voidwolf-dogfood-check` | (manual) | Host readiness for startx dogfood |

## System menu behavior

Order in `voidwolf-system-menu`:

1. **Lock**
2. **Lock & suspend** (design default power path)
3. Suspend (no lock)
4. Logout (SIGTERM dwm)
5. Reboot / Power off via `loginctl`

## Theming helpers

dmenu colors come from environment (defaults match voidwolf-dark):

```bash
export VOIDWOLF_DMENU_NB="#1d2021"
export VOIDWOLF_DMENU_NF="#ebdbb2"
export VOIDWOLF_DMENU_SB="#458588"
export VOIDWOLF_DMENU_SF="#1d2021"
export VOIDWOLF_DMENU_FN="Fira Code:size=11"
```

PR8/9a will export these from the active theme.

## Screenshot

```bash
voidwolf-screenshot menu     # dmenu
voidwolf-screenshot full     # Print
voidwolf-screenshot region   # Shift+Print
voidwolf-screenshot window
```

Saves under `~/Pictures/Screenshots/` (override with `VOIDWOLF_SCREENSHOT_DIR`).

## Related

- [keybindings.md](keybindings.md)  
- [session.md](session.md)  
- [design.md](design.md)
