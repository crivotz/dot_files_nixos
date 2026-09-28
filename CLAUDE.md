# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

NixOS system configuration using Flakes + Home Manager. Manages two `x86_64-linux` NixOS hosts:
- **NIXMAU** — desktop
- **NIXMAULT** — laptop

A third, standalone (non-NixOS) Home Manager profile — `homeConfigurations."mauro@debian"` in `flake.nix`, built from `home/home-debian.nix` + `home/packages-debian.nix` — targets a Debian machine.

## Key commands

Apply `.nix` changes (no package updates, fast):
```bash
sudo nixos-rebuild switch --flake . --impure
```
The host is auto-detected from the machine's hostname (`networking.hostName`).

Update all flake inputs then rebuild (equivalent to `apt upgrade`):
```bash
nix flake update
sudo nixos-rebuild switch --flake . --impure
```

Garbage-collect old generations:
```bash
sudo nix-collect-garbage -d
```

Dry-run to preview what would change without applying:
```bash
sudo nixos-rebuild dry-activate --flake .
```

## Architecture

```
flake.nix                              # inputs + nixosConfigurations for NIXMAU and NIXMAULT (+ standalone homeConfigurations."mauro@debian")
hosts/NIXMAU/configuration.nix         # desktop: system-level config (boot, services, users, fonts)
hosts/NIXMAULT/configuration.nix      # laptop: same structure, adds power management + backlight
config/                                # dotfiles symlinked into $HOME via home.file (ghostty, lazygit, bat, eza, ruby, p10k, DankMaterialShell, claude)
home/home-laptop.nix                   # home-manager entry point for laptop (NIXMAULT)
home/home-desktop.nix                  # home-manager entry point for desktop (NIXMAU)
home/home-debian.nix                   # standalone home-manager entry point for the Debian machine
home/packages.nix                      # user packages shared between both NixOS hosts
home/programs/                         # per-program config; desktop variants use -desktop.nix, laptop use -laptop.nix suffix
home/services/syncthing.nix            # syncthing user service
devenv-example/devenv.nix              # copy-paste template for Ruby on Rails projects
```

### Flake inputs

| Input | Purpose |
|---|---|
| `nixpkgs` (nixos-26.05 stable) | All packages |
| `nixpkgs-unstable` | Cherry-picked packages not yet backported to stable |
| `home-manager` | User-level config, follows nixpkgs |
| `dms` (DankMaterialShell/stable) | Sway/Hyprland shell/widget layer (bar, IPC keybindings) |
| `dank-greeter` | dms-greeter (split out of the `dms` flake into its own repo) |
| `copilot-cli-flake`, `zen-browser`, `iris`, `nix-graph` | Individual package overlays (GitHub Copilot CLI, Zen Browser, IRIS CLI, nix-graph) |

Neovim uses the plain `nixpkgs` package (no nightly overlay).

### Sibling repos auto-synced at rebuild

`home.activation.syncPrivate` clones (first run) or `git pull --ff-only` (subsequent runs):
- `crivotz/nubem_dot_files` → `~/.nubem_dot_files` (private: gitconfig, zsh_aliases, nubem_env, tmuxp)
- `crivotz/nv-ide` → `~/.nv-ide` (Neovim/LazyVim config)
- `crivotz/gcheck` → `~/.gcheck`

All other dotfiles (ghostty, lazygit, bat, eza, ruby, p10k, DankMaterialShell, claude statusline) live in `config/` inside this repo and are symlinked via `home.file`.

### Desktop vs laptop differences

| Feature | NIXMAU (desktop) | NIXMAULT (laptop) |
|---|---|---|
| GNOME | enabled (additional session) | enabled (additional session) |
| Power profiles | no | `power-profiles-daemon` |
| Backlight | DDC/CI via dms | `brightnessctl` |
| Hyprland config | `hyprland-desktop.nix` | `hyprland-laptop.nix` |

Sway is currently **disabled** on both hosts — `programs.sway` is commented out at the system level (`hosts/*/configuration.nix`) and the home-manager Sway modules (`home/programs/sway-desktop.nix`, `home/programs/sway-laptop.nix`) are commented out of the `imports` list in `home/home-desktop.nix` / `home/home-laptop.nix`. The files are kept as commented-out fallbacks, not actively maintained. Hyprland is the only compositor in use.

### LSP / Neovim

Mason is disabled. All LSPs and formatters are installed as Nix packages via `extraPackages` in `home/programs/neovim.nix`. To add an LSP, add the package there and rebuild.

### devenv (Ruby on Rails projects)

`devenv-example/devenv.nix` is a template. Copy it to a project root, add `.envrc` with `use devenv`, run `direnv allow`. It provisions per-project PostgreSQL + Redis and sets `DATABASE_URL`/`REDIS_URL` automatically.

## Display manager

Both hosts use **dms-greeter** (`programs.dms-greeter`, `compositor.name = "hyprland"`). Built on greetd. Hyprland and GNOME are selectable as sessions at login on both hosts (Sway is disabled — see above).

Check module API with: `nix flake show github:AvengeMedia/DankMaterialShell/stable`

## Manual post-install steps

These must be done manually after a fresh install:

- **Syncthing**: open the web UI (`http://localhost:8384`) and pair with other devices
- **Atuin**: `atuin login` to sync shell history
- **GitHub CLI**: `gh auth login` to authenticate (needed by the activation script to clone private repos)

## Hardware-specific notes

- `hardware-configuration.nix` is machine-generated and read from `/etc/nixos/hardware-configuration.nix` (absolute path in `configuration.nix`), not in this repo.
- Monitor output names (`eDP-1`, `DP-1`, etc.) are configured in the Hyprland program files (`home/programs/hyprland-desktop.nix`, `home/programs/hyprland-laptop.nix`). Use `wdisplays` or `hyprctl monitors -j` to identify them.
- **NIXMAULT lid-switch handling**: `services.logind.settings.Login.HandleLidSwitch = "ignore"` (both hosts) so logind never auto-suspends on lid close — this is delegated entirely to `home/programs/hyprland-laptop.nix`'s `bindl switch:on:Lid Switch`, which disables `eDP-1` and then calls `systemctl suspend` *only if* no external monitor is detected as active (so closing the lid while docked doesn't suspend). If suspend doesn't happen on lid close outside the office dock, check that logic first — `services.logind` shows the lid open/close events in `journalctl` even though it takes no action on them, which is useful for diagnosing whether the Hyprland-side suspend script actually ran.
