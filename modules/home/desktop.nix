{ config, lib, pkgs, ... }:

{
  imports = [
    # Any GUI-specific sub-modules could go here
  ];

  # --- GUI Packages ---
  home.packages = with pkgs; [
    # Productivity
    obsidian
    
    # Media & Personal
    spotify
    stremio-linux-shell
    
    # Gaming & Tools
    prismlauncher
    dualsensectl
    mangohud
    melonds
    osu-lazer-bin
    
    # Fonts
    nerd-fonts.fira-code
  ];

  # --- GUI Programs ---

  # Kitty
  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    settings = {
      cursor_shape = "beam";
      cursor_trail = 1;
      window_margin_width = "21.75";
      confirm_os_window_close = 0;
      shell = "zsh";
    };
    keybindings = {
      "ctrl+c" = "copy_or_interrupt";
      "page_up" = "scroll_page_up";
      "page_down" = "scroll_page_down";
      "ctrl+plus" = "change_font_size all +1";
      "ctrl+equal" = "change_font_size all +1";
      "ctrl+minus" = "change_font_size all -1";
      "ctrl+0" = "change_font_size all 0";
    };
  };

  # Ghostty
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "FiraCode Nerd Font";
      font-size = 11;
      cursor-style = "bar";
      keybind = "ctrl+backspace=text:\\x17";
      window-padding-x = 0;
      window-padding-y = 0;
      confirm-close-surface = false;
      font-style = "Medium";
      freetype-load-flags = "hinting,autohint,light";
      alpha-blending = "linear-corrected";

      # kitty default color scheme
      background = "000000";
      foreground = "dddddd";
      cursor-color = "cccccc";
      selection-background = "555555";
      selection-foreground = "ffffff";
      palette = [
        "0=#000000" "1=#cc0403" "2=#19cb00" "3=#cecb00"
        "4=#0d73cc" "5=#cb1ed1" "6=#0dcdcd" "7=#dddddd"
        "8=#767676" "9=#f2201f" "10=#23fd00" "11=#fffd00"
        "12=#1a8fff" "13=#fd28ff" "14=#14ffff" "15=#ffffff"
      ];
    };
  };

  # Vesktop (Discord)
  programs.vesktop = {
    enable = true;
    settings.hardwareAcceleration = false;
  };

  # Firefox
  programs.firefox = {
    enable = true;
    profiles.default = {
      settings = {
        "media.ffmpeg.vaapi.enabled" = true;
        "media.rdd-ffmpeg.enabled" = true;
        "gfx.webrender.all" = true;
        "gfx.canvas.accelerated" = true;
        "widget.dmabuf.force-enabled" = true;
      };
    };
  };

  # --- Theming ---
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    hyprcursor.enable = true;
  };

  gtk.gtk4.theme = null;
}
