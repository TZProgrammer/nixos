{ config, lib, pkgs, inputs, ... }:

let
  treesitter-parsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
  };
in
{
  home.sessionVariables.NIX_TS_PARSERS = "${treesitter-parsers}";

  # 1. CLI Tools
  home.packages = with pkgs; [
    # --- System Monitoring & Search ---
    bottom
    fd
    ripgrep
    jq

    # --- Productivity ---
    obsidian
    yazi
    tldr
    bat
    eza

    # --- AI ---
    claude-code
    gemini-cli
    starship

    # --- Dev Tools ---
    gcc
    unzip
    nodejs
    python3
    python3Packages.pip
    go
    gofumpt
    gotools
    luarocks
    rustc
    cargo
    rust-analyzer
    fish            # for fish_indent
    ast-grep
    lsof
    imagemagick
    ghostscript
    tectonic
    mermaid-cli
    prettier
    markdown-toc
    markdownlint-cli2
    lua51Packages.jsregexp
    nixd
    nixpkgs-fmt
    zsh-abbr
  ];

  # 2. Zoxide, Nix-index
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd j" ];
  };

  # 3. Lazygit
  programs.lazygit = {
    enable = true;
    settings.gui.theme.lightTheme = false;
  };

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

  # 5. ZSH
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      export ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh"
      source ${inputs.zsh-config}/.zshrc
    '';

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

  # 6. Tmux
  programs.tmux.enable = true;
  home.file.".tmux.conf".source = "${inputs.oh-my-tmux}/.tmux.conf";
  home.file.".tmux.conf.local".source = "${inputs.tmux-config}/tmux.conf.local";

  # 7. Atuin
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings.search_mode = "fuzzy";
  };

  # 8. FZF
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f";
  };

  # 9. Kitty (config overridden per-machine as needed)
  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    settings = {
      cursor_shape = "beam";
      cursor_trail = 1;
      window_margin_width = "21.75";
      confirm_os_window_close = 0;
      shell = "zsh";
    };
    keybindings = {
      "ctrl+c" = "copy_or_interrupt";
      "page_up" = "scroll_page_up";
      "page_down" = "scroll_page_down";
      "ctrl+plus" = "change_font_size all +1";
      "ctrl+equal" = "change_font_size all +1";
      "ctrl+minus" = "change_font_size all -1";
      "ctrl+0" = "change_font_size all 0";
    };
  };

  # 10. Git
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

  # 11. Direnv
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
