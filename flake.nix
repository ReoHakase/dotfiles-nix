{
  description = "nix-darwin + home-manager dotfiles";

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
    # Homebrew 本体（brew バイナリ）を Nix でピン留めし、nix-darwin の homebrew.* と併用する
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, home-manager, nixpkgs, ... }:
    let
      user = "ReoHakase";
      hostname = "reohakase";
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
    };
}
