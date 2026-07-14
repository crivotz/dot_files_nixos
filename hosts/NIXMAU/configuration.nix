{ config, pkgs, ... }:
{
  imports = [ /etc/nixos/hardware-configuration.nix ];

  # Boot: systemd-boot on EFI; canTouchEfiVariables lets the loader update the EFI boot entry.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "NIXMAU";
  networking.networkmanager.enable = true;

  # Italian locale for time formatting and number separators.
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "it_IT.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ALL = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
  };

  # Display manager: dms-greeter (speculare a NIXMAU_LT).
  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "sway";
  };
  services.greetd.settings.default_session.user = "greeter";
  # Registers gnome-keyring's D-Bus service (org.freedesktop.secrets) so apps like VSCode/Brave
  # can find a Secret Service to store credentials, since there's no GNOME session to start it.
  services.gnome.gnome-keyring.enable = true;
  # Unlock the GNOME keyring on login so apps using libsecret work without a desktop environment.
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Hyprland — available as an alternative session alongside Sway.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  # Enables Sway system-wide with the GTK wrapper (needed for GTK file dialogs, app theming).
  # Extra packages are Wayland utilities that don't fit in home.packages (they need system-level access).
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock
      swayidle
      wdisplays   # GUI monitor layout tool (identify output names for sway output config)
      grim        # Wayland screenshot
      slurp       # Region selector (used by grimshot)
      sway-contrib.grimshot
      wl-clipboard
      cliphist    # Clipboard history daemon
    ];
  };

  # DankMaterialShell — Sway shell/widget layer providing bar, spotlight, clipboard, and audio IPC.
  programs.dms-shell = {
    enable = true;
    systemd = {
      enable = true;
      # Restart the dms systemd service automatically when the NixOS config changes.
      restartIfChanged = true;
    };
    enableClipboardPaste = true;
    enableSystemMonitoring = true;
    # Audio wavelength visualiser disabled (no use case on desktop).
    enableAudioWavelength = false;
  };

  # XDG portals: wlr per Sway (screen sharing), hyprland per Hyprland, gtk per file picker.
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
    config = {
      common.default = [ "gtk" ];
      hyprland = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
      };
    };
  };

  # GNOME — available as an additional session for other users alongside Sway/Hyprland.
  services.desktopManager.gnome.enable = true;

  # rtkit grants real-time scheduling priority to PipeWire, preventing audio glitches.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    # 32-bit ALSA support is needed for Wine and older games.
    alsa.support32Bit = true;
    # PulseAudio compatibility layer so apps that use libpulse still work.
    pulse.enable = true;
  };

  # Remove these two lines if the desktop board has no Bluetooth chip.
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Primary user account.
  users.users.mauro = {
    isNormalUser = true;
    description = "Mauro Locatelli";
    extraGroups = [
      "wheel"        # sudo
      "networkmanager"
      "audio"
      "video"
      "docker"
      "lp"           # printing
      "lpadmin"      # manage printers via CUPS web UI
      "input"        # raw input device access (needed by some Wayland tools)
      "plugdev"      # unprivileged USB device access via udisks2
    ];
    shell = pkgs.zsh;
  };

  users.users.andrea = {
    isNormalUser = true;
    description = "Andrea";
    extraGroups = [ "networkmanager" "audio" "video" ];
  };

  users.users.laura = {
    isNormalUser = true;
    description = "Laura";
    extraGroups = [ "networkmanager" "audio" "video" ];
  };

  # Must be true so the zsh module generates /etc/zshrc and zsh is available system-wide.
  programs.zsh.enable = true;

  # 1Password: CLI + GUI with polkit integration so the GUI can authenticate privileged operations.
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Grants mauro the polkit policy that lets 1Password GUI unlock the SSH agent.
    polkitPolicyOwners = [ "mauro" ];
  };

  virtualisation.docker.enable = true;

  # Local PostgreSQL for devenv projects. mkOverride 10 wins over the default priority (1000),
  # replacing pg_hba.conf with a fully-trusted local config so devenv doesn't need passwords.
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    authentication = pkgs.lib.mkOverride 10 ''
      # TYPE  DATABASE  USER  ADDRESS       METHOD
      local   all       all                 trust
      host    all       all   127.0.0.1/32  trust
      host    all       all   ::1/128       trust
    '';
    ensureUsers = [
      {
        name = "mauro";
        # Superuser role lets devenv projects create/drop databases without extra grants.
        ensureClauses.superuser = true;
      }
    ];
  };

  # SSH server with password auth disabled; key-only access enforced.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # NTP via Italian national time institute (INRIM) servers.
  services.ntp = {
    enable = true;
    servers = [ "ntp1.inrim.it" "ntp2.inrim.it" ];
  };

  # CUPS printing with foomatic-db for generic PostScript/PCL driver support.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.foomatic-db ];

  # Avahi enables mDNS (.local hostnames) and automatic printer discovery for CUPS.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # udisks2 is the system daemon that lets unprivileged users mount removable drives.
  # udiskie (started per-user by home-manager) calls udisks2 for automounting.
  services.udisks2.enable = true;

  # gvfs provides trash, network shares (SMB/WebDAV), and MTP (Android) to Nautilus.
  services.gvfs.enable = true;

  # Required for GTK theme/font/cursor settings to persist across sessions.
  programs.dconf.enable = true;

  # upower is used by idle detectors and some desktop apps even on non-laptop hardware.
  services.upower.enable = true;

  # Polkit is required by 1Password GUI and various Wayland/system tools.
  security.polkit.enable = true;

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.symbols-only    # Icon-only font for terminals
      nerd-fonts.jetbrains-mono  # Primary coding font with Nerd Font icons
      victor-mono                # Cursive italic alternative
      noto-fonts
      noto-fonts-color-emoji
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font Mono" "JetBrains Mono" ];
        sansSerif = [ "Noto Sans" ];
        serif     = [ "Noto Serif" ];
        emoji     = [ "Noto Color Emoji" ];
      };
      hinting = {
        enable = true;
        # "slight" hinting improves sharpness without distorting letterforms.
        style = "slight";
      };
      antialias = true;
      # RGB subpixel order matches standard LCD panels; improves text clarity.
      subpixel.rgba = "rgb";
      subpixel.lcdfilter = "default";
    };
  };

  # Desktop has no backlight so brightnessctl is omitted; brightness is controlled via DDC/CI through dms.
  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    wl-clipboard
    pamixer             # PulseAudio/PipeWire volume control (used by keybindings)
    networkmanagerapplet
  ];

  # Italian keyboard layout; second variant "nodeadkeys" gives a US-style layout as an alt.
  # ctrl:nocaps remaps CapsLock to Ctrl; grp:alt_shift_toggle switches between the two layouts.
  services.xserver.xkb = {
    layout = "it,it";
    variant = ",nodeadkeys";
    options = "ctrl:nocaps,grp:alt_shift_toggle";
  };
  console.keyMap = "it";

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "mauro" ];
      # Binary caches for nixpkgs, devenv, and nix-community (neovim nightly, etc.).
      substituters = [
        "https://cache.nixos.org"
        "https://devenv.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--keep-last 3 --delete-old";
    };
  };

  system.stateVersion = "26.05";
}
