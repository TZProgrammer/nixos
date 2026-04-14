{ config, lib, pkgs, ... }:

{
  # 11. Direnv
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
