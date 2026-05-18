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

  networking.hostName = "nixos";

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
    XDG_SESSION_TYPE = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland,x11";
    _JAVA_AWT_WM_NONREPARENTING = "1";

    # VA-API hardware video acceleration (Intel iGPU)
    LIBVA_DRIVER_NAME = "iHD";
    MOZ_DISABLE_RDD_SANDBOX = "1";   # Let Firefox RDD process access VA-API
    NVD_BACKEND = "direct";          # nvidia-vaapi-driver backend
  };

  # Power profiles daemon for KDE/ROG integration
  services.power-profiles-daemon.enable = true;

  services.asusd = {
    enable = true;
  };

  services.tlp = {
    enable = false;
    settings.USB_AUTOSUSPEND = 0;
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
      volume."\/" = {
        snapshot_dir = "/btrbk_snapshots";
        subvolume = ".";
      };
    };
  };

  services.printing.enable = true;
  hardware.enableAllFirmware = true;

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

  hardware.i2c.enable = true; # Required for ddcutil (external monitor brightness via DDC/CI)

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    wget
    asusctl
    kitty
    google-chrome
    piper
  ];

  system.stateVersion = "25.11";
}
