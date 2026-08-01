# bootstrap/

Install voidwolf onto an **existing** Void Linux (glibc x86_64) system.

## PR2 (current)

| File | Role |
|------|------|
| `repos.sh` | Enable nonfree, optional multilib, XLibre + vw-repo (fail-closed keys) |
| `bootstrap.sh` | Entrypoint; use `--repos-only` for PR2 scope |
| `keys/` | Shipped XBPS key plists + `pins.conf` |

```bash
./bootstrap/repos.sh --dry-run
./bootstrap/bootstrap.sh --repos-only
./bootstrap/repos.sh --with-32bit          # multilib
./bootstrap/repos.sh --disable-third-party # rollback XLibre + vw-repo
```

Docs: [docs/repos.md](../docs/repos.md).

## Later PRs

| File | PR |
|------|-----|
| `packages-*.txt` | PR3 |
| `enable-services.sh` | PR3 |
| `install-dotfiles.sh`, `setup-pipewire.sh` | PR5 |
| `build-suckless.sh` | PR4 |

See [docs/design.md](../docs/design.md) for session, package, and NVIDIA rules.
