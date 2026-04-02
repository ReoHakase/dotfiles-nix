-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

vim.filetype.add({ extension = { nix = "nix" } })
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "nix" },
  callback = function(args)
    local path = vim.api.nvim_buf_get_name(args.buf)
    local root = path ~= "" and vim.fs.root(path, { "flake.nix", ".git" }) or nil
    vim.lsp.start({
      name = "nixd",
      cmd = { "nixd" },
      root_dir = root,
      settings = {
        nixd = {
          nixpkgs = { expr = "import <nixpkgs> { }" },
          formatting = { command = { "nixfmt" } },
          options = {
            ["nix-darwin"] = {
              expr = "(builtins.getFlake (builtins.toString ./.)).darwinConfigurations.reohakase.options",
            },
          },
        },
      },
    })
  end,
})
