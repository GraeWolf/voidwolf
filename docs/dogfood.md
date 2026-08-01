# Dogfood notes (host validation)

Live testing of voidwolf on real hardware. Update this file when you validate a path.

## Reference host (2026-08-01)

| Item | Value |
|------|--------|
| Host | `voidwolf` |
| CPU / GPU | Discrete **RTX 4060 Ti** (AD106) |
| Kernel | 6.18.x |
| Driver | `nvidia` 595.84 (DKMS) |
| X server | **XLibre** 25.x (`xlibre-xserver` 25.2.2) |
| Session | `startx` → voidwolf `~/.xinitrc` → dwm |
| Displays | **dual-left** default (HDMI-1 1080p left, HDMI-0 1440p primary right) |
| Theme (live) | `catppuccin-mocha` + preset wall; GTK **Yaru-dark** |
| Browser | Brave Origin Nightly via `voidwolf-browser` |
| Recommended bootstrap | `--profile desktop --gpu nvidia` |

### What works on this host

- Vendor + voidwolf NVIDIA snippets: `nvidia-smi`, GL (`OpenGL renderer: NVIDIA GeForce RTX 4060 Ti`), dual head under XLibre.
- XLibre logs **ABI warnings** (input driver ABI; “unsupported” but continues). Treat XLibre × NVIDIA as high-risk; re-validate after upgrades.
- Dual monitors via absolute `--pos` in `dual-left.sh` (prefer over `--left-of` with proprietary NVIDIA).
- Super+Shift+Q ends the X session (`dwm && break` loop). Super+Ctrl+Shift+Q restarts dwm only.
- Theme apply rebuilds dwm when `colors.h` changes; bar colors track the active theme.
- GTK dark: **Yaru-dark** (Void lacks a full Adwaita theme tree; Adwaita-dark left apps light).
- PR13b: vanitygaps, scratchpad (Super+S), sticky (Super+O), attachaside.
- Local XBPS packages + ISO scaffold present (PR15–17); optional system install path.

### Dogfood steps (fresh / re-sync)

```bash
cd /path/to/voidwolf
export PATH="$HOME/.local/bin:$PATH" VOIDWOLF_ROOT="$PWD"

./bin/install-user-bin.sh
./bootstrap/setup-pipewire.sh
./bootstrap/install-dotfiles.sh   # backs up prior ~/.xinitrc
voidwolf-theme set voidwolf-dark  # or nord / catppuccin-mocha / …
voidwolf-displays set-default dual-left   # this desk layout
voidwolf-gpu-check
voidwolf-dogfood-check
```

### Still requires operator / root

```bash
# root: modeset + explicit Device/OutputClass (safe even if vendor confs work)
sudo ./bootstrap/nvidia-setup.sh --profile nvidia --force

# optional packages if missing
sudo xbps-install -y maim xclip yaru

# full session: from a TTY as your user (not root), after logging out of other WM
export PATH="$HOME/.local/bin:$PATH"
startx
```

Prior bspwm/xinitrc (if any) is saved as `~/.xinitrc.voidwolf-bak.<timestamp>` (may be a symlink).

### Issues fixed during dogfood

| Issue | Fix |
|-------|-----|
| Stale stubs in `~/.local/bin` (theme engine “not implemented”) | Re-run `install-user-bin.sh` after PR8+ |
| `voidwolf-browser` missed `brave-origin-nightly` | Resolve nightly binary + `/opt/brave.com/...` paths |
| PipeWire conf.d not linked | `setup-pipewire.sh` / install-dotfiles |
| Live session still bspwm | install-dotfiles installs voidwolf `~/.xinitrc`; **next** `startx` uses dwm |
| Super+Shift+Q only restarted dwm | `.xinitrc` loop: `dwm && break` so clean exit ends X |
| Dual monitors wrong geometry | `dual-left` absolute `--pos`; `voidwolf-displays restore` at startx |
| Theme bar colors stuck after `theme set` | Rebuild when `colors.h` changes; force unlink if make is stale |
| GTK apps stayed light with Adwaita-dark | Prefer **Yaru-dark** + `gsettings` + `gtk.env` |
| `voidwolf-dogfood-check` false WARN for XLibre | `xbps-query -p pkgver` (not `xbps-query -l \| rg -q` under pipefail) |

## Smoke checklist

### Automated (run from repo)

```bash
cd /path/to/voidwolf
export PATH="$HOME/.local/bin:$PATH"

# unit / structural tests
for t in tests/*-validate.sh tests/keybind-lint.sh; do bash "$t" || exit 1; done

# live host readiness (needs DISPLAY for GL / X vendor lines)
voidwolf-dogfood-check
voidwolf-gpu-check
voidwolf-about          # PipeWire / BT / NM / GPU snapshot
voidwolf-displays list  # default → dual-left on this host
```

**Last automated run (2026-08-01):** all `tests/*-validate.sh` + `keybind-lint.sh` **PASS**. Dogfood check expected **READY** (or READY WITH WARNINGS only for optional INFO).

### Inside dwm (manual)

| Check | How | Status (ref host) |
|-------|-----|-------------------|
| Terminal | Super+Return → `st` | OK |
| Browser | Super+Shift+B → Brave Origin Nightly | OK |
| Launcher | Super+Space | OK |
| Control menu | Super+Alt+Space | OK |
| Bar / status | `voidwolf-status` on root name | OK |
| GPU | `nvidia-smi` / `glxinfo -B` in st | OK (4060 Ti) |
| Dual head | `xrandr` / pointer spans both panels | OK via dual-left |
| Theme switch | Super+Ctrl+Shift+Space or `voidwolf-theme set …` | OK (rebuild + bar) |
| GTK dark | open file chooser / Brave chrome | OK with Yaru-dark |
| Wallpaper | matches theme preset | OK |
| Scratchpad | Super+S | OK (PR13b) |
| Sticky | Super+O | OK |
| Gaps | Super+G / Super+Shift+G | OK |
| Screenshots | Super+Print family (needs maim/xclip) | deps present |
| Volume keys | XF86 volume → `voidwolf-volume` | if keyboard has them |
| Lock | Super+Ctrl+L | manual |
| Quit X | Super+Shift+Q | OK (ends session) |
| Restart dwm | Super+Ctrl+Shift+Q | OK (stays in X) |

Keybinds not exercised in every session (lock, full screenshot matrix, BT TUI) are still covered by `helpers-validate` / `keybind-lint` and code review.

## Packaging / ISO (not full install dogfood)

Local templates and scripts exist; system-wide `xbps-install` of voidwolf packages and live ISO build are **optional** follow-ups:

| Area | Docs |
|------|------|
| Metas + suckless packages | [packaging.md](packaging.md) |
| Live image scaffold | [iso.md](iso.md) |

## Related

- [nvidia.md](nvidia.md)
- [session.md](session.md)
- [displays.md](displays.md)
- [theming.md](theming.md)
- [hardware-profiles.md](hardware-profiles.md)
- [keybindings.md](keybindings.md)
