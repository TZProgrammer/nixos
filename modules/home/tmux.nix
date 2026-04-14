{ config, lib, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    tmux
  ];

  # oh-my-tmux lives at the XDG path so tmux 3.1+ always finds it first.
  # Plugins are appended to .local by Nix — no TPM, no TMUX_PLUGIN_MANAGER_PATH.
  home.file.".config/tmux/tmux.conf".source = "${inputs.oh-my-tmux}/.tmux.conf";
  home.file.".config/tmux/tmux.conf.local".text =
    builtins.readFile "${inputs.tmux-config}/tmux.conf.local" + ''

      # --- Nix-managed plugins (appended by home-manager, no TPM needed) ---
      run-shell ${pkgs.tmuxPlugins.tmux-sessionx}/share/tmux-plugins/sessionx/sessionx.tmux
      run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux
      run-shell ${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux
      set -g @continuum-restore 'on'
      set -g @sessionx-preview-enabled false
      set -g mouse on

      # Pass extended key sequences (e.g. ctrl+backspace) through to the shell
      set -s extended-keys on
      set -as terminal-features '*:extkeys'
    '';
}
