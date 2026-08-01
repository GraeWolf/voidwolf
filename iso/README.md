# iso/

Phase 5 live image scaffolding (**PR17**). Uses external [void-mklive](https://github.com/void-linux/void-mklive); not vendored.

## Quick start

```bash
# 1. Optional: build voidwolf packages for the image
./packages/build-local-repo.sh

# 2. Clone void-mklive somewhere
git clone https://github.com/void-linux/void-mklive ~/src/void-mklive

# 3. Configure
cp iso/mklive.env.example iso/mklive.env
# edit VOID_MKLIVE_DIR=…

# 4. Dry-run / build (build needs root/sudo)
./iso/build-iso.sh --dry-run
sudo ./iso/build-iso.sh
```

## Layout

| Path | Role |
|------|------|
| `build-iso.sh` | Orchestrator |
| `mklive.env.example` | Build variables |
| `package-lists/` | Live + voidwolf package names |
| `overlay/` | Rootfs include (`-I`): hostname, motd, ISO-README |
| `scripts/assemble-pkglist.sh` | Merge package lists |
| `out/` | Build output (gitignored) |

## Locked product decisions (PR17)

| Topic | Choice |
|-------|--------|
| Hostname | **voidwolf** |
| Login | **startx only** (no DM) |
| FDE | **Not** in installer |
| Arch | **x86_64** glibc first |
| Live user (docs) | **voidwolf** (password via mklive / operator) |
| XLibre / Brave / NVIDIA | Post-boot / extra repos — not assumed on bare mklive mirror |

Full narrative: [docs/iso.md](../docs/iso.md).
