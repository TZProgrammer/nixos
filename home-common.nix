{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./modules/atuin.nix
    ./modules/home/zsh.nix
    ./modules/home/tmux.nix
    ./modules/home/git.nix
    ./modules/home/kitty.nix
    ./modules/home/neovim.nix
    ./modules/home/direnv.nix
  ];

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

  # 8. FZF
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f";
  };
}
