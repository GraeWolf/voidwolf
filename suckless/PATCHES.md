# Suckless patches (Phase 1 locked)

Sources are vendored and **already patched** in-tree. Diffs under each `patches/`
directory are kept for audit/reproducibility; rebuild does **not** re-apply them.

## Versions

| Project | Version | Upstream |
|---------|---------|----------|
| dwm | 6.5 | https://dl.suckless.org/dwm/dwm-6.5.tar.gz |
| st | 0.9.2 | https://dl.suckless.org/st/st-0.9.2.tar.gz |
| dmenu | 5.3 | https://dl.suckless.org/tools/dmenu-5.3.tar.gz |

## dwm — apply order (historical)

1. **actualfullscreen** — `dwm-actualfullscreen-20211013-cb3f58a.diff`  
   https://dwm.suckless.org/patches/actualfullscreen/
2. **movestack** — `dwm-movestack-20211115-a786211.diff` (`movestack.c` + `#include` in config)  
   https://dwm.suckless.org/patches/movestack/
3. **focusdir** — bakkeby `dwm-focusdir-6.5.diff` (not on suckless.org)  
   https://github.com/bakkeby/patches (directional focus)  
   API: `.i = 0` left, `1` right, `2` up, `3` down
4. **restartsig** — `dwm-restartsig-20180523-6.2.diff` (SIGHUP restart / SIGTERM quit)  
   https://dwm.suckless.org/patches/restartsig/

### focusdir policy (voidwolf)

| Bind | `.i` | Action |
|------|------|--------|
| Super+H / Left | 0 | focus left |
| Super+L / Right | 1 | focus right (**not** layout) |
| Super+Up | 2 | focus up |
| Super+J / Down | 3 | focus down |
| Super+K | — | cheatsheet (not focus) |
| Super+Shift+L | — | layout toggle (`setlayout {0}`) |

## st — apply order

1. **xresources** — `st-xresources-20200604-9ba7ecf.diff`  
   https://st.suckless.org/patches/xresources/
2. **scrollback** — `st-scrollback-0.9.2.diff` (`HISTSIZE` 2000, Shift+PgUp/PgDn)  
   https://st.suckless.org/patches/scrollback/

## dmenu

Unpatched upstream 5.3. Colors via CLI (`-nb/-nf/-sb/-sf`) from `voidwolf-launcher` — CLI overrides `config.h`.

## Install prefix

```bash
./bootstrap/build-suckless.sh          # PREFIX=$HOME/.local, no sudo
./bin/install-user-bin.sh              # helpers → ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"
```

`colors.h` is the theme surface for dwm (overwritten by `voidwolf-theme` in PR8).
