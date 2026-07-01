{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # CLI essenziali
    wget
    curl
    unzip
    file
    tmuxp
    htop
    ncdu
    croc
    graphviz
    plocate
    gnupg
    gnumake
    html-tidy
    unrar          # unfree, richiede config.allowUnfree = true (già in flake.nix)

    # CLI moderni (sostituiscono zinit downloads)
    eza
    bat
    bat-extras.batgrep
    bat-extras.batdiff
    bat-extras.batman
    ripgrep
    fd
    delta
    duf

    # Dev tools
    lazygit
    lazydocker
    gh           # GitHub CLI
    git-ftp
    overmind     # process manager (Procfile)
    netwatch

    # Shell utilities
    fzf
    zoxide
    atuin
    prettyping
    yazi            # file manager TUI (wrapper con cwd persistence in zsh.nix)

    # Terminale
    ghostty

    # 1Password CLI
    _1password-cli

    # Network / Remote
    nmap
    net-tools
    remmina

    # Multimedia
    vlc

    # Wayland tools
    wdisplays
    cliphist

    # Produttività desktop
    brave
    nautilus
    gnome-disk-utility  # GUI per gestire dischi e drive USB
    papirus-icon-theme
    filezilla
    gimp
    inkscape

    # Database
    dbeaver-bin

    # Editor / Cloud
    vscode
    google-cloud-sdk

    # Varie
    xdg-utils

    # AI
    claude-code
    github-copilot-cli
  ];
}
