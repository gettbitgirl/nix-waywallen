{
  description = "waywallen - Rust daemon + display backends + renderer plugins";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    lito = {
      url = "github:litocpp/lito";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    waywallen-src = {
      url = "github:waywallen/waywallen/v0.4.4";
      flake = false;
    };
    waywallen-display-src = {
      url = "github:waywallen/waywallen-display/v0.4.2";
      flake = false;
    };
    open-wallpaper-engine-src = {
      url = "github:waywallen/open-wallpaper-engine/v0.3.0";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      lito,
      waywallen-src,
      waywallen-display-src,
      open-wallpaper-engine-src,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      homeManagerModules = {
        default =
          { config, lib, pkgs, ... }:
          import ./modules/home-manager.nix {
            inherit
              config
              lib
              pkgs
              self
              ;
          };
        waywallen = self.homeManagerModules.default;
      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          litoPkg = pkgs.callPackage ./pkgs/lito.nix { };

          waywallen = pkgs.callPackage ./pkgs/waywallen.nix {
            lito = litoPkg;
            src = waywallen-src;
          };

          waywallen-open-wallpaper-engine = pkgs.callPackage ./pkgs/waywallen-open-wallpaper-engine.nix {
            lito = litoPkg;
            waywallen-plugins = waywallen;
            src = open-wallpaper-engine-src;
          };

          waywallen-layer-shell = pkgs.callPackage ./pkgs/waywallen-layer-shell.nix {
            src = waywallen-display-src;
          };

          waywallen-kde = pkgs.callPackage ./pkgs/waywallen-kde.nix {
            src = waywallen-display-src;
          };

          waywallen-gnome = pkgs.callPackage ./pkgs/waywallen-gnome.nix {
            src = waywallen-display-src;
          };
        in
        {
          inherit
            waywallen
            waywallen-open-wallpaper-engine
            waywallen-layer-shell
            waywallen-kde
            waywallen-gnome
            ;

          # Aliases for backwards compatibility
          waywallen-daemon = waywallen;
          waywallen-ui = waywallen;
          waywallen-plugins = waywallen;

          default = waywallen;
        }
      );
    };
}
