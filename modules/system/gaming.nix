{ config, lib, pkgs, ... }:

let
  # DLSS-Updater (https://github.com/Recol/DLSS-Updater) updates DLSS/FSR/XeSS
  # DLLs in Proton/Wine game prefixes. Not in nixpkgs or on Flathub; Linux
  # builds ship only as a .flatpak bundle on GitHub releases.
  # To bump: update the version, then refresh the hash with
  #   nix store prefetch-file <release-url>
  dlssUpdaterVersion = "4.3.1";
  dlssUpdaterBundle = pkgs.fetchurl {
    url = "https://github.com/Recol/DLSS-Updater/releases/download/V${dlssUpdaterVersion}/DLSS_Updater-${dlssUpdaterVersion}.flatpak";
    hash = "sha256-o4SVCfrGAaMim1jRS668E4hv0EDHZzAkXGqiCRrJ9aQ=";
  };
in
{
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

  environment.systemPackages = [ pkgs.lsfg-vk ];

  services.flatpak.enable = true;

  # Installs the pinned DLSS-Updater bundle (and the Flathub remote its
  # freedesktop runtime comes from). Skips network entirely once the pinned
  # version is installed; re-runs on version bumps.
  systemd.services.flatpak-dlss-updater = {
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.flatpak ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # network-online.target can fire before Wi-Fi has actually associated/
      # gotten DNS, so retry a few times instead of landing in "failed".
      Restart = "on-failure";
      RestartSec = 10;
      StartLimitIntervalSec = 120;
      StartLimitBurst = 5;
    };
    script = ''
      # Bundle-installed flatpaks (from a local .flatpak file, as opposed to
      # a repo) have no "Version:" field in `flatpak info` output, so we
      # can't compare against dlssUpdaterVersion that way. Instead stamp the
      # exact bundle store path (which changes whenever the version/hash
      # above changes) to a marker file after a successful install, and
      # skip re-installing when it already matches.
      stamp=/var/lib/flatpak-dlss-updater.stamp
      if [ ! -f "$stamp" ] || [ "$(cat "$stamp")" != "${dlssUpdaterBundle}" ]; then
        flatpak remote-add --system --if-not-exists flathub \
          https://dl.flathub.org/repo/flathub.flatpakrepo
        flatpak install --system --noninteractive --reinstall ${dlssUpdaterBundle}
        echo "${dlssUpdaterBundle}" > "$stamp"
      fi
    '';
  };
}
