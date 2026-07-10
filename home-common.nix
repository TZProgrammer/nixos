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
    # --- Audio ---
    qpwgraph

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

    # --- Dev Tools ---
    gcc
    clang-tools
    shfmt
    stylua
    unzip
    nodejs
    # lowPrio: on the NixOS host, illogical-flake also installs a python3.withPackages
    # `pythonEnv`; both ship bin/idle3.13 etc. Lower this one so the env wins the
    # buildEnv collision. (Harmless on the work config, which has no pythonEnv.)
    (lib.lowPrio python3)
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

  # 2. nix-index
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  # 3. starship
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # 4. zoxide
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd j" ];
  };

  # 5. Lazygit
  programs.lazygit = {
    enable = true;
    settings.gui.theme.lightTheme = false;
  };

  # 6. FZF
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f";
  };
  # 7. gh
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings.git_protocol = "https";
  };
}
