#!/usr/bin/env bash
# Validate PR12 bash + neovim defaults.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0

need() {
	if [[ -f "$1" ]]; then
		echo "OK   $1"
	else
		echo "FAIL missing $1"
		fail=1
	fi
}

need_pat() {
	local file="$1" pat="$2" desc="$3"
	if rg -q "$pat" "$file"; then
		echo "OK   $desc"
	else
		echo "FAIL $desc ($file ~ /$pat/)"
		fail=1
	fi
}

need "${ROOT}/config/bash/voidwolf-path.sh"
need "${ROOT}/config/bash/voidwolf-rc.sh"
need "${ROOT}/config/bash/voidwolf-profile.sh"
need "${ROOT}/config/neovim/init.lua"
need "${ROOT}/config/neovim/lua/voidwolf/options.lua"
need "${ROOT}/config/neovim/lua/voidwolf/keymaps.lua"
need "${ROOT}/config/neovim/lua/voidwolf/autocmds.lua"
need "${ROOT}/docs/bash-nvim.md"

need_pat "${ROOT}/config/bash/voidwolf-path.sh" '\.local/bin' "path puts ~/.local/bin first"
need_pat "${ROOT}/config/bash/voidwolf-rc.sh" 'voidwolf-bash-rc-v1' "rc has version marker"
need_pat "${ROOT}/config/bash/voidwolf-rc.sh" 'NVIM_APPNAME=voidwolf-nvim' "rc sets NVIM_APPNAME"
need_pat "${ROOT}/config/bash/voidwolf-rc.sh" 'bash-completion' "rc loads bash-completion"
need_pat "${ROOT}/config/bash/voidwolf-profile.sh" 'voidwolf-bash-profile-v1' "profile has version marker"
need_pat "${ROOT}/config/bash/voidwolf-profile.sh" 'startx' "profile documents auto-startx"
need_pat "${ROOT}/config/neovim/init.lua" 'voidwolf-nvim-v1' "init.lua version marker"
need_pat "${ROOT}/config/neovim/init.lua" 'require\("voidwolf.options"\)' "init requires options"
need_pat "${ROOT}/config/neovim/lua/voidwolf/options.lua" 'undofile' "options: undofile"
need_pat "${ROOT}/config/neovim/init.lua" 'mapleader' "mapleader set"
need_pat "${ROOT}/config/neovim/lua/voidwolf/keymaps.lua" 'diagnostic' "keymaps: diagnostics"

# install-dotfiles understands nvim/bash
need_pat "${ROOT}/bootstrap/install-dotfiles.sh" 'voidwolf-rc.sh' "install-dotfiles installs bash rc"
need_pat "${ROOT}/bootstrap/install-dotfiles.sh" 'voidwolf-nvim' "install-dotfiles installs voidwolf-nvim"
need_pat "${ROOT}/bootstrap/install-dotfiles.sh" 'skip-nvim' "install-dotfiles --skip-nvim"

# dry-run into temp home
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if bash "${ROOT}/bootstrap/install-dotfiles.sh" --dry-run --home "$tmp" >/dev/null; then
	echo "OK   install-dotfiles --dry-run (bash/nvim path)"
else
	echo "FAIL install-dotfiles --dry-run"
	fail=1
fi

# real install into temp home (no touch user)
if bash "${ROOT}/bootstrap/install-dotfiles.sh" --home "$tmp" --skip-pipewire >/dev/null; then
	echo "OK   install-dotfiles --home temp"
else
	echo "FAIL install-dotfiles --home temp"
	fail=1
fi

for f in voidwolf-path.sh voidwolf-rc.sh voidwolf-profile.sh; do
	if [[ -f "${tmp}/.config/voidwolf/${f}" ]]; then
		echo "OK   installed ${f}"
	else
		echo "FAIL missing installed ${f}"
		fail=1
	fi
done

if [[ -f "${tmp}/.config/voidwolf-nvim/init.lua" && -f "${tmp}/.config/voidwolf-nvim/lua/voidwolf/options.lua" ]]; then
	echo "OK   installed voidwolf-nvim tree"
else
	echo "FAIL voidwolf-nvim tree incomplete under temp home"
	fail=1
fi

if [[ -f "${tmp}/.bashrc" ]] && grep -q 'voidwolf-rc.sh' "${tmp}/.bashrc"; then
	echo "OK   temp bashrc sources voidwolf-rc"
else
	echo "FAIL temp bashrc missing voidwolf-rc source"
	fail=1
fi

# nvim headless loads config (if nvim present)
if command -v nvim >/dev/null 2>&1; then
	if NVIM_APPNAME=voidwolf-nvim XDG_CONFIG_HOME="${tmp}/.config" \
		nvim --headless "+lua require('voidwolf.options')" "+qa" 2>/dev/null; then
		echo "OK   nvim headless loads voidwolf options"
	else
		# XDG_CONFIG_HOME may need voidwolf-nvim under it - we installed to tmp/.config/voidwolf-nvim
		if NVIM_APPNAME=voidwolf-nvim XDG_CONFIG_HOME="${tmp}/.config" \
			nvim --headless "+qa" 2>/tmp/voidwolf-nvim-test.err; then
			echo "OK   nvim headless +qa with voidwolf-nvim"
		else
			echo "FAIL nvim headless failed:"
			cat /tmp/voidwolf-nvim-test.err 2>/dev/null || true
			fail=1
		fi
	fi
else
	echo "SKIP nvim not installed"
fi

if [[ "$fail" -ne 0 ]]; then
	echo "bash-nvim-validate: FAILED"
	exit 1
fi
echo "bash-nvim-validate: all OK"
