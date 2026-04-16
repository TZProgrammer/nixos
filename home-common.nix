{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./modules/atuin.nix
    ./modules/home/zsh.nix
    ./modules/home/tmux.nix
    ./modules/home/git.nix
    ./modules/home/neovim.nix
    ./modules/home/direnv.nix
  ];

  # 1. CLI Tools (Headless Safe)
  home.packages = with pkgs; [
    # --- System Monitoring & Search ---
    bottom
    fd
    ripgrep
    jq

    # --- Productivity ---
    yazi
    tldr
    bat
    eza

    # --- AI ---
    claude-code
    gemini-cli
    starship

    # --- Git/GitHub ---
    gh

    # --- Dev Tools ---
    gcc
    clang-tools
    shfmt
    stylua
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
