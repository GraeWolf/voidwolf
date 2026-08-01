# Packaging (Phase 4 / PR15–PR16)

Personal **local XBPS** packages for voidwolf. No public signing service required.

## Meta packages (PR15)

| Package | Role |
|---------|------|
| **voidwolf-base** | Deps from `bootstrap/packages-base.txt` |
| **voidwolf-themes** | Themes + wallpapers → `/usr/share/voidwolf/{themes,wallpapers}` |
| **voidwolf-desktop** | Deps: base + themes + `packages-desktop-required.txt` + `xlibre-minimal` |
| **voidwolf-laptop** | Deps: desktop + `packages-laptop.txt` (brightnessctl, tlp) |
| **voidwolf-helpers** | `bin/voidwolf-*` → `/usr/bin` (depends on themes) |

## Suckless packages (PR16)

| Package | Arch | Installs |
|---------|------|----------|
| **voidwolf-dwm** | native | `/usr/bin/dwm` + man + example `config.h`/`colors.h` |
| **voidwolf-st** | native | `/usr/bin/st` + man + terminfo |
| **voidwolf-dmenu** | native | `/usr/bin/dmenu{,_run,_path}`, `stest` |
| **voidwolf-suckless** | noarch meta | depends on the three above |

Runtime deps: `libX11 libXft libXinerama fontconfig freetype`.

### PATH coexistence (locked design)

| Location | Who |
|----------|-----|
| `/usr/bin/dwm` (package) | System default from voidwolf-dwm |
| `~/.local/bin/dwm` (user rebuild) | **Preferred** when `PATH` has `~/.local/bin` first — theme rebuilds never need sudo |

`voidwolf-theme` still rebuilds into `$HOME/.local` from the git tree (or copy examples from `/usr/share/voidwolf/examples/`).

**Not** in these packages (by design):

| Piece | Why |
|-------|-----|
| Brave (`brave-origin`) | Third-party vw-repo; install separately |
| NVIDIA stack | Hardware profile; use bootstrap `--gpu` |

## Build local repo

```bash
# from repo root (no root required for build)
# needs gcc/make + X11 devel headers for suckless packages
./packages/build-local-repo.sh
# → packages/repo/*.xbps + repodata

./packages/build-local-repo.sh --only voidwolf-dwm
./packages/build-local-repo.sh --skip-suckless   # metas only
./packages/build-local-repo.sh --clean
./packages/build-local-repo.sh --dry-run
```

Version: `packages/version.conf` (`VOIDWOLF_PKGVER` / `VOIDWOLF_PKGREVISION`).

**Dependency patterns:** XBPS requires versioned patterns in package metadata (e.g. `sudo>=0`), not bare names. `build-local-repo.sh` appends `>=0` to entries from bootstrap package lists and to suckless runtime libs.

## Enable repo + install

```bash
# absolute path required
repo="$(cd packages/repo && pwd)"
printf 'repository=%s\n' "$repo" | sudo tee /etc/xbps.d/98-voidwolf-local.conf

sudo xbps-install -S
sudo xbps-install -y voidwolf-desktop voidwolf-helpers voidwolf-suckless

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
- PR17: ISO scaffolding (after packaging)
