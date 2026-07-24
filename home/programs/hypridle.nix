{ ... }:
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        # flock garantisce una sola istanza: se già in esecuzione il secondo invocante esce subito.
        lock_cmd = "flock -n /tmp/hyprlock.lock hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        # Works on Hyprland; swaymsg fallback for Sway sessions on the laptop.
        after_sleep_cmd = "hyprctl dispatch dpms on 2>/dev/null; swaymsg 'output * dpms on' 2>/dev/null; sleep 0.5; systemctl --user restart dms";
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 360;
          on-timeout = "hyprctl dispatch dpms off 2>/dev/null; swaymsg 'output * dpms off' 2>/dev/null";
          on-resume = "hyprctl dispatch dpms on 2>/dev/null; swaymsg 'output * dpms on' 2>/dev/null; sleep 0.5; systemctl --user restart dms";
        }
      ];
    };
  };
}
