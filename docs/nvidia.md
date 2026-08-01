# NVIDIA (PR10)

First-class proprietary NVIDIA support for voidwolf on **Void Linux** + **XLibre**.

XLibre × NVIDIA is the **highest integration risk** in voidwolf. Validate after every driver or X server update.

## Quick start

```bash
# 1. Detect hardware
voidwolf-gpu-check
voidwolf-gpu-check --print-profile    # e.g. nvidia-hybrid
voidwolf-gpu-check --print-package    # e.g. nvidia or nvidia580

# 2. Bootstrap packages (nonfree + driver)
./bootstrap/bootstrap.sh --profile desktop --gpu nvidia --with-suckless
# or hybrid laptop:
./bootstrap/bootstrap.sh --profile laptop --gpu nvidia-hybrid --with-suckless
# override family package:
VOIDWOLF_NVIDIA_PKG=nvidia580 ./bootstrap/bootstrap.sh --profile laptop --gpu nvidia-hybrid-randr

# 3. System conf (modprobe modeset + xorg snippet)
sudo ./bootstrap/nvidia-setup.sh --profile nvidia
#    or --profile nvidia-hybrid | nvidia-hybrid-randr

# 4. Reboot after first DKMS build, then:
voidwolf-gpu-check
nvidia-smi
startx
```

## Profiles

| `--gpu` | Hardware | X primary | Offload | Driver package (typical) |
|---------|----------|-----------|---------|---------------------------|
| `none` | Intel/AMD only | iGPU/mesa | — | — |
| `nvidia` | Discrete NVIDIA | NVIDIA | — | `nvidia` (Turing+) or family override |
| `nvidia-hybrid` | Optimus / dual GPU | **iGPU modesetting** | PRIME (`voidwolf-prime`) | `nvidia` or `nvidia470` |
| `nvidia-hybrid-randr` | Hybrid, older / power | modesetting + nvidia | RandR 1.4 / session | `nvidia580`, `nvidia390`, … |

### Family → package

| Family | Package | PRIME Render Offload (Void handbook) |
|--------|---------|--------------------------------------|
| Turing+ (RTX 20/30/40/50, GTX 16) | `nvidia` | Yes |
| Maxwell–Volta (GTX 9xx/10xx, …) | `nvidia580` | **Not listed** — prefer hybrid-randr |
| Kepler | `nvidia470` | Yes |
| Fermi | `nvidia390` | No — RandR or nouveau |
| Older | — | nouveau / unsupported |

Override anytime: `VOIDWOLF_NVIDIA_PKG=nvidia470`.

## Install order

1. `void-repo-nonfree` (bootstrap `repos.sh`)
2. `linux-headers` (matching kernel) + `dkms`
3. Selected `nvidia*` package (blacklists nouveau)
4. `nvidia-drm.modeset=1` via `/etc/modprobe.d/voidwolf-nvidia.conf`
5. XLibre (`xlibre-minimal`) + tools
6. Xorg conf snippet (`nvidia-setup.sh`)
7. **Reboot** after first module build
8. Validate: `nvidia-smi`, `glxinfo`, `startx`, `voidwolf-gpu-check`

## PRIME offload (hybrid)

```bash
voidwolf-prime glxinfo | grep "OpenGL renderer"
voidwolf-prime brave-origin
```

Env used when `prime-run` is absent:

```bash
__NV_PRIME_RENDER_OFFLOAD=1
__GLX_VENDOR_LIBRARY_NAME=nvidia
__VK_LAYER_NV_optimus=NVIDIA_only
```

**Do not install Bumblebee** for new voidwolf setups.

### External displays on hybrid

Outputs may hang off the dGPU. After login:

```bash
xrandr --listproviders
# offload sink recipes depend on providers — see Void Optimus handbook
```

## Xorg snippets (repo)

| File | Profile |
|------|---------|
| `config/X11/xorg.conf.d/20-nvidia-discrete.conf` | `nvidia` |
| `config/X11/xorg.conf.d/20-nvidia-hybrid-prime.conf` | `nvidia-hybrid` |
| `config/X11/xorg.conf.d/20-nvidia-hybrid-randr.conf` | `nvidia-hybrid-randr` |
| `config/X11/modprobe.d/voidwolf-nvidia.conf` | all NVIDIA profiles |

## Recovery: stock Xorg fallback

Bootstrap **never** falls back silently. Explicit recovery:

```bash
sudo ./bootstrap/nvidia-fallback-xorg.sh --yes
# or dry-run:
./bootstrap/nvidia-fallback-xorg.sh --dry-run
```

Manual outline:

```bash
sudo mv /etc/xbps.d/99-repository-xlibre.conf{,.disabled}
sudo xbps-remove -Ry xlibre-minimal   # and other xlibre-* as needed
sudo xbps-install -Sy
sudo xbps-install -y xorg-minimal xorg-server
# keep nvidia packages; reboot; startx
```

Re-enable XLibre later with `./bootstrap/repos.sh` and reinstall `xlibre-minimal`.

## Validation checklist

| Check | Command |
|-------|---------|
| Module | `lsmod \| grep nvidia` |
| Driver | `nvidia-smi` |
| GL | `glxinfo -B` / `voidwolf-prime glxinfo -B` |
| Session | `startx` → dwm |
| Report | `voidwolf-gpu-check` / `--json` |

## 32-bit libs

Only with bootstrap `--with-32bit` (multilib nonfree) for Steam-class needs:

```bash
./bootstrap/bootstrap.sh --profile desktop --gpu nvidia --with-32bit
```

## Related

- [bootstrap.md](bootstrap.md)  
- [session.md](session.md)  
- [design.md](design.md) — profile matrix  
- Void: [NVIDIA](https://docs.voidlinux.org/config/graphical-session/graphics-drivers/nvidia.html), [Optimus](https://docs.voidlinux.org/config/graphical-session/graphics-drivers/optimus.html)
