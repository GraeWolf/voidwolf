# bootstrap/

Install voidwolf onto an **existing** Void Linux (glibc x86_64) system.

## Quick start

```bash
./bootstrap/bootstrap.sh --profile laptop --gpu none --dry-run
./bootstrap/bootstrap.sh --profile laptop --gpu nvidia-hybrid
```

Full docs: [docs/bootstrap.md](../docs/bootstrap.md).

## Layout

| Path | PR | Role |
|------|-----|------|
| `repos.sh` | PR2 | nonfree, XLibre, vw-repo (fail-closed keys) |
| `keys/` | PR2 | Pinned XBPS key plists |
| `install-packages.sh` | PR3 | Package lists install |
| `enable-services.sh` | PR3 | runit, sudoers, ufw, groups |
| `packages-*.txt` | PR3 | Required / optional package sets |
| `sudoers.d/voidwolf-wheel` | PR3 | `%wheel` sudo |
| `lib.sh` | PR3 | Shared helpers |
| `bootstrap.sh` | PR2–3 | Entrypoint |
| `build-suckless.sh` | PR4 | (not yet) |
| `setup-pipewire.sh`, `install-dotfiles.sh` | PR5 | (not yet) |

## Partial runs

```bash
./bootstrap/bootstrap.sh --repos-only
./bootstrap/bootstrap.sh --packages-only --profile desktop --gpu none
./bootstrap/bootstrap.sh --services-only
./bootstrap/repos.sh --disable-third-party
```
