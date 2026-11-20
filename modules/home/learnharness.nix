{ config, lib, pkgs, ... }:

# LearnHarness (https://github.com/amosblomqvist/learnharness): Electron app,
# packaged from the upstream AppImage. The in-app updater can't write to the
# Nix store, so to upgrade, bump `version` and refresh `hash` with:
#   nix store prefetch-file https://github.com/amosblomqvist/learnharness/releases/download/v<ver>/LearnHarness-<ver>-x86_64.AppImage
let
  pname = "learnharness";
  version = "0.6.1";

  src = pkgs.fetchurl {
    url = "https://github.com/amosblomqvist/learnharness/releases/download/v${version}/LearnHarness-${version}-x86_64.AppImage";
    hash = "sha256-uKAz63QhZ3iT2W5JiLMBU/3+T8bw3EVveUcWG7oEG5g=";
  };

  extracted = pkgs.appimageTools.extract { inherit pname version src; };

  learnharness = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm444 ${extracted}/learnharness.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/learnharness.desktop \
        --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=learnharness %U'
      cp -r ${extracted}/usr/share/icons $out/share
    '';
  };
in
{
  home.packages = [ learnharness ];
}
