---@type LazySpec
return {
  "nosduco/remote-sshfs.nvim",
  cmd = {
    "RemoteSSHFSConnect",
    "RemoteSSHFSDisconnect",
    "RemoteSSHFSEdit",
    "RemoteSSHFSFindFiles",
    "RemoteSSHFSLiveGrep",
  },
  dependencies = {
    "folke/snacks.nvim",
    "nvim-lua/plenary.nvim",
  },
  opts = {
    ui = {
      picker = "snacks",
    },
  },
  keys = {
    {
      "<Leader>rc",
      function() require("remote-sshfs.api").connect() end,
      desc = "Remote SSHFS Connect",
    },
    {
      "<Leader>rd",
      function() require("remote-sshfs.api").disconnect() end,
      desc = "Remote SSHFS Disconnect",
    },
    {
      "<Leader>re",
      function() require("remote-sshfs.api").edit() end,
      desc = "Remote SSHFS Edit SSH Config",
    },
    {
      "<Leader>rf",
      function() require("remote-sshfs.api").find_files() end,
      desc = "Remote SSHFS Find Files",
    },
    {
      "<Leader>rg",
      function() require("remote-sshfs.api").live_grep() end,
      desc = "Remote SSHFS Live Grep",
    },
  },
}
