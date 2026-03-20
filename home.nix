{ config, lib, pkgs, inputs, ... }:

let
  # Pre-compiled treesitter parsers via Nix (NixOS can't run dynamically
  # linked binaries that treesitter compiles at runtime). Each grammar is
  # a separate derivation, so symlinkJoin merges them into one directory.
  treesitter-parsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
  };
in
{
  imports = [
    inputs.illogical-flake.homeManagerModules.default
    ./hyprland-endots-keybinds.nix
  ];

  # Enable end-4's illogical-impulse desktop
  programs.illogical-impulse = {
    enable = true;
  };

  # Patch obsolete hyprexpo options that illogical-flake missed
  xdg.configFile."hypr/hyprland/general.conf" = lib.mkForce {
    text = builtins.replaceStrings
      [ "enable_gesture = false" "gesture_positive = false" "gesture_distance = 300" ]
      [ "# enable_gesture = false" "# gesture_positive = false" "# gesture_distance = 300" ]
      (builtins.readFile "${inputs.illogical-flake.inputs.dotfiles}/dots/.config/hypr/hyprland/general.conf");
  };

  home.username = "zegertho";
  home.homeDirectory = "/home/zegertho";

  # Expose treesitter parser path to neovim (read in LazyVim's config/lazy.lua)
  home.sessionVariables.NIX_TS_PARSERS = "${treesitter-parsers}";

  # 1. Shell & CLI Tools
  home.packages = with pkgs; [
    # --- System Monitoring & Search ---
    bottom      # System monitor (graphical)
    fd          # Better find
    ripgrep     # Better grep
    jq          # JSON processor (Restored)

    # --- Productivity ---
    obsidian    # Note-taking
    yazi        # Terminal file manager (Restored)
    tldr        # Simplified man pages
    bat         # Better cat
    eza         # Better ls

    # --- GUI / Terminal ---
    # ghostty is managed via programs.ghostty below

    # --- AI ---
    claude-code
    gemini-cli
    starship

    # --- Minecraft ---
    prismlauncher

    # --- Gaming ---
    dualsensectl
    mangohud
    nvtopPackages.full
    melonds
    nixd
    nixpkgs-fmt
    zsh-abbr
    osu-lazer-bin

    # --- Dev Tools ---
    gcc             # C compiler (required by nvim-treesitter)
    unzip           # Required by Mason to install LSP servers
    nodejs          # Required by Mason, markdown-preview, and many LSP servers
    python3         # Required by Mason for python LSPs/debuggers
    python3Packages.pip
    go
    gofumpt
    gotools         # provides goimports
    luarocks
    rustc
    cargo
    rust-analyzer
    fish            # for fish_indent
    ast-grep
    lsof            # for sidekick
    imagemagick     # for snacks.image
    ghostscript     # for snacks.image (PDF)
    tectonic        # for snacks.image (LaTeX)
    mermaid-cli     # for snacks.image (Mermaid)
    prettier
    markdown-toc
    markdownlint-cli2
    lua51Packages.jsregexp

    # --- Misc ---
    pkgs.stremio-linux-shell
    spotify
  ];

  # 2. Zoxide (The 'cd' replacement)
  # Nix-index (provides nix-locate and command-not-found integration)
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
    # This replaces 'z' with 'j' and 'zi' with 'ji'
    options = [
      "--cmd j"
    ];
  };

  # 3. Lazygit
  programs.lazygit = {
    enable = true;
    settings = {
      # Custom config goes here
      gui.theme.lightTheme = false;
    };
  };

  # 4. Neovim (LazyVim from flake input)
  # LazyVim manages its own plugins, so we just install neovim and dependencies
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    # No initLua here - it doesn't get injected into the wrapper when
    # ~/.config/nvim/init.lua exists (from LazyVim flake input).
    # Instead, we set NIX_TS_PARSERS env var and read it in LazyVim's
    # config/lazy.lua via performance.rtp.paths (cross-platform safe).
  };

  # LazyVim config from flake input
  # Use: --override-input lazyvim-config path:/home/zegertho/repos/LazyVim for local dev
  xdg.configFile."nvim" = {
    source = inputs.lazyvim-config;
    recursive = true; # Symlink individual files so LazyVim can write lazy-lock.json etc.
  };

  # 5. ZSH & Oh-My-Zsh
  # 5. ZSH
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    # Source your local .zshrc from the repo
    initContent = ''
      export ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh"
      source ${inputs.zsh-config}/.zshrc
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "docker" "kubectl" ];
      theme = "robbyrussell";
    };
  };

  # Link the zsh config directory for extra scripts/plugins
  xdg.configFile."zsh" = {
    source = inputs.zsh-config;
    recursive = true;
  };

    home.file.".oh-my-zsh".source = "${pkgs.oh-my-zsh}/share/oh-my-zsh";

  # 6. Tmux & Oh-My-Tmux (from flake inputs)
  programs.tmux = {
    enable = true;
    # Minimal config - oh-my-tmux handles everything via sourced files
  };

  # oh-my-tmux base config from gpakosz/.tmux
  home.file.".tmux.conf".source = "${inputs.oh-my-tmux}/.tmux.conf";

  # Your local customizations from TZProgrammer/.tmux
  # Use: --override-input tmux-config path:/home/zegertho/repos/.tmux for local dev
  home.file.".tmux.conf.local".source = "${inputs.tmux-config}/tmux.conf.local";

  # 7. Atuin (Shell History)
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings.search_mode = "fuzzy";
  };

  # 8. FZF (Fuzzy Finder)
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f";
  };

  # 9. Ghostty
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 11;
      cursor-style = "bar";
      window-padding-x = 22;
      window-padding-y = 22;
      confirm-close-surface = false;
    };
  };

  # 10. Firefox
  programs.firefox = {
    enable = true;
  };

  # 10. Git
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Thomas Zeger";
        email = "thomaszeger@gmail.com";
      };
    };
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  # 11. Direnv (Environment Switching)
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # 12. Vesktop (Discord client)
  programs.vesktop = {
    enable = true;

    settings.hardwareAcceleration = false;

    # This configures the internal "Vencord" settings
    vencord = {
      settings = {
        plugins = {
          MessageLogger = {      # (Optional) See deleted messages
            enabled = true;
            ignoreSelf = true;
          };
          VolumeBooster.enabled = true;  # Boost user volume beyond 100%
          FakeNitro.enabled = true;  # High quality stream/stickers without paying
        };
        # Block Discord's telemetry
        notifyAboutUpdates = false;
        autoUpdate = false;
      };
    };
  };

  # Symlink GBA/DS roms from Arch partition
  home.file."roms".source = config.lib.file.mkOutOfStoreSymlink "/mnt/arch_home/thomas/roms";

  # Symlink Obsidian vault from Arch partition
  home.file."Brain".source = config.lib.file.mkOutOfStoreSymlink "/mnt/arch_home/thomas/Brain";

  home.stateVersion = "25.11";
}
