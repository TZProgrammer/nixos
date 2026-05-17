{ config, lib, pkgs, inputs, ... }:

# Injects custom keybindings, window rules, and autostart into the
# illogical-impulse custom/ overlay files. Upstream migrated to a Lua-based
# Hyprland config in May 2026 (Hyprland 0.55+), so the overrides below now
# write Lua instead of the legacy .conf syntax.

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
  # ---------------------------------------------------------------------------
  # Input: disable mouse acceleration (custom/general.lua)
  # ---------------------------------------------------------------------------
  xdg.configFile."hypr/custom/general.lua" = lib.mkForce {
    text = ''
      hl.config({
          input = {
              accel_profile = "flat",
          },
          cursor = {
              no_hardware_cursors = 0,
          },
          monitor = {
              "eDP-1, preferred, 0x0, 1",
              "DP-1, preferred, 1920x0, 1",
          },
      })
    '';
  };

  # ---------------------------------------------------------------------------
  # Disable idle locking: override hypridle.conf with no listeners
  # (hypridle.conf is still a .conf file in upstream.)
  # ---------------------------------------------------------------------------
  xdg.configFile."hypr/hypridle.conf" = lib.mkForce {
    text = ''
      general {
        inhibit_sleep = 3
      }
    '';
  };

  # ---------------------------------------------------------------------------
  # Autostart (custom/execs.lua)
  # ---------------------------------------------------------------------------
  xdg.configFile."hypr/custom/execs.lua" = lib.mkForce {
    text = ''
      hl.on("hyprland.start", function()
          -- wl-gammarelay-rs for external monitor gamma dimming
          hl.exec_cmd("wl-gammarelay-rs")

          -- Workspace-targeted silent launch
          hl.exec_cmd("[workspace 1] ghostty")
          hl.exec_cmd("[workspace 2 silent] firefox")
          hl.exec_cmd("[workspace 4 silent] vesktop")
          hl.exec_cmd("[workspace 5 silent] steam")
          hl.exec_cmd("[workspace 7 silent] spotify")
          hl.exec_cmd("[workspace 10 silent] obsidian")
      end)
    '';
  };

  # ---------------------------------------------------------------------------
  # Keybindings (custom/keybinds.lua)
  # ---------------------------------------------------------------------------
  xdg.configFile."hypr/custom/keybinds.lua" = lib.mkForce {
    text = ''
      -- --- Unbind end-4 keys that conflict with our binds ---
      hl.unbind("SUPER + J")        -- was: toggle bar
      hl.unbind("SUPER + K")        -- was: toggle on-screen keyboard
      hl.unbind("SUPER + L")        -- was: lock screen
      hl.unbind("SUPER + Tab")      -- was: overview toggle
      hl.unbind("SUPER + Return")   -- was: launch $TERMINAL
      hl.unbind("CTRL + SUPER + R") -- was: restart QuickShell widgets
      hl.unbind("CTRL + SUPER + P") -- was: cycle panel family

      -- --- Focus movement (hjkl) ---
      hl.bind("SUPER + h", hl.dsp.focus({ direction = "left"  }))
      hl.bind("SUPER + l", hl.dsp.focus({ direction = "right" }))
      hl.bind("SUPER + k", hl.dsp.focus({ direction = "up"    }))
      hl.bind("SUPER + j", hl.dsp.focus({ direction = "down"  }))

      -- --- Move window in direction ---
      hl.bind("SUPER + SHIFT + h", hl.dsp.window.move({ direction = "left"  }))
      hl.bind("SUPER + SHIFT + l", hl.dsp.window.move({ direction = "right" }))
      hl.bind("SUPER + SHIFT + k", hl.dsp.window.move({ direction = "up"    }))
      hl.bind("SUPER + SHIFT + j", hl.dsp.window.move({ direction = "down"  }))

      -- --- Monitor focus / move workspace to monitor ---
      hl.bind("SUPER + Tab",         hl.dsp.focus({ monitor = "+1" }))
      hl.bind("SUPER + SHIFT + Tab", hl.dsp.workspace.move({ monitor = "+1" }))

      -- --- App launcher & terminal ---
      hl.bind("SUPER + SPACE",  hl.dsp.exec_cmd("fuzzel"))
      hl.bind("SUPER + Return", hl.dsp.exec_cmd("ghostty"))

      -- --- Close window ---
      hl.bind("SUPER + Q", hl.dsp.window.close())

      -- --- Reload config / restart widgets ---
      hl.bind("SUPER + CTRL + R",         hl.dsp.exec_cmd("hyprctl reload"))
      hl.bind("SUPER + CTRL + SHIFT + R", hl.dsp.exec_cmd("killall qs quickshell; qs -c $qsConfig &"))

      -- --- App shortcuts ---
      hl.bind("SUPER + CTRL + D", hl.dsp.exec_cmd("vesktop"))
      hl.bind("SUPER + CTRL + F", hl.dsp.exec_cmd("firefox"))
      hl.bind("SUPER + CTRL + G", hl.dsp.exec_cmd("steam"))
      hl.bind("SUPER + CTRL + M", hl.dsp.exec_cmd("stremio-linux-shell"))
      hl.bind("SUPER + CTRL + S", hl.dsp.exec_cmd("spotify"))

      -- --- Screenshot ---
      hl.bind("SUPER + CTRL + P", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))

      -- --- Lock screen ---
      hl.bind("SUPER + CTRL + L", hl.dsp.exec_cmd("hyprlock"))

      -- --- Bar toggle ---
      hl.bind("SUPER + CTRL + J", hl.dsp.global("quickshell:barToggle"))

      -- --- Brightness ---
      hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true, locked = true })
      hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true, locked = true })
      hl.bind("SUPER + F6", hl.dsp.exec_cmd("${ext-brightness}/bin/ext-brightness up"))
      hl.bind("SUPER + F5", hl.dsp.exec_cmd("${ext-brightness}/bin/ext-brightness down"))

      -- --- Workspace switching (Super+number) ---
      -- end-4 already binds these; no override needed.

      -- --- Move window to workspace silently (stay on current) ---
      for i = 1, 10 do
          local key = (i == 10) and "0" or tostring(i)
          local ws  = tostring(i)
          hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = ws, follow = false }))
      end

      -- --- Mouse ---
      hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),   { mouse = true })
      hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
      hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "+1" }))
      hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "-1" }))
    '';
  };

  # ---------------------------------------------------------------------------
  # Window rules (custom/rules.lua)
  # ---------------------------------------------------------------------------
  xdg.configFile."hypr/custom/rules.lua" = lib.mkForce {
    text = ''
      hl.window_rule({ match = { class = "^com\\.mitchellh\\.ghostty$" }, workspace = "1"  })
      hl.window_rule({ match = { class = "^firefox$"                  }, workspace = "2"  })
      hl.window_rule({ match = { class = "^[Ss]tremio$"               }, workspace = "3"  })
      hl.window_rule({ match = { class = "^vesktop$"                  }, workspace = "4"  })
      hl.window_rule({ match = { class = "^steam$"                    }, workspace = "5"  })
      hl.window_rule({ match = { class = "^[Ss]potify$"               }, workspace = "7"  })
      hl.window_rule({ match = { class = "^obsidian$"                 }, workspace = "10" })

      hl.window_rule({ match = { class = "^steam$",  title = "^(?!Steam$).*" },           float = true })
      hl.window_rule({ match = { title = "^[Pp]icture.in.[Pp]icture$"        },           float = true })
      hl.window_rule({ match = { title = "^[Pp]icture.in.[Pp]icture$"        },           pin   = true })

      -- Tearing for native games not caught by the default rules
      hl.window_rule({ match = { class = "^osu!$"         }, immediate = true })
      hl.window_rule({ match = { class = "^prismlauncher$" }, immediate = true })
      hl.window_rule({ match = { title = "^Celeste$"       }, immediate = true })
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
