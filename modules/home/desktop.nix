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
    kdePackages.dolphin

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

  gtk = {
    enable = true;
    gtk4.theme = null;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "Adwaita-dark";
  };

  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = lib.mkForce "breeze-dark";
  };
}
