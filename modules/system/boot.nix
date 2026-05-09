{ config, lib, pkgs, inputs, ... }:

let
  pinnedPkgs = import inputs.nixpkgs-kernel {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
in

let
  # --- TOGGLE NVK HERE ---
  useNVK = false;
in
{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Fix for audio on this laptop - asus-zenbook model hint resolves sound issues
  boot.extraModprobeConfig = ''
    options snd-hda-intel model=asus-zenbook
    options iwlwifi bt_coex_active=0
  '';

  # Pinned to nixpkgs rev 1c3fe55 (2026-04-27) for kernel 7.0.1 + nvidia 595.45.04.
  # See flake.nix nixpkgs-kernel input for the why.
  boot.kernelPackages = pinnedPkgs.linuxPackages_7_0;

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

  boot.kernelModules = [ "uinput" ];
}
