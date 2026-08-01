# Bootstrap

Install voidwolf onto an **existing** Void Linux (glibc x86_64) system.

## Prerequisites

- Void Linux, x86_64, network access
- `sudo` (or root) for system changes
- Not a replacement for a full ISO (Phase 5)

## Quick start

```bash
# Dry-run (no writes)
./bootstrap/bootstrap.sh --profile laptop --gpu none --dry-run

# Full PR2+PR3 path
./bootstrap/bootstrap.sh --profile laptop --gpu nvidia-hybrid

# Laptop without NVIDIA
./bootstrap/bootstrap.sh --profile laptop --gpu none

# Desktop discrete NVIDIA
./bootstrap/bootstrap.sh --profile desktop --gpu nvidia
```

After a real run: **re-login** (groups + elogind), then later `startx` (PR5+).

## Stages

| Stage | Script | PR |
|-------|--------|-----|
| Repos (nonfree, XLibre, vw-repo) | `repos.sh` | PR2 |
| Packages | `install-packages.sh` | PR3 |
| Services, sudoers, ufw, groups | `enable-services.sh` | PR3 |
| Suckless build | `build-suckless.sh` (`--with-suckless`) | PR4 |
| PipeWire conf.d + dotfiles | `setup-pipewire.sh`, `install-dotfiles.sh` | PR5 |

### Flags

| Flag | Effect |
|------|--------|
| `--profile desktop\|laptop` | Hardware package set (required for package install) |
| `--gpu none\|nvidia\|nvidia-hybrid\|nvidia-hybrid-randr` | NVIDIA packages when not `none` |
| `--with-32bit` | Multilib repos + optional 32-bit NVIDIA libs |
| `--no-brave` | Skip browser |
| `--xlibre-full` | `xlibre` meta instead of `xlibre-minimal` |
| `--with-picom` | Historical flag (picom is now in desktop-required) |
| `--repos-only` / `--packages-only` / `--services-only` | Partial runs |
| `--skip-repos` / `--skip-packages` / `--skip-services` | Skip stages |
| `--dry-run` | Print actions only |

`VOIDWOLF_NVIDIA_PKG=nvidia580` overrides the default `nvidia` package when a GPU profile is selected.

## Package lists

| File | Role |
|------|------|
| `packages-base.txt` | sudo, curl, git, … |
| `packages-desktop-required.txt` | elogind, PipeWire, NM, BT, fonts, tools |
| `packages-desktop-optional.txt` | best-effort TUIs, extractors |
| `packages-build-suckless.txt` | gcc/make/X11 devel |
| `packages-laptop.txt` | brightnessctl, tlp (PR11) |
| `packages-desktop.txt` | desktop extras (optional; lean) |
| `packages-nvidia.txt` | dkms, linux-headers (+ driver via script) |

## Services enabled

`dbus`, `elogind`, `NetworkManager`, `bluetoothd`, `polkitd`, `ufw` under `/var/service/`.

## Security baseline

- `/etc/sudoers.d/voidwolf-wheel` — `%wheel ALL=(ALL:ALL) ALL` (validated with `visudo`)
- `ufw`: default deny incoming, allow outgoing, `ufw --force enable`
- No FDE; no passwordless sudo

## Related

- [repos.md](repos.md) — third-party keys  
- [design.md](design.md) — full architecture  
- [nvidia.md](nvidia.md) — GPU deep config (PR10)
