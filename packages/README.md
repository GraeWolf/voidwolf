# packages/

Phase 4 local XBPS meta packages (PR15).

```bash
./packages/build-local-repo.sh          # → packages/repo/
./packages/build-local-repo.sh --dry-run
```

| Package | Contents |
|---------|----------|
| `voidwolf-base` | base package deps |
| `voidwolf-desktop` | desktop session deps + xlibre-minimal |
| `voidwolf-themes` | `/usr/share/voidwolf/{themes,wallpapers}` |
| `voidwolf-laptop` | laptop package deps |
| `voidwolf-helpers` | `/usr/bin/voidwolf-*` scripts |

Full docs: [docs/packaging.md](../docs/packaging.md).

Suckless binary packages (`voidwolf-dwm`, …) land in **PR16**.
