{
  description = "Home Manager configuration of kyoh86";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    homeConfigurations = {
      "kyoh86@kyoh86-desktop" = home-manager.lib.homeManagerConfiguration ({
        modules = [ (import ./home.nix) ];
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          # config.allowUnfree = true;
        };
      });

      "yamada@PC5050.local" = home-manager.lib.homeManagerConfiguration ({
        modules = [ (import ./home.nix) ];
        pkgs = import nixpkgs {
          system = "aarch64-darwin";   ## For M1/M2/etc Apple Silicon
          # system = "x86_64-darwin";
        };
      });
    };
  };
}
