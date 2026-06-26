# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

NixOS system configuration using Flakes + Home Manager. Manages a single `x86_64-linux` host (`nixos`).

## Key commands

Apply `.nix` changes (no package updates, fast):
```bash
sudo nixos-rebuild switch --flake . --impure
```

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
flake.nix                          # inputs + single nixosConfiguration "nixos"
hosts/nixos/configuration.nix      # system-level: boot, services, users, fonts, nix settings
hosts/nixos/hardware-configuration.nix  # machine-specific, NOT in git
home/home.nix                      # home-manager entry point; activation clones/pulls sibling repos
home/packages.nix                  # user packages (GUI apps, CLI tools, claude-code, etc.)
home/programs/                     # per-program home-manager config (zsh, neovim, tmux, git, sway)
home/services/syncthing.nix        # syncthing user service
devenv-example/devenv.nix          # copy-paste template for Ruby on Rails projects
```

### Flake inputs

| Input | Purpose |
|---|---|
| `nixpkgs` (unstable) | All packages |
| `home-manager` | User-level config, follows nixpkgs |
| `neovim-nightly-overlay` | Neovim nightly build |
| `dms` (DankMaterialShell/stable) | Sway shell/widget layer + greeter |

### Sibling repos auto-synced at rebuild

`home.activation.syncDotfiles` in `home/home.nix` clones (first run) or `git pull --ff-only` (subsequent runs):
- `crivotz/dot_files` → `~/.dot_files` (this repo's dotfiles counterpart)
- `crivotz/nubem_dot_files` → `~/.nubem_dot_files` (private aliases/env)
- `crivotz/nv-ide` → `~/.nv-ide` (Neovim/LazyVim config)
- `crivotz/bin` → `~/.bin-various`

### LSP / Neovim

Mason is disabled. All LSPs and formatters are installed as Nix packages via `extraPackages` in `home/programs/neovim.nix`. To add an LSP, add the package there and rebuild.

### devenv (Ruby on Rails projects)

`devenv-example/devenv.nix` is a template. Copy it to a project root, add `.envrc` with `use devenv`, run `direnv allow`. It provisions per-project PostgreSQL + Redis and sets `DATABASE_URL`/`REDIS_URL` automatically.

## Display manager

Two options commented in `hosts/nixos/configuration.nix`:
- **Option A** (active): `greetd + tuigreet`
- **Option B**: `dms-greeter` — check current module API first with `nix flake show github:AvengeMedia/DankMaterialShell/stable`

## Manual post-install steps

These must be done manually after a fresh install:

- **Syncthing**: open the web UI (`http://localhost:8384`) and pair with other devices
- **Atuin**: `atuin login` to sync shell history
- **GitHub CLI**: `gh auth login` to authenticate

## Hardware-specific notes

- `hardware-configuration.nix` è machine-generated e viene letto da `/etc/nixos/hardware-configuration.nix` (path assoluto in `configuration.nix`), non è nel repo.
- Monitor output names (`eDP-1`, `DP-1`, etc.) are configured in `home/programs/sway.nix`. Use `wdisplays` to identify them.
