---@type LazySpec
return {
  "petertriho/nvim-scrollbar",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    handlers = {
      cursor = true,
      diagnostic = true,
      gitsigns = true,
      handle = true,
      search = false,
    },
  },
  config = function(_, opts) require("scrollbar").setup(opts) end,
}
