# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, inputs, ... }:

let
  # --- TOGGLE NVK HERE ---
  useNVK = false; 
in
{
  imports =
    [ # Include the results of the hardware scan.
      #./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Fix for audio on this laptop - asus-zenbook model hint resolves sound issues
  boot.extraModprobeConfig = ''
    options snd-hda-intel model=asus-zenbook
    options iwlwifi bt_coex_active=0
  '';

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos";

  # --- Graphics Configuration ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # Hardware acceleration for the Intel iGPU (VA-API)
      libva-vdpau-driver         # Translation layer
      libvdpau-va-gl     # Translation layer
    ] ++ (pkgs.lib.optional (!useNVK) nvidia-vaapi-driver); # VA-API for proprietary NVIDIA
  };

  # Kernel Parameters
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    "usbcore.autosuspend=-1"
    "btusb.enable_autosuspend=0"  # Disable btusb's own autosuspend (separate from usbcore)
    "usbhid.mousepoll=1"                           # 1ms polling interval (1000Hz)
    "usbhid.quirks=0x046d:0xc539:0x00000400"       # HID_QUIRK_ALWAYS_POLL for Lightspeed receiver
  ] ++ (pkgs.lib.optional useNVK "nouveau.config=NvGspRm=1");

  # SteamOS-derived sysctl tweaks for gaming
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;           # Prevents crashes in memory-heavy Proton games
    "kernel.split_lock_mitigate" = 0;          # Disables split-lock FPS penalty
    "kernel.sched_cfs_bandwidth_slice_us" = 3000; # SteamOS CFS bandwidth slicing
    "vm.compaction_proactiveness" = 0;         # Disable proactive memory compaction
  };

  services.xserver.videoDrivers = if useNVK then [ "nouveau" ] else [ "nvidia" ];

  hardware.nvidia = if useNVK then { } else {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    nvidiaPersistenced = true;
    powerManagement.enable = true;
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
      offload.enable = true;
      offload.enableOffloadCmd = true;
    };
  };

  # Enable networking
  networking.networkmanager.enable = true;
  networking.firewall.trustedInterfaces = [ "wlo1" ];

  # ProtonVPN via WireGuard
  # Before rebuilding: save your private key to /etc/wireguard/protonvpn.key (chmod 600)
  # Download the .conf from: https://account.proton.me/vpn/wireguard
  networking.wg-quick.interfaces.protonvpn = {
    address = [ "10.2.0.2/32" "2a07:b944::2:2/128" ];
    dns = [ "10.2.0.1" "2a07:b944::2:1" ];
    privateKeyFile = "/etc/wireguard/protonvpn.key";
    peers = [
      {
        publicKey = "bXjH25gkRdWvXKahKY4iJNE+v/TVdT0uXE6WQJrX51Q=";
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
        endpoint = "169.150.204.44:51820";
        persistentKeepalive = 25;
      }
    ];
  };

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

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Disables the BlueZ input plugin so the kernel's hid_playstation driver handles it
        DisablePlugins = "input";

        # Forces Bluetooth Classic over LE for higher bandwidth and polling rates
        ControllerMode = "bredr";

        # Prevent BlueZ from suspending the adapter
        FastConnectable = true;
      };
      LE = {
        # Tighten connection interval for any LE fallback (units of 1.25ms)
        MinConnectionInterval = 6;
        MaxConnectionInterval = 9;
        ConnectionLatency = 0;
      };
    };
  };

  # Logitech Lightspeed wireless support (udev rules + Solaar)
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;

  # Piper mouse configuration daemon (button remapping, DPI, LEDs)
  services.ratbagd.enable = true;

  # Keep BT adapter power state always on (prevents HCI-level suspend)
  # Keep Logitech Lightspeed receiver and USB hub power always on
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="bluetooth", KERNEL=="hci0", RUN+="${pkgs.bash}/bin/bash -c 'echo on > /sys/class/bluetooth/hci0/power/control'"
    # Logitech Lightspeed Receiver - force power always on
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c539", TEST=="power/control", ATTR{power/control}="on"
    # USB hub - prevent hub suspend (receiver goes through this hub)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="05e3", ATTR{idProduct}=="0610", TEST=="power/control", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="05e3", ATTR{idProduct}=="0625", TEST=="power/control", ATTR{power/control}="on"
  '';

  programs.zsh.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_SESSION_TYPE = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland,x11";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    WLR_NO_HARDWARE_CURSORS = "1"; # Required for NVIDIA
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

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    extraConfig.pipewire."92-low-latency" = {
      context.properties = {
        default.clock.rate = 48000;
        default.clock.quantum = 64;
        default.clock.min-quantum = 64;
        default.clock.max-quantum = 64;
      };
    };
  };

  users.users.zegertho = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "Thomas Zeger";
    extraGroups = [ "networkmanager" "wheel" "input" "i2c" "video" ];
    packages = with pkgs; [];
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  boot.kernelModules = [ "uinput" ];
  hardware.uinput.enable = true;

  services.kanata = {
    enable = true;
    keyboards.internal.configFile = "${inputs.kanata-config}/kanata.kbd";
  };

  hardware.i2c.enable = true; # Required for ddcutil (external monitor brightness via DDC/CI)

  nixpkgs.config.allowUnfree = true;

  # Fix: kde-material-you-colors is missing python-magic as a declared runtime dep.
  # Must patch python3 via packageOverrides so python3.pkgs (used by withPackages)
  # sees the fix. The base interpreter is given lower priority (higher number) so
  # buildEnv resolves any conflict with the python3 env in favour of the env.
  nixpkgs.overlays = [
    (final: prev: {
      python3 = (prev.python3.override {
        packageOverrides = _pyfinal: pyprev: {
          kde-material-you-colors = pyprev.kde-material-you-colors.overridePythonAttrs (old: {
            propagatedBuildInputs = (old.propagatedBuildInputs or []) ++ [ pyprev.python-magic ];
          });
        };
      }).overrideAttrs (old: {
        meta = (old.meta or {}) // { priority = 20; };
      });
      python3Packages = final.python3.pkgs;
    })
  ];

  environment.systemPackages = with pkgs; [
    wget
    asusctl
    kitty
    google-chrome
    piper
  ];

  programs.nh = {
    enable = true;
    flake = "/home/zegertho/.config/nixos";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.stateVersion = "25.11";
}
