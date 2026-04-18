{ config, lib, pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    profiles.default = {
      settings = {
        "media.ffmpeg.vaapi.enabled" = true;
        "media.rdd-ffmpeg.enabled" = true;
        "gfx.webrender.all" = true;
        "gfx.canvas.accelerated" = true;
        "widget.dmabuf.force-enabled" = true;
      };
    };
  };
}
