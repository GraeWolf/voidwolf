-- voidwolf palette-driven colorscheme
-- Reads ~/.config/voidwolf/generated/nvim.lua written by voidwolf-theme.
-- Falls back to a dark default if missing.

local M = {}

local function hex_to_rgb(hex)
  hex = hex:gsub("#", "")
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

local function blend(fg, bg, alpha)
  -- alpha 0..1 toward bg
  local fr, fg_, fb = hex_to_rgb(fg)
  local br, bg_, bb = hex_to_rgb(bg)
  local r = math.floor(fr * (1 - alpha) + br * alpha)
  local g = math.floor(fg_ * (1 - alpha) + bg_ * alpha)
  local b = math.floor(fb * (1 - alpha) + bb * alpha)
  return string.format("#%02x%02x%02x", r, g, b)
end

local defaults = {
  bg = "#0b0c0e",
  fg = "#e6e8eb",
  accent = "#e6a23c",
  urgent = "#f07178",
  cursor = "#e6e8eb",
  color0 = "#0b0c0e",
  color1 = "#f07178",
  color2 = "#c3e88d",
  color3 = "#ffcb6b",
  color4 = "#82aaff",
  color5 = "#c792ea",
  color6 = "#89ddff",
  color7 = "#e6e8eb",
  color8 = "#4a5160",
  color9 = "#f07178",
  color10 = "#c3e88d",
  color11 = "#ffcb6b",
  color12 = "#82aaff",
  color13 = "#c792ea",
  color14 = "#89ddff",
  color15 = "#ffffff",
}

function M.load()
  local pal = vim.deepcopy(defaults)
  local gen = vim.fn.expand("~/.config/voidwolf/generated/nvim.lua")
  if vim.fn.filereadable(gen) == 1 then
    local ok, loaded = pcall(dofile, gen)
    if ok and type(loaded) == "table" then
      for k, v in pairs(loaded) do
        if type(v) == "string" then
          pal[k] = v
        end
      end
    end
  end

  vim.o.termguicolors = true
  vim.o.background = "dark"
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  vim.g.colors_name = "voidwolf"

  local bg, fg = pal.bg, pal.fg
  local dim = pal.color8 or blend(fg, bg, 0.55)
  local soft = blend(fg, bg, 0.15)
  local sel = blend(pal.accent, bg, 0.75)
  local line = blend(fg, bg, 0.92)

  local function hi(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi("Normal", { fg = fg, bg = bg })
  hi("NormalFloat", { fg = fg, bg = soft })
  hi("FloatBorder", { fg = pal.accent, bg = soft })
  hi("Cursor", { fg = bg, bg = pal.cursor or fg })
  hi("CursorLine", { bg = line })
  hi("CursorColumn", { bg = line })
  hi("CursorLineNr", { fg = pal.accent, bold = true })
  hi("LineNr", { fg = dim })
  hi("SignColumn", { fg = dim, bg = bg })
  hi("ColorColumn", { bg = soft })
  hi("VertSplit", { fg = dim, bg = bg })
  hi("WinSeparator", { fg = dim, bg = bg })
  hi("StatusLine", { fg = fg, bg = soft })
  hi("StatusLineNC", { fg = dim, bg = soft })
  hi("TabLine", { fg = dim, bg = soft })
  hi("TabLineSel", { fg = bg, bg = pal.accent, bold = true })
  hi("TabLineFill", { bg = bg })
  hi("Pmenu", { fg = fg, bg = soft })
  hi("PmenuSel", { fg = bg, bg = pal.accent })
  hi("PmenuSbar", { bg = soft })
  hi("PmenuThumb", { bg = dim })
  hi("Visual", { bg = sel })
  hi("Search", { fg = bg, bg = pal.color3 or pal.accent })
  hi("IncSearch", { fg = bg, bg = pal.accent })
  hi("MatchParen", { fg = pal.accent, bold = true })
  hi("NonText", { fg = dim })
  hi("Whitespace", { fg = dim })
  hi("SpecialKey", { fg = dim })
  hi("Directory", { fg = pal.color4 })
  hi("Title", { fg = pal.accent, bold = true })
  hi("Error", { fg = pal.urgent })
  hi("ErrorMsg", { fg = pal.urgent })
  hi("WarningMsg", { fg = pal.color3 })
  hi("ModeMsg", { fg = pal.accent })
  hi("MoreMsg", { fg = pal.color2 })
  hi("Question", { fg = pal.color2 })
  hi("Todo", { fg = pal.color3, bold = true })
  hi("Underlined", { underline = true })
  hi("Bold", { bold = true })
  hi("Italic", { italic = true })

  -- syntax
  hi("Comment", { fg = dim, italic = true })
  hi("Constant", { fg = pal.color5 })
  hi("String", { fg = pal.color2 })
  hi("Character", { fg = pal.color2 })
  hi("Number", { fg = pal.color5 })
  hi("Boolean", { fg = pal.color5 })
  hi("Float", { fg = pal.color5 })
  hi("Identifier", { fg = pal.color4 })
  hi("Function", { fg = pal.color4 })
  hi("Statement", { fg = pal.color1 })
  hi("Conditional", { fg = pal.color1 })
  hi("Repeat", { fg = pal.color1 })
  hi("Label", { fg = pal.color3 })
  hi("Operator", { fg = pal.color6 })
  hi("Keyword", { fg = pal.color5 })
  hi("Exception", { fg = pal.urgent })
  hi("PreProc", { fg = pal.color3 })
  hi("Include", { fg = pal.color5 })
  hi("Define", { fg = pal.color5 })
  hi("Macro", { fg = pal.color5 })
  hi("Type", { fg = pal.color3 })
  hi("StorageClass", { fg = pal.color3 })
  hi("Structure", { fg = pal.color3 })
  hi("Typedef", { fg = pal.color3 })
  hi("Special", { fg = pal.color6 })
  hi("SpecialChar", { fg = pal.color6 })
  hi("Tag", { fg = pal.color1 })
  hi("Delimiter", { fg = fg })
  hi("SpecialComment", { fg = dim })
  hi("Debug", { fg = pal.urgent })

  -- diagnostics (stock)
  hi("DiagnosticError", { fg = pal.urgent })
  hi("DiagnosticWarn", { fg = pal.color3 })
  hi("DiagnosticInfo", { fg = pal.color4 })
  hi("DiagnosticHint", { fg = pal.color6 })

  -- diff
  hi("DiffAdd", { fg = pal.color2, bg = soft })
  hi("DiffChange", { fg = pal.color3, bg = soft })
  hi("DiffDelete", { fg = pal.urgent, bg = soft })
  hi("DiffText", { fg = pal.accent, bg = sel })
end

return M
