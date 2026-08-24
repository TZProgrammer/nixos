{ config, lib, pkgs, ... }:

{
  networking.hostName = "nixos";
  
  # Enable networking
  networking.networkmanager.enable = true;
  # NOTE: do NOT add wlo1 to firewall.trustedInterfaces — that accepts all
  # inbound traffic on Wi-Fi (untrusted networks). Steam already opens its own
  # ports via remotePlay/dedicatedServer.openFirewall in gaming.nix.

  # AdGuard Home: local DNS-level ad/tracker blocking for this machine only.
  # First boot after this is applied, finish setup at http://127.0.0.1:3000
  # (pick an admin password there, DNS starts working immediately either way).
  services.adguardhome = {
    enable = true;
    openFirewall = false; # loopback-only; no LAN access needed
    settings = {
      dns = {
        # DNS-over-TLS upstreams: encrypts AdGuard Home's own outgoing
        # queries so your ISP/network can't see plaintext DNS traffic.
        upstream_dns = [
          "tls://1.1.1.1"
          "tls://1.0.0.1"
          "tls://8.8.8.8"
          "tls://8.8.4.4"
        ];
        bootstrap_dns = [ "1.1.1.1" "8.8.8.8" ]; # plain DNS, only to resolve the tls:// hostnames/IPs above
      };
    };
  };

  # Upstream only orders adguardhome after network.target, which just means
  # "interfaces exist" -- not that Wi-Fi has actually associated/gotten an
  # IP yet. Since we force ALL system DNS through 127.0.0.1 below, if
  # AdGuard starts before Wi-Fi is really up, its DoT upstream dials fail
  # ("network is unreachable") and NOTHING on the machine can resolve any
  # hostname until it recovers -- this is what caused the
  # "Connect to the internet" Firefox error after boot on 2026-08-24.
  # Fix: wait for NetworkManager-wait-online.service (already enabled) to
  # confirm a real, working connection before starting AdGuard.
  systemd.services.adguardhome = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  # Point the system at AdGuard Home instead of the network-provided DNS.
  # NetworkManager would otherwise clobber resolv.conf with the DHCP/VPN
  # resolvers on every reconnect.
  networking.networkmanager.dns = "none";
  networking.nameservers = [ "127.0.0.1" ];

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
