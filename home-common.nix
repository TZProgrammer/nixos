{ config, lib, pkgs, inputs, ... }:

let
  treesitter-parsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
  };
in
{
  imports = [
    ./modules/atuin.nix
  ];

  home.sessionVariables.NIX_TS_PARSERS = "${treesitter-parsers}";

  # 1. CLI Tools
  home.packages = with pkgs; [
    # --- System Monitoring & Search ---
    tmux
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
    # claude-code — removed; 2.1.88 yanked from npm, installed via npm instead
    gemini-cli
    starship

    # --- Git/GitHub ---
    gh

    # --- Dev Tools ---
    gcc
    clang-tools
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
    marksman
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

  # 6. Tmux
  # oh-my-tmux lives at the XDG path so tmux 3.1+ always finds it first.
  # Plugins are appended to .local by Nix — no TPM, no TMUX_PLUGIN_MANAGER_PATH.
  home.file.".config/tmux/tmux.conf".source = "${inputs.oh-my-tmux}/.tmux.conf";
  home.file.".config/tmux/tmux.conf.local".text =
    builtins.readFile "${inputs.tmux-config}/tmux.conf.local" + ''

      # --- Nix-managed plugins (appended by home-manager, no TPM needed) ---
      run-shell ${pkgs.tmuxPlugins.tmux-sessionx}/share/tmux-plugins/sessionx/sessionx.tmux
      run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux
      run-shell ${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux
      set -g @continuum-restore 'on'
      set -g @sessionx-preview-enabled false
      set -g mouse on

      # Pass extended key sequences (e.g. ctrl+backspace) through to the shell
      set -s extended-keys on
      set -as terminal-features '*:extkeys'
    '';

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
