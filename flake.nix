{
  description = "waywallen - Rust daemon + Qt/QML UI + renderer plugins";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
  in {
    packages = forAllSystems (
      system: let
        pkgs = nixpkgsFor.${system};
        waywallen-daemon = pkgs.callPackage ./pkgs/waywallen-daemon.nix {};
        waywallen-ui = pkgs.callPackage ./pkgs/waywallen-ui.nix {};
        waywallen-plugins = pkgs.callPackage ./pkgs/waywallen-plugins.nix {};
        waywallen-display-layer-shell = pkgs.callPackage ./pkgs/waywallen-display-layer-shell.nix {};
        waywallen-kde = pkgs.callPackage ./pkgs/waywallen-kde.nix {};
        waywallen-gnome = pkgs.callPackage ./pkgs/waywallen-gnome.nix {};
      in rec {
        inherit waywallen-daemon waywallen-ui waywallen-plugins waywallen-display-layer-shell waywallen-kde waywallen-gnome;

        waywallen-open-wallpaper-engine = pkgs.callPackage ./pkgs/waywallen-open-wallpaper-engine.nix {
          inherit waywallen-plugins;
        };

        # Combined package: daemon + renderer plugins + ui + owe
        # in a single store path, suitable for `nix profile install`.
        waywallen = pkgs.symlinkJoin {
          name = "waywallen-${waywallen-daemon.version}";
          paths = [waywallen-daemon waywallen-plugins waywallen-open-wallpaper-engine waywallen-ui];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          meta =
            waywallen-daemon.meta
            // {
              description = "waywallen - daemon, renderer plugins, open-wallpaper-engine and UI";
            };
        };

        default = self.packages.${system}.waywallen;
      }
    );

    overlays.default = final: prev: {
      waywallen-daemon = final.callPackage ./pkgs/waywallen-daemon.nix {};
      waywallen-ui = final.callPackage ./pkgs/waywallen-ui.nix {};
      waywallen-plugins = final.callPackage ./pkgs/waywallen-plugins.nix {};
      waywallen-display-layer-shell = final.callPackage ./pkgs/waywallen-display-layer-shell.nix {};
      waywallen-kde = final.callPackage ./pkgs/waywallen-kde.nix {};
      waywallen-gnome = final.callPackage ./pkgs/waywallen-gnome.nix {};
      waywallen-open-wallpaper-engine = final.callPackage ./pkgs/waywallen-open-wallpaper-engine.nix {
        waywallen-plugins = final.waywallen-plugins;
      };
      waywallen = final.symlinkJoin {
        name = "waywallen-${final.waywallen-daemon.version}";
        paths = [final.waywallen-daemon final.waywallen-plugins final.waywallen-open-wallpaper-engine final.waywallen-ui];
        nativeBuildInputs = [ final.makeWrapper ];
        meta = final.waywallen-daemon.meta // {
          description = "waywallen - daemon, renderer plugins, open-wallpaper-engine and UI";
        };
      };
    };
  };
}
