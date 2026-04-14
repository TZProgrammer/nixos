{ inputs, ... }:

{
  # Overlay: fix stremio-linux-shell substituteInPlace glob failure
  stremio-linux-shell = final: prev: {
    stremio-linux-shell = prev.stremio-linux-shell.overrideAttrs (old: {
      postPatch = ''
        substituteInPlace src/config.rs \
          --replace-fail "@serverjs@" "${placeholder "out"}/share/stremio/server.js"

        for f in $cargoDepsCopy/libappindicator-sys-*/src/lib.rs; do
          substituteInPlace "$f" \
            --replace-fail "libayatana-appindicator3.so.1" "${prev.libayatana-appindicator}/lib/libayatana-appindicator3.so.1"
        done
        for f in $cargoDepsCopy/xkbcommon-dl-*/src/lib.rs; do
          substituteInPlace "$f" \
            --replace-fail "libxkbcommon.so.0" "${prev.libxkbcommon}/lib/libxkbcommon.so.0"
        done
        for f in $cargoDepsCopy/xkbcommon-dl-*/src/x11.rs; do
          substituteInPlace "$f" \
            --replace-fail "libxkbcommon-x11.so.0" "${prev.libxkbcommon}/lib/libxkbcommon-x11.so.0"
        done
      '';
    });
  };

  # intel-ocl source URL is dead (Intel 403, Wayback 429) — replace with empty derivation
  intel-ocl = final: prev: {
    intel-ocl = prev.emptyDirectory.overrideAttrs { pname = "intel-ocl"; name = "intel-ocl-dummy"; };
  };

  # Fix: kde-material-you-colors is missing python-magic as a declared runtime dep.
  python3-fix = final: prev: {
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
  };
}
