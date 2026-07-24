{ ... }:
{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
      };

      background = [
        {
          monitor = "";
          path = "";
          color = "rgba(1a1b26ff)";
          blur_passes = 0;
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          font_size = 72;
          font_family = "JetBrainsMono Nerd Font";
          color = "rgba(c0caf5ff)";
          position = "0, 150";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "300, 50";
          outline_thickness = 3;
          dots_size = 0.33;
          dots_spacing = 0.15;
          outer_color = "rgb(7aa2f7)";
          inner_color = "rgb(1a1b26)";
          font_color = "rgb(c0caf5)";
          fail_color = "rgb(f7768e)";
          check_color = "rgb(e0af68)";
          placeholder_text = "";
          position = "0, -50";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
