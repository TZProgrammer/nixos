{ config, lib, pkgs, ... }:

{
  imports = [
    ./anki.nix
    ./firefox.nix
    ./ghostty.nix
    ./kitty.nix
    ./vesktop.nix
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
