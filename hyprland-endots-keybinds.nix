{ config, pkgs, inputs, ... }:

# This file appends custom keybindings and window rules on top of end-4's
# illogical-impulse dotfiles. end-4's binds use SUPER+key patterns; we
# add our own and override where needed via extraConfig.
{
  wayland.windowManager.hyprland.extraConfig = ''
    # ===========================================================================
    # Custom keybindings (appended on top of illogical-impulse defaults)
    # ===========================================================================

    # --- Focus movement (meta+hjkl) ---
    bind = SUPER, h, movefocus, l
    bind = SUPER, l, movefocus, r
    bind = SUPER, k, movefocus, u
    bind = SUPER, j, movefocus, d

    # --- Monitor focus / move window to monitor ---
    bind = SUPER, TAB, focusmonitor, +1
    bind = SUPER SHIFT, TAB, movewindow, mon:+1

    # --- App launcher & terminal ---
    bind = SUPER, SPACE, exec, fuzzel
    bind = SUPER, Return, exec, ghostty

    # --- Close window ---
    bind = SUPER, Q, killactive

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

    # ===========================================================================
    # Workspace rules
    # ===========================================================================
    windowrulev2 = workspace 1, class:^(com\.mitchellh\.ghostty)$
    windowrulev2 = workspace 2, class:^(firefox)$
    windowrulev2 = workspace 3, class:^([Ss]tremio)$
    windowrulev2 = workspace 4, class:^(vesktop)$
    windowrulev2 = workspace 5, class:^(steam)$
    windowrulev2 = workspace 7, class:^([Ss]potify)$
    windowrulev2 = workspace 10, class:^(obsidian)$

    # Steam pop-ups float
    windowrulev2 = float, class:^(steam)$, title:^(?!Steam$).*

    # Picture-in-picture
    windowrulev2 = float, title:^([Pp]icture.in.[Pp]icture)$
    windowrulev2 = pin, title:^([Pp]icture.in.[Pp]icture)$

    # ===========================================================================
    # Autostart (workspace-targeted silent launch)
    # ===========================================================================
    exec-once = ghostty
    exec-once = firefox
    exec-once = [workspace 4 silent] vesktop
    exec-once = [workspace 5 silent] steam
    exec-once = [workspace 7 silent] spotify
    exec-once = [workspace 10 silent] obsidian
  '';

  # Screenshot tools (grim/slurp/wl-copy may already be in illogical-flake
  # packages but added here to be safe)
  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
  ];
}
