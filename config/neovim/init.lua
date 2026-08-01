-- voidwolf-nvim-v1 — lean developer defaults (PR12)
-- Not LazyVim: no plugin manager, stock Neovim only.
-- Installed as NVIM_APPNAME=voidwolf-nvim → ~/.config/voidwolf-nvim/

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("voidwolf.options")
require("voidwolf.keymaps")
require("voidwolf.autocmds")
