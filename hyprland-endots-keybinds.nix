{ config, pkgs, inputs, ... }:

# This file appends custom keybindings and window rules on top of end-4's
# illogical-impulse dotfiles. end-4's binds use SUPER+key patterns; we
# add our own and override where needed via extraConfig.

let
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
  wayland.windowManager.hyprland.extraConfig = ''
    # Override end-4's terminal variable so his SUPER+Return bind uses ghostty
    $terminal = ghostty

    # ===========================================================================
    # Custom keybindings (appended on top of illogical-impulse defaults)
    # ===========================================================================

    # --- Focus movement (meta+hjkl) ---
    bind = SUPER, h, movefocus, l
    bind = SUPER, l, movefocus, r
    bind = SUPER, k, movefocus, u
    bind = SUPER, j, movefocus, d

    # --- Move window in direction (meta+shift+hjkl) ---
    bind = SUPER SHIFT, h, movewindow, l
    bind = SUPER SHIFT, l, movewindow, r
    bind = SUPER SHIFT, k, movewindow, u
    bind = SUPER SHIFT, j, movewindow, d

    # --- Monitor focus / move workspace to monitor ---
    bind = SUPER, TAB, focusmonitor, +1
    bind = SUPER SHIFT, TAB, movecurrentworkspacetomonitor, +1

    # --- App launcher & terminal ---
    bind = SUPER, SPACE, exec, fuzzel
    bind = SUPER, Return, exec, ghostty

    # --- Close window ---
    bind = SUPER, Q, killactive

    # --- Reload config ---
    bind = SUPER CTRL, r, exec, hyprctl reload

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

    # --- Brightness ---
    bindel = , XF86MonBrightnessUp,   exec, brightnessctl set 5%+
    bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
    bind = SUPER, F6, exec, ext-brightness up
    bind = SUPER, F5, exec, ext-brightness down

    # --- wl-gammarelay-rs for external monitor gamma dimming ---
    exec-once = wl-gammarelay-rs

    # --- Workspace switching (meta+alt+number) ---
    bind = SUPER ALT, 1, workspace, 1
    bind = SUPER ALT, 2, workspace, 2
    bind = SUPER ALT, 3, workspace, 3
    bind = SUPER ALT, 4, workspace, 4
    bind = SUPER ALT, 5, workspace, 5
    bind = SUPER ALT, 6, workspace, 6
    bind = SUPER ALT, 7, workspace, 7
    bind = SUPER ALT, 8, workspace, 8
    bind = SUPER ALT, 9, workspace, 9
    bind = SUPER ALT, 0, workspace, 10

    # --- Move window to workspace (meta+alt+shift+number) ---
    bind = SUPER ALT SHIFT, 1, movetoworkspace, 1
    bind = SUPER ALT SHIFT, 2, movetoworkspace, 2
    bind = SUPER ALT SHIFT, 3, movetoworkspace, 3
    bind = SUPER ALT SHIFT, 4, movetoworkspace, 4
    bind = SUPER ALT SHIFT, 5, movetoworkspace, 5
    bind = SUPER ALT SHIFT, 6, movetoworkspace, 6
    bind = SUPER ALT SHIFT, 7, movetoworkspace, 7
    bind = SUPER ALT SHIFT, 8, movetoworkspace, 8
    bind = SUPER ALT SHIFT, 9, movetoworkspace, 9
    bind = SUPER ALT SHIFT, 0, movetoworkspace, 10

    # --- Mouse binds ---
    bindm = SUPER, mouse:272, movewindow
    bindm = SUPER, mouse:273, resizewindow
    bind = SUPER, mouse_down, workspace, e+1
    bind = SUPER, mouse_up, workspace, e-1

    # ===========================================================================
    # Workspace rules (v3 syntax)
    # ===========================================================================
    windowrule {
      name = ws_ghostty
      match:class = com\.mitchellh\.ghostty
      workspace = 1
    }
    windowrule {
      name = ws_firefox
      match:class = firefox
      workspace = 2
    }
    windowrule {
      name = ws_stremio
      match:class = [Ss]tremio
      workspace = 3
    }
    windowrule {
      name = ws_vesktop
      match:class = vesktop
      workspace = 4
    }
    windowrule {
      name = ws_steam
      match:class = steam
      workspace = 5
    }
    windowrule {
      name = ws_spotify
      match:class = [Ss]potify
      workspace = 7
    }
    windowrule {
      name = ws_obsidian
      match:class = obsidian
      workspace = 10
    }
    windowrule {
      name = float_steam_popups
      match:class = steam
      match:title = ^(?!Steam$).*
      float = true
    }
    windowrule {
      name = pip
      match:title = [Pp]icture.in.[Pp]icture
      float = true
      pin = true
    }

    # ===========================================================================
    # Autostart (workspace-targeted silent launch)
    # ===========================================================================
    exec-once = [workspace 1] ghostty
    exec-once = [workspace 2 silent] firefox
    exec-once = [workspace 4 silent] vesktop
    exec-once = [workspace 5 silent] steam
    exec-once = [workspace 7 silent] spotify
    exec-once = [workspace 10 silent] obsidian
  '';

  home.packages = (with pkgs; [
    grim
    slurp
    wl-clipboard
    brightnessctl
    wl-gammarelay-rs
  ]) ++ [ ext-brightness ];
}
