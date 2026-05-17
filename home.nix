{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./home-common.nix
    ./modules/home/desktop.nix
    inputs.illogical-flake.homeManagerModules.default
    ./hyprland-endots-keybinds.nix
  ];

  # Enable end-4's illogical-impulse desktop
  programs.illogical-impulse.enable = true;
  # kitty config is managed by modules/home/kitty.nix
  programs.illogical-impulse.dotfiles.kitty.enable = false;

  home.username = "zegertho";
  home.homeDirectory = "/home/zegertho";

  # Symlink GBA/DS roms from Arch partition
  home.file."roms".source = config.lib.file.mkOutOfStoreSymlink "/mnt/arch_home/thomas/roms";

  # Symlink Obsidian vault from Arch partition
  home.file."Brain".source = config.lib.file.mkOutOfStoreSymlink "/mnt/arch_home/thomas/Brain";

  home.stateVersion = "25.11";
}
