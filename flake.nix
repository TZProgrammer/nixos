{
  description = "NixOS ROG Strix G15 Configuration";

  inputs = {
    # The main NixOS package repository (Unstable usually better for gaming/new hardware)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Critical for your specific laptop model (drivers, quirks)
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      # The `follows` line ensures home-manager uses the same nixpkgs as your system
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- Personal config repos (flake = false means they're just source, not flakes) ---
    lazyvim-config = {
      url = "github:TZProgrammer/LazyVim";
      flake = false;
    };

    tmux-config = {
      url = "github:TZProgrammer/.tmux";
      flake = false;
    };

    oh-my-tmux = {
      url = "github:gpakosz/.tmux";
      flake = false;
    };

    zsh-config = {
      url = "github:TZProgrammer/zshrc";
      flake = false;
    };

    kanata-config = {
      url = "git+ssh://git@github.com/TZProgrammer/kanata-configuration.git";
      flake = false;
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- Inputs for the vendored illogical-flake home module ---
    # (formerly nested under illogical-flake/flake.nix; flattened so edits to
    # ./illogical-flake take effect immediately and there is a single lockfile.)
    # dotfiles is pinned by rev: end-4/dots-hyprland restructures often and the
    # home module is hand-matched to it, so bump deliberately, not on every
    # `nix flake update`. To bump: change the rev (or run
    # `nix flake update quickshell nur dotfiles`) and re-check the module.
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell?ref=refs/heads/master&rev=191085a8821b35680bba16ce5411fc9dbe912237";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR/0e6e5ff852c442598d1ae8ca5f042947f123f798";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dotfiles = {
      url = "git+https://github.com/end-4/dots-hyprland?submodules=1&ref=refs/heads/main&rev=c04b0bbc8143a2b2166c1f699f7583cb28ff78fe";
      flake = false;
    };

    # Lossless Scaling Frame Generation (Vulkan layer + Qt6 UI + CLI), v2.0.0-dev
    lsfg-vk = {
      url = "github:Daaboulex/lsfg-vk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pin to nixpkgs PR #551916 (proton-ge-bin: GE-Proton11-3 -> GE-Proton11-5)
    # until it's merged upstream: https://github.com/NixOS/nixpkgs/pull/551916
    proton-ge-pr-nixpkgs.url = "github:Gliczy/nixpkgs/df53b72a5b5233fae66c0d1bb85a3215b3c230bf";

  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, ... }@inputs:
    {

      # Standalone home-manager config for non-NixOS machines (e.g. work laptop)
      # Usage: home-manager switch --flake .#zegertho
      homeConfigurations."zegertho" = home-manager.lib.homeManagerConfiguration {
        # Build pkgs with allowUnfree here — standalone home-manager ignores
        # `nixpkgs.config` when it's handed an external pkgs set.
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        extraSpecialArgs = { inherit inputs; };
        modules = [ ./home-work.nix ];
      };

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # Consolidated overlays
          {
            nixpkgs.overlays = [
              inputs.lsfg-vk.overlays.default
              # proton-ge-bin from nixpkgs PR #547604, see flake input above
              (final: prev: {
                proton-ge-bin = (import inputs.proton-ge-pr-nixpkgs {
                  inherit (prev) system;
                  config.allowUnfree = true;
                }).proton-ge-bin;
              })
            ];
          }

          # Import hardware scan from the new hosts/nixos directory
          ./hosts/nixos/hardware-configuration.nix

          # ASUS ROG Strix G15 (model G512) hardware optimizations
          nixos-hardware.nixosModules.common-cpu-intel
          nixos-hardware.nixosModules.common-gpu-nvidia
          nixos-hardware.nixosModules.common-pc-laptop-ssd

          # Import the main configuration from the new hosts/nixos directory
          ./hosts/nixos/configuration.nix

          inputs.sops-nix.nixosModules.sops

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Pass inputs to home-manager so it can access the config repos
            home-manager.extraSpecialArgs = {
              inherit inputs;
            };
            home-manager.backupFileExtension = "backup";
            home-manager.users.zegertho = import ./home.nix;
          }
        ];
      };
    };
}
