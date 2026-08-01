# bin/

voidwolf user-facing helpers. Install with:

```bash
./bin/install-user-bin.sh   # → ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"
```

Full catalog: [docs/helpers.md](../docs/helpers.md).

| Script | Bind / use |
|--------|------------|
| `voidwolf-dmenu` | Themed dmenu wrapper |
| `voidwolf-launcher` | Super+Space |
| `voidwolf-menu` | Super+Alt+Space |
| `voidwolf-displays` | menu → Displays (PR13) |
| `voidwolf-about` | menu → About / session (PR13) |
| `voidwolf-system-menu` | Super+Escape (lock & suspend default) |
| `voidwolf-lock` | Super+Ctrl+L |
| `voidwolf-screenshot` | Super+Shift+P / Super+Shift+S / Super+Ctrl+C |
| `voidwolf-float-term` | Floating centered st for TUIs |
| `voidwolf-cheatsheet` | Super+K (fzf / dmenu key list) |
| `voidwolf-browser` | Super+Shift+B |
| `voidwolf-filemanager` | Super+Shift+F (Nemo) |
| `voidwolf-clipboard` | Super+Ctrl+V |
| `voidwolf-audio-tui` | Super+Ctrl+A |
| `voidwolf-bluetooth-tui` | Super+Ctrl+B |
| `voidwolf-wifi-tui` | Super+Ctrl+W |
| `voidwolf-status` | Session autostart (bar) |
| `voidwolf-wallpaper` | Super+Ctrl+Space |
| `voidwolf-theme` | Super+Ctrl+Shift+Space — set/list/pick/validate (PR8) |
| `voidwolf-gpu-check` | GPU detect / profile recommendation (PR10) |
| `voidwolf-prime` | PRIME offload wrapper (PR10) |
| `voidwolf-volume` | XF86 volume (PR11) |
| `voidwolf-brightness` | XF86 backlight (PR11) |
| `voidwolf-dogfood-check` | Host readiness report |
