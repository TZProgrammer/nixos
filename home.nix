{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./home-common.nix
    ./modules/home/desktop.nix
    # Vendored end-4 Hyprland module, imported directly (see flake.nix inputs).
    # It reads inputs.{quickshell,nur,dotfiles} from the flake's specialArgs.
    ./illogical-flake/home-module.nix
    ./hyprland-endots-keybinds.nix
  ];

  # Enable end-4's illogical-impulse desktop
  programs.illogical-impulse.enable = true;
  # kitty config is managed by modules/home/kitty.nix
  programs.illogical-impulse.dotfiles.kitty.enable = false;
  # zsh is the shell in use; skip fish (and its generated completions, e.g. wf-recorder's)
  programs.illogical-impulse.dotfiles.fish.enable = false;

  home.username = "zegertho";
  home.homeDirectory = "/home/zegertho";

  # Symlink GBA/DS roms from Arch partition
  home.file."roms".source = config.lib.file.mkOutOfStoreSymlink "/mnt/arch_home/thomas/roms";

  # Symlink Obsidian vault from Arch partition
  home.file."Brain".source = config.lib.file.mkOutOfStoreSymlink "/mnt/arch_home/thomas/Brain";

  home.stateVersion = "25.11";
}
