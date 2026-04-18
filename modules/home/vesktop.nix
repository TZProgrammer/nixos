{ config, lib, pkgs, ... }:

{
  programs.vesktop = {
    enable = true;
    settings.hardwareAcceleration = false;
  };
}
