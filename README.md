# NixOS Configuration

## TODO

- [ ] Migration lua hyprland

Configurazione NixOS con Home Manager, Flakes, Sway + Hyprland (Wayland) e devenv per Ruby on Rails.
Migrazione da Debian: zinit → pacchetti nix, asdf → devenv, Mason → LSP via nix.

## Struttura

```
dot_files_nixos/
├── flake.nix                      # nixpkgs unstable, home-manager, neovim-nightly, dms
├── hosts/
│   ├── NIXMAU/
│   │   └── configuration.nix      # desktop: boot, utente, servizi, font, SSD, VPN
│   └── NIXMAU_LT/
│       └── configuration.nix      # laptop: stessa base, hardware diverso
│   (hardware-configuration.nix generato dall'installer, non in git)
├── home/
│   ├── home.nix                   # home-manager entry point + sync dotfiles
│   ├── home-desktop.nix           # override/extra per desktop
│   ├── packages.nix               # pacchetti utente
│   ├── programs/
│   │   ├── zsh.nix                # zsh + plugin
│   │   ├── neovim.nix             # neovim nightly + LSP via nix (Mason disabilitato)
│   │   ├── tmux.nix               # tmux + plugin
│   │   ├── git.nix                # git + gh CLI
│   │   ├── sway.nix               # sway WM + keybinding (laptop)
│   │   ├── sway-desktop.nix       # sway WM + keybinding (desktop)
│   │   ├── hyprland.nix           # hyprland WM + keybinding (laptop)
│   │   └── hyprland-desktop.nix   # hyprland WM + keybinding (desktop)
│   └── services/
│       └── syncthing.nix          # syncthing servizio utente
├── config/                        # file di configurazione copiati in ~/.config
│   ├── bat/themes/                # temi bat (arctic, rose-pine, tokyonight)
│   ├── DankMaterialShell/         # settings DMS
│   ├── eza/                       # temi eza
│   ├── ghostty/                   # config ghostty + shader GLSL
│   ├── lazygit/                   # config lazygit
│   ├── ruby/                      # gemrc, irbrc, default-gems
│   └── p10k.zsh                   # powerlevel10k prompt
└── devenv-example/
    ├── devenv.nix                 # template per progetti Ruby on Rails
    └── .envrc                     # attivazione automatica con direnv
```

## Prima installazione

### 1. Installare NixOS

Scarica l'ISO da https://nixos.org/download e installa scegliendo **no desktop environment** (minimal).

### 2. Abilitare i flakes (solo nel periodo pre-rebuild)

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### 3. Clonare questa repo

```bash
nix-shell -p git
git clone git@github.com:crivotz/dot_files_nixos ~/dot_files_nixos
mkdir ~/bin
```

`dot_files`, `nubem_dot_files`, `nv-ide` e `bin` vengono clonati automaticamente
da `home.activation` al primo `nixos-rebuild switch` e aggiornati con pull ai successivi.

### 4. Collegare hardware-configuration.nix

```bash
cp /etc/nixos/hardware-configuration.nix ~/dot_files_nixos/hosts/nixos/hardware-configuration.nix
```

### 5. Applicare la configurazione

```bash
sudo nixos-rebuild switch --flake ~/dot_files_nixos.
```

### 6. Setup post-rebuild (una volta sola)

```bash
# Neovim: disabilita Mason su NixOS
cat > ~/.nv-ide/lua/plugins/nix-mason-override.lua << 'EOF'
return {
  { "williamboman/mason.nvim",                    enabled = false },
  { "williamboman/mason-lspconfig.nvim",          enabled = false },
  { "WhoIsSethDaniel/mason-tool-installer.nvim",  enabled = false },
}
EOF
echo "lua/plugins/nix-mason-override.lua" >> ~/.nv-ide/.gitignore
```

### 7. Riavviare

```bash
sudo reboot
# dms-greeter appare → seleziona Sway o Hyprland → accedi
```

## Aggiornamento sistema

### Applicare modifiche ai file .nix (senza aggiornare pacchetti)

```bash
cd ~/dot_files_nixos
git add -A
sudo nixos-rebuild switch --flake .
```

Usa le versioni dei pacchetti già bloccate in `flake.lock`. Veloce, scarica poco o niente.

### Aggiornare tutti i pacchetti (tipo apt upgrade)

```bash
cd ~/dot_files_nixos
nix flake update                              # aggiorna flake.lock all'ultima versione
sudo nixos-rebuild switch --flake .
```

Aggiorna nixpkgs, home-manager, neovim-nightly, dms, ecc. Può scaricare aggiornamenti.

### Rimuovere software e liberare spazio

Rimuovi il pacchetto dalla configurazione `.nix`, poi:

```bash
sudo nixos-rebuild switch --flake .          # rimuove dal profilo attivo
sudo nix-collect-garbage -d                  # elimina vecchie generazioni e libera spazio
```

