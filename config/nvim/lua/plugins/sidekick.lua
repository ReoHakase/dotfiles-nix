---@type LazySpec
return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      panel = { enabled = true },
      suggestion = {
        enabled = true,
        auto_trigger = true,
      },
    },
    config = function(_, opts)
      require("copilot").setup(opts)
      pcall(vim.lsp.enable, "copilot")
    end,
  },
  {
    "folke/sidekick.nvim",
    dependencies = { "zbirenbaum/copilot.lua" },
    opts = {
      cli = {
        mux = {
          backend = "tmux",
          enabled = true,
        },
      },
    },
    keys = {
      {
        "<Tab>",
        function()
          if require("sidekick").nes_jump_or_apply() then return "" end
          local inline_completion = vim.lsp.inline_completion
          if inline_completion and inline_completion.get() then return "" end
          return "<Tab>"
        end,
        mode = { "i", "n" },
        expr = true,
        desc = "Goto/Apply Next Edit Suggestion",
      },
      {
        "<C-.>",
        function() require("sidekick.cli").focus() end,
        desc = "Sidekick Focus",
        mode = { "n", "t", "i", "x" },
      },
      {
        "<Leader>aa",
        function() require("sidekick.cli").toggle() end,
        desc = "Sidekick Toggle CLI",
      },
      {
        "<Leader>as",
        function() require("sidekick.cli").select() end,
        desc = "Sidekick Select CLI",
      },
      {
        "<Leader>ad",
        function() require("sidekick.cli").close() end,
        desc = "Sidekick Detach CLI Session",
      },
      {
        "<Leader>at",
        function() require("sidekick.cli").send { msg = "{this}" } end,
        mode = { "x", "n" },
        desc = "Sidekick Send This",
      },
      {
        "<Leader>af",
        function() require("sidekick.cli").send { msg = "{file}" } end,
        desc = "Sidekick Send File",
      },
      {
        "<Leader>av",
        function() require("sidekick.cli").send { msg = "{selection}" } end,
        mode = "x",
        desc = "Sidekick Send Visual Selection",
      },
      {
        "<Leader>ap",
        function() require("sidekick.cli").prompt() end,
        mode = { "n", "x" },
        desc = "Sidekick Select Prompt",
      },
      {
        "<Leader>ac",
        function() require("sidekick.cli").toggle { name = "codex", focus = true } end,
        desc = "Sidekick Toggle Codex",
      },
    },
  },
}
