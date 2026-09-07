{ pkgs, ... }:
{
  # Curated for the hybrid Debian+Nix setup: only tools that are missing from apt,
  # stuck on very old versions in Debian stable, or that come from our own overlay/flake
  # inputs. Everything else (git, curl, build-essential, docker, gh, vscode, 1password,
  # google-cloud-sdk, dbeaver, ...) is expected to come from apt or its vendor's own repo.
  home.packages = with pkgs; [
    # Modern CLI rewrites — absent or ancient in Debian stable
    eza
    bat
    bat-extras.batgrep
    bat-extras.batdiff
    bat-extras.batman
    delta
    duf
    fzf
    zoxide
    atuin

    # Not packaged in Debian at all
    lazygit
    lazydocker
    yazi
    overmind
    croc
    devenv
    tmuxp

    # Own flake inputs / overlay — no apt equivalent
    iris
    claude-code
    github-copilot-cli
  ];
}
