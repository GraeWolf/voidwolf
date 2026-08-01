# packages/

Phase 4 local XBPS packages (PR15 meta + PR16 suckless).

```bash
./packages/build-local-repo.sh              # all packages → packages/repo/
./packages/build-local-repo.sh --skip-suckless
./packages/build-local-repo.sh --only voidwolf-dwm
./packages/build-local-repo.sh --dry-run
```

| Package | Type |
|---------|------|
| `voidwolf-base` | meta deps |
| `voidwolf-desktop` | meta deps + xlibre-minimal |
| `voidwolf-themes` | `/usr/share/voidwolf/{themes,wallpapers}` |
| `voidwolf-laptop` | laptop deps |
| `voidwolf-helpers` | `/usr/bin/voidwolf-*` |
| `voidwolf-dwm` | `/usr/bin/dwm` (native) |
| `voidwolf-st` | `/usr/bin/st` + terminfo (native) |
| `voidwolf-dmenu` | `/usr/bin/dmenu*` (native) |
| `voidwolf-suckless` | meta → dwm+st+dmenu |

Docs: [docs/packaging.md](../docs/packaging.md).
