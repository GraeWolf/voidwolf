# Packaging (Phase 4 / PR15)

Personal **local XBPS** packages for voidwolf. No public signing service required.

## Meta packages

| Package | Role |
|---------|------|
| **voidwolf-base** | Deps from `bootstrap/packages-base.txt` |
| **voidwolf-themes** | Themes + wallpapers → `/usr/share/voidwolf/{themes,wallpapers}` |
| **voidwolf-desktop** | Deps: base + themes + `packages-desktop-required.txt` + `xlibre-minimal` |
| **voidwolf-laptop** | Deps: desktop + `packages-laptop.txt` (brightnessctl, tlp) |
| **voidwolf-helpers** | `bin/voidwolf-*` → `/usr/bin` (depends on themes) |

**Not** in these metas (by design):

| Piece | Why |
|-------|-----|
| Brave (`brave-origin`) | Third-party vw-repo; install separately |
| NVIDIA stack | Hardware profile; use bootstrap `--gpu` |
| dwm/st/dmenu binaries | **PR16** suckless packages; until then use `build-suckless.sh` → `~/.local` |

## Build local repo

```bash
# from repo root (no root required for build)
./packages/build-local-repo.sh
# → packages/repo/*.xbps + repodata

./packages/build-local-repo.sh --only voidwolf-themes
./packages/build-local-repo.sh --clean
./packages/build-local-repo.sh --dry-run
```

Version: `packages/version.conf` (`VOIDWOLF_PKGVER` / `VOIDWOLF_PKGREVISION`).

## Enable repo + install

```bash
# absolute path required
repo="$(cd packages/repo && pwd)"
printf 'repository=%s\n' "$repo" | sudo tee /etc/xbps.d/98-voidwolf-local.conf

sudo xbps-install -S
sudo xbps-install -y voidwolf-desktop voidwolf-helpers

# laptop extras
sudo xbps-install -y voidwolf-laptop

# still needed once (third-party / hardware)
./bootstrap/repos.sh
# xlibre already dep of voidwolf-desktop as xlibre-minimal (repo must be enabled)
# brave:
sudo xbps-install -y brave-origin   # or brave-origin-bin
```

## Theme paths after packaging

`voidwolf-theme` already searches:

1. `~/.config/voidwolf/themes`
2. `$VOIDWOLF_ROOT/themes` (git checkout)
3. **`/usr/share/voidwolf/themes`** (voidwolf-themes package)

So a machine with only packages (no git tree) can still `voidwolf-theme set nord` if helpers + themes packages are installed.

## Coexistence with bootstrap scripts

| Method | Use when |
|--------|----------|
| `./bootstrap/bootstrap.sh` | Full greenfield on a Void install |
| Local XBPS metas | Reproduce deps on a second machine without re-running every list |
| Both | Fine — packages pull deps; bootstrap still owns services/repos/dotfiles |

Services, sudoers, and dotfiles remain **script-owned** (`enable-services.sh`, `install-dotfiles.sh`) until later packaging expands.

## Unsigned local repo

Packages are **unsigned** by default (owner machine only). For a signed personal repo:

```bash
# optional — see xbps-rindex(1)
xbps-rindex --sign --privkey ~/.ssh/voidwolf-repo.pem --signedby "you <you@host>" packages/repo
```

Do not commit private keys.

## Layout

```text
packages/
  version.conf
  build-local-repo.sh
  xbps.d/98-voidwolf-local.conf.example
  voidwolf-base/DESCRIPTION
  voidwolf-desktop/DESCRIPTION
  voidwolf-themes/DESCRIPTION
  voidwolf-laptop/DESCRIPTION
  voidwolf-helpers/DESCRIPTION
  repo/                    # build output (gitignored)
  .build/                  # staging (gitignored)
```

## Related

- [bootstrap.md](bootstrap.md)  
- [design.md](design.md) — Phase 4  
- PR16: suckless binary packages (`voidwolf-dwm`, …)
