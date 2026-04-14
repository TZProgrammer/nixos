{ config, lib, pkgs, inputs, ... }:

let
  treesitter-parsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
  };
in
{
  home.sessionVariables.NIX_TS_PARSERS = "${treesitter-parsers}";

  # 4. Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  xdg.configFile."nvim" = {
    source = inputs.lazyvim-config;
    recursive = true;
  };
}
