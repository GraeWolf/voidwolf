# Theming

voidwolf theming engine: named presets + wallpaper-driven palettes.

> **Status:** Stub for PR1. Schema, CLI, and adapters land in **PR8 / PR9a / PR9b**.  
> Full design: [design.md](design.md) (Theme engine sections).

## Planned CLI

```bash
voidwolf-theme list
voidwolf-theme set voidwolf-dark
voidwolf-theme from-wallpaper ~/Pictures/wall.png
voidwolf-theme pick
voidwolf-theme validate themes/gruvbox.toml
voidwolf-theme build-suckless   # PREFIX=$HOME/.local — no sudo
```

## Shipped presets (planned)

| ID | Name |
|----|------|
| `voidwolf-dark` | Voidwolf Dark (default) |
| `gruvbox` | Gruvbox |
| `catppuccin-mocha` | Catppuccin Mocha |
| `nord` | Nord |
| `rose-pine` | Rosé Pine |

## Targets

| Target | Mechanism (Phase 2+) |
|--------|----------------------|
| st | Xresources / xrdb (new windows) |
| dwm | generate `colors.h` → rebuild → re-exec |
| dmenu | CLI color args (override config.h) |
| GTK 3/4 | settings + gtk.css |
| dunst | generated config from palette |
| Wallpaper | feh / xwallpaper |

## Extractor order (locked)

**wallust → matugen → pywal** (automatic fallback at PR9b).
