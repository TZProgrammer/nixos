{ config, lib, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  programs.nh = {
    enable = true;
    flake = "/home/zegertho/.config/nixos";
  };

  nixpkgs.config.allowUnfree = true;
}
