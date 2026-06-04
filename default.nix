{pkgs ? import <nixpkgs> {}}: let
  waywallen-daemon = pkgs.callPackage ./pkgs/waywallen-daemon.nix {};
  waywallen-ui = pkgs.callPackage ./pkgs/waywallen-ui.nix {};
  waywallen-plugins = pkgs.callPackage ./pkgs/waywallen-plugins.nix {};
  waywallen-layer-shell = pkgs.callPackage ./pkgs/waywallen-layer-shell.nix {};
  waywallen-kde = pkgs.callPackage ./pkgs/waywallen-kde.nix {};
  waywallen-gnome = pkgs.callPackage ./pkgs/waywallen-gnome.nix {};
in rec {
  inherit waywallen-daemon waywallen-ui waywallen-plugins waywallen-layer-shell waywallen-kde waywallen-gnome;

  waywallen-open-wallpaper-engine = pkgs.callPackage ./pkgs/waywallen-open-wallpaper-engine.nix {
    inherit waywallen-plugins;
  };

  # Combined package: daemon + plugins + open wallpaper engine + ui
  waywallen = pkgs.symlinkJoin {
    name = "waywallen-${waywallen-daemon.version}";
    paths = [waywallen-daemon waywallen-plugins waywallen-open-wallpaper-engine waywallen-ui];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/waywallen \
        --add-flags "--ui $out/bin/waywallen-ui --plugin $out/share/waywallen"
    '';
  };
}
