{
  description = "nix-darwin + home-manager dotfiles (macOS + Home Manager on Linux)";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-casks = {
      url = "github:atahanyorganci/nix-casks/archive";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    actrun = {
      url = "github:mizchi/actrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      home-manager,
      nixpkgs,
      ...
    }:
    let
      user = "ReoHakase";
      hostname = "reohakase";
      linuxSystem = "x86_64-linux";
      linuxUser = "reohakuta";
      linuxHmHostname = "reohakuta-kcvl";
      patchedApmFor =
        system:
        let
          pkgsForSystem = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        pkgsForSystem.callPackage ./pkgs/apm-codex-user-scope.nix {
          apm = inputs.llm-agents.packages.${system}.apm;
        };

      devShellFor =
        system:
        let
          pkgsForSystem = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        pkgsForSystem.mkShell {
          packages = [
            pkgsForSystem.commitlint-rs
            pkgsForSystem.dotenvx
            pkgsForSystem.git
            pkgsForSystem.lefthook
          ];
        };

      localOverlay = final: prev: {
        turso-cli = final.callPackage ./pkgs/turso-cli.nix { };
        similarity = final.callPackage ./pkgs/similarity.nix { };
      };

      pkgsLinux = import nixpkgs {
        system = linuxSystem;
        overlays = [
          inputs.actrun.overlays.default
          localOverlay
          (final: prev: {
            cursor-appimage = import ./pkgs/appimages/cursor.nix final;
            vicinae-appimage = final.callPackage ./pkgs/appimages/vicinae.nix { };
          })
        ];
        config.allowUnfree = true;
      };

      homeLinux = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsLinux;
        extraSpecialArgs = { inherit inputs; };
        modules = [ ./home/linux.nix ];
      };
    in
    {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit inputs self user;
        };
        modules = [
          inputs.nix-homebrew.darwinModules.nix-homebrew
          ./hosts/${hostname}.nix
          home-manager.darwinModules.home-manager
        ];
      };

      homeConfigurations."${linuxUser}@${linuxHmHostname}" = homeLinux;

      packages.${linuxSystem} = {
        apm = patchedApmFor linuxSystem;
        home-reohakuta-kcvl = homeLinux.activationPackage;
        ghostty = pkgsLinux.callPackage ./pkgs/gui/ghostty.nix { };
        cursor-appimage = pkgsLinux.cursor-appimage;
        turso-cli = pkgsLinux.turso-cli;
        similarity = pkgsLinux.similarity;
        vicinae-appimage = pkgsLinux.vicinae-appimage;
      };

      packages.aarch64-darwin = {
        apm = patchedApmFor "aarch64-darwin";
        turso-cli =
          (import nixpkgs {
            system = "aarch64-darwin";
            overlays = [ localOverlay ];
            config.allowUnfree = true;
          }).turso-cli;
        similarity =
          (import nixpkgs {
            system = "aarch64-darwin";
            overlays = [ localOverlay ];
            config.allowUnfree = true;
          }).similarity;
      };

      devShells.aarch64-darwin.default = devShellFor "aarch64-darwin";
      devShells.${linuxSystem}.default = devShellFor linuxSystem;
    };
}
