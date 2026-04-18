{ config, lib, pkgs, ... }:

{
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
}
