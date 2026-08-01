# Theming (PR8)

voidwolf theming engine: named presets, generate adapters, rebuild dwm user-local.

## CLI

```bash
export PATH="$HOME/.local/bin:$PATH"
export VOIDWOLF_ROOT=/path/to/voidwolf   # optional if repo-root recorded

voidwolf-theme list
voidwolf-theme validate              # all shipped themes
voidwolf-theme set voidwolf-dark     # apply default
voidwolf-theme set nord
voidwolf-theme current
voidwolf-theme show gruvbox
voidwolf-theme pick                  # dmenu chooser
voidwolf-theme build-suckless        # re-apply current + rebuild dwm
voidwolf-theme reload
voidwolf-theme from-wallpaper ~/Pictures/wall.png
voidwolf-theme from-wallpaper ./wallpapers/voidwolf-default.png --backend builtin
voidwolf-theme from-wallpaper ./img.png --name derived-lake --no-apply
```

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | ok |
| 1 | usage |
| 2 | theme not found |
| 3 | adapter failure (e.g. dwm rebuild) |
| 4 | schema invalid |

## Shipped presets

| name | display |
|------|---------|
| `voidwolf-dark` | Voidwolf Dark (default) |
| `gruvbox` | Gruvbox |
| `catppuccin-mocha` | Catppuccin Mocha |
| `nord` | Nord |
| `rose-pine` | Rosé Pine |

Default wallpaper: `wallpapers/voidwolf-default.png` (voidwolf-dark).  
Preset walls (PR14): `gruvbox.png`, `catppuccin-mocha.png`, `nord.png`, `rose-pine.png` under `wallpapers/`.

## What `set` does

1. Validate TOML (`schema_version = 1`, palette, color0–15)
2. Write `$VOIDWOLF_HOME/generated/`:
   - `colors.h`, `theme.Xresources`, `dmenu.env` (PR8)
   - `dunstrc.colors`, `gtk-3.0.*`, `gtk-4.0.*`, `xcursor.env` (**PR9a**)
3. Atomic update `$VOIDWOLF_HOME/current/name`
4. Copy `colors.h` → `suckless/dwm/colors.h`
5. If palette hash changed: `build-suckless.sh --dwm-only` (**no sudo**, `PREFIX=$HOME/.local`)
6. `kill -HUP dwm` when `DISPLAY` set (restartsig re-exec)
7. `xrdb -merge` theme Xresources
8. Install user configs (unless `VOIDWOLF_THEME_SKIP_USER_CONFIG=1`):
   - `~/.config/dunst/dunstrc` (template with include) + `dunstrc.d/10-voidwolf-theme.conf`
   - `~/.config/gtk-3.0/{settings.ini,gtk.css}`
   - `~/.config/gtk-4.0/{settings.ini,gtk.css}`
9. Reload dunst (`dunstctl reload` / HUP)
10. Set wallpaper via `voidwolf-wallpaper set` when path resolves
11. If `colors.h` hash changed: force-recompile `dwm` (depends on `colors.h`) and `SIGHUP` to re-exec
12. `xrdb -merge` theme Xresources — **new** `st` windows pick up colors; existing st keep the old palette

`VOIDWOLF_HOME` defaults to `~/.config/voidwolf`.

| Env | Effect |
|-----|--------|
| `VOIDWOLF_THEME_SKIP_REBUILD=1` | Skip dwm rebuild (tests) |
| `VOIDWOLF_THEME_SKIP_USER_CONFIG=1` | Only write under `VOIDWOLF_HOME/generated` |

## Adapters

| Target | Mechanism |
|--------|-----------|
| st | Xresources / xrdb |
| dwm | `colors.h` + rebuild + HUP |
| dmenu | `dmenu.env` → voidwolf-dmenu / launcher |
| dunst | `dunstrc.colors` include + conf.d drop-in |
| GTK 3/4 | `settings.ini` (theme/icon/cursor) + best-effort `gtk.css` accents |
| cursor | `xcursor.env` sourced from `.xinitrc` |

GTK recolor is **best-effort**; `meta.gtk_theme` (e.g. Adwaita-dark) is the primary switch.

## Schema (summary)

See [design.md](design.md) for the full field table. Required:

- `schema_version = 1`
- `name`
- `palette.bg`, `fg`, `accent`, `urgent`
- `palette.color0` … `color15` for shipped themes

Fonts are **not** themed (edit `suckless/*/config.h`).

## from-wallpaper (PR9b)

```bash
voidwolf-theme from-wallpaper <image> [--name derived-slug] [--backend B] [--no-apply]
```

**Backend order (locked):** `wallust` → `matugen` → `pywal` (`wal`) → **`builtin`** (PNG quantizer; always available).

| Backend | Notes |
|---------|--------|
| wallust | `wallust run` / `cs`; reads `~/.cache/wallust` |
| matugen | `matugen image … --json hex` Material You → ANSI map |
| pywal | `wal -i …`; reads `~/.cache/wal/colors.json` |
| builtin | Pure-Python PNG sampling (+ ImageMagick for other formats) |

Writes `$VOIDWOLF_HOME/themes/<name>.toml` then applies (unless `--no-apply`). Full 16 ANSI colors are always filled (lighten/dim if backend is partial).

`voidwolf-wallpaper pick` lists images under `~/Pictures` and runs `from-wallpaper`.
