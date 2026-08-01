# voidwolf

Personal, opinionated **Void Linux** desktop setup inspired by [Omarchy](https://omarchy.org/)’s *philosophy* (beautiful defaults, paved path, developer-ready) — not its Hyprland/Arch stack.

| | |
|---|---|
| **Hostname default** | `voidwolf` |
| **License** | [MIT](LICENSE) |
| **Base** | Void Linux (runit, XBPS), glibc x86_64 first |
| **Display** | XLibre + dwm + st + startx |
| **Browser** | [brave-origin](https://codeberg.org/Graewolf/vw-repo) via vw-repo |
| **Status** | PR1–17 complete; dogfood host READY (see [docs/dogfood.md](docs/dogfood.md)) |

## Stack (locked)

- **X server:** XLibre (community Void repo)
- **WM / terminal:** dwm + st (vendored suckless, `PREFIX=$HOME/.local`)
- **Shell / editor:** bash + neovim
- **Audio / net:** PipeWire + NetworkManager + Bluetooth
- **GPU:** NVIDIA first-class (desktop discrete + laptop PRIME)
- **Security:** ufw + sudo (no FDE installer story)
- **Theming:** named presets + wallpaper extraction (`voidwolf-theme`)

## Repository layout

```text
voidwolf/
├── docs/           # design, keybinds, theming, NVIDIA, repos
├── bin/            # voidwolf-* helpers (theme, menus, lock, …)
├── config/         # bash, neovim, dunst, gtk, X11 session
├── themes/         # TOML theme presets
├── wallpapers/     # default + preset wallpapers
├── suckless/       # vendored dwm, st, dmenu + patches
├── bootstrap/      # install on existing Void
├── packages/       # Phase 4 XBPS templates
├── iso/            # Phase 5 live image scaffolding
└── tests/          # schema / keybind checks
```

See [docs/design.md](docs/design.md) for the full architecture, keybind map, theme schema, NVIDIA profiles, and PR plan.

## Quick status

| Phase | Goal | State |
|-------|------|--------|
| 0 | Design | **Done** ([docs/design.md](docs/design.md)) |
| 1 | Bootstrap on existing Void (XLibre, dwm, st, session) | **Done** (PR1–7) |
| 2 | Theming engine | **Done** (PR8–9b) |
| 3 | Opinionated desktop polish | **Done** (PR10–14: NVIDIA, profiles, bash/nvim, displays, walls, gaps/scratch/sticky) |
| 4 | XBPS packages | **Done** (PR15–16: metas + suckless → `packages/repo`) |
| 5 | ISO / installer | **Scaffolding done** (PR17: void-mklive driver; no FDE; build/boot still optional) |
| — | Live dogfood (RTX 4060 Ti + XLibre + startx) | **READY** ([docs/dogfood.md](docs/dogfood.md)) |

Optional follow-ups: install from the local XBPS repo on a clean path, build/boot the live ISO, second-machine bootstrap.

## Development

```bash
# Dry-run PR2+PR3 (no root)
./bootstrap/bootstrap.sh --profile laptop --gpu none --dry-run
make test

# Build suckless + session files (no sudo for these)
make build-suckless
make install-dotfiles
export PATH="$HOME/.local/bin:$PATH"
voidwolf-theme set voidwolf-dark   # PR8: colors + wallpaper + rebuild dwm
# startx   # after elogind re-login

# On Void (needs sudo for packages/services):
# ./bootstrap/bootstrap.sh --profile laptop --gpu nvidia-hybrid --with-suckless
```

```bash
make help
make test
make build-suckless
make install-dotfiles
make theme-list
```

## Documentation

| Doc | Purpose |
|-----|---------|
| [docs/design.md](docs/design.md) | Approved architecture & PR plan |
| [docs/bootstrap.md](docs/bootstrap.md) | Bootstrap usage (PR2–5) |
| [docs/session.md](docs/session.md) | startx / PipeWire / dwm loop |
| [docs/helpers.md](docs/helpers.md) | User scripts (launcher, lock, capture) |
| [docs/theming.md](docs/theming.md) | Theme engine (PR8–9) |
| [docs/nvidia.md](docs/nvidia.md) | NVIDIA / PRIME / fallback (PR10) |
| [docs/keybindings.md](docs/keybindings.md) | Omarchy → dwm map (filled in PR6) |
| [docs/theming.md](docs/theming.md) | Theme engine usage (PR8+) |
| [docs/repos.md](docs/repos.md) | XLibre + vw-repo wiring (PR2) |
| [docs/nvidia.md](docs/nvidia.md) | GPU profiles (PR10) |
| [docs/hardware-profiles.md](docs/hardware-profiles.md) | Laptop / desktop (PR11) |
| [docs/dogfood.md](docs/dogfood.md) | Live host validation notes |
| [docs/bash-nvim.md](docs/bash-nvim.md) | Bash + neovim defaults (PR12) |
| [docs/displays.md](docs/displays.md) | Multi-monitor presets + HiDPI (PR13) |
| [docs/packaging.md](docs/packaging.md) | Local XBPS meta packages (PR15–16) |
| [docs/iso.md](docs/iso.md) | Live ISO / void-mklive (PR17) |

## License

MIT — see [LICENSE](LICENSE).
