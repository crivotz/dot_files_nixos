{ ... }:
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        # flock garantisce una sola istanza. Il restart di dms è incluso QUI, dopo che hyprlock esce,
        # così gli sfondi tornano dopo ogni sblocco (manuale o da idle) senza race condition.
        lock_cmd = "flock -n /tmp/hyprlock.lock sh -c 'hyprlock; systemctl --user restart dms'";
        before_sleep_cmd = "loginctl lock-session";
        # Riaccende i display. Non restarta dms se hyprlock è attivo: lo farà la lock_cmd allo sblocco.
        after_sleep_cmd = "hyprctl dispatch dpms on 2>/dev/null; swaymsg 'output * dpms on' 2>/dev/null; sleep 1; pgrep -x hyprlock || systemctl --user restart dms";
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 360;
          on-timeout = "hyprctl dispatch dpms off 2>/dev/null; swaymsg 'output * dpms off' 2>/dev/null";
          # Solo DPMS: non restartare dms mentre hyprlock è in esecuzione.
          on-resume = "hyprctl dispatch dpms on 2>/dev/null; swaymsg 'output * dpms on' 2>/dev/null";
        }
      ];
    };
  };
}
