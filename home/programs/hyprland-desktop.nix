{ pkgs, ... }:
{
  # Force-overwrite hyprland.conf se esiste già come file non gestito da HM.
  xdg.configFile."hypr/hyprland.conf".force = true;

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;
    configType = "hyprlang";

    settings = {
      # Desktop monitor layout — mirrors sway-desktop.nix output config.
      # Due schermi 2560×1440 affiancati.
      # Run `hyprctl monitors` o `wdisplays` per confermare i nomi dei connettori.
      monitor = [
        "DP-1,2560x1440@60,0x0,1"
        "DP-2,2560x1440@60,2560x0,1"
        ",preferred,auto,1"
      ];

      workspace = [
        "1,monitor:DP-1,default:true"
        "2,monitor:DP-2,default:true"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 5;
        border_size = 4;
        "col.active_border" = "rgba(7aa2f7ff)";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
        resize_on_border = true;
      };

      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        shadow.enabled = false;
      };

      animations = {
        enabled = true;
        bezier = "ease, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 5, ease"
          "windowsOut, 1, 5, default, popin 80%"
          "border, 1, 8, default"
          "fade, 1, 5, default"
          "workspaces, 1, 4, default"
        ];
      };

      dwindle = {
        preserve_split = true;
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };

      input = {
        kb_layout = "it,it";
        kb_variant = ",nodeadkeys";
        kb_options = "grp:alt_shift_toggle,ctrl:nocaps";
        follow_mouse = 1;
        sensitivity = 0;
        # Nessun touchpad sul desktop
      };

      # dms viene avviato dal suo servizio systemd (programs.dms-shell.systemd.enable = true).
      "exec-once" = [
        "syncthing serve --no-browser --logfile=default"
        "wl-paste --watch cliphist store"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      ];

      bind = [
        # Navigazione finestre (vim-style, speculare a sway-desktop.nix)
        "SUPER, H, movefocus, l"
        "SUPER, J, movefocus, d"
        "SUPER, K, movefocus, u"
        "SUPER, L, movefocus, r"
        "SUPER, left, movefocus, l"
        "SUPER, down, movefocus, d"
        "SUPER, up, movefocus, u"
        "SUPER, right, movefocus, r"

        # Spostamento finestre
        "SUPER SHIFT, H, movewindow, l"
        "SUPER SHIFT, J, movewindow, d"
        "SUPER SHIFT, K, movewindow, u"
        "SUPER SHIFT, L, movewindow, r"
        "SUPER SHIFT, left, movewindow, l"
        "SUPER SHIFT, down, movewindow, d"
        "SUPER SHIFT, up, movewindow, u"
        "SUPER SHIFT, right, movewindow, r"

        # Layout
        "SUPER, F, fullscreen, 0"
        "SUPER SHIFT, SPACE, togglefloating,"
        "SUPER, E, layoutmsg, togglesplit"
        "SUPER, S, layoutmsg, orientationtop"
        "SUPER, R, submap, resize"

        # Azioni sistema
        "SUPER, RETURN, exec, ghostty"
        "SUPER, N, exec, nautilus"
        "SUPER, C, exec, brave"
        "SUPER SHIFT, Q, killactive,"
        "SUPER SHIFT, C, exec, hyprctl reload"
        "SUPER SHIFT, E, exit,"

        # DankMaterialShell — stesse chiamate di sway-desktop.nix
        "SUPER, SPACE, exec, dms ipc call spotlight toggle"
        "SUPER, V, exec, dms ipc call clipboard toggle"
        "SUPER, M, exec, dms ipc call processlist focusOrToggle"
        "SUPER, comma, exec, dms ipc call settings focusOrToggle"

        # 1Password quick access
        "CTRL SHIFT, SPACE, exec, 1password --quick-access"

        # Screenshot (grim+slurp, già installati tramite programs.sway.extraPackages)
        "SUPER, P, exec, grim -g \"$(slurp -d)\" - | wl-copy"
        "SUPER SHIFT, P, exec, grim -g \"$(slurp)\" - | wl-copy"
        "SUPER ALT, P, exec, grim - | wl-copy"
        "SUPER CTRL, P, exec, grim -g \"$(slurp -d)\" - | wl-copy"

        # Tasti speciali tastiera
        ", XF86HomePage, exec, brave"
        ", XF86Explorer, exec, nautilus"
        ", XF86Calculator, exec, gnome-calculator"

        # Workspace
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"
        "SUPER, 0, workspace, 10"
        "SUPER SHIFT, 1, movetoworkspace, 1"
        "SUPER SHIFT, 2, movetoworkspace, 2"
        "SUPER SHIFT, 3, movetoworkspace, 3"
        "SUPER SHIFT, 4, movetoworkspace, 4"
        "SUPER SHIFT, 5, movetoworkspace, 5"
        "SUPER SHIFT, 6, movetoworkspace, 6"
        "SUPER SHIFT, 7, movetoworkspace, 7"
        "SUPER SHIFT, 8, movetoworkspace, 8"
        "SUPER SHIFT, 9, movetoworkspace, 9"
        "SUPER SHIFT, 0, movetoworkspace, 10"
      ];

      # Mouse: drag floating con Mod+click-sx, resize con Mod+click-dx
      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      # Audio via dms (DDC/CI per luminosità sul desktop, gestito da dms)
      bindel = [
        ", XF86AudioRaiseVolume, exec, dms ipc call audio increment 3"
        ", XF86AudioLowerVolume, exec, dms ipc call audio decrement 3"
        ", XF86MonBrightnessUp, exec, dms ipc call brightness increment 5"
        ", XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5"
      ];

      bindl = [
        ", XF86AudioMute, exec, dms ipc call audio mute"
      ];

    };

    # Submap resize — entra con SUPER+R, esci con Return o Escape
    extraConfig = ''
      hl.window_rule({ match = { class = "org.gnome.Calculator" }, float = true })
      hl.window_rule({ match = { title = ".*About.*" }, float = true })
      hl.window_rule({ match = { title = "pop-up" }, float = true })
      hl.window_rule({ match = { class = "brave-browser" }, workspace = "1 silent" })
      hl.window_rule({ match = { class = "com.mitchellh.ghostty" }, workspace = "2 silent" })
      hl.window_rule({ match = { class = "Spotify" }, workspace = "9 silent" })

      submap = resize

      binde = , H, resizeactive, -10 0
      binde = , J, resizeactive, 0 10
      binde = , K, resizeactive, 0 -10
      binde = , L, resizeactive, 10 0
      binde = , left, resizeactive, -10 0
      binde = , down, resizeactive, 0 10
      binde = , up, resizeactive, 0 -10
      binde = , right, resizeactive, 10 0

      bind = , RETURN, submap, reset
      bind = , ESCAPE, submap, reset

      submap = reset
    '';
  };
}
