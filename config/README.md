# config/

Dotfiles and session configuration installed by `bootstrap/install-dotfiles.sh` (PR5+).

| Path | Purpose |
|------|---------|
| `bash/` | PATH, rc, profile snippets (PR12) → `~/.config/voidwolf/` |
| `neovim/` | lean nvim (PR12) → `~/.config/voidwolf-nvim/` via `NVIM_APPNAME` |
| `X11/.xinitrc`, `.Xresources` | startx session (PR5) |
| `X11/dpi-*.Xresources` | optional HiDPI merges (PR13) |
| `displays/examples/` | xrandr preset examples (PR13) → `~/.config/voidwolf/displays/` |
| `pipewire/pipewire.conf.d/` | handbook conf.d links (PR5) |
| `dunst/` | dunstrc template (include theme colors) — PR9a |
| `gtk-3.0/`, `gtk-4.0/` | settings/css templates (reference; engine writes live) — PR9a |
