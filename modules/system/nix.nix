{ config, lib, pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" ];
    warn-dirty = false;
    # nix-community builds home-manager/NUR-adjacent and many fast-moving
    # packages, saving local builds on unstable.
    substituters = [ "https://nix-community.cachix.org" ];
    trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };
  # Periodic store optimisation instead of auto-optimise-store, which hardlinks
  # on every build (added latency) and has had store-corruption reports.
  nix.optimise.automatic = true;

  programs.nh = {
    enable = true;
    flake = "/home/zegertho/.config/nixos";
    # Replaces nix.gc: keeps the last 5 generations as well as anything
    # newer than 30 days, so a bad update can always be rolled back.
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 5 --keep-since 30d";
    };
  };

  nixpkgs.config.allowUnfree = true;
}
