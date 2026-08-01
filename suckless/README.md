# suckless/

Vendored **dwm**, **st**, and **dmenu** with voidwolf Phase 1 patches.

| Tree | Version | Notes |
|------|---------|--------|
| `dwm/` | 6.5 | actualfullscreen, movestack, focusdir, restartsig |
| `st/` | 0.9.2 | xresources, scrollback |
| `dmenu/` | 5.3 | unpatched; colors via CLI |

See [PATCHES.md](PATCHES.md) for patch origins and apply order.

## Build / install (no sudo)

```bash
# Requires packages from packages-build-suckless.txt (PR3)
./bootstrap/build-suckless.sh
./bin/install-user-bin.sh
export PATH="$HOME/.local/bin:$PATH"
# or: source config/bash/voidwolf-path.sh
```

- **PREFIX:** `$HOME/.local` (override with `PREFIX=...` or `--prefix`)
- **Theme surface:** `dwm/colors.h` (rewritten by voidwolf-theme in PR8)
- **Keybinds:** `dwm/config.h` (Mod4 / Omarchy-inspired)

## Restart dwm after rebuild

```bash
kill -HUP "$(pidof dwm)"   # restartsig re-exec
# or Super+Ctrl+Shift+Q
```
