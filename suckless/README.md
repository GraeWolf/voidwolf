# suckless/

Vendored **dwm**, **st**, and **dmenu** with voidwolf patches.

- **Phase 1–3 install prefix:** `$HOME/.local` (no sudo for theme rebuilds)
- **PATH:** `export PATH="$HOME/.local/bin:$PATH"`
- **Phase 1 patches (locked):** see [docs/design.md](../docs/design.md) Key Decisions
- **Vendoring + build scripts:** PR4

Do not commit generated `colors.h` (see root `.gitignore`).
