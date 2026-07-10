{ config, lib, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Periodic store optimisation instead of auto-optimise-store, which hardlinks
  # on every build (added latency) and has had store-corruption reports.
  nix.optimise.automatic = true;
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
