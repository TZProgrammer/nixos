{ config, lib, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    zsh-abbr
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = lib.mkMerge [
      (lib.mkOrder 1000 ''
        export ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh"
        source ${inputs.zsh-config}/.zshrc
        t() { tmux a || tmux; }
      '')
      (lib.mkOrder 1500 ''
        # Fix starship/atuin zle-keymap-select infinite recursion in vi mode
        function zle-keymap-select {
          zle reset-prompt
        }
        zle -N zle-keymap-select
      '')
    ];

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "docker" "kubectl" ];
      theme = ""; # disabled — starship handles the prompt
    };
  };

  xdg.configFile."zsh" = {
    source = inputs.zsh-config;
    recursive = true;
  };

  home.file.".oh-my-zsh".source = "${pkgs.oh-my-zsh}/share/oh-my-zsh";
}
