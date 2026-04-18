{ config, lib, pkgs, ... }:

{
  programs.anki = {
    enable = true;
    theme = "followSystem";
    addons = with pkgs.ankiAddons; [
      anki-connect
    ];
  };
}
