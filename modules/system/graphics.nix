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
    # Shim a `.mod` passthru: the pinned-old nvidia derivation (from nixpkgs-kernel)
    # predates nixpkgs splitting nvidia_x11 into .bin/.mod sub-outputs, but the new
    # nixos module reads nvidia_x11.mod. Aliasing it to the package itself works
    # because the old single-derivation form already contains the kernel module.
    package =
      let p = config.boot.kernelPackages.nvidiaPackages.beta;
      in p.overrideAttrs (old: {
        passthru = (old.passthru or {}) // { mod = p; };
      });
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
  };
}
