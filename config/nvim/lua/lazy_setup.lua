require("lazy").setup({
  {
    "AstroNvim/AstroNvim",
    -- v6.0 (2026-03-30) で nvim-treesitter が main ブランチへ正式移行。
    -- 旧 master ブランチは upstream archive 済みで nvim 0.12 の
    -- Query:iter_matches 変更（`all = false` 削除）に追従しておらず、
    -- Markdown 等を開いた瞬間 `attempt to call method 'range' (a nil value)`
    -- で落ちる。v6 以降にピンして main ブランチの nvim-treesitter を引く。
    version = "^6", -- Remove version tracking to elect for nightly AstroNvim
    import = "astronvim.plugins",
    opts = { -- AstroNvim options must be set here with the `import` key
      mapleader = " ", -- This ensures the leader key must be configured before Lazy is set up
      maplocalleader = ",", -- This ensures the localleader key must be configured before Lazy is set up
      icons_enabled = true, -- Set to false to disable icons (if no Nerd Font is available)
      pin_plugins = nil, -- Default will pin plugins when tracking `version` of AstroNvim, set to true/false to override
      update_notifications = true, -- Enable/disable notification about running `:Lazy update` twice to update pinned plugins
    },
  },
  { import = "community" },
  { import = "plugins" },
} --[[@as LazySpec]], {
  -- Configure any other `lazy.nvim` configuration options here
  install = { colorscheme = { "onedark_dark", "astrotheme", "habamax" } },
  ui = { backdrop = 100 },
  performance = {
    rtp = {
      -- disable some rtp plugins, add more to your liking
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "zipPlugin",
      },
    },
  },
} --[[@as LazyConfig]])
