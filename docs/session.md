# Session model

voidwolf uses **startx** only (no display manager). Phase 1 session correctness is owned by PR5.

## Requirements

| Piece | Source |
|-------|--------|
| Seat / `XDG_RUNTIME_DIR` | **elogind** (enabled in PR3) |
| Session D-Bus | `dbus-launch` in `.xinitrc` |
| Audio | **pipewire** only + conf.d (WirePlumber + pulse) |
| WM | **dwm** in a restart-safe loop |
| Status | `voidwolf-status` → `xsetroot -name` |

After enabling elogind the first time: **re-login** so `echo $XDG_RUNTIME_DIR` is `/run/user/$(id -u)`.

## Install

```bash
# packages + services (PR2–3)
./bootstrap/bootstrap.sh --profile laptop --gpu none

# suckless (PR4)
./bootstrap/build-suckless.sh
./bin/install-user-bin.sh

# session files (PR5)
./bootstrap/install-dotfiles.sh
# or full path continues after packages once wired into bootstrap.sh
```

Then:

```bash
export PATH="$HOME/.local/bin:$PATH"
voidwolf-dogfood-check   # optional host readiness report
startx
```

Live host notes: [dogfood.md](dogfood.md).

## Files

| Path | Role |
|------|------|
| `config/X11/.xinitrc` → `~/.xinitrc` | Session entry |
| `config/X11/.Xresources` → `~/.Xresources` | Fonts, DPI, st colors |
| `~/.config/pipewire/pipewire.conf.d/` | Handbook conf.d links |
| `~/.config/voidwolf/` | State, generated themes, logs |
| `bin/voidwolf-status` | Bar text |

## `.xinitrc` rules

1. Refuse root.
2. Warn if `XDG_RUNTIME_DIR` missing.
3. Start **one** session bus; export DISPLAY/XAUTHORITY.
4. `xrdb` base + generated theme.
5. `pipewire &` only — **not** wireplumber/pipewire-pulse siblings.
6. dunst, voidwolf-status, wallpaper.
7. `while true; do dwm || break; done` so theme re-exec keeps X alive.

## Auto-startx (default OFF)

```bash
# optional in ~/.bash_profile — not installed by default
if [ -z "$DISPLAY" ] && [ "$(tty)" = /dev/tty1 ]; then
  exec startx
fi
```

## PipeWire checklist

```bash
./bootstrap/setup-pipewire.sh
ls -l ~/.config/pipewire/pipewire.conf.d/
# expect 10-wireplumber.conf and 20-pipewire-pulse.conf → /usr/share/examples/...

# After startx:
pactl info 2>/dev/null | head   # if pulse tools present
wpctl status
```

## Troubleshooting

| Symptom | Check |
|---------|--------|
| PipeWire fails “no runtime dir” | elogind enabled? re-login? `echo $XDG_RUNTIME_DIR` |
| No audio | conf.d links? only one `pipewire`? `wpctl status` |
| dwm missing | `build-suckless.sh`, `PATH` has `~/.local/bin` |
| Bar empty | `voidwolf-status` on PATH? `xsetroot` installed? |
| Root X refused | correct — do not `startx` as root |

## Related

- [bootstrap.md](bootstrap.md)  
- [bash-nvim.md](bash-nvim.md) — bash + neovim (PR12)  
- [design.md](design.md) — architecture sequence diagram  
- [keybindings.md](keybindings.md)
