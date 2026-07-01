# Copilot Instructions

NixOS system configuration using Flakes + Home Manager. Manages two `x86_64-linux` hosts: **NIXMAU_LT** (laptop) and **NIXMAU** (desktop).

## Key commands

Apply `.nix` changes (uses locked `flake.lock`, no package updates):
```bash
sudo nixos-rebuild switch --flake . --impure
```

Preview changes without applying:
```bash
sudo nixos-rebuild dry-activate --flake .
```

Update all flake inputs then rebuild:
```bash
nix flake update
sudo nixos-rebuild switch --flake . --impure
```

Garbage-collect old generations:
```bash
sudo nix-collect-garbage -d
```

## Architecture

```
flake.nix                              # Two nixosConfigurations: NIXMAU_LT and NIXMAU
hosts/NIXMAU_LT/configuration.nix     # Laptop: boot, services, users, fonts, nix settings
hosts/NIXMAU/configuration.nix        # Desktop: same structure, different hardware/WM config
home/home.nix                         # Laptop home-manager entry point
home/home-desktop.nix                 # Desktop home-manager entry point
home/packages.nix                     # User packages shared by both hosts
home/programs/                        # Per-program home-manager modules
home/services/syncthing.nix           # Syncthing user service
config/                               # Config files symlinked into ~/.config via mkOutOfStoreSymlink
devenv-example/devenv.nix             # Template for per-project Ruby on Rails devenv
```

`flake.nix` builds a shared `pkgs` set (with `allowUnfree = true` and the neovim-nightly overlay) and passes it to both hosts via `specialArgs`/`extraSpecialArgs`. The `stateVersion` is set to `"25.11"` — **do not change it**.

### Laptop vs desktop split

- Laptop (`home.nix`) imports `programs/sway.nix` and `programs/hyprland.nix`
- Desktop (`home-desktop.nix`) imports `programs/sway-desktop.nix` and `programs/hyprland-desktop.nix`
- Desktop uses `gitconfig_7040`; laptop uses `gitconfig_laptop_silver` (both from `~/.nubem_dot_files`)

### Sibling repos synced at rebuild

`home.activation.syncPrivate` in both `home.nix` and `home-desktop.nix` clones or `git pull --ff-only` these at every `nixos-rebuild switch`:
- `crivotz/nubem_dot_files` → `~/.nubem_dot_files` (private aliases, env vars, tmuxp sessions, gitconfig)
- `crivotz/nv-ide` → `~/.nv-ide` (Neovim/LazyVim config, symlinked to `~/.config/nvim`)

The laptop uses SSH (`id_ed25519`); the desktop uses `gh auth git-credential` + HTTPS rewrite.

## Key conventions

### `mkOutOfStoreSymlink` for config files
All entries in `home.file` use `config.lib.file.mkOutOfStoreSymlink` so the files remain **mutable live symlinks** into `~/.dot_files_nixos/config/` rather than read-only copies in the Nix store. Use `force = true` when the target path might already exist as a directory.

```nix
".config/lazygit/config.yml" = {
  source = config.lib.file.mkOutOfStoreSymlink "${cfg}/lazygit/config.yml";
  force = true;
};
```

### Neovim: `home.packages` not `programs.neovim`
Neovim is installed via `home.packages = [ pkgs.neovim ]` in `home/programs/neovim.nix`, **not** via `programs.neovim`. Using the HM module would generate an `init.lua` that overwrites the `~/.nv-ide` symlink. Mason is disabled; all LSPs and formatters are Nix packages in `extraPackages` (same file). To add an LSP: add its package to `home.packages` in `neovim.nix` and rebuild.

### Display manager options
Both `configuration.nix` files contain two options (swap by commenting/uncommenting):
- **Active**: `dms-greeter` (`programs.dank-material-shell.greeter`)
- **Alternative**: `greetd + tuigreet` (`services.greetd`)

Before enabling `dms-greeter`, verify the current module API:
```bash
nix flake show github:AvengeMedia/DankMaterialShell/stable
```

### Monitor/output names
- Sway: configure `output` blocks in `home/programs/sway.nix` (laptop) or `sway-desktop.nix` (desktop). Use `wdisplays` to identify connector names.
- Hyprland: configure `monitor` blocks in the corresponding `hyprland*.nix`. Use `hyprctl monitors`.

### `hardware-configuration.nix` is not in git
Both hosts read it from `/etc/nixos/hardware-configuration.nix` via an absolute import path. On a fresh install, copy it manually:
```bash
cp /etc/nixos/hardware-configuration.nix ~/dot_files_nixos/hosts/<HOST>/hardware-configuration.nix
```

### devenv for Rails projects
`devenv-example/devenv.nix` is a copy-paste template. Copy to a project root, add `.envrc` containing `use devenv`, then `direnv allow`. It provisions per-project PostgreSQL + Redis and sets `DATABASE_URL`/`REDIS_URL` automatically.

### Binary caches
`nix.settings.substituters` in `configuration.nix` includes `devenv.cachix.org` and `nix-community.cachix.org` alongside `cache.nixos.org`. Always ensure `trusted-public-keys` stays in sync when adding a new cache.
