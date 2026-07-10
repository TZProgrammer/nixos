{ config, lib, pkgs, ... }:

{
  networking.hostName = "nixos";
  
  # Enable networking
  networking.networkmanager.enable = true;
  # NOTE: do NOT add wlo1 to firewall.trustedInterfaces — that accepts all
  # inbound traffic on Wi-Fi (untrusted networks). Steam already opens its own
  # ports via remotePlay/dedicatedServer.openFirewall in gaming.nix.

  # ProtonVPN via WireGuard
  # Before rebuilding: save your private key to /etc/wireguard/protonvpn.key (chmod 600)
  # Download the .conf from: https://account.proton.me/vpn/wireguard
  networking.wg-quick.interfaces.protonvpn = {
    autostart = false;
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
}
