# Hardware profiles

Laptop vs desktop configuration for voidwolf.

> **Status:** Stub for PR1. Package lists and helpers land in **PR11**.  
> Full design: [design.md](design.md).

## Profiles

| Profile | Flag (planned) | Focus |
|---------|----------------|--------|
| Desktop | `--profile desktop` | Discrete GPU, multi-monitor |
| Laptop | `--profile laptop` | Brightness, suspend, hybrid GPU options |

## Laptop extras (planned)

- Brightness control keybinds / tools
- Suspend / lock-then-suspend via system menu
- Optional hybrid GPU path (`--gpu nvidia-hybrid`) without requiring NVIDIA PR for pure Intel/AMD

## Desktop extras (planned)

- Discrete NVIDIA profile (`--gpu nvidia-desktop`)
- Multi-monitor / displays menu (Phase 3)

GPU flags are **orthogonal** to laptop/desktop: a pure Intel laptop must work without the NVIDIA package set.
