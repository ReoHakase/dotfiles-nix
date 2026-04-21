{
  description = "nix-darwin + home-manager dotfiles (macOS + Home Manager on Linux)";

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
  };

  outputs =
    inputs@{ self, nix-darwin, home-manager, nixpkgs, ... }:
    let
      user = "ReoHakase";
      hostname = "reohakase";
      linuxSystem = "x86_64-linux";
      linuxUser = "reohakuta";
      linuxHmHostname = "reohakuta-kcvl";

      pkgsLinux = import nixpkgs {
        system = linuxSystem;
        overlays = [
          inputs.actrun.overlays.default
          (import ./pkgs/npm)
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
        home-reohakuta-kcvl = homeLinux.activationPackage;
        ghostty = pkgsLinux.callPackage ./pkgs/gui/ghostty.nix { };
        cursor-appimage = pkgsLinux.cursor-appimage;
        vicinae-appimage = pkgsLinux.vicinae-appimage;
      };
    };
}
