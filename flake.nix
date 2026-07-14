{
  description = "NixOS configuration - Crivotz";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      # Pins home-manager to the same nixpkgs revision, preventing a second nixpkgs copy in the closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DankMaterialShell — Sway shell/widget layer used for the bar, greeter, and IPC keybindings.
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, neovim-nightly-overlay, dms, ... }:
    let
      system = "x86_64-linux";
      # Shared nixpkgs.* settings applied identically on both hosts, via the ordinary
      # nixpkgs module (no specialArgs.pkgs, so nixpkgs.config/overlays keep working
      # and hardware-configuration.nix can still set nixpkgs.hostPlatform itself).
      nixpkgsModule = {
        # Required for vscode, unrar, and other non-free packages in packages.nix.
        nixpkgs.config.allowUnfree = true;
        # Injects the neovim nightly build so `pkgs.neovim` resolves to nightly everywhere.
        nixpkgs.overlays = [ neovim-nightly-overlay.overlays.default ];
      };
    in
    {
      # Laptop (NIXMAU_LT)
      nixosConfigurations.NIXMAU_LT = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          nixpkgsModule
          ./hosts/NIXMAU_LT/configuration.nix
          dms.nixosModules.default
          dms.nixosModules.greeter
          home-manager.nixosModules.home-manager
          ({ pkgs, ... }: {
            home-manager = {
              # Share nixpkgs with the NixOS system to avoid building packages twice.
              useGlobalPkgs = true;
              # Install user packages into /etc/profiles/per-user instead of ~/.nix-profile.
              useUserPackages = true;
              # Forwards the pkgs set (with overlays) into home-manager modules.
              # stateVersion must match the NixOS version at the time of the original install.
              extraSpecialArgs = { inherit pkgs; stateVersion = "25.11"; };
              users.mauro = import ./home/home.nix;
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
          dms.nixosModules.greeter
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
