{
  description = "NixOS configuration - Crivotz";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
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
      pkgs = import nixpkgs {
        inherit system;
        # Required for vscode, unrar, and other non-free packages in packages.nix.
        config.allowUnfree = true;
        # Injects the neovim nightly build so `pkgs.neovim` resolves to nightly everywhere.
        overlays = [ neovim-nightly-overlay.overlays.default ];
      };
    in
    {
      # Laptop (NIXMAU_LT)
      nixosConfigurations.NIXMAU_LT = nixpkgs.lib.nixosSystem {
        inherit system;
        # Passes the pre-built pkgs set (with overlays and allowUnfree) into all NixOS modules.
        specialArgs = { inherit pkgs; };
        modules = [
          ./hosts/NIXMAU_LT/configuration.nix
          dms.nixosModules.default
          dms.nixosModules.greeter
          home-manager.nixosModules.home-manager
          {
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
          }
        ];
      };

      # Desktop (NIXMAU)
      nixosConfigurations.NIXMAU = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit pkgs; };
        modules = [
          ./hosts/NIXMAU/configuration.nix
          dms.nixosModules.default
          dms.nixosModules.greeter
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit pkgs; stateVersion = "25.11"; };
              users.mauro = import ./home/home-desktop.nix;
            };
          }
        ];
      };

    };
}
