{ config, lib, pkgs, inputs, ... }:

{
  imports = [ ./home-common.nix ];

  # Allow unfree packages (e.g. obsidian, spotify)
  nixpkgs.config.allowUnfree = true;

  # Change these for the work machine if needed
  home.username = "zegertho";
  home.homeDirectory = "/home/zegertho";

  # Work git email — override if different from personal
  # programs.git.settings.user.email = "thomas@work.com";

  # 1. Disable Atuin sync for work
  programs.atuin.settings = {
    sync_address = lib.mkForce "";
    auto_sync = lib.mkForce false;
  };

  # 2. Work-specific aliases
  programs.zsh.shellAliases = {
    # Add your work aliases here
    # Example: deploy = "ssh work-server './deploy.sh'";
  };

  home.stateVersion = "25.11";
}
