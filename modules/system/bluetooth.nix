{ config, lib, pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Disables the BlueZ input plugin so the kernel's hid_playstation driver handles it
        DisablePlugins = "input";

        # Forces Bluetooth Classic over LE for higher bandwidth and polling rates.
        # Side effect: disables BLE entirely — LE-only devices (many earbuds,
        # some mice) will not pair while this is "bredr". Switch to "dual" if needed.
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
  programs.solaar.enable = true;

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

  hardware.uinput.enable = true;
}
