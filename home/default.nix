{ config, pkgs, inputs, ... }:

let
  user = "ReoHakase";
  inherit (pkgs) lib;
  # NixCasks: add GUI apps here (after CI is green). Example:
  # nixCasks = with inputs.nix-casks.packages.${pkgs.system}; [ raycast slack ];
  nixCasks = [ ];
in
{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  xdg.enable = true;

  # Nix / HM の bin を先に。続けて Homebrew（`brew` コマンド用。CLI の重複は Nix が優先）。
  home.sessionPath = [
    "/etc/profiles/per-user/${user}/bin"
    "/nix/var/nix/profiles/default/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.cache/lm-studio/bin"
    "${config.home.homeDirectory}/.antigravity/antigravity/bin"
    "/Library/TeX/texbin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    # zsh-autosuggestions / zsh-syntax-highlighting は nixpkgs 由来（HM が .zshrc に source する）。brew 版は不要。
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    defaultKeymap = "emacs";
    # PATH の先頭付けは home.sessionPath のみ（profileExtra/initContent と重複させると which -a で同じパスが二重になる）
    # HM が plugins + user-abbreviations を配る（手動 source より確実）
    "zsh-abbr" = {
      enable = true;
      abbreviations = {
        gs = "git switch";
        gsc = "git switch -c";
        gpush = "git push origin HEAD";
        gpull = "git pull origin HEAD";
        "gc-" = "git reset --soft HEAD^";
        gc = "git commit -S";
        ghi = "gh issue create";
        ghp = "gh pr create";
        ghw = "gh repo view -w";
      };
    };
    initContent = ''
      export GPG_TTY=$(tty)

      if command -v wtp >/dev/null 2>&1; then
        eval "$(wtp shell-init zsh)"
      fi

      if command -v uv >/dev/null 2>&1; then
        eval "$(uv generate-shell-completion zsh)"
      fi

      # Tethering (hotspot) TTL workaround — requires sudo
      function hotspot() {
        if [ "$#" -ne 1 ]; then
          echo "Usage: ''${0} <on|off>"
          return
        fi
        local on_or_off="''${1}"
        if [ "''${on_or_off}" = "on" ]; then
          sudo sysctl net.inet.ip.ttl=65
          sudo networksetup -setv6off "Wi-Fi"
          echo "Hotspot mode is now enabled."
        else
          sudo sysctl net.inet.ip.ttl=64
          sudo networksetup -setv6automatic "Wi-Fi"
          echo "Hotspot mode is now disabled."
        fi
      }
    '';
    shellAliases = {
      ls = "eza";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.configFile."starship.toml".source = ../config/starship.toml;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    # nixd: `nixd` / `nixfmt` は home.packages。オプションは flake ルートの darwin 構成に合わせる。
    initLua = ''
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
    '';
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    # Silence HM warning: legacy default for stateVersion < 25.05
    signing.format = "openpgp";
  };

  programs.gh.enable = true;

  programs.fzf.enable = true;

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs;
    [
      # CLI は nixpkgs 優先。Homebrew の `brews` は tap 専用（例: wtp）以外は空にする。
      act
      arp-scan
      bat
      brotli
      cloc
      dnsutils # dig / host など（brew の bind クライアント相当）
      eza
      fastfetch
      fd
      ffmpeg
      fzf
      gcc
      gettext
      gh
      git
      gnupg
      graphviz
      guetzli
      hyperfine
      inetutils # telnet / ftp など
      jdk
      libwebp # cwebp, dwebp, …
      lzo
      lz4
      mise
      nixd
      nixfmt
      nmap
      opencode
      openssl
      pinentry_mac
      pkgconf
      rWrapper
      ripgrep
      supabase-cli
      tcl
      terminal-notifier
      tk # tcl-tk / wish 用（brew の tcl-tk の一部）
      tmux
      tree-sitter
      typst
      uv
      wget
      xz
      zstd
    ]
    ++ nixCasks;
}
