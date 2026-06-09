{pkgs ? import <nixpkgs> {}}: let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);

  # Fetch git input from lockfile
  fetchInput = nodeName: let
    node = lock.nodes.${nodeName}.locked;
  in
    if node.type or "" == "github"
    then
      pkgs.fetchFromGitHub {
        owner = node.owner;
        repo = node.repo;
        rev = node.rev;
        hash = node.narHash;
      }
    else
      pkgs.fetchgit {
        url = node.url;
        rev = node.rev;
        hash = node.narHash;
      };

  waywallen-src = fetchInput "waywallen-src";
  waywallen-display-src = fetchInput "waywallen-display-src";
  open-wallpaper-engine-src = fetchInput "open-wallpaper-engine-src";

  # Parse deps.json from waywallen-src
  depsJson = builtins.fromJSON (builtins.readFile "${waywallen-src}/deps.json");

  # Helper to resolve sub-dependencies dynamically from deps.json
  fetchDep = name: let
    match = builtins.filter (d: d.x-cmake.name or "" == name) depsJson;
  in
    if builtins.length match > 0
    then let
      dep = builtins.head match;
    in
      if name == "qml_material"
      then
        pkgs.fetchgit {
          url = dep.url;
          rev = dep.commit;
          hash = "sha256-iygNy9PvQpK0/PoHCNOjMYNNn19YMSWFSaVakFK3XQI=";
          fetchLFS = true;
        }
      else
        builtins.fetchGit {
          url = dep.url;
          rev = dep.commit;
          allRefs = true;
        }
    else throw "Dependency ${name} not found in deps.json";

  waywallen-daemon = pkgs.callPackage ./pkgs/waywallen-daemon.nix {src = waywallen-src;};
  waywallen-ui = pkgs.callPackage ./pkgs/waywallen-ui.nix {
    src = waywallen-src;
    rstd-src = fetchDep "rstd";
    ncrequest-src = fetchDep "ncrequest";
    wavsen-src = fetchDep "wavsen";
    qml_material-src = fetchDep "qml_material";
    QExtra-src = fetchDep "QExtra";
    asio-src = fetchDep "asio";
    pegtl-src = fetchDep "pegtl";
  };
  waywallen-plugins = pkgs.callPackage ./pkgs/waywallen-plugins.nix {
    src = waywallen-src;
    rstd-src = fetchDep "rstd";
    wavsen-src = fetchDep "wavsen";
  };
  waywallen-layer-shell = pkgs.callPackage ./pkgs/waywallen-layer-shell.nix {src = waywallen-display-src;};
  waywallen-kde = pkgs.callPackage ./pkgs/waywallen-kde.nix {src = waywallen-display-src;};
  waywallen-gnome = pkgs.callPackage ./pkgs/waywallen-gnome.nix {src = waywallen-display-src;};
in rec {
  inherit waywallen-daemon waywallen-ui waywallen-plugins waywallen-layer-shell waywallen-kde waywallen-gnome;

  waywallen-open-wallpaper-engine = pkgs.callPackage ./pkgs/waywallen-open-wallpaper-engine.nix {
    inherit waywallen-plugins;
    src = open-wallpaper-engine-src;
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
