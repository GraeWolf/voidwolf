# Bash & Neovim (PR12)

Lean developer defaults. **Not** a full distro-of-dotfiles or LazyVim clone.

## Install

```bash
./bootstrap/install-dotfiles.sh
# or full bootstrap (includes this)
./bootstrap/bootstrap.sh --profile desktop --gpu none --with-suckless
```

## Bash

| File (repo) | Install path | Role |
|-------------|--------------|------|
| `config/bash/voidwolf-path.sh` | `~/.config/voidwolf/voidwolf-path.sh` | `~/.local/bin` first on PATH |
| `config/bash/voidwolf-rc.sh` | `~/.config/voidwolf/voidwolf-rc.sh` | Interactive aliases, history, prompt, completion |
| `config/bash/voidwolf-profile.sh` | `~/.config/voidwolf/voidwolf-profile.sh` | Login: source bashrc; auto-startx **commented OFF** |

`install-dotfiles.sh` appends source lines to `~/.bashrc` and `~/.bash_profile` if missing (does not replace your whole shell rc).

### fastfetch

Interactive bash runs **fastfetch** once per shell session (package: `fastfetch` on the desktop-required list).

```bash
export VOIDWOLF_NO_FASTFETCH=1   # disable
```

### Opt-outs

```bash
# Disable voidwolf PS1
export VOIDWOLF_PROMPT_OFF=1

# Disable multi-terminal shared history refresh
export VOIDWOLF_NO_SHARED_HISTORY=1

# Disable fastfetch on shell start
export VOIDWOLF_NO_FASTFETCH=1

# Use a different nvim config (see below)
export NVIM_APPNAME=nvim   # stock ~/.config/nvim
# or: unset NVIM_APPNAME
```

### Auto-startx

Default **OFF**. Edit `~/.config/voidwolf/voidwolf-profile.sh` (or your `~/.bash_profile`) and uncomment the tty1 block. See [session.md](session.md).

## Neovim

| Item | Value |
|------|--------|
| App name | `voidwolf-nvim` |
| Config dir | `~/.config/voidwolf-nvim/` |
| Marker | `voidwolf-nvim-v1` in `init.lua` |

voidwolf **does not overwrite** an existing `~/.config/nvim`. Instead it installs a parallel config and sets:

```bash
export NVIM_APPNAME=voidwolf-nvim   # from voidwolf-rc.sh when config present
```

So `nvim`, Super+Shift+N (`st -e nvim`), and aliases `v`/`vi`/`vim` use the lean voidwolf config. Your previous config remains at `~/.config/nvim` (or wherever it lived).

### What’s included

- Options: numbers, 2-space indent, undofile, clipboard, ripgrep `:grep`
- Leader `Space`: save/quit, buffers, diagnostics float
- Ctrl-h/j/k/l window nav, yank highlight, trim trailing whitespace on save
- **Colorscheme** from active voidwolf theme (`voidwolf.colors` + `~/.config/voidwolf/generated/nvim.lua`)
- **No** plugin manager, LSP servers, or treesitter packs (add your own later)

### Use your old config again

```bash
# session-only
NVIM_APPNAME=nvim nvim

# permanent: put in ~/.bashrc after voidwolf-rc, or edit voidwolf-rc
export NVIM_APPNAME=nvim
```

## Related

- [session.md](session.md)
- [helpers.md](helpers.md)
- [keybindings.md](keybindings.md) — Super+Shift+N → nvim
