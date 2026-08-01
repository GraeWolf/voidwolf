# voidwolf

Personal, opinionated **Void Linux** desktop setup inspired by [Omarchy](https://omarchy.org/)’s *philosophy* (beautiful defaults, paved path, developer-ready) — not its Hyprland/Arch stack.

| | |
|---|---|
| **Hostname default** | `voidwolf` |
| **License** | [MIT](LICENSE) |
| **Base** | Void Linux (runit, XBPS), glibc x86_64 first |
| **Display** | XLibre + dwm + st + startx |
| **Browser** | [brave-origin](https://codeberg.org/Graewolf/vw-repo) via vw-repo |
| **Status** | Phase 0 design approved; implementation in progress |

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
| 1 | Bootstrap on existing Void (XLibre, dwm, st, session) | In progress (PR1–6b: full keybind map) |
| 2 | Theming engine | Planned |
| 3 | Opinionated desktop polish | Planned |
| 4 | XBPS meta-packages | Planned |
| 5 | ISO / installer | After packaging |

## Development

```bash
# Dry-run PR2+PR3 (no root)
./bootstrap/bootstrap.sh --profile laptop --gpu none --dry-run
make test

# Build suckless + session files (no sudo for these)
make build-suckless
make install-dotfiles
export PATH="$HOME/.local/bin:$PATH"
# startx   # after elogind re-login

# On Void (needs sudo for packages/services):
# ./bootstrap/bootstrap.sh --profile laptop --gpu nvidia-hybrid --with-suckless
```

```bash
make help
make test
make build-suckless
make install-dotfiles
```

## Documentation

| Doc | Purpose |
|-----|---------|
| [docs/design.md](docs/design.md) | Approved architecture & PR plan |
| [docs/bootstrap.md](docs/bootstrap.md) | Bootstrap usage (PR2–5) |
| [docs/session.md](docs/session.md) | startx / PipeWire / dwm loop |
| [docs/keybindings.md](docs/keybindings.md) | Omarchy → dwm map (filled in PR6) |
| [docs/theming.md](docs/theming.md) | Theme engine usage (PR8+) |
| [docs/repos.md](docs/repos.md) | XLibre + vw-repo wiring (PR2) |
| [docs/nvidia.md](docs/nvidia.md) | GPU profiles (PR10) |
| [docs/hardware-profiles.md](docs/hardware-profiles.md) | Laptop / desktop (PR11) |

## License

MIT — see [LICENSE](LICENSE).
