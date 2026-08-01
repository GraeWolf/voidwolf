-- voidwolf neovim options (PR12)
local o = vim.opt

o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.scrolloff = 6
o.sidescrolloff = 8

o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.smartindent = true
o.breakindent = true

o.ignorecase = true
o.smartcase = true
o.incsearch = true
o.hlsearch = true

o.termguicolors = true
o.mouse = "a"
o.clipboard = "unnamedplus"
o.completeopt = "menu,menuone,noselect"
o.updatetime = 250
o.timeoutlen = 400
o.splitright = true
o.splitbelow = true
o.wrap = false
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

o.undofile = true
o.swapfile = false
o.backup = false

o.confirm = true
o.wildmode = "longest:full,full"

-- Prefer ripgrep for :grep when available
if vim.fn.executable("rg") == 1 then
  o.grepprg = "rg --vimgrep --smart-case"
  o.grepformat = "%f:%l:%c:%m"
end
