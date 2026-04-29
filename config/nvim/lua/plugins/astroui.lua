---@type LazySpec
return {
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000,
    opts = {
      colors = {
        onedark_dark = {
          bg = "#16191d",
          fg = "#abb2bf",
          gray = "#7f848e",
          red = "#e06c75",
          orange = "#d19a66",
          yellow = "#e5c07b",
          green = "#98c379",
          cyan = "#56b6c2",
          blue = "#61afef",
          purple = "#c678dd",
        },
      },
      highlights = {
        CursorLine = { bg = "#2c313c" },
        LineNr = { fg = "#667187" },
        PmenuSel = { bg = "#2c313a", fg = "#d7dae0" },
        TabLineSel = { bg = "#23272e", fg = "#dcdcdc" },
        WinSeparator = { fg = "#3e4452" },
      },
      options = {
        cursorline = true,
        terminal_colors = true,
        transparency = true,
      },
    },
  },
  {
    "AstroNvim/astroui",
    ---@type AstroUIOpts
    opts = {
      colorscheme = "onedark_dark",
    },
  },
}