I pacchetti rimossi restano in `/nix/store` per permettere rollback. Il garbage collector li elimina definitivamente.

### Rollback (tornare alla versione precedente)

```bash
sudo nixos-rebuild switch --rollback
```

Se il sistema non si avvia, seleziona la generazione precedente direttamente dal menu del boot loader (systemd-boot) al riavvio.

### Vedere le generazioni disponibili

```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

### Cancellare le generazioni vecchie

```bash
sudo nix-collect-garbage -d                  # elimina tutte le generazioni tranne quella attiva
sudo nix-collect-garbage --delete-older-than 7d   # tieni solo le ultime 7 giorni
```

Dopo la pulizia non è più possibile fare rollback alle generazioni cancellate.

## Ruby on Rails multi-versione con devenv

**devenv**: ogni progetto dichiara le proprie versioni di Ruby e Node.

```bash
cd ~/Dev/mio-progetto
cp ~/dot_files_nixos/devenv-example/devenv.nix .
echo 'use devenv' > .envrc
direnv allow
```

Versioni disponibili in `devenv.nix`:
- Ruby: `pkgs.ruby_3_2`, `pkgs.ruby_3_3`, `pkgs.ruby_3_4`
- Node: `pkgs.nodejs_20`, `pkgs.nodejs_22`

Direnv attiva l'ambiente automaticamente quando entri nella directory.

```bash
devenv up           # avvia PostgreSQL + Redis in background
bundle exec rails s
# oppure
overmind start      # avvia tutto via Procfile.dev
```

## Neovim

La configurazione LazyVim (`~/.nv-ide`) è mantenuta invariata tramite symlink.
Mason è disabilitato: i LSP/formatter sono installati via nix e disponibili nel PATH.

| Tool | Pacchetto nix |
|---|---|
| Lua LSP | `lua-language-server` |
| TypeScript/JS LSP | `typescript-language-server` |
| HTML/CSS/JSON/ESLint | `vscode-langservers-extracted` |
| YAML LSP | `yaml-language-server` |
| Vim LSP | `vim-language-server` |
| Dockerfile LSP | `dockerfile-language-server-nodejs` |
| Ruby LSP | `solargraph` |
| Formatter JS/TS/CSS | `prettierd` |
| Formatter Lua | `stylua` |
| Linter Ruby | `rubocop` |
| Linter Dockerfile | `hadolint` |
| Linter Shell | `shellcheck` |

Per aggiungere un LSP: modifica `extraPackages` in `home/programs/neovim.nix` e rebuilda.

## Hyprland

Hyprland è disponibile come sessione alternativa a Sway, selezionabile dal dms-greeter.
Configurazione in `home/programs/hyprland.nix` (laptop) e `hyprland-desktop.nix` (desktop).

Le keybinding sono identiche a Sway. Le uniche differenze:
- Layout: `dwindle` (invece di tiling i3-style) con submap resize (`SUPER+R`)
- Screenshot: `grim -g "$(slurp)"` al posto di `grimshot`
- dms si avvia comunque via systemd e gestisce bar, spotlight, audio, luminosità

### Monitor Hyprland

Aggiorna la sezione `monitor` in `hyprland.nix` in base all'hardware.
Usa `hyprctl monitors` per identificare i nomi dei connettori.

```bash
hyprctl monitors        # lista monitor connessi con nomi e risoluzioni
hyprctl activewindow    # info finestra attiva (utile per window rules)
hyprctl reload          # ricarica config senza riavviare (SUPER+SHIFT+C)
```

## DankMaterialShell (dms)

DMS gestisce: spotlight (`Mod+Space`), clipboard (`Mod+v`), processlist (`Mod+m`),
settings (`Mod+,`), volume (`XF86Audio*`), luminosità (`XF86Brightness*`).

Abilitato come modulo NixOS in `configuration.nix`. Si avvia automaticamente via systemd.

Display manager: il `dms-greeter` può sostituire greetd/tuigreet.
Per abilitarlo, commenta il blocco `services.greetd` in `configuration.nix` e cerca
la sintassi corretta nel modulo:
```bash
nix flake show github:AvengeMedia/DankMaterialShell/stable
```

## Note specifiche

### Monitor
Aggiorna la sezione `output` in `home/programs/sway.nix` in base all'hardware.
Usa `wdisplays` per identificare i nomi degli output (`eDP-1`, `DP-1`, etc.).

### Display manager
Default: `dms-greeter` (vedi sezione DMS sopra).
Alterativa: `greetd + tuigreet` (schermata testuale).

### DBeaverData
I dati di DBeaver non sono sincronizzati. Copia da vecchio PC:
```bash
scp -r vecchio-pc:~/.local/share/DBeaverData ~/.local/share/DBeaverData
```

### gcloud CLI
Configurazione account dopo il primo avvio:
```bash
gcloud auth login
gcloud config set project <project-id>
```

### mtab
Configurare manualmente dopo l'installazione.

### Atuin: sincronizza la history
atuin login
atuin sync
