# wallpapers/

| File | Theme | Notes |
|------|--------|--------|
| `voidwolf-default.png` | voidwolf-dark | Default dark gradient (PR8) |
| `voidwolf-default.jpg` | — | Symlink → png |
| `gruvbox.png` | gruvbox | Warm amber / hard-black gradient (PR14) |
| `catppuccin-mocha.png` | catppuccin-mocha | Soft purple/blue (PR14) |
| `nord.png` | nord | Polar night blues (PR14) |
| `rose-pine.png` | rose-pine | Deep purple / mauve (PR14) |
| `*.jpg` | — | Symlinks to matching `.png` |

Each preset’s `themes/*.toml` `meta.wallpaper` points at its image.
Regenerate (requires ffmpeg):

```bash
# from repo root — see scripts or PR14 history for gradients filter lines
ffmpeg -f lavfi -i "gradients=s=1920x1080:..." -frames:v 1 wallpapers/NAME.png
```
