# NVIDIA

First-class proprietary NVIDIA support for voidwolf on Void Linux.

> **Status:** Stub for PR1. Install profiles, PRIME helpers, and `voidwolf-gpu-check` land in **PR10**.  
> Full design: [design.md](design.md) (NVIDIA install profiles).

## Profiles (planned)

| Profile | Use case | Notes |
|---------|----------|--------|
| Desktop discrete | Single NVIDIA GPU | proprietary module + XLibre |
| Laptop hybrid PRIME | Modern Optimus | iGPU primary X; `prime-run` offload |
| Laptop RandR 1.4 | Older / power-focused hybrid | Handbook alternative when PRIME is wrong fit |
| Unsupported legacy | e.g. very old (`nvidia390` era) | Documented; may recommend nouveau |

## Principles

1. Install order: kernel headers / DKMS → nvidia packages → XLibre validation.
2. Hybrid: **iGPU modesetting is primary**; NVIDIA is offload sink.
3. Reject Bumblebee for new installs.
4. XLibre × NVIDIA is the highest external risk — validate with `nvidia-smi` + `glxinfo` + startx.
5. Recovery: documented fallback path to stock Xorg if needed (design PR10).

## Helpers (planned)

```bash
voidwolf-gpu-check    # recommend profile
voidwolf-prime        # prime-run style wrapper
```
