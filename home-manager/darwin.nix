{ pkgs, ... }:
{
  # macOS-specific settings

  home.username = "yamada";
  home.homeDirectory = "/Users/yamada";

  home.packages = with pkgs; [
    # Add any macOS-specific packages here
    wezterm
    raycast
    plemoljp
    plemoljp-hs
    slack
  ];
}
