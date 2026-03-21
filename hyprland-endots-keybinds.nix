{ config, lib, pkgs, inputs, ... }:

# Injects custom keybindings, window rules, and autostart into the
# illogical-impulse custom/ overlay files (sourced by hyprland.conf).
# extraConfig is ignored because illogical-flake owns hyprland.conf via
# xdg.configFile, bypassing the home-manager Hyprland module entirely.

let
  # Build a patched kitty config dir: same files as illogical-impulse dotfiles
  # but with shell changed from fish to zsh, and cursor trail disabled.
  kittyConfig = pkgs.runCommand "kitty-config-zsh" {} ''
    cp -r ${inputs.illogical-flake.inputs.dotfiles}/dots/.config/kitty $out
    chmod -R +w $out
    sed -i 's/^shell fish$/shell zsh/' $out/kitty.conf
    sed -i 's/^cursor_trail.*/cursor_trail 0/' $out/kitty.conf
    sed -i 's/^window_margin_width.*/window_margin_width 0/' $out/kitty.conf
  '';

  ext-brightness = pkgs.writeShellScriptBin "ext-brightness" ''
    DBUS_SERVICE="rs.wl-gammarelay"
    DBUS_PATH="/outputs/DP_1"
    DBUS_IFACE="rs.wl-gammarelay.output"

    get_val() {
      busctl --user get-property "$DBUS_SERVICE" "$DBUS_PATH" "$DBUS_IFACE" Brightness \
        2>/dev/null | awk '{print $2}'
    }

    case "$1" in
      up)
        val=$(get_val); val=''${val:-1.0}
        new=$(awk "BEGIN {v=$val+0.05; if(v>1.0) v=1.0; printf \"%.2f\", v}")
        busctl --user set-property "$DBUS_SERVICE" "$DBUS_PATH" "$DBUS_IFACE" Brightness d "$new"
        ;;
      down)
        val=$(get_val); val=''${val:-1.0}
        new=$(awk "BEGIN {v=$val-0.05; if(v<0.1) v=0.1; printf \"%.2f\", v}")
        busctl --user set-property "$DBUS_SERVICE" "$DBUS_PATH" "$DBUS_IFACE" Brightness d "$new"
        ;;
    esac
  '';
in

