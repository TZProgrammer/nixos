{ config, lib, pkgs, ... }:

{
  # Shared Atuin configuration
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      search_mode = "fuzzy";
      filter_mode = "global";
      filter_mode_shell_up_arrow = "directory";
      enter_accept = true;
      show_preview = true;
      keymap_mode = "vim-insert";
    };
  };
}
