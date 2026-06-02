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
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    mizchi-skills = {
      url = "github:mizchi/skills/a2b5a796a5f22fc05fb515cef106993b84cf08cc";
      flake = false;
    };
    ast-grep-agent-skill = {
      url = "github:ast-grep/agent-skill/577f4d4507678f2c8cee150fae25e6ce309f70b1";
      flake = false;
    };
    reohakase-skills = {
      url = "github:ReoHakase/skills/bdc317003cc64835552a5df26ba1ed7159f9964d";
      flake = false;
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
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      devShellFor =
        system:
        let
          pkgsForSystem = pkgsFor system;
        in
        pkgsForSystem.mkShell {
          packages = [
            pkgsForSystem.commitlint-rs
            pkgsForSystem.deadnix
            pkgsForSystem.dotenvx
            pkgsForSystem.git
            pkgsForSystem.lefthook
            pkgsForSystem.nixfmt
            pkgsForSystem.statix
          ];
        };

      localOverlay =
        final: _prev:
        {
          mole = final.callPackage ./pkgs/mole.nix { };
          turso-cli = final.callPackage ./pkgs/turso-cli.nix { };
          similarity = final.callPackage ./pkgs/similarity.nix { };
          harano-aji-fonts = final.callPackage ./pkgs/harano-aji-fonts.nix { };
        }
        // _prev.lib.optionalAttrs _prev.stdenv.hostPlatform.isDarwin {
          matio = _prev.matio.overrideAttrs (old: {
            postFixup = (old.postFixup or "") + ''
              hdf5Dylibs=(${final.hdf5}/lib/libhdf5.[0-9]*.dylib)
              hdf5AbiDylibs=()
              for candidate in "''${hdf5Dylibs[@]}"; do
                case "$(basename "$candidate")" in
                  *.*.*.dylib) ;;
                  *) hdf5AbiDylibs+=("$candidate") ;;
                esac
              done

              if [ "''${#hdf5AbiDylibs[@]}" -ne 1 ]; then
                echo "expected exactly one hdf5 ABI dylib, found ''${#hdf5AbiDylibs[@]}" >&2
                exit 1
              fi

              hdf5Dylib="''${hdf5AbiDylibs[0]}"
              install_name_tool -change "@rpath/$(basename "$hdf5Dylib")" "$hdf5Dylib" "$out/lib/libmatio.13.dylib"
            '';
          });
        };

      pkgsLinux = import nixpkgs {
        system = linuxSystem;
        overlays = [
          inputs.actrun.inputs.moonbit-overlay.overlays.default
          inputs.actrun.overlays.default
          localOverlay
          (final: _prev: {
            cursor-appimage = import ./pkgs/appimages/cursor.nix final;
            vicinae-appimage = final.callPackage ./pkgs/appimages/vicinae.nix { };
          })
        ];
        config.allowUnfree = true;
      };
      pkgsDarwin = import nixpkgs {
        system = "aarch64-darwin";
        overlays = [ localOverlay ];
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
          inherit
            inputs
            localOverlay
            self
            user
            ;
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
        inherit (pkgsLinux)
          cursor-appimage
          harano-aji-fonts
          proton-vpn
          similarity
          turso-cli
          veracrypt
          vicinae-appimage
          ;
      };

      packages.aarch64-darwin = {
        inherit (pkgsDarwin)
          harano-aji-fonts
          mole
          similarity
          turso-cli
          ;
      };

      devShells.aarch64-darwin.default = devShellFor "aarch64-darwin";
      devShells.${linuxSystem}.default = devShellFor linuxSystem;
    };
}