{
  # ---------------------------------------------------------------------------
  # Kitty: override shell to zsh (illogical-impulse defaults to fish)
  # ---------------------------------------------------------------------------
  xdg.configFile."kitty" = lib.mkForce {
    source = kittyConfig;
  };

  # ---------------------------------------------------------------------------
  # Input: disable mouse acceleration
  # ---------------------------------------------------------------------------
  xdg.configFile."hypr/custom/general.conf" = lib.mkForce {
    text = ''
      input {
          accel_profile = flat
      }
    '';
  };

  # ---------------------------------------------------------------------------
  # Disable idle locking: override hypridle.conf with no listeners
  # ---------------------------------------------------------------------------
  xdg.configFile."hypr/hypridle.conf" = lib.mkForce {
    text = ''
      general {
        inhibit_sleep = 3
      }
    '';
  };

  # ---------------------------------------------------------------------------
  # Autostart (custom/execs.conf)
  # ---------------------------------------------------------------------------
  xdg.configFile."hypr/custom/execs.conf" = lib.mkForce {
    text = ''
      # wl-gammarelay-rs for external monitor gamma dimming
      exec-once = wl-gammarelay-rs

      # Workspace-targeted silent launch
      exec-once = [workspace 1] kitty
      exec-once = [workspace 2 silent] firefox
      exec-once = [workspace 4 silent] vesktop
      exec-once = [workspace 5 silent] steam
      exec-once = [workspace 7 silent] spotify
      exec-once = [workspace 10 silent] obsidian
    '';
  };

  # ---------------------------------------------------------------------------
  # Keybindings (custom/keybinds.conf)
  # ---------------------------------------------------------------------------
  xdg.configFile."hypr/custom/keybinds.conf" = lib.mkForce {
    text = ''
      # --- Unbind end-4 keys that conflict with our binds ---
      unbind = SUPER, J        # was: toggle bar
      unbind = SUPER, K        # was: toggle on-screen keyboard
      unbind = SUPER, L        # was: lock screen
      unbind = SUPER, Tab      # was: overview toggle
      unbind = SUPER, Return   # was: launch $TERMINAL
      unbind = CTRL SUPER, R   # was: restart QuickShell widgets
      unbind = CTRL SUPER, P   # was: cycle panel family

      # --- Focus movement (hjkl) ---
      bind = SUPER, h, movefocus, l
      bind = SUPER, l, movefocus, r
      bind = SUPER, k, movefocus, u
      bind = SUPER, j, movefocus, d

      # --- Move window in direction ---
      bind = SUPER SHIFT, h, movewindow, l
      bind = SUPER SHIFT, l, movewindow, r
      bind = SUPER SHIFT, k, movewindow, u
      bind = SUPER SHIFT, j, movewindow, d

      # --- Monitor focus / move workspace to monitor ---
      bind = SUPER, TAB, focusmonitor, +1
      bind = SUPER SHIFT, TAB, movecurrentworkspacetomonitor, +1

      # --- App launcher & terminal ---
      bind = SUPER, SPACE, exec, fuzzel
      bind = SUPER, Return, exec, kitty

      # --- Close window ---
      bind = SUPER, Q, killactive

      # --- Reload config / restart widgets ---
      bind = SUPER CTRL, r, exec, hyprctl reload
      bind = SUPER CTRL SHIFT, r, exec, killall qs quickshell; qs -c $qsConfig &

      # --- App shortcuts ---
      bind = SUPER CTRL, d, exec, vesktop
      bind = SUPER CTRL, f, exec, firefox
      bind = SUPER CTRL, g, exec, steam
      bind = SUPER CTRL, m, exec, stremio-linux-shell
      bind = SUPER CTRL, s, exec, spotify

      # --- Screenshot ---
      bind = SUPER CTRL, p, exec, grim -g "$(slurp)" - | wl-copy

      # --- Lock screen ---
      bind = SUPER CTRL, l, exec, hyprlock

      # --- Bar toggle ---
      bind = SUPER CTRL, j, global, quickshell:barToggle

      # --- Brightness ---
      bindel = , XF86MonBrightnessUp,   exec, brightnessctl set 5%+
      bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
      bind = SUPER, F6, exec, ${ext-brightness}/bin/ext-brightness up
      bind = SUPER, F5, exec, ${ext-brightness}/bin/ext-brightness down

      # --- Workspace switching (Super+number) ---
      # end-4 already binds these via workspace_action.sh; no override needed.

      # --- Move window to workspace silently (stay on current) ---
      bind = SUPER SHIFT, 1, movetoworkspacesilent, 1
      bind = SUPER SHIFT, 2, movetoworkspacesilent, 2
      bind = SUPER SHIFT, 3, movetoworkspacesilent, 3
      bind = SUPER SHIFT, 4, movetoworkspacesilent, 4
      bind = SUPER SHIFT, 5, movetoworkspacesilent, 5
      bind = SUPER SHIFT, 6, movetoworkspacesilent, 6
      bind = SUPER SHIFT, 7, movetoworkspacesilent, 7
      bind = SUPER SHIFT, 8, movetoworkspacesilent, 8
      bind = SUPER SHIFT, 9, movetoworkspacesilent, 9
      bind = SUPER SHIFT, 0, movetoworkspacesilent, 10

      # --- Mouse ---
      bindm = SUPER, mouse:272, movewindow
      bindm = SUPER, mouse:273, resizewindow
      bind = SUPER, mouse_down, workspace, e+1
      bind = SUPER, mouse_up, workspace, e-1
    '';
  };

  # ---------------------------------------------------------------------------
  # Window rules (custom/rules.conf)
  # ---------------------------------------------------------------------------
  xdg.configFile."hypr/custom/rules.conf" = lib.mkForce {
    text = ''
      windowrule = match:class ^kitty$, workspace 1
      windowrule = match:class ^firefox$,               workspace 2
      windowrule = match:class ^[Ss]tremio$,            workspace 3
      windowrule = match:class ^vesktop$,               workspace 4
      windowrule = match:class ^steam$,                 workspace 5
      windowrule = match:class ^[Ss]potify$,            workspace 7
      windowrule = match:class ^obsidian$,              workspace 10

      windowrule = match:class ^steam$, match:title ^(?!Steam$).*, float on
      windowrule = match:title ^[Pp]icture.in.[Pp]icture$, float on
      windowrule = match:title ^[Pp]icture.in.[Pp]icture$, pin on
    '';
  };

  home.packages = (with pkgs; [
    grim
    slurp
    wl-clipboard
    brightnessctl
    wl-gammarelay-rs
  ]) ++ [ ext-brightness ];
}
