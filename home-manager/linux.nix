{ pkgs, ... }:
{
  # Linux-specific settings

  home.username = "kyoh86";
  home.homeDirectory = "/home/kyoh86";

  home.packages = with pkgs; [
    inotify-tools
    wslu
    coreutils
    binutils
    gnumake
  ];
}
