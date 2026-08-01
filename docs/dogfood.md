# Dogfood notes (host validation)

Live testing of voidwolf on real hardware. Update this file when you validate a path.

## Reference host (2026-07-31)

| Item | Value |
|------|--------|
| Host | `voidwolf` |
| CPU / GPU | Discrete **RTX 4060 Ti** (AD106) |
| Kernel | 6.18.x |
| Driver | `nvidia` 595.84 (DKMS) |
| X server | **XLibre** 25.x (`xlibre-xserver`) |
| Recommended | `--profile desktop --gpu nvidia` |

### What worked without voidwolf X conf

- Vendor snippets under `/usr/share/X11/xorg.conf.d/10-nvidia*.conf` load the proprietary DDX.
- `nvidia-smi`, GL (`OpenGL renderer: NVIDIA GeForce RTX 4060 Ti`), dual monitors OK under existing startx session.
- XLibre logs **ABI warnings** (input driver ABI; “unsupported” but continues). Treat XLibre × NVIDIA as high-risk; re-validate after upgrades.

### Dogfood steps run in-repo

```bash
cd /path/to/voidwolf
export PATH="$HOME/.local/bin:$PATH" VOIDWOLF_ROOT="$PWD"

./bin/install-user-bin.sh
./bootstrap/setup-pipewire.sh
./bootstrap/install-dotfiles.sh   # backs up prior ~/.xinitrc
voidwolf-theme set voidwolf-dark
voidwolf-gpu-check
voidwolf-dogfood-check
```

### Still requires operator / root

```bash
# root: modeset + explicit Device/OutputClass (safe even if vendor confs work)
sudo ./bootstrap/nvidia-setup.sh --profile nvidia --force

# optional packages if missing
sudo xbps-install -y maim xclip

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

### Smoke checklist inside dwm

| Check | How |
|-------|-----|
| Terminal | Super+Return |
| Browser | Super+Shift+B |
| Launcher | Super+Space |
| Bar | `voidwolf-status` text on root name |
| GPU | `nvidia-smi` / `glxinfo -B` in st |
| Volume keys | XF86 volume (if keyboard has them) |
| Quit X | Super+Shift+Q |

## Related

- [nvidia.md](nvidia.md)
- [session.md](session.md)
- [hardware-profiles.md](hardware-profiles.md)
