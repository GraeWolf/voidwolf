-- voidwolf neovim autocmds (PR12)
local aug = vim.api.nvim_create_augroup("voidwolf", { clear = true })

-- Highlight yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = aug,
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

-- Restore cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
  group = aug,
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Trim trailing whitespace on save (skip binary-ish buffers)
vim.api.nvim_create_autocmd("BufWritePre", {
  group = aug,
  callback = function()
    if vim.bo.binary or vim.bo.filetype == "diff" then
      return
    end
    local view = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- Terminal buffers: no numbers, start insert
vim.api.nvim_create_autocmd("TermOpen", {
  group = aug,
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.cmd("startinsert")
  end,
})
