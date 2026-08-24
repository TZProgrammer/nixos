# Main NixOS configuration for the ROG Strix G15 (Desktop/Laptop)
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ../../modules/system/boot.nix
    ../../modules/system/graphics.nix
    ../../modules/system/gaming.nix
    ../../modules/system/bluetooth.nix
    ../../modules/system/networking.nix
    ../../modules/system/audio.nix
    ../../modules/system/nix.nix
  ];

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.displayManager.defaultSession = "hyprland";

  services.geoclue2.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    # XDG_SESSION_TYPE intentionally not forced here — the session manager sets it.
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland,x11";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    # VA-API vars (LIBVA_DRIVER_NAME, MOZ_DISABLE_RDD_SANDBOX, NVD_BACKEND)
    # are defined once in modules/system/graphics.nix.
  };

  # Power profiles daemon for KDE/ROG integration
  services.power-profiles-daemon.enable = true;

  services.asusd = {
    enable = true;
  };

  zramSwap = {
    enable = true;
    priority = 100;
    algorithm = "lz4";
    memoryPercent = 50;
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };

  services.btrbk.instances."btrbk" = {
    onCalendar = "daily";
    settings = {
      snapshot_preserve_min = "2d";
      snapshot_preserve = "7d 4w";
      volume."/" = {
        # Relative (no leading /): resolves to <volume path>/btrbk_snapshots,
        # i.e. /btrbk_snapshots here. A leading / would make every volume
        # point at the same absolute path instead of one dir per volume.
        snapshot_dir = "btrbk_snapshots";
        subvolume = ".";
      };
      # @home is a sibling subvolume; btrfs snapshots don't cross subvolume
      # boundaries, so it needs its own volume entry or it goes unprotected.
      volume."/home" = {
        snapshot_dir = "btrbk_snapshots";
        subvolume = ".";
      };
    };
  };

  # btrbk requires the snapshot dirs to exist ahead of time, one per volume.
  systemd.tmpfiles.rules = [
    "d /btrbk_snapshots 0755 root root -"
    "d /home/btrbk_snapshots 0755 root root -"
  ];

  services.printing.enable = true;

  # Redistributable firmware covers this laptop (Intel CNVi Wi-Fi/BT is in it).
  # If a device silently stops working after a rebuild, check the kernel log:
  #   journalctl -b | grep -i firmware      # or: dmesg | grep -i firmware
  # A line like "Direct firmware load for <path> failed with error -2" means a
  # blob is missing. If it's for real hardware you use, that firmware is likely
  # non-redistributable — set `hardware.enableAllFirmware = true;` here instead
  # (or add just the specific firmware package to hardware.firmware).
  hardware.enableRedistributableFirmware = true;

  programs.zsh.enable = true;
  programs.dconf.enable = true;

  users.users.zegertho = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "Thomas Zeger";
    extraGroups = [ "networkmanager" "wheel" "input" "i2c" "video" ];
    packages = with pkgs; [];
  };

  services.kanata = {
    enable = true;
    keyboards.internal.configFile = "${inputs.kanata-config}/kanata.kbd";
  };

  # private.kbd (text-expansion macros) is gitignored in kanata-config, so
  # the flake input never has it. sops-nix decrypts it at runtime and this
  # override assembles a config dir next to the store files so kanata's
  # relative `include "private.kbd"` resolves.
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.secrets."kanata-private-kbd" = {
    sopsFile = ../../secrets/kanata.yaml;
    key = "private_kbd";
  };

  systemd.services.kanata-internal.serviceConfig = {
    LoadCredential = "private.kbd:${config.sops.secrets."kanata-private-kbd".path}";
    ExecStart = lib.mkForce (
      let
        kanataCfg = config.services.kanata.keyboards.internal;
      in
      "${pkgs.writeShellScript "kanata-internal-start" ''
        set -euo pipefail
        cfgdir="$RUNTIME_DIRECTORY/cfg"
        mkdir -p "$cfgdir"
        ln -sf "${inputs.kanata-config}/kanata.kbd" "$cfgdir/kanata.kbd"
        ln -sf "${inputs.kanata-config}/common.kbd" "$cfgdir/common.kbd"
        ln -sf "${inputs.kanata-config}/platform-linux.kbd" "$cfgdir/platform-linux.kbd"
        cp "$CREDENTIALS_DIRECTORY/private.kbd" "$cfgdir/private.kbd"
        exec ${lib.getExe config.services.kanata.package} \
          --cfg "$cfgdir/kanata.kbd" \
          --symlink-path "$RUNTIME_DIRECTORY/internal" \
          ${lib.optionalString (kanataCfg.port != null) "--port ${toString kanataCfg.port}"}
      ''}"
    );
  };

  hardware.i2c.enable = true; # Required for ddcutil (external monitor brightness via DDC/CI)

  # allowUnfree is set in modules/system/nix.nix.
  # pnpm 10.29.2 (pulled transitively as a build-time dep) is flagged insecure in
  # current nixpkgs. It's only used offline inside the build sandbox, so allow it.
  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-10.29.2"
    "electron-40.10.5"
  ];

  environment.systemPackages = with pkgs; [
    wget
    asusctl
    kitty
    google-chrome
    piper
  ];

  system.stateVersion = "25.11";
}
