{ config, lib, pkgs, inputs, ... }:

{
  imports = [ ./home-common.nix ];

  # Change these for the work machine if needed
  home.username = "zegertho";
  home.homeDirectory = "/home/zegertho";

  # Work git email — override if different from personal
  # programs.git.settings.user.email = "thomas@work.com";

  home.stateVersion = "25.11";
}
