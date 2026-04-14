{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings.user = {
      name = "Thomas Zeger";
      email = "thomaszeger@gmail.com";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
