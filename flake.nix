{
  description = "NixOS configuration - Crivotz";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      # Pins home-manager to the same nixpkgs revision, preventing a second nixpkgs copy in the closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DankMaterialShell — Sway shell/widget layer used for the bar and IPC keybindings.
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # dms-greeter moved out of the dms flake into its own repo.
    dank-greeter = {
      url = "github:AvengeMedia/dank-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    copilot-cli-flake.url = "github:scarisey/copilot-cli-flake";

    # Better nix-tree
    nix-graph = {
      url = "github:AlexAntonik/nix-graph";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, dms, dank-greeter, copilot-cli-flake, nix-graph, ... }:
    let
      system = "x86_64-linux";
      # Shared nixpkgs.* settings applied identically on both hosts, via the ordinary
      # nixpkgs module (no specialArgs.pkgs, so nixpkgs.config/overlays keep working
      # and hardware-configuration.nix can still set nixpkgs.hostPlatform itself).
      nixpkgsModule = {
        # Required for vscode, unrar, and other non-free packages in packages.nix.
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [
          (final: prev: {
            github-copilot-cli = copilot-cli-flake.packages.${system}.default;
            nix-graph = nix-graph.packages.${system}.nix-graph;
            # Bundled onig (in 3rdparty/edbee-lib) fails to build against newer GCC's
            # stricter C23-by-default dialect ("too many arguments to function" on
            # old K&R-style ANYARGS callbacks). Force gnu17 for C sources only
            # (CMAKE_C_FLAGS, not NIX_CFLAGS_COMPILE, so C++ sources are unaffected).
            mudlet = prev.mudlet.overrideAttrs (old: {
              cmakeFlags = (old.cmakeFlags or [ ]) ++ [
                "-DCMAKE_C_FLAGS=-std=gnu17 -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types"
              ];
            });
          })
        ];
      };
    in
    {
      # Standalone Home Manager profile for a non-NixOS (Debian) machine: `nix` runs as a
      # regular package manager on top of apt, no nixosConfigurations/system integration.
      # Only for tools that are missing or outdated on apt — see home/packages-debian.nix.
      homeConfigurations."mauro@debian" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        extraSpecialArgs = { stateVersion = "26.05"; };
        modules = [ ./home/home-debian.nix ];
      };

      # Laptop (NIXMAULT)
      nixosConfigurations.NIXMAULT = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          nixpkgsModule
          ./hosts/NIXMAULT/configuration.nix
          dms.nixosModules.default
          dank-greeter.nixosModules.default
          home-manager.nixosModules.home-manager
          ({ pkgs, ... }: {
            home-manager = {
              # Share nixpkgs with the NixOS system to avoid building packages twice.
              useGlobalPkgs = true;
              # Install user packages into /etc/profiles/per-user instead of ~/.nix-profile.
              useUserPackages = true;
              # Forwards the pkgs set (with overlays) into home-manager modules.
              # stateVersion must match the NixOS version at the time of the original install.
              extraSpecialArgs = { inherit pkgs; stateVersion = "26.05"; };
              users.mauro = import ./home/home-laptop.nix;
            };
          })
        ];
      };

      # Desktop (NIXMAU)
      nixosConfigurations.NIXMAU = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          nixpkgsModule
          ./hosts/NIXMAU/configuration.nix
          dms.nixosModules.default
          dank-greeter.nixosModules.default
          home-manager.nixosModules.home-manager
          ({ pkgs, ... }: {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit pkgs; stateVersion = "26.05"; };
              users.mauro = import ./home/home-desktop.nix;
            };
          })
        ];
      };

    };
}
