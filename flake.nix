{
  description = "NixOS configuration - Crivotz";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    # Only used to pull individual packages (e.g. netwatch) not yet backported to stable.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      # Pins home-manager to the same nixpkgs revision, preventing a second nixpkgs copy in the closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DankMaterialShell — Sway shell/widget layer used for the bar, greeter, and IPC keybindings.
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    copilot-cli-flake.url = "github:scarisey/copilot-cli-flake";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # IRIS — CLI autocomplete/navigation tool (https://github.com/versenilvis/IRIS)
    iris.url = "github:versenilvis/iris/main";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, dms, copilot-cli-flake, zen-browser, iris, ... }:
    let
      system = "x86_64-linux";
      pkgsUnstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      # Shared nixpkgs.* settings applied identically on both hosts, via the ordinary
      # nixpkgs module (no specialArgs.pkgs, so nixpkgs.config/overlays keep working
      # and hardware-configuration.nix can still set nixpkgs.hostPlatform itself).
      nixpkgsModule = {
        # Required for vscode, unrar, and other non-free packages in packages.nix.
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [
          (final: prev: {
            github-copilot-cli = copilot-cli-flake.packages.${system}.default;
            zen-browser = zen-browser.packages.${system}.default;
            # Not yet backported to nixos-26.05 stable (added to unstable 2026-05-31, after the freeze).
            # Drop this once we move to nixos-26.11 ("Zokor").
            netwatch = pkgsUnstable.netwatch;
            # Upstream's flake.nix hardcodes a vendorHash computed against nixpkgs-unstable.
            # Since we follow our own nixpkgs (26.05 stable), the go module vendoring output
            # differs, so the hash must be overridden to the value nix actually computes here.
            iris = iris.packages.${system}.default.overrideAttrs (old: {
              vendorHash = "sha256-huyTWK6ef42KY2zmFIQuFoeR8B8XKHE7OVfFnfefeCU=";
            });
          })
        ];
      };
      # Grants netwatch raw-socket capabilities via a setcap wrapper in /run/wrappers/bin
      # (which precedes the home-manager profile in PATH), since it's a home.packages
      # entry and can't otherwise open packet-capture sockets as a regular user.
      netwatchWrapperModule = { pkgs, ... }: {
        security.wrappers.netwatch = {
          owner = "root";
          group = "root";
          capabilities = "cap_net_raw,cap_net_admin+ep";
          source = "${pkgs.netwatch}/bin/netwatch";
        };
      };
    in
    {
      # Laptop (NIXMAULT)
      nixosConfigurations.NIXMAULT = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          nixpkgsModule
          netwatchWrapperModule
          ./hosts/NIXMAULT/configuration.nix
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
          netwatchWrapperModule
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
