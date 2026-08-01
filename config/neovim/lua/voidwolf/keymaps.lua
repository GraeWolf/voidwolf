-- voidwolf neovim keymaps (PR12)
local map = vim.keymap.set

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Save / quit conveniences
map({ "n", "i" }, "<C-s>", "<cmd>write<CR>", { desc = "Save" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })
map("n", "<leader>x", "<cmd>xit<CR>", { desc = "Save and quit" })

-- Window navigation (aligns with common vim muscle memory)
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Buffers
map("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- Diagnostics (built-in LSP UI; no plugins required)
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Diagnostics list" })

-- Better indent stay in visual
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Move lines in visual mode
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Center search jumps
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
