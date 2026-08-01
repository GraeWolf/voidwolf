# Hardware profiles (PR11)

Laptop vs desktop configuration for voidwolf. **GPU flags are orthogonal** to form-factor profiles.

| Flag | When |
|------|------|
| `--profile desktop` | Tower / fixed machine; multi-monitor; rarely needs TLP |
| `--profile laptop` | Portable; backlight + power management packages |
| `--gpu none` | Intel / AMD only (works on laptop or desktop) |
| `--gpu nvidia` | Discrete NVIDIA primary (typical desktop) |
| `--gpu nvidia-hybrid` | Optimus PRIME offload |
| `--gpu nvidia-hybrid-randr` | Older hybrid / RandR path |

## Quick start

```bash
# Pure Intel laptop
./bootstrap/bootstrap.sh --profile laptop --gpu none --with-suckless

# Discrete NVIDIA desktop (this project's dogfood host shape)
./bootstrap/bootstrap.sh --profile desktop --gpu nvidia --with-suckless
sudo ./bootstrap/nvidia-setup.sh --profile nvidia

# Hybrid laptop
./bootstrap/bootstrap.sh --profile laptop --gpu nvidia-hybrid --with-suckless
sudo ./bootstrap/nvidia-setup.sh --profile nvidia-hybrid
```

## Package lists

| List | Profile | Contents |
|------|---------|----------|
| `packages-desktop-required.txt` | both | Session stack (X tools, PipeWire, NM, …) |
| `packages-laptop.txt` | laptop | `brightnessctl`, `tlp` |
| `packages-desktop.txt` | desktop | Optional extras (lean; often empty) |
| `packages-nvidia.txt` | any + `--gpu` | DKMS headers, `glxinfo`, … |

## Helpers

| Script | Role |
|--------|------|
| `voidwolf-brightness` | XF86 brightness up/down (`brightnessctl` → `light` → sysfs) |
| `voidwolf-volume` | XF86 volume / mute via `wpctl` |
| `voidwolf-gpu-check` | Recommend `--gpu` / driver package |
| `voidwolf-prime` | Hybrid offload wrapper |

## Keybinds (media / backlight)

| Key | Action |
|-----|--------|
| XF86 AudioRaiseVolume / Lower / Mute | `voidwolf-volume` up / down / mute |
| XF86 MonBrightnessUp / Down | `voidwolf-brightness` up / down |

Binds live in `suckless/dwm/config.h` (no Super modifier). Brightness is harmless on desktop if no backlight sysfs exists (helper exits non-zero; spawn ignores).

## Services

| Service | Profile |
|---------|---------|
| dbus, elogind, NetworkManager, bluetoothd, polkitd, ufw | both |
| **tlp** | **laptop only** (`enable-services.sh --profile laptop`) |

## Laptop extras

- **Brightness** — XF86 keys + `voidwolf-brightness`
- **Suspend** — system menu **Lock & suspend** (`voidwolf-lock` then `loginctl suspend`)
- **Hybrid GPU** — optional `--gpu nvidia-hybrid*` without requiring NVIDIA packages for pure Intel/AMD (`--gpu none`)

## Desktop extras

- **Discrete NVIDIA** — `--gpu nvidia` + `docs/nvidia.md`
- **Multi-monitor** — Super+period family (`focusmon` / `tagmon`); presets via `voidwolf-displays` ([displays.md](displays.md))

## Validation

```bash
./bootstrap/bootstrap.sh --profile laptop --gpu none --dry-run
./bootstrap/bootstrap.sh --profile desktop --gpu nvidia --dry-run
make test
voidwolf-dogfood-check   # live host readiness
```

## Related

- [bootstrap.md](bootstrap.md)
- [nvidia.md](nvidia.md)
- [session.md](session.md)
- [keybindings.md](keybindings.md)
