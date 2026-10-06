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
      })

      hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0",    scale = "1" })
      hl.monitor({ output = "DP-1",  mode = "preferred", position = "1920x0", scale = "1" })
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
          -- Hyprland only imports the environment into the systemd user
          -- manager on startup; it never starts graphical-session.target
          -- itself, and this setup has no hyprland-session.target unit to
          -- pull it in either. Without this, xdg-desktop-portal (and
          -- anything that depends on it -- screen sharing, screenshot
          -- pickers, sandboxed file-open dialogs) fails to start with
          -- "Dependency failed for Portal service" for the entire session.
          hl.exec_cmd("systemctl --user start hyprland-session.target")

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
      -- SUPER+SHIFT+Tab sends the active workspace to the other monitor and
      -- backfills the monitor it left, so Hyprland does not pick the lowest
      -- workspace id for it. The backfill is, in order:
      --   1. the workspace the moved one hid when it arrived on this monitor
      --      (so moving a workspace over and straight back restores both
      --      monitors exactly), as long as nothing has changed since;
      --   2. the monitor's most recently used workspace that still exists
      --      and is not on screen (per-monitor MRU history).
      hl.bind("SUPER + Tab", hl.dsp.focus({ monitor = "+1" }))

      local ws_history = {}  -- monitor name -> list of workspace names, MRU first
      local displaced = {}   -- moved workspace name -> { mon = monitor it landed on, ws = workspace it hid there }
      local moving = false   -- true while the move bind runs, so Hyprland's transient filler workspace is not recorded

      local function history_touch(mon_name, ws_name)
          if ws_name:sub(1, 8) == "special:" then return end
          for name, list in pairs(ws_history) do
              for i = #list, 1, -1 do
                  if list[i] == ws_name and (name ~= mon_name or i ~= 1) then
                      table.remove(list, i)
                  end
              end
          end
          local list = ws_history[mon_name]
          if not list then
              list = {}
              ws_history[mon_name] = list
          end
          if list[1] ~= ws_name then table.insert(list, 1, ws_name) end
      end

      local function history_sync()
          if moving then return end
          local active = {}
          for _, mon in ipairs(hl.get_monitors()) do
              local ws = mon.active_workspace
              if ws then
                  active[mon.name] = ws.name
                  history_touch(mon.name, ws.name)
              end
          end
          -- A round-trip record only holds while the moved workspace is still
          -- what its new monitor shows; any other change means the user has
          -- moved on and plain MRU takes over.
          for ws_name, rec in pairs(displaced) do
              if active[rec.mon] ~= ws_name then displaced[ws_name] = nil end
          end
      end

      hl.on("hyprland.start", history_sync)
      hl.on("workspace.active", history_sync)
      hl.on("monitor.focused", history_sync)

      local function move_workspace_to_other_monitor()
          history_sync()
          local cur_mon = hl.get_active_monitor()
          if not cur_mon then return end
          local src_name = cur_mon.name
          local dst_name = (src_name == "eDP-1") and "DP-1" or "eDP-1"
          if not hl.get_monitor(dst_name) then return end

          local moving_ws = hl.get_active_workspace(src_name)
          if not moving_ws then return end
          local dst_ws = hl.get_active_workspace(dst_name)

          local visible = {}
          for _, mon in ipairs(hl.get_monitors()) do
              if mon.active_workspace then visible[mon.active_workspace.name] = true end
          end
          local function usable(name)
              return name and not visible[name] and hl.get_workspace(name)
          end

          -- Backfill for the source monitor, decided before the move. First
          -- choice: whatever this workspace hid when it arrived here, so moving
          -- it straight back restores both monitors. Otherwise the monitor's
          -- most recently used workspace that still exists and is not on screen.
          local backfill
          local rec = displaced[moving_ws.name]
          if rec and rec.mon == src_name and usable(rec.ws) then backfill = rec.ws end
          if not backfill then
              for _, name in ipairs(ws_history[src_name] or {}) do
                  if usable(name) then backfill = name; break end
              end
          end

          moving = true
          hl.dispatch(hl.dsp.workspace.move({ workspace = moving_ws.name, monitor = dst_name }))
          if backfill then
              -- focus() ignores `workspace` when `monitor` is also given, so
              -- focus the source monitor first, then switch its workspace.
              hl.dispatch(hl.dsp.focus({ monitor = src_name }))
              hl.dispatch(hl.dsp.focus({ workspace = backfill }))
          end
          moving = false

          displaced[moving_ws.name] = dst_ws and { mon = dst_name, ws = dst_ws.name } or nil
          history_sync()
      end

      hl.bind("SUPER + SHIFT + Tab", move_workspace_to_other_monitor)

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

      -- --- Screenshot ---
      hl.bind("SUPER + CTRL + P", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))

      -- --- Lock screen ---
      hl.bind("SUPER + CTRL + L", hl.dsp.exec_cmd("hyprlock"))

      -- --- Bar toggle ---
      hl.bind("SUPER + CTRL + J", hl.dsp.global("quickshell:barToggle"))

      -- --- Brightness ---
      -- XF86MonBrightness{Up,Down} are already bound by end-4 (same flags); binding them again steps twice.
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
      -- Steam is launched silently on workspace 5 at login; stop it from
      -- stealing focus off whatever workspace/window you're actually on.
      hl.window_rule({ match = { class = "^steam$" },                                     no_initial_focus = true })
      hl.window_rule({ match = { title = "^[Pp]icture.in.[Pp]icture$"        },           float = true })
      hl.window_rule({ match = { title = "^[Pp]icture.in.[Pp]icture$"        },           pin   = true })

      -- Tearing for native games not caught by the default rules
      hl.window_rule({ match = { class = "^osu!$"         }, immediate = true })
      hl.window_rule({ match = { class = "^prismlauncher$" }, immediate = true })
      hl.window_rule({ match = { title = "^Celeste$"       }, immediate = true })
    '';
  };

  # graphical-session.target refuses manual/direct starts -- it can only be
  # pulled in via a BindsTo dependency from another unit. home-manager's
  # native Hyprland module normally provides this target automatically; we
  # don't use that module (custom Lua overlay instead), so define it
  # ourselves and start it from custom/execs.lua above.
  systemd.user.targets.hyprland-session = {
    Unit = {
      Description = "Hyprland compositor session";
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
    };
  };

  home.packages = (with pkgs; [
    grim
    slurp
    wl-clipboard
    brightnessctl
    wl-gammarelay-rs
  ]) ++ [ ext-brightness ];
}
