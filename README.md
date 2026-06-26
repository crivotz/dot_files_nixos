# NixOS Configuration

Configurazione NixOS con Home Manager, Flakes, Sway (Wayland) e devenv per Ruby on Rails.
Migrazione da Debian: zinit → pacchetti nix, asdf → devenv, Mason → LSP via nix.

## Struttura

```
dot_files_nixos/
├── flake.nix                      # nixpkgs unstable, home-manager, neovim-nightly, dms
├── hosts/nixos/
│   ├── configuration.nix          # sistema: boot, utente, servizi, font, SSD, VPN
│   └── hardware-configuration.nix # generato dall'installer (non in git)
├── home/
│   ├── home.nix                   # home-manager entry point + symlink dotfiles
│   ├── packages.nix               # pacchetti utente (sostituisce zinit downloads)
│   └── programs/
│       ├── zsh.nix                # zsh + plugin (sostituisce zinit)
│       ├── neovim.nix             # neovim nightly + LSP via nix (Mason disabilitato)
│       ├── tmux.nix               # tmux + plugin
│       ├── git.nix                # git + gh CLI
│       └── sway.nix               # sway WM + keybinding dms
│   └── services/
│       └── syncthing.nix          # syncthing servizio utente
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
# greetd/tuigreet appare → accedi → sway si avvia
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
