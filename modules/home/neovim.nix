{ config, lib, pkgs, inputs, ... }:

let
  treesitter-parsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
  };
in
{
  home.sessionVariables.NIX_TS_PARSERS = "${treesitter-parsers}";

  # Neovim package only — config (init.lua) comes from LazyVim via xdg.configFile below.
  # programs.neovim is intentionally not used because it would write its own init.lua
  # and conflict with the recursively symlinked LazyVim config.
  home.packages = [ pkgs.neovim ];
  home.sessionVariables.EDITOR = "nvim";
  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };

  xdg.configFile."nvim" = {
    source = inputs.lazyvim-config;
    recursive = true;
  };
}
