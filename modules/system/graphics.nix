{ config, lib, pkgs, ... }:

let
  # --- TOGGLE NVK HERE ---
  useNVK = false;
in
{
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

  services.xserver.videoDrivers = if useNVK then [ "nouveau" ] else [ "nvidia" ];

  hardware.nvidia = if useNVK then { } else {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    # beta (595.45.04) fails to build on kernel 7.0.x (VMA_LOCK_OFFSET removed);
    # production 595.71.05 carries the fix and builds cleanly.
    package = config.boot.kernelPackages.nvidiaPackages.production;
    nvidiaPersistenced = true;
    powerManagement.enable = true;
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
      offload.enable = true;
      offload.enableOffloadCmd = true;
    };
  };

  environment.sessionVariables = {
    # VA-API hardware video acceleration (Intel iGPU)
    LIBVA_DRIVER_NAME = "iHD";
    MOZ_DISABLE_RDD_SANDBOX = "1";   # Let Firefox RDD process access VA-API
    NVD_BACKEND = "direct";          # nvidia-vaapi-driver backend

    # Aquamarine (Hyprland) device order: NVIDIA first so it's the primary
    # render + scanout device. DP-1 is wired to the dGPU, so this avoids a
    # cross-GPU copy that caused cursor/window lag on the external monitor.
    # eDP-1 (Intel) becomes the secondary cross-GPU output.
    AQ_DRM_DEVICES = "/dev/dri/card0:/dev/dri/card1";
  };
}
