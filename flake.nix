{
  description = "NixOS ROG Strix G15 Configuration";

  inputs = {
    # The main NixOS package repository (Unstable usually better for gaming/new hardware)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Pinned nixpkgs solely for boot.kernelPackages (kernel + nvidia) — frozen at the
    # last known-good rev (kernel 7.0.1 + nvidia 595.45.04). Kernel 7.0.3 in newer
    # nixpkgs removed VMA_LOCK_OFFSET, breaking the nvidia 595.x build. Unpin once
    # nvidia ships a 7.0-compatible driver in nixpkgs-unstable.
    nixpkgs-kernel.url = "github:nixos/nixpkgs/1c3fe55ad329cbcb28471bb30f05c9827f724c76";

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

    # end-4's Hyprland dotfiles via illogical-flake wrapper
    illogical-flake = {
      url = "path:./illogical-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, ... }@inputs:
    let
      overlays = import ./overlays/default.nix { inherit inputs; };
    in
    {

      # Standalone home-manager config for non-NixOS machines (e.g. work laptop)
      # Usage: home-manager switch --flake .#zegertho
      homeConfigurations."zegertho" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs; };
        modules = [ ./home-work.nix ];
      };

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # Consolidated overlays
          { nixpkgs.overlays = [ overlays.stremio-linux-shell overlays.intel-ocl overlays.python3-fix ]; }

          # Import hardware scan from the new hosts/nixos directory
          ./hosts/nixos/hardware-configuration.nix

          # ASUS ROG Strix G512 Specific Hardware Optimizations
          nixos-hardware.nixosModules.common-cpu-intel
          nixos-hardware.nixosModules.common-gpu-nvidia
          nixos-hardware.nixosModules.common-pc-laptop-ssd

          # Import the main configuration from the new hosts/nixos directory
          ./hosts/nixos/configuration.nix

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
